#!/bin/bash

configure_dhcp() {
    local SERVER_IP=$1
    local RANGE_START=$2
    local RANGE_END=$3

    # Extraer la base de la IP (los tres primeros octetos)
    IFS='.' read -r o1 o2 o3 o4 <<< "$SERVER_IP"
    local SUBNET_IP="$o1.$o2.$o3.0"
    local GATEWAY_IP="$o1.$o2.$o3.1"

    # Configuración del DHCP
    cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf > /dev/null
default-lease-time 600;
max-lease-time 7200;
subnet $SUBNET_IP netmask 255.255.255.0 {
    range ${RANGE_START} ${RANGE_END};
    option routers $GATEWAY_IP;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

    # Recargar y reiniciar el servicio DHCP
    sudo systemctl daemon-reload
    sudo systemctl restart isc-dhcp-server
    sudo systemctl enable isc-dhcp-server

    echo "Servidor DHCP configurado y ejecutándose en enp0s8 con rango $RANGE_START - $RANGE_END en la subred $SUBNET_IP."
}
