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
New-NetFirewallRule -DisplayName "DNS TCP Port 53" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow
New-NetFirewallRule -DisplayName "DNS UDP Port 53" -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow

#Opret DNS forwarder
Set-DnsServerForwarder -IPAddress "10.142.12.2","10.142.12.3" -PassThru

########## MGMT - Management server

#Denne installerer AD tools på managements serveren.
Add-WindowsCapability -Online -Name RSAT:ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

#Denne installerer DNS tools på management serveren.
Add-WindowsCapability -Online -Name RSAT:DNS.Server.Tools~~~~0.0.1.0

#Denne installerer Fil server tools på management serveren. Bruges til fil serveren.
Install-WindowsFeature RSAT-File-Services

