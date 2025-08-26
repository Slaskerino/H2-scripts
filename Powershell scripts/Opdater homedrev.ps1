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

            Write-Host "✅ Updated ${username}: $homePath mapped to $driveLetter" -ForegroundColor Green
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


Invoke-Command -ComputerName "dc01" -ScriptBlock {
    #Import-Module ActiveDirectory

    $sharePath = "\\fil01\homefolders"
    $domainAdminsGroup = "alpaco.local\Domain Admins"   # Replace with your actual domain
    $users = Get-ADUser -Filter {HomeDirectory -like "*"} -SearchBase "OU=staff,DC=alpaco,DC=local" -Properties SamAccountName, HomeDirectory, HomeDrive

    foreach ($user in $users) {
        $username = $user.SamAccountName
        $homeDir = Join-Path $sharePath $username

        try {
            # Create folder if it doesn't exist
            if (-not (Test-Path $homeDir)) {
                New-Item -ItemType Directory -Path $homeDir -Force | Out-Null
                Write-Host "✅ Created folder: $homeDir"
            } else {
                Write-Host "🔄 Folder already exists: $homeDir"
            }

            # Set NTFS permissions: user full control + domain admins
            $acl = Get-Acl $homeDir

            $userIdentity = "$env:USERDOMAIN\$username"
            $accessRuleUser = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $userIdentity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )

            $accessRuleAdmins = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $domainAdminsGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )

            $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance
            $acl.ResetAccessRule($accessRuleUser)
            $acl.AddAccessRule($accessRuleAdmins)

            Set-Acl -Path $homeDir -AclObject $acl

            Write-Host "🔐 Set NTFS permissions for $username"
        }
        catch {
            Write-Warning "❌ Failed for ${username}: $($_.Exception.Message)"
        }
    }
}
