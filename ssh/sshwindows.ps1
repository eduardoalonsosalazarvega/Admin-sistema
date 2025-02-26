# ¡Hola amigos de YouTube! Vamos a aprender cómo activar el servicio SSH en Windows 

# Instalamos el servidor OpenSSH
Write-Output "Instalando OpenSSH Server..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Iniciamos el servicio SSH
Write-Output "Iniciando el servicio SSH..."
Start-Service sshd

# Verificamos el estado del servicio SSH
Write-Output "Verificando el estado del servicio SSH..."
Get-Service sshd

# Configuramos el servicio para que se inicie automáticamente al arrancar
Write-Output "Configurando el servicio SSH para iniciar automáticamente..."
Set-Service -Name sshd -StartupType 'Automatic'

# Activamos la regla del firewall para permitir conexiones SSH
Write-Output "Configurando el firewall para SSH..."
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (SSH)' -Enabled True -Protocol TCP -Action Allow -LocalPort 22

# Confirmación final
Write-Output "El servicio SSH se ha instalado y configurado correctamente."