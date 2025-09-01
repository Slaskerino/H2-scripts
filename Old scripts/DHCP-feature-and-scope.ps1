# Variables for scopes

# Der kan oprettes startIP og endIP i array i stedet for at convertere til byte arrays.
$scopes = @(
    @{Name = "VLAN10"; Subnet = "10.0.10.0"; Mask = "255.255.255.0"; Gateway = "10.0.10.1"; DNS = "10.0.10.11"; IPv6Subnet = "2001:db8:acad:10::"; IPv6DNS = "2001:db8:acad:10::11"; StartIP = "10.0.10.50"; EndIP = "10.0.10.200"},
    @{Name = "VLAN20"; Subnet = "10.0.20.0"; Mask = "255.255.255.0"; Gateway = "10.0.20.1"; DNS = "10.0.10.11"; IPv6Subnet = "2001:db8:acad:20::"; IPv6DNS = "2001:db8:acad:10::11"; StartIP = "10.0.20.50"; EndIP = "10.0.20.200"},
    @{Name = "VLAN30"; Subnet = "10.0.30.0"; Mask = "255.255.255.0"; Gateway = "10.0.30.1"; DNS = "10.0.10.11"; IPv6Subnet = "2001:db8:acad:30::"; IPv6DNS = "2001:db8:acad:10::11"; StartIP = "10.0.30.50"; EndIP = "10.0.30.200"},
    @{Name = "VLAN69"; Subnet = "10.0.69.0"; Mask = "255.255.255.0"; Gateway = "10.0.69.1"; DNS = "10.0.10.11"; IPv6Subnet = "2001:db8:acad:69::"; IPv6DNS = "2001:db8:acad:10::11"; StartIP = "10.0.69.50"; EndIP = "10.0.69.200"},
    @{Name = "VLAN120"; Subnet = "192.168.20.0"; Mask = "255.255.255.0"; Gateway = "192.168.20.1"; DNS = "10.0.10.11"; IPv6Subnet = "2001:db8:acad:120::"; IPv6DNS = "2001:db8:acad:10::11"; StartIP = "192.168.20.50"; EndIP = "192.168.20.200"}
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
        $startIP = $scope.StartIP
        $endIP = $scope.EndIP

        # Check if scope exists
        $existingScope = Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $scopeName }
        if (-not $existingScope) {
            Write-Host "Creating IPv4 Scope: $scopeName"
            Add-DhcpServerv4Scope -Name $scopeName -StartRange $startIP -EndRange $endIP -SubnetMask $mask -State Active

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
            # Set-DhcpServerv6OptionValue -ScopeId $ipv6Subnet -Router $scope.Gateway

            # Add DNS servers option (option 23 is router, option 24 is DNS servers)
            Set-DhcpServerv6OptionValue -Prefix $ipv6Subnet -DnsServer $scope.IPv6DNS
        }
        else {
            Write-Host "IPv6 Scope $scopeName already exists."
        }
    }
} -ArgumentList (,$scopes)
