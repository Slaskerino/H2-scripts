# Set keyboard til dansk (https://learn.microsoft.com/en-us/answers/questions/618101/how-to-change-keyboard-in-windows-server-2019-core)
Set-ItemProperty 'HKCU:\Keyboard Layout\Preload' -Name 1 -Value 00000406

# Forsøg at installere VirtIO driver til netværk hvis drevet er mounted i D:
Write-Host "Forsoeger at installere virtIO driverpakke" -ForegroundColor Yellow

try {
    $Virtio_Drive_letter = Get-Volume | Where-Object { $_.FileSystemLabel -like "*virtio*"}
    $Virtio_Driver_Path = $Virtio_Drive_letter.DriveLetter
    $Virtio_Driver_Path += ":\virtio-win-gt-x64"
    msiexec.exe /i $Virtio_Driver_Path /qn /norestart
    Write-Host "Driver installeret" -ForegroundColor Green
}
catch {
    write-host "Kunne ikke installere VirtIO driver. Er der mounted en ISO til dette?"
}

# Hent info til netkort

$Host_IP = Read-Host "Hvilken IP skal serveren have?: "
$Host_DG = Read-Host "Hvilken IP Har Default gateway? "
$Prefix = 24
$DNS1 = "10.0.10.11"
$DNS2 = "10.142.12.2"
$IPv6_subnet = "2001:db8:acad:10::"

#Find InterfaceAlias på adapteren
$Adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" })

# Konfigurer netkort

Write-Host "Finder antal adaptere installeret samt forsoeger at tilfoje konfiguration" -ForegroundColor Yellow

if ($Adapters.count -eq 1) {
    Write-Host $Adapters.name "Bliver configureret"
    New-NetIPAddress -InterfaceAlias $Adapters.name -IPAddress $Host_IP -PrefixLength $Prefix -DefaultGateway $Host_DG
    Set-DnsClientServerAddress -InterfaceAlias $Adapters.name -ServerAddresses $DNS1,$DNS2
    ipconfig
    Write-Host "Konfiguration udfort" -ForegroundColor Green
}
elseif ($Adapters.count -gt 1) {
    Write-Host "Der er pt."$Adapters.count " adaptere installeret. De er foelgende:"
    Get-NetAdapter | Where-Object Status -eq "Up"
    $Single_Adapter = Read-Host "Hvilken adapter vil du opdatere? Du skal svare med navnet og det skal aere praecist det der staar: "

    Write-Host $Single_Adapter " Bliver configureret"
    New-NetIPAddress -InterfaceAlias $Single_Adapter -IPAddress $Host_IP -PrefixLength $Prefix -DefaultGateway $Host_DG
    Set-DnsClientServerAddress -InterfaceAlias $Single_Adapter -ServerAddresses $DNS1,$DNS2
    Write-Host "Konfiguration udfort" -ForegroundColor Green
}
else {
    Write-Host "Der er fandeme ikke nogen Adapterer! Har du installeret en driver Henri?!?" -ForegroundColor Red
}


# Få en ssh server op og køre

try {
    Write-Host "Installerer OpenSSH Server..." -ForegroundColor Cyan
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop

    Write-Host "Starter sshd service..." -ForegroundColor Cyan
    Start-Service sshd -ErrorAction Stop

    Write-Host "Konfigurerer sshd service til at starte automatisk..." -ForegroundColor Cyan
    Set-Service -Name "sshd" -StartupType Automatic -ErrorAction Stop

    Write-Host "Opretter firewall regel til sshd..." -ForegroundColor Cyan
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction Stop

    Write-Host "Opretter firewall regel til at tillade ICMP ping..." -ForegroundColor Cyan
    New-NetFirewallRule -Name allow-ping -DisplayName 'Svar ICMP req' -Enabled True -Direction Inbound -Protocol ICMPv4 -Action Allow -ErrorAction Stop

    Write-Host "OpenSSH Server installeret og konfigureret korrekt." -ForegroundColor Green
}
catch {
    Write-Host "Der opsted en fejl: $_" -ForegroundColor Red
}

# Sæt tidszone til dansk tid

Write-Host "Dansk tidszone konfigureres" -ForegroundColor Cyan
Set-TimeZone -Id "Central Europe Standard Time"
Write-Host "Dansk tidszone konfigureret" -ForegroundColor Green
 
# Spørg brugeren om nyt servernavn
$NewName = Read-Host "Indtast det nye servernavn: "
 
# Bekræft med brugeren inden ændringen
Write-Host "Det nye servernavn bliver sat til: $NewName" -ForegroundColor Yellow
$Confirm = Read-Host "Vil du fortsaette? (ja/nej)"

