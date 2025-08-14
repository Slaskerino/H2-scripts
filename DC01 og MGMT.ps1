######## DC-server

#Dette installerer rollen som AD domain service.
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

#Nedenstående promoverer til DC og laver en ny forest med domain name.
Install-ADDSForest -DomainName "alpaco.local" -DomainNetbiosName "Alpaco" -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password")

#Powershell remote acces aktiveres.
Enable-PSRemoting -Force

#Aktiverer MMC og andre værktøjer.
Configure-SMRemoting.exe -Enable



######### MGMT server

#Nedenstående tilføjer pc til domænet.
Add-Computer -DomainName "Alpaco.local" -Credential (Get-Credential) -Restart

#DNS på management serveren peger over på DC'ens IP.
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "10.0.10.11"
