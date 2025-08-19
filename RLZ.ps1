Add-DnsServerPrimaryZone `
    -NetworkId "10.0.10.0/24" `
    -ZoneFile "10.0.10.in-addr.arpa.dns" `
    -DynamicUpdate Secure
