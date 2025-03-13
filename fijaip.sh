#Fijar la IP
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.0.16/24]
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]" | sudo tee /etc/netplan/01-network-manager-all.yml > /dev/null
echo "Fijando la IP $192.168.0.1