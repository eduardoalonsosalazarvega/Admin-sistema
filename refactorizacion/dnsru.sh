#!/bin/bash

# Importar funciones desde archivos separados
source ./validaciones/validaciones.sh
source ./red/configurar_ip.sh
source ./dns/configuracion_dns.sh

# Obtener la IP
ip_address=$(bash ./validaciones/obtener_ip.sh)

# Obtener el dominio
domain=$(bash ./validaciones/obtener_dominio.sh)

# Validar IP y dominio
validate_ip "$ip_address"
validate_domain "$domain"

# Configurar IP estática
configure_network "$ip_address"

# Configurar DNS
configure_dns "$ip_address" "$domain"

# Reiniciar BIND9 y verificar estado
restart_bind9

echo "Servidor DNS configurado correctamente."