######### DC01 - Domain controller Server

#Denne del installerer de manglende RSAT features, som ikke i forvejen er installeret.
Get-WindowsFeature *RSAT* | Install-WindowsFeature

#Installerer AD DS rollen på DC'en.
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

#Denne opretter et nyt domæne ved navn Alpaco.local og beder om adminstrator password.
Install-ADDSForest -DomainName "Alpaco.local" -DomainNetbiosName "Alpaco" -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password")

#Denne rolle tillader zoneoverførsel af DNS fra serveren.
Install-WindowsFeature DNS -IncludeManagementTools

#Her sættes primary DNS zone og pointerer secondary DNS server.
Set-DnsServerPrimaryZone -Name "alpaco.local" -securesecondaries transfertosecureservers -SecondaryServers "10.0.10.22"

#Åben op for TCP 53 forbindelsen fra DC01 til DNS02 igennem firewall.
New-NetFirewallRule -DisplayName "DNS Zone Transfer TCP" -Direction Inbound -Protocol TCP -LocalPort 53 -RemoteAddress 10.0.10.22 -Action Allow


########## MGMT - Management server

#Denne installerer AD tools på managements serveren.
Add-WindowsCapability -Online -Name RSAT:ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

#Denne installerer DNS tools på management serveren.
Add-WindowsCapability -Online -Name RSAT:DNS.Server.Tools~~~~0.0.1.0

#Denne installerer Fil server tools på management serveren. Bruges til fil serveren.
Install-WindowsFeature RSAT-File-Services


########### DNS02 - DNS server

#Denne del installerer de manglende RSAT features, som ikke i forvejen er installeret.
Get-WindowsFeature *RSAT* | Install-WindowsFeature

#Ovenstående kræver genstart før resten kan køres

# Variabler
$ZoneName = "alpaco.local"           # Domænenavnet på zonen
$MasterDNS = "10.0.10.11"           # IP på din primary DNS-server (master)
$ZoneFile = "alpaco.local.dns"       # Filnavnet (kan være valgfrit, men standard er 'zonnavn.dns')

# Tilføj zonen som secondary
Add-DnsServerSecondaryZone -Name $ZoneName -ZoneFile $ZoneFile -MasterServers $MasterDNS
