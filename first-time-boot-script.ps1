# Set keyboard til dansk (https://learn.microsoft.com/en-us/answers/questions/618101/how-to-change-keyboard-in-windows-server-2019-core)

Set-ItemProperty 'HKCU:\Keyboard Layout\Preload' -Name 1 -Value 00000406

# Få en ssh server op og køre

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name "sshd" -StartupType Automatic
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22