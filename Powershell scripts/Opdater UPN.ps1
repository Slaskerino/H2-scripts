# Import AD module (for systems that need it)
Import-Module ActiveDirectory

# Optional: log file path
$logPath = "C:\Scripts\upn_update_log.txt"
$errorLog = @()

# Fetch all users with UPN ending in @alpaca.local
$users = Get-ADUser -Filter {UserPrincipalName -like "*@alpaca.local"} -Properties UserPrincipalName, SamAccountName

foreach ($user in $users) {
    try {
        $oldUPN = $user.UserPrincipalName
        $newUPN = "$($user.SamAccountName)@alpaco.local"

        Set-ADUser -Identity $user.DistinguishedName -UserPrincipalName $newUPN

        $logEntry = "✅ Updated $($user.SamAccountName): $oldUPN → $newUPN"
        Write-Host $logEntry
        Add-Content -Path $logPath -Value $logEntry
    }
    catch {
        $errorEntry = "❌ Failed to update $($user.SamAccountName): $($_.Exception.Message)"
        Write-Warning $errorEntry
        Add-Content -Path $logPath -Value $errorEntry
        $errorLog += $errorEntry
    }
}

# Show summary of errors (if any)
if ($errorLog.Count -gt 0) {
    Write-Host "`n=== Errors Encountered ==="
    $errorLog | ForEach-Object { Write-Host $_ }
}
