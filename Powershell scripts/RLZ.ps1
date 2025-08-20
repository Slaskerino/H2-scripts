$Zone = "10.0.10.in-addr.arpa"
$zonefile = "10.0.10.in-addr.arpa.dns"
$DomainName = "alpaco.local"
$PrimaryDNS = "10.0.10.11" ##DC01
$SecondaryDNS = "10.0.10.22" ##DNS02
#$zonepolicy = $(Get-DnsServerZoneTransferPolicy -ComputerName dc01)


try {
    #Opretter en primær DNS-zone for netværket 10.0.10.0/24 med den angivne zonefil
    Add-DnsServerPrimaryZone `
    -NetworkId "10.0.10.0/24" `
    -ZoneFile $zonefile `
    -DynamicUpdate Secure `
    -ComputerName $PrimaryDNS
    
    Write-Host "Zonen $zonefile blev oprettet"
}
catch {
    Write-Host "Zonen blev ikke oprettet grundet: $($_.Exception.Message)"
}

try {
    #Her konfigureres zonetransfer til kun at sende til den specificerede sekundære DNS-server ($SecondaryDNS) og sætter den som sikker sekundær.
    Set-DnsServerPrimaryZone -Name $zone -SecureSecondaries "TransferToSecureServers" -SecondaryServers $SecondaryDNS -ComputerName $PrimaryDNS
    Write-Host "Serveren $SecondaryDNS blev oprettet som 2. DNS server for zonen $zonefile"
}
catch {
    Write-Host "Serveren kunne ikke tilfojes grundet: $($_.Exception.Message)"
}

try {
    #Her konfigureres DNS-replikation, så sekundærserveren får en kopi af zonen fra primærserveren.
    Add-DnsServerSecondaryZone -Name $zone -MasterServers $PrimaryDNS -ComputerName $SecondaryDNS -ZoneFile $zonefile
    Write-Host "Serveren $SecondaryDNS blev oprettet som 2. DNS server for zonen $zonefile"
}
catch {
    Write-Host "Serveren kunne ikke tilfojes grundet: $($_.Exception.Message)"
}

