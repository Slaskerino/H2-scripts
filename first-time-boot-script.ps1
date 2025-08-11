# Set keyboard til dansk (https://learn.microsoft.com/en-us/answers/questions/618101/how-to-change-keyboard-in-windows-server-2019-core)
Set-ItemProperty 'HKCU:\Keyboard Layout\Preload' -Name 1 -Value 00000406

# Forsøg at installere VirtIO driver til netværk

try {
    $Virtio_Drive_letter = Get-Volume | Where-Object { $_.FileSystemLabel -like "*virtio*"}
    $Virtio_Driver_Path = $Virtio_Drive_letter.DriveLetter
    $Virtio_Driver_Path += ":\virtio-win-gt-x64"
    msiexec.exe /i $Virtio_Driver_Path /qn /norestart
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


#Find InterfaceAlias på adapteren
$Adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" })

# Konfigurer netkort

if ($Adapters.count -eq 1) {
    Write-Host $Adapters.name "Bliver configureret"
    New-NetIPAddress -InterfaceAlias $Adapters.name -IPAddress $Host_IP -PrefixLength $Prefix -DefaultGateway $Host_DG
    Set-DnsClientServerAddress -InterfaceAlias $Adapters.name -ServerAddresses $DNS1,$DNS2
}
elseif ($Adapters.count -gt 1) {
    Write-Host "Der er pt."$Adapters.count " adaptere installeret. De er følgende:"
    Get-NetAdapter | Where-Object Status -eq "Up"
    $Single_Adapter = Read-Host "Hvilken adapter vil du opdatere? Du skal svare med navnet og det skal være præcist det der står: "
}
else {
    Write-Host "Der er fandeme ikke nogen Adapterer! Har du installeret en driver Henri?!?"
}

# Få en ssh server op og køre

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name "sshd" -StartupType Automatic
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22


# Sæt tidszone til dansk tid
Set-TimeZone -Id "Central Europe Standard Time"
 
# Spørg brugeren om nyt servernavn
$NewName = Read-Host "Indtast det nye servernavn: "
 
# Bekræft med brugeren inden ændringen
Write-Host "Det nye servernavn bliver sat til: $NewName" -ForegroundColor Yellow
$Confirm = Read-Host "Vil du fortsætte? (ja/nej)"
 
if ($Confirm -eq "ja") {
    try {
        # Ændr servernavnet
        Rename-Computer -NewName $NewName -Force
        Write-Host "Servernavn aendret til $NewName." -ForegroundColor Green
        Write-Host "Genstarter for at gennemfoere aendringen..." -ForegroundColor Cyan
        # Genstart maskinen
        Restart-Computer
    }
    catch {
        Write-Host "Der opstod en fejl: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Ingen ændringer foretaget." -ForegroundColor Gray
}

if ($PSVersionTable.PSVersion.Major -isnot 7) {
    $opdater_PS = Read-Host "Du kører på Version "$PSVersionTable.PSVersion.Major" af Powershell. Den seneste version er 7.5.2. Vil du opdatere? (ja/nej)"
    if($opdater_PS -eq "ja") {
        Start-BitsTransfer -Source "https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi" -Destination "pwsh.msi"
        msiexec.exe /i "pwsh.msi" /qn /norestart
    }
    else {
        write-host "Powershell bliver ikke opdateret"
    }
}
else {
    Write-Host "Powershell ser ud til at være opdateret"
}

# Angiv NTP-server, fx Microsofts offentlige
$NtpServer = "time.windows.com,0x9"
 
# Stop tidsservice
Stop-Service w32time
 
# Konfigurer NTP-serveren
w32tm /config /manualpeerlist:$NtpServer /syncfromflags:manual /reliable:YES /update
 
# Start tidsservice
Start-Service w32time
 
# Tving straks en tidsopdatering
w32tm /resync /nowait
 
Write-Host "NTP-server sat til $NtpServer og tidssynkronisering startet." -ForegroundColor Green
# Din mor er en mand

