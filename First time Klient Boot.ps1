Set-ExecutionPolicy RemoteSigned -Scope CurrentUser


#Find InterfaceAlias på adapteren
$Adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" })

if ($Adapters.count -eq 1) {
    Write-Host $Adapters.Name "Bliver sat til DHCP"
    Set-NetIPInterface -InterfaceAlias $Adapters.Name -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $Adapters.Name -ResetServerAddresses
}
elseif ($Adapters.count -gt 1) {
    Write-Host "Der er pt." $Adapters.count "adaptere installeret. De er følgende:"
    Get-NetAdapter | Where-Object Status -eq "Up"
    $Single_Adapter = Read-Host "Hvilken adapter vil du opdatere? (navnet skal være præcist som vist)"
    Set-NetIPInterface -InterfaceAlias $Single_Adapter -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $Single_Adapter -ResetServerAddresses
}
else {
    Write-Host "Der er ikke nogen adaptere!"
}

#Anskaffer sig en Ip adresse fra DHCP serveren
Write-Host "Frigiver IP..."
ipconfig /release

Write-Host "Fornyer IP..."
ipconfig /renew

Write-Host "Anskaffer sig en IP fra DHCP serveren, vent venligst"
Start-Sleep -Seconds 10


# Sæt tidszone til dansk tid
Set-TimeZone -Id "Central Europe Standard Time"

# Spørg brugeren om nyt pcnavn
$NewName = Read-Host "Indtast det nye Computernavn: "
 
# Bekræft med brugeren inden ændringen
Write-Host "Det nye computernavn bliver sat til: $NewName" -ForegroundColor Yellow
$Confirm = Read-Host "Vil du fortsætte? (ja/nej)"
 
if ($Confirm -eq "ja") {
    try {
        # Ændre pcnavnet
        Rename-Computer -NewName $NewName -Force
        Write-Host "Computernavn aendret til $NewName." -ForegroundColor Green
        
    }
    catch {
        Write-Host "Der opstod en fejl: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Ingen ændringer foretaget." -ForegroundColor Gray
}

# Input: Domænenavn
$domainName = "alpaco.local"

# Input: Admin bruger til domænet 
$domainUser += $domainName + "\"
$domainUser += Read-Host "Indtast brugernavn med admin rettigheder"

# Input: Password (skjult)
$password = Read-Host "Indtast adgangskode" -AsSecureString

# Lav PSCredential objekt
$credential = New-Object System.Management.Automation.PSCredential ($domainUser, $password)

try {
    Write-Host "Forsøger at tilføje computeren til domænet $domainName ..." -ForegroundColor Cyan
    
    Add-Computer -DomainName $domainName -Credential $credential -Force -ErrorAction Stop

    Write-Host "Computeren er blevet tilføjet til domænet $domainName." -ForegroundColor Green

    # Spørg om genstart
    $restart = Read-Host "Vil du genstarte computeren nu? (J/N)"
    if ($restart.ToUpper() -eq 'J') {
        Restart-Computer
    } else {
        Write-Host "Husk at genstarte computeren senere for at fuldføre domæne-join."
    }

} catch {
    Write-Error "Noget gik galt under domænetilknytning: $($_.Exception.Message)"
}