if ($Confirm -eq "ja") {
    try {
        # Ændr servernavnet
        Rename-Computer -NewName $NewName -Force
        Write-Host "Servernavn aendret til $NewName." -ForegroundColor Green
        Write-Host "Husk at genstarte senere i scriptet for at opdatere serverens hostname til $NewName..." -ForegroundColor Cyan
        
    }
    catch {
        Write-Host "Der opstod en fejl: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Intet foretaget." -ForegroundColor Gray
}

# Opdater hostname i registreringsdatabasen

if ($Confirm -eq "ja") {
    Write-Host "Opdaterer hostname i registreringsdatabasen" -ForegroundColor Yellow
    try {
        Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" 
        Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" 

        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value $NewName
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value $NewName
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value $NewName
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  $NewName
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value $NewName
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value $NewName

        Write-Host "Hvis det her virker, saa er det bare fe" -ForegroundColor Green
    }
    catch {
        Write-Host "Der opstod en fejl: $_" -ForegroundColor Red
    }
}

$actual_hostname = hostname

write-host "Nye hostname fra maskinen er: $actual_hostname"

if ($NewName -like "*DC*") {
    Write-Host "Konfigurerer IPv6 da dette er en DC" -ForegroundColor Gray
    $IPv6_address = $IPv6_subnet += Read-Host "Hvilken adresse skal hosten have paa subnettet $IPv6_subnet/64?:"
    try {
        New-NetIPAddress -InterfaceAlias $adapters.name -IPAddress $IPv6_address -PrefixLength 64 -AddressFamily IPv6
    }
    catch {
        Write-Host "Der opstod en fejl: $_" -ForegroundColor Red
    }
}
#Dette vil informere om en forældet version af Powershell og tilbyde at hent og installere nyere version.
try {
    if ($PSVersionTable.PSVersion.Major -ne 7) {
        $opdater_PS = Read-Host "Du kører på version $($PSVersionTable.PSVersion.Major) af PowerShell. Den seneste version er 7.5.2. Vil du opdatere? (ja/nej)"
        
        if ($opdater_PS -eq "ja") {
            # Lav temp-mappe hvis den ikke findes
            if (-not (Test-Path "C:\temp")) {
                New-Item -ItemType Directory -Path "C:\temp" | Out-Null
            }

            # Download MSI
            Start-BitsTransfer -Source "https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi" -Destination "C:\temp\pwsh.msi"

            # Installer MSI
            Start-Process -FilePath "msiexec.exe" -ArgumentList '/package "C:\temp\pwsh.msi" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1' -Wait

            Write-Host "PowerShell er opdateret. Husk at bruge 'pwsh' for at starte PowerShell 7 fremover." -ForegroundColor Green
        }
        else {
            Write-Host "PowerShell bliver ikke opdateret."
        }
    }
    else {
        Write-Host "PowerShell ser ud til at være opdateret."
    }
}
catch {
    Write-Host "Der opstod en fejl under opdateringen: $($_.Exception.Message)" -ForegroundColor Red
}

#Vi opsætter forbindelse til NTP server.
try {
    Write-Host "Opdaterer NTP server til $Ntpserver" -ForegroundColor Cyan 

    # Angiv NTP-server
    $NtpServer = "time.windows.com,0x9"

    # Stop tidsservice
    Stop-Service w32time -ErrorAction Stop

    # Konfigurer NTP-serveren
    w32tm /config /manualpeerlist:$NtpServer /syncfromflags:manual /reliable:YES /update

    # Start tidsservice
    Start-Service w32time -ErrorAction Stop

    # Tving straks en tidsopdatering
    w32tm /resync /nowait

    Write-Host "NTP-server sat til $NtpServer og tidssynkronisering startet." -ForegroundColor Green
}
catch {
    Write-Host "Der opstod en fejl under NTP konfururationen." -ForegroundColor Red  # <-- Enter your error message here
    Write-Host "Fejl detaljer: $_" -ForegroundColor Red
}

# Domænenavn
$domainName = "alpaco.local"

Write-Host "starter domain tilslutning af $NewName til $domainName ..." -ForegroundColor Cyan

# Input: Admin bruger til domænet 
$domainUser += $domainName + "\"
$domainUser += Read-Host "Indtast brugernavn med domain-admin rettigheder"

# Input: Password (skjult)
$password = Read-Host "Indtast adgangskode" -AsSecureString

# Lav PSCredential objekt
$credential = New-Object System.Management.Automation.PSCredential ($domainUser, $password)

try {
    Write-Host "Forsoeger at tilfoeje computeren til domainet $domainName ..." -ForegroundColor Cyan
    
    Add-Computer -DomainName $domainName -Credential $credential -Force -ErrorAction Stop

    Write-Host "Computeren er blevet tilfoejet til domainet $domainName." -ForegroundColor Green

    # Spørg om genstart
    $restart = Read-Host "Vil du genstarte computeren nu? (J/N)"
    if ($restart.ToUpper() -eq 'J') {
        Restart-Computer
    } else {
        Write-Host "Husk at genstarte computeren senere for at fuldfore domain-join."
    }

} catch {
    Write-Error "Noget gik galt under domaine tilknytning: $($_.Exception.Message)"
}