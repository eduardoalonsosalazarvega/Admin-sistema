#holaamigosdelyutuvamos a aprender a como activar el ssh en windows
Add-windowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
#ahora vamos a iniciar el servicio ssh
Start-Service sshd
Get-Service sshd
#ahora configuramos el servicio para que se inicie automaticamente
Set-Service -Name sshd -StartupType 'Automatic'
#En la siguiente linea vamos a acrtivar la regla del firewall
New-NetFirewallRule -Name sshd -Displayname 'OpenSSH server (ssh)' -Enabled True -Protocol TCP -Action Allow -LocalPort 22
