# Importar funciones desde archivos separados
. .\validaciones\validaciones.ps1
. .\red\configurar_ip.ps1
. .\dns\configuracion_dns.ps1

# Obtener la IP
$IPDestino = Obtener-IP

# Obtener el dominio
$Dominio = Obtener-Dominio

# Validar IP y dominio
Validar-IP $IPDestino
Validar-Dominio $Dominio

# Configurar IP estática
Configurar-Red $IPDestino

# Configurar DNS
Configurar-DNS $IPDestino $Dominio

# Reiniciar el servicio DNS
Reiniciar-DNS

Write-Host "Servidor DNS configurado correctamente." -ForegroundColor Cyan
