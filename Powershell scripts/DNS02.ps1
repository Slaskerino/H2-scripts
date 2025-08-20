#Hent og installer DNS
Get-WindowsFeature DNS
Install-WindowsFeature DNS -IncludeManagementTools -Restart

# Variabler
$ZoneName = "alpaco.local"           # Domænenavnet på zonen
$MasterDNS = "10.0.10.11"           # IP på din primary DNS-server (master)
$ZoneFile = "alpaco.local.dns"       # Filnavnet (kan være valgfrit, men standard er 'zonnavn.dns')

# Tilføj zonen som secondary
Add-DnsServerSecondaryZone -Name $ZoneName -ZoneFile $ZoneFile -MasterServers $MasterDNS


###### Skal køres på DC01
#Dette opretter DNS02 som name server i Alpaco.local

# ===============================
# CONFIGURATION
# ===============================
$DomainName = "alpaco.local"
$PrimaryDNS = "10.0.10.11" ##DC01
$SecondaryDNS = "10.0.10.22" ##DNS02

# ===============================
# ADD SECONDARY DNS AS NAME SERVER
# ===============================
# Hent den eksisterende forward zone
$zone = Get-DnsServerZone -Name $DomainName -ComputerName $PrimaryDNS

# Tilføj DNS02 som Name Server (NS-record)
Add-DnsServerSecondaryZone -Name $DomainName -MasterServers $PrimaryDNS -ComputerName $SecondaryDNS -ZoneFile "$DomainName.dns"

Write-Host "DNS02 ($SecondaryDNS) er nu tilføjet som sekundær Name Server for $DomainName"
