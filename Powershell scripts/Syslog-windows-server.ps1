# Define variables
$nxlogUrl = "https://dl.nxlog.co/dl/68ac2ca8f1127"  # <-- Replace with your actual download link
$installerPath = "$env:TEMP\nxlog.msi"
$nxlogConfPath = "C:\Program Files\nxlog\conf\nxlog.conf"
$graylogIP = "10.0.10.15"
$graylogPort = 1531

# Download NXLog MSI
Write-Host "Downloading NXLog..."
Invoke-WebRequest -Uri $nxlogUrl -OutFile $installerPath

# Install NXLog silently
Write-Host "Installing NXLog..."
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /qn"

# Wait briefly to ensure installation is complete
Start-Sleep -Seconds 5

# Define NXLog configuration
$nxlogConf = @"
define ROOT C:\Program Files\nxlog
Moduledir \${ROOT}\modules
CacheDir \${ROOT}\data
Pidfile \${ROOT}\data\nxlog.pid
SpoolDir \${ROOT}\data
LogFile \${ROOT}\data\nxlog.log

<Extension _syslog>
    Module      xm_syslog
</Extension>

<Input in_eventlog>
    Module      im_msvistalog
</Input>

<Output out_graylog>
    Module      om_udp
    Host        $graylogIP
    Port        $graylogPort
    OutputType  Syslog_UDP
</Output>

<Route r>
    Path        in_eventlog => out_graylog
</Route>
"@

# Write the configuration file
Write-Host "Writing NXLog configuration..."
Set-Content -Path $nxlogConfPath -Value $nxlogConf -Encoding UTF8

# Start NXLog service
Write-Host "Starting NXLog service..."
Start-Service -Name nxlog

Write-Host "NXLog installation and configuration complete. Logs should now be forwarded to $graylogIP:$graylogPort via UDP."
