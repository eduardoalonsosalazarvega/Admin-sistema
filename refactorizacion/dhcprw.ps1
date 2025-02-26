Clear-Host
Write-Host "Bienvenido a la configuración principal de DHCP"

# Importar módulos
. ./validaciones/validaciones.ps1
. ./validaciones/obtener_ip.ps1
. ./dhcp/configurar_dhcp.ps1

# Obtener IP del servidor DHCP
$IpDestino = Obtener-IP

# Validar IP
Validar-IP $IpDestino

# Obtener el rango de IP
$IpInicial, $IpFinal = Obtener-Rango-IP

# Configurar DHCP
Configurar-DHCP $IpDestino $IpInicial $IpFinal

Write-Host "Servidor DHCP configurado correctamente en la IP $IpDestino con el rango $IpInicial - $IpFinal." -ForegroundColor Cyan
