#!/bin/bash

configure_netplan() {
    local SERVER_IP=$1

    # Extraer la base de la IP (los tres primeros octetos)
    IFS='.' read -r o1 o2 o3 o4 <<< "$SERVER_IP"
    local SUBNET_IP="$o1.$o2.$o3.0"
    local GATEWAY_IP="$o1.$o2.$o3.1"

    echo "Subred detectada: $SUBNET_IP"
    echo "Puerta de enlace configurada en: $GATEWAY_IP"

    # Configuración de Netplan
    echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [$SERVER_IP/24]
      gateway4: $GATEWAY_IP
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]" | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null

    echo "Fijando la IP $SERVER_IP con puerta de enlace $GATEWAY_IP"
    sudo netplan apply
    echo "Aplicando cambios"

    # Configurar DHCP en interfaces
    echo "INTERFACESv4=\"enp0s8\"" | sudo tee /etc/default/isc-dhcp-server > /dev/null
}
