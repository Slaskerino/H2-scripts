$zonefile = "10.0.10.in-addr.arpa.dns"
$DomainName = "alpaco.local"
$PrimaryDNS = "10.0.10.11" ##DC01
$SecondaryDNS = "10.0.10.22" ##DNS02



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
    Set-DnsServerPrimaryZone -ComputerName DC01 -Name $DomainName -ZoneTransferType Specific -SecondaryServers $SecondaryDNS
    Write-Host "Ja fandeme om $SecondaryDNS blev oprettet!"
}
catch {
    Write-Host "Bedre held en anden gang: $($_.Exception.Message)"
}



try {
    Add-DnsServerSecondaryZone -Name $DomainName -MasterServers $PrimaryDNS -ComputerName $SecondaryDNS -ZoneFile $zonefile
    Write-Host "Serveren $SecondaryDNS blev oprettet som 2. DNS server for zonen $zonefile"
}
catch {
    Write-Host "Serveren kunne ikke tilfojes grundet: $($_.Exception.Message)"
}