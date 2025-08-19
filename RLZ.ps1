$zonefile = "10.0.10.in-addr.arpa.dns"
$DomainName = "alpaco.local"
$PrimaryDNS = "10.0.10.11" ##DC01
$SecondaryDNS = @("10.0.10.22") ##DNS02
#$zonepolicy = $(Get-DnsServerZoneTransferPolicy -ComputerName dc01)


try {
    Add-DnsServerPrimaryZone `
    -NetworkId "10.0.10.0/24" `
    -ZoneFile $zonefile `
    -DynamicUpdate Secure
    
    Write-Host "Zonen $zonefile blev oprettet"
}
catch {
    Write-Host "Zonen blev ikke oprettet grundet: $($_.Exception.Message)"
}

try {
    Set-DnsServerPrimaryZone -Name $zonefile -SecureSecondaries "TransferToSecureServers" -SecondaryServers $SecondaryDNS -ComputerName $PrimaryDNS
    Write-Host "Serveren $SecondaryDNS blev oprettet som 2. DNS server for zonen $zonefile"
}
catch {
    Write-Host "Serveren kunne ikke tilfojes grundet: $($_.Exception.Message)"
}

try {
    Add-DnsServerSecondaryZone -Name $DomainName -MasterServers $PrimaryDNS -ComputerName $SecondaryDNS -ZoneFile $zonefile
    Write-Host "Serveren $SecondaryDNS blev oprettet som 2. DNS server for zonen $zonefile"
}
catch {
    Write-Host "Serveren kunne ikke tilfojes grundet: $($_.Exception.Message)"
}

