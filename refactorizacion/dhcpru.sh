#!/bin/bash

# Importar funciones desde archivos separados
source ./red/dhcp/validar_ip.sh
source ./red/dhcp/configurar_netplan.sh
source ./red/dhcp/configurar_dhcp_conf.sh

# Instalar el servidor DHCP
sudo apt-get install -y isc-dhcp-server
echo "ISC DHCP se instaló correctamente"

# Solicitar la IP del servidor DHCP
read -p "Ingrese la IP del servidor DHCP: " SERVER_IP
validate_ip "$SERVER_IP"

# Configurar la IP estática con Netplan
configure_netplan "$SERVER_IP"

# Solicitar rango de IPs para DHCP
read -p "Ingrese la IP inicial del rango DHCP: " RANGE_START
validate_ip "$RANGE_START"
read -p "Ingrese la IP final del rango DHCP: " RANGE_END
validate_ip "$RANGE_END"

# Configurar el servicio DHCP
configure_dhcp "$SERVER_IP" "$RANGE_START" "$RANGE_END"

echo "Servidor DHCP configurado y ejecutándose correctamente."
