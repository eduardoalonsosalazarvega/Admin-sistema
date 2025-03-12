#!/bin/bash

source funciones.sh

configuraciones

# Reiniciar servicio vsftpd
echo "Reiniciando servicio FTP..."
sudo systemctl reload vsftpd
sudo systemctl enable vsftpd

# Configuración de seguridad
echo "Configurando seguridad..."
sudo chmod 755 /home/ftp

# Configuración del firewall
echo "Configurando firewall..."
sudo ufw allow 21/tcp
mostrar_menu