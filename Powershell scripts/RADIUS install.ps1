# Run in an elevated PowerShell session on Windows Server 2022

$ErrorActionPreference = 'Stop'

Write-Host "Installing NPS (NPAS) with management tools..." -ForegroundColor Cyan
$feature = Get-WindowsFeature -Name NPAS
if (-not $feature.Installed) {
    Install-WindowsFeature -Name NPAS -IncludeManagementTools -Verbose
} else {
    Write-Host "NPS is already installed." -ForegroundColor Yellow
}

# Ensure the NPS service is enabled and running
Write-Host "Configuring the NPS service (IAS)..." -ForegroundColor Cyan
Set-Service -Name IAS -StartupType Automatic
Start-Service -Name IAS

# OPTIONAL: Register NPS in Active Directory (required for PEAP/EAP auth reading user properties)
# Requires the server to be domain-joined and you to be a Domain Admin or have delegated rights.
try {
    Write-Host "Attempting to register this NPS in Active Directory..." -ForegroundColor Cyan
    # This is equivalent to the GUI "Register server in Active Directory"
    netsh nps add registeredserver
    Write-Host "NPS registered in AD (or already registered)." -ForegroundColor Green
}
catch {
    Write-Host "Skipping AD registration (are you domain-joined and running as a domain admin?)." -ForegroundColor Yellow
}

# Open common RADIUS ports (adjust to your environment)
Write-Host "Creating firewall rules for RADIUS (UDP 1812/1813 and legacy 1645/1646)..." -ForegroundColor Cyan
$rules = @(
    @{Name='NPS RADIUS Auth 1812 UDP'; Port=1812},
    @{Name='NPS RADIUS Acct 1813 UDP'; Port=1813},
    @{Name='NPS RADIUS Auth 1645 UDP'; Port=1645},  # legacy
    @{Name='NPS RADIUS Acct 1646 UDP'; Port=1646}   # legacy
)
foreach ($r in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Protocol UDP -LocalPort $r.Port -Action Allow | Out-Null
    }
}

# Verify
Write-Host "`nVerification:" -ForegroundColor Cyan
Get-WindowsFeature NPAS | Format-Table DisplayName, InstallState
Get-Service IAS | Format-Table Name, Status, StartType

Write-Host "`nDone. Launch the console with: nps.msc" -ForegroundColor Green