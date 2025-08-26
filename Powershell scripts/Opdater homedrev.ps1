
# Start på første del af Home drev script - Opret stien på hver brugerprofil

Invoke-Command -ComputerName "DC01" -ScriptBlock {
    # importer AD modulet for at sikre at cmdlet's som "Get-ADUser" findes i den nuværende session
    Import-Module ActiveDirectory


    # Definer variabler til vores drev bogstav samt opret et array til fejlbeskeder
    $driveLetter = "H:"
    $errorLog = @()

    # Hent nødvendig info fra brugere i AD som ikke har et Home drev og som kan findes under OU'et "Staff"
    $users = Get-ADUser -Filter {HomeDirectory -notlike "*"} -SearchBase "OU=staff,DC=alpaco,DC=local" -Properties SamAccountName, HomeDirectory, HomeDrive

    # Start for loop til at opdatere plasering af home drev for hver bruger
    foreach ($user in $users) {
        try {
            # hiv SamAccountName fra aktuel bruger i loopet samt set sti til drev
            $username = $user.SamAccountName
            $homePath = "\\fil01\homedrive\$username"

            # forsøg at opdatere Home drev for hver bruger
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

    # Opsumering af fejl hvis der er nogen
    if ($errorLog.Count -gt 0) {
        Write-Host "`n=== Errors Encountered ==="
        $errorLog | ForEach-Object { Write-Host $_ }
    }
}


# Start på anden del af Home drev script - opret mapper for hver bruger samt set ACL og fjern nedarvning

Invoke-Command -ComputerName "dc01" -ScriptBlock {

    # opret variabler til senere brug
    $sharePath = "\\fil01\homefolders"
    $domainAdminsGroup = "alpaco.local\Domain Admins"   

    # Hent nødvendig info fra brugere i AD som HAR et Home drev og som kan findes under OU'et "Staff"
    $users = Get-ADUser -Filter {HomeDirectory -like "*"} -SearchBase "OU=staff,DC=alpaco,DC=local" -Properties SamAccountName, HomeDirectory, HomeDrive

    foreach ($user in $users) {
        $username = $user.SamAccountName
        $homeDir = Join-Path $sharePath $username

        try {
            # Tjek om sti findes - ellers oprettes den
            if (-not (Test-Path $homeDir)) {
                New-Item -ItemType Directory -Path $homeDir -Force | Out-Null
                Write-Host "✅ Created folder: $homeDir"
            } else {
                Write-Host "🔄 Folder already exists: $homeDir"
            }

            # Set NTFS rettigheder: full control til brugeren samt full control til medlemmer af domain admins gruppen
            $acl = Get-Acl $homeDir
            $userIdentity = "$env:USERDOMAIN\$username"
            $accessRuleUser = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $userIdentity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )

            $accessRuleAdmins = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $domainAdminsGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )

            $acl.SetAccessRuleProtection($true, $false)  # Fjern nedarvning
            $acl.ResetAccessRule($accessRuleUser) # giv rettigheder til bruger
            $acl.AddAccessRule($accessRuleAdmins) # giv rettigheder til domain admins

            # Skriv rettigheder ind i ACL
            Set-Acl -Path $homeDir -AclObject $acl

            Write-Host "🔐 Set NTFS permissions for $username"
        }
        catch {
            Write-Warning "❌ Failed for ${username}: $($_.Exception.Message)"
        }
    }
}
