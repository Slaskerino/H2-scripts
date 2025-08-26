Invoke-Command -ComputerName "DC01" -ScriptBlock {
    Import-Module ActiveDirectory

    $driveLetter = "H:"
    $errorLog = @()

    # Get all users (customize filter or OU as needed)
    $users = Get-ADUser -Filter {HomeDirectory -notlike "*"} -SearchBase "OU=staff,DC=alpaco,DC=local" -Properties SamAccountName, HomeDirectory, HomeDrive

    foreach ($user in $users) {
        try {
            $username = $user.SamAccountName
            $homePath = "\\fil01\homedrive\$username"

            Set-ADUser -Identity $user.DistinguishedName `
                -HomeDirectory $homePath `
                -HomeDrive $driveLetter

            Write-Host "✅ Updated $username: $homePath mapped to $driveLetter" -ForegroundColor Green
        }
        catch {
            $errorMessage = "❌ Failed to update $($user.SamAccountName): $($_.Exception.Message)"
            Write-Warning $errorMessage 
            $errorLog += $errorMessage
        }
    }

    # Output summary of errors (if any)
    if ($errorLog.Count -gt 0) {
        Write-Host "`n=== Errors Encountered ==="
        $errorLog | ForEach-Object { Write-Host $_ }
    }
}
