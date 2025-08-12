#########DC-Server

#Denne del installerer de manglende RSAT features, som ikke i forvejen er installeret.
Get-WindowsFeature *RSAT* | Install-WindowsFeature

#Installerer AD DS rollen på DC'en.
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

#Denne opretter et nyt domæne ved navn Alpaco.local og beder om adminstrator password.
Install-ADDSForest -DomainName "Alpaco.local" -DomainNetbiosName "Alpaco" -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password")


########## Management server

#Denne installerer AD tools på managements serveren.
Add-WindowsCapability -Online -Name RSAT:ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

#Denne installerer DNS tools på management serveren.
Add-WindowsCapability -Online -Name RSAT:DNS.Server.Tools~~~~0.0.1.0

#Denne installerer Fil server tools på management serveren. Bruges til fil serveren.
Install-WindowsFeature RSAT-File-Services