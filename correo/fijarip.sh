#!/bin/bash
#ip_address=$1

echo "Configurando IP estática en 192.168.0....."

sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOT
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.0.15/24]
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOT

sudo netplan apply
echo "IP configurada exitosamente."