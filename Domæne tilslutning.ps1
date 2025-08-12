# Input: Domænenavn
$domainName = "alpaco.local"

# Input: Brugernavn til domænet (kan skrives som f.eks. 'CONTOSO\Administrator' eller 'Administrator')
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