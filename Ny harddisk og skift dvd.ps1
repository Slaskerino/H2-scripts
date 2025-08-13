#Flyt DVD-drevet (hvis D: allerede er taget)
$cdrom = Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.DriveLetter -eq "D:" -and $_.DriveType -eq 5 }
if ($cdrom) {
    Set-CimInstance -InputObject $cdrom -Property @{DriveLetter = "Z:"}
    Write-Host "DVD-drevet flyttet til Z:"
}

#Find ny disk (Offline, ikke initialiseret)
$newDisk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Offline" -or $_.PartitionStyle -eq "RAW" } | Select-Object -First 1

if (-not $newDisk) {
    Write-Host "Ingen ny disk fundet!"
    exit
}

#Gør disken online og initialiser
Initialize-Disk -Number $newDisk.Number -PartitionStyle GPT
Write-Host "Disk initialiseret."

#Opret partition og formater
$part = New-Partition -DiskNumber $newDisk.Number -UseMaximumSize -AssignDriveLetter
Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false
Write-Host "Disk formateret."

#Tildel drevbogstav D:
Write-Host "Disk tildelt drevbogstav D:"