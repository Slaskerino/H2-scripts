# Din mor er en mand

# Import the Active Directory module
Import-Module ActiveDirectory

# Path to the CSV file
$csvPath = "C:\ADSetup\users.csv"

# Base OU path for the company
$ouBase = "OU=Users,OU=ALPACA,DC=corp,DC=sdwmu,DC=dk"

# Import users from CSV
$users = Import-Csv -Path $csvPath

Write-Host "=== Creating OUs... ===" -ForegroundColor Cyan

# Create required OUs
$users | ForEach-Object {
    $countryOU = "OU=$($_.Country)"
    $departmentOU = "OU=$($_.Department)"
    $fullOU = "$departmentOU,$countryOU,$ouBase"

    # Create Country OU if it doesn't exist
    $countryPath = "$countryOU,$ouBase"
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$countryPath)" -ErrorAction SilentlyContinue)) {
        Write-Host "Creating OU: $($_.Country)" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $_.Country -Path $ouBase
    }

    # Create Department OU if it doesn't exist
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$fullOU)" -ErrorAction SilentlyContinue)) {
        Write-Host "Creating OU: $($_.Department) under $($_.Country)" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $_.Department -Path $countryPath
    }
}

Write-Host "`n=== Creating Users... ===" -ForegroundColor Cyan

# Create users
foreach ($user in $users) {
    $fullName = "$($user.GivenName) $($user.Surname)"
    $samAccountName = $user.Username
    $userPrincipalName = "$samAccountName@alpaca.local"
    $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
    $ouPath = $user.OU

    # Check if user already exists
    if (Get-ADUser -Filter { SamAccountName -eq $samAccountName } -ErrorAction SilentlyContinue) {
        Write-Host "User $samAccountName already exists. Skipping." -ForegroundColor Gray
        continue
    }

    try {
        New-ADUser `
            -Name $fullName `
            -GivenName $user.GivenName `
            -Surname $user.Surname `
            -SamAccountName $samAccountName `
            -UserPrincipalName $userPrincipalName `
            -AccountPassword $securePassword `
            -Path $ouPath `
            -Enabled $true `
            -Title $user.Title `
            -OfficePhone $user.HomePhone `
            -MobilePhone $user.MobilePhone `
            -Office $user.Office `
            -StreetAddress $user.StreetAddress `
            -PostalCode $user.PostalCode `
            -Company $user.Company `
            -Department $user.Department `
            -City $user.City `
            -Country $user.Country `
            -ChangePasswordAtLogon $false

        Write-Host "Created user: $fullName ($samAccountName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating user $fullName: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Finished creating OUs and users. ===" -ForegroundColor Cyan
