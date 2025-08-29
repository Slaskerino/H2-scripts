# Angiv NTP-server, fx Microsofts offentlige
$NtpServer = "time.windows.com,0x9"

# Stop tidsservice
Stop-Service w32time

# Konfigurer NTP-serveren
w32tm /config /manualpeerlist:$NtpServer /syncfromflags:manual /reliable:YES /update

# Start tidsservice
Start-Service w32time

# Tving straks en tidsopdatering
w32tm /resync /nowait

Write-Host "NTP-server sat til $NtpServer og tidssynkronisering startet." -ForegroundColor Green
