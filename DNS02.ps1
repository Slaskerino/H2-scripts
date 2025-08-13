#Hent og installer DNS
Get-WindowsFeature DNS
Install-WindowsFeature DNS -IncludeManagementTools -Restart

# Variabler
$ZoneName = "alpaco.local"           # Domænenavnet på zonen
$MasterDNS = "10.0.10.11"           # IP på din primary DNS-server (master)
$ZoneFile = "alpaco.local.dns"       # Filnavnet (kan være valgfrit, men standard er 'zonnavn.dns')

# Tilføj zonen som secondary
Add-DnsServerSecondaryZone -Name $ZoneName -ZoneFile $ZoneFile -MasterServers $MasterDNS