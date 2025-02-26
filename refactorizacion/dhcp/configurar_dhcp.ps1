function Configurar-DHCP {
    param ([string]$IpDestino, [string]$IpInicial, [string]$IpFinal)

    # Extraer partes de la IP para generar subnet y gateway
    $partes = $IpDestino -split "\."
    $subneteo = "$($partes[0]).$($partes[1]).$($partes[2]).0"
    $puerta = "$($partes[0]).$($partes[1]).$($partes[2]).1"
    $mascara = "255.255.255.0"

    Write-Host "Configuración completa:"
    Write-Host "Servidor DHCP: $IpDestino"
    Write-Host "Rango de IPs: $IpInicial - $IpFinal"
    Write-Host "Subnet: $subneteo"
    Write-Host "Puerta de enlace: $puerta"

    # Configurar IP estática
    netsh interface ipv4 set address name="Ethernet 2" static $IpDestino $mascara

    # Instalar DHCP si no está instalado
    Install-WindowsFeature DHCP -IncludeManagementTools

    # Configurar Scope de DHCP
    Add-DhcpServerv4Scope -Name "RedLocal" -StartRange $IpInicial -EndRange $IpFinal -SubnetMask $mascara

    # Excluir IP del servidor DHCP del rango de asignaciones
    Add-DhcpServerv4ExclusionRange -ScopeId $subneteo -StartRange $IpDestino -EndRange $IpDestino

    # Reiniciar servicio DHCP
    Restart-Service -Name DHCPServer

    # Permitir tráfico ICMP en el firewall
    New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -Direction Inbound -Action Allow
}
