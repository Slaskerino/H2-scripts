<# 
Hvad scriptet gør :

D:\data: slår nedarvning fra og sætter kun SYSTEM + Domain Admins = Full Control.

Salg/Marketing/Produktion/CorpData: sætter eksplicit NTFS:

SYSTEM = Full, Domain Admins = Full, relevant FGr_* = Modify.

Shares (samme navn som mappen): giver Authenticated Users = Full Access (share-niveau) + sikrer drift-adgang (Admins/SYSTEM).

Indeholder validering af gruppenavne, så du får en tydelig fejl hvis en FGr_* mangler.

FGr_*** = Sikkerhedsgrupper i AD, der skal oprettes på forhånd.

#>

$ErrorActionPreference = 'Stop'

# === Konfiguration ===
$RootPath = 'D:\data'
$Map = @{
    'Salg'       = 'FGr_Salg'
    'Marketing'  = 'FGr_Marketing'
    'Produktion' = 'FGr_Produktion'
    'CorpData'   = 'FGr_CorpData'
}

# Find domænets NetBIOS-navn (til "Domain Admins") – fallback til USERDOMAIN
$DomainNetBIOS = try { (Get-ADDomain).NetBIOSName } catch { $env:USERDOMAIN }

# Identities
$SYSTEM          = 'NT AUTHORITY\SYSTEM'
$DomainAdmins    = "$DomainNetBIOS\Domain Admins"
$Authenticated   = 'Authenticated Users'

# --- Helper: valider at en konto/gruppe kan mappes til SID ---
function Test-Principal {
    param([Parameter(Mandatory)][string]$Identity)
    try {
        ([System.Security.Principal.NTAccount]$Identity).
            Translate([System.Security.Principal.SecurityIdentifier]) | Out-Null
        return $true
    } catch { return $false }
}

# --- Helper: sæt præcis (eksplicit) ACL på en mappe; ingen nedarvning ---
function Set-ExactAcl {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][array]$Rules # hver: @{ Identity='DOM\X'; Rights='FullControl' | 'Modify' }
    )
    # Sørg for, at stien findes
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }

    # Byg en ny DirectorySecurity fra scratch (disable inheritance og fjern arvede)
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false) # disable inheritance, remove inherited rules

    $inheritFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    $propFlags    = [System.Security.AccessControl.PropagationFlags]::None

    foreach ($r in $Rules) {
        if (-not (Test-Principal $r.Identity)) {
            throw "Kan ikke mappe identitet til SID: '$($r.Identity)'. Findes kontoen/gruppen?"
        }
        $rights = [System.Security.AccessControl.FileSystemRights]$r.Rights
        $ntacc  = New-Object System.Security.Principal.NTAccount($r.Identity)
        $rule   = New-Object System.Security.AccessControl.FileSystemAccessRule($ntacc, $rights, $inheritFlags, $propFlags, 'Allow')
        $acl.AddAccessRule($rule) | Out-Null
    }

    Set-Acl -Path $Path -AclObject $acl
}

# --- Helper: sikr (idempotent) SMB-share med AU = Full + Admins/SYSTEM ---
function Ensure-Share {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Path
    )
    $existing = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-SmbShare -Name $Name -Path $Path -FullAccess @($Authenticated, 'BUILTIN\Administrators', $SYSTEM) | Out-Null
        Write-Host "Share oprettet: \\$env:COMPUTERNAME\$Name" -ForegroundColor Green
    } else {
        Write-Host "Share findes allerede: $Name" -ForegroundColor DarkGray
        # Sikr at AU har Full
        $has = Get-SmbShareAccess -Name $Name | Where-Object { $_.AccountName -ieq $Authenticated -and $_.AccessRight -eq 'Full' }
        if (-not $has) {
            Grant-SmbShareAccess -Name $Name -AccountName $Authenticated -AccessRight Full -Force | Out-Null
            Write-Host "Tilføjede 'Authenticated Users' = Full på share '$Name'." -ForegroundColor Green
        }
    }
}

# 1) Opret rodmappe og sæt præcis ACL (kun SYSTEM + Domain Admins = Full)
if (-not (Test-Path $RootPath)) {
    New-Item -ItemType Directory -Path $RootPath -Force | Out-Null
    Write-Host "Oprettede mappe: $RootPath" -ForegroundColor Green
} else {
    Write-Host "Mappe findes allerede: $RootPath" -ForegroundColor DarkGray
}

Write-Host "Sætter NTFS på $RootPath (kun SYSTEM og Domain Admins = Full, ingen nedarvning)..." -ForegroundColor Cyan
Set-ExactAcl -Path $RootPath -Rules @(
    @{ Identity = $SYSTEM;       Rights = 'FullControl' }
    @{ Identity = $DomainAdmins; Rights = 'FullControl' }
)

# 2) Undermapper: opret, stop nedarvning og sæt eksplicitte rettigheder
foreach ($kvp in $Map.GetEnumerator()) {
    $FolderName = $kvp.Key
    $GroupName  = $kvp.Value
    $FolderPath = Join-Path $RootPath $FolderName

    if (-not (Test-Principal $GroupName)) {
        throw "Gruppen findes ikke: '$GroupName'. Opret den i AD eller ret navnet."
    }

    # Sæt præcis ACL: SYSTEM = Full, Domain Admins = Full, FGr_<xxx> = Modify
    Write-Host "Sætter NTFS på $FolderPath ..." -ForegroundColor Cyan
    Set-ExactAcl -Path $FolderPath -Rules @(
        @{ Identity = $SYSTEM;       Rights = 'FullControl' }
        @{ Identity = $DomainAdmins; Rights = 'FullControl' }
        @{ Identity = $GroupName;    Rights = 'Modify' }
    )

    # 3) Del mappen med AU = Full (og Admins/System for drift)
    Ensure-Share -Name $FolderName -Path $FolderPath
}

# 4) Hurtig verifikation
Write-Host "`n=== Verifikation (uddrag) ===" -ForegroundColor Yellow
Get-ChildItem $RootPath -Directory | ForEach-Object {
    Write-Host "`n$($_.FullName)" -ForegroundColor Cyan
    icacls $_.FullName | Select-Object -First 5 | ForEach-Object { $_ }
}
Write-Host "`nShare-tilgange:" -ForegroundColor Yellow
Get-SmbShare | Where-Object { $_.Path -like "$RootPath*" } | ForEach-Object {
    Write-Host "`nShare $($_.Name)" -ForegroundColor Cyan
    Get-SmbShareAccess -Name $_.Name | Format-Table -AutoSize
}
Write-Host "`nFærdig ✔️" -ForegroundColor Green