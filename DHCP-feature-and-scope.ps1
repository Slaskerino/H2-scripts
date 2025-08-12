# Variables for scopes
$scopes = @(
    @{Name = "VLAN10"; Subnet = "10.0.10.0"; Mask = "255.255.255.0"; Gateway = "10.0.10.1"; DNS = @("10.0.10.11", "10.0.10.12"); IPv6Subnet = "2001:db8:acad:10::"; IPv6DNS = @("2001:db8:acad:10::11","2001:db8:acad:10::12")},
    @{Name = "VLAN20"; Subnet = "10.0.20.0"; Mask = "255.255.255.0"; Gateway = "10.0.20.1"; DNS = @("10.0.20.11", "10.0.20.12"); IPv6Subnet = "2001:db8:acad:20::"; IPv6DNS = @("2001:db8:acad:10::11","2001:db8:acad:10::12")},
    @{Name = "VLAN30"; Subnet = "10.0.30.0"; Mask = "255.255.255.0"; Gateway = "10.0.30.1"; DNS = @("10.0.30.11", "10.0.30.12"); IPv6Subnet = "2001:db8:acad:30::"; IPv6DNS = @("2001:db8:acad:10::11","2001:db8:acad:10::12")},
    @{Name = "VLAN69"; Subnet = "10.0.69.0"; Mask = "255.255.255.0"; Gateway = "10.0.69.1"; DNS = @("10.0.69.11", "10.0.69.12"); IPv6Subnet = "2001:db8:acad:69::"; IPv6DNS = @("2001:db8:acad:10::11","2001:db8:acad:10::12")}
)

$server = "DC01"

Invoke-Command -ComputerName $server -ScriptBlock {
    param($scopes)

    Import-Module DHCPServer

    # Check if DHCP Server Role is installed
    $dhcpInstalled = Get-WindowsFeature -Name DHCP | Select-Object -ExpandProperty Installed
    if (-not $dhcpInstalled) {
        Write-Host "DHCP Server role not installed. Installing..."
        Install-WindowsFeature -Name DHCP -IncludeManagementTools -Restart:$false
    }
    else {
        Write-Host "DHCP Server role already installed."
    }

    # Wait a moment for DHCP service to be ready
    Start-Sleep -Seconds 5

    # Create IPv4 Scopes
    foreach ($scope in $scopes) {
        $scopeName = $scope.Name
        $subnet = $scope.Subnet
        $mask = $scope.Mask
        $startIP = ([System.Net.IPAddress]::Parse($subnet)).GetAddressBytes()
        $startIP[3] = 10  # Start IP address .10 (adjust as needed)
        $startIPStr = ([System.Net.IPAddress]::new($startIP)).ToString()
        $endIP = ([System.Net.IPAddress]::Parse($subnet)).GetAddressBytes()
        $endIP[3] = 200   # End IP address .200 (adjust as needed)
        $endIPStr = ([System.Net.IPAddress]::new($endIP)).ToString()

        # Check if scope exists
        $existingScope = Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $scopeName }
        if (-not $existingScope) {
            Write-Host "Creating IPv4 Scope: $scopeName"
            Add-DhcpServerv4Scope -Name $scopeName -StartRange $startIPStr -EndRange $endIPStr -SubnetMask $mask -State Active

            # Add Router (Gateway) option
            Set-DhcpServerv4OptionValue -ScopeId $subnet -Router $scope.Gateway

            # Add DNS servers option
            Set-DhcpServerv4OptionValue -ScopeId $subnet -DnsServer $scope.DNS
        }
        else {
            Write-Host "IPv4 Scope $scopeName already exists."
        }
    }

    # Create IPv6 Scopes
    foreach ($scope in $scopes) {
        $scopeName = $scope.Name + "_IPv6"
        $ipv6Subnet = $scope.IPv6Subnet

        # Check if IPv6 scope exists
        $existingScopeV6 = Get-DhcpServerv6Scope | Where-Object { $_.Name -eq $scopeName }
        if (-not $existingScopeV6) {
            Write-Host "Creating IPv6 Scope: $scopeName"
            Add-DhcpServerv6Scope -Name $scopeName -Prefix $ipv6Subnet -State Active

            # Add Router option (option 23)
            Set-DhcpServerv6OptionValue -ScopeId $ipv6Subnet -Router $scope.Gateway

            # Add DNS servers option (option 23 is router, option 24 is DNS servers)
            Set-DhcpServerv6OptionValue -ScopeId $ipv6Subnet -DnsServer $scope.DNS
        }
        else {
            Write-Host "IPv6 Scope $scopeName already exists."
        }
    }
} -ArgumentList ($scopes)
