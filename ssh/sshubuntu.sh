#!/bin/bash

# Instalamos el servidor SSH
echo "Instalando OpenSSH Server..."
sudo apt -y install openssh-server

# Habilitamos el servicio SSH para que inicie automáticamente al arrancar
echo "Habilitando el servicio SSH..."
sudo systemctl enable ssh

# Reiniciamos el servicio SSH para aplicar cambios
echo "Reiniciando el servicio SSH..."
sudo systemctl restart ssh

# Configuramos el firewall para permitir conexiones SSH
echo "Configurando el firewall para SSH..."
sudo ufw allow ssh

# Habilitamos el firewall
echo "Habilitando el firewall..."
sudo ufw enable

# Verificamos que el servicio SSH esté funcionando correctamente
echo "Verificando el estado del servicio SSH..."
sudo systemctl status ssh

# Verificamos las reglas activas del firewall
echo "Verificando el estado del firewall..."
sudo ufw status

echo "Configuración de SSH completada exitosamente."


