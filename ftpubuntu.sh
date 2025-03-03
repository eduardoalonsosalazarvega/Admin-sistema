#!/bin/bash

# Definición de variables
FTP_DIR="/srv/ftp"
GROUP_REPROBADOS="reprobados"
GROUP_RECURSADORES="recursadores"
FTP_USERS_DIR="/srv/ftp/users"
MOUNT_DIR="/mnt/ftp_mount"
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

# Función para instalar y configurar vsftpd
install_vsftpd() {
    echo "Instalando vsftpd..."
    apt update && apt install -y vsftpd openssl ufw
    systemctl enable vsftpd
}

# Función para configurar la IP con Netplan
configure_network() {
    echo "Configurando la red..."
    cat > $NETPLAN_FILE <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.0.10/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOL
    netplan apply
}

# Función para configurar vsftpd
configure_vsftpd() {
    echo "Configurando vsftpd..."
    cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
    
    # Generar certificado SSL si no existe
    if [ ! -f /etc/ssl/private/vsftpd.pem ]; then
        echo "Generando certificado SSL para vsftpd..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem \
            -subj "/C=US/ST=State/L=City/O=Company/OU=IT/CN=localhost"
    fi
    
    cat > /etc/vsftpd.conf <<EOL
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
ssl_enable=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
EOL
    
    systemctl restart vsftpd
}

# Función para abrir puertos en el firewall
configure_firewall() {
    echo "Configurando firewall..."
    ufw allow OpenSSH
    ufw allow 20/tcp
    ufw allow 21/tcp
    ufw allow 40000:50000/tcp
    ufw enable
    ufw reload
}

# Función para crear grupos y carpetas
setup_groups_and_dirs() {
    echo "Creando grupos y directorios..."
    groupadd -f $GROUP_REPROBADOS
    groupadd -f $GROUP_RECURSADORES
    mkdir -p $FTP_DIR/general $FTP_USERS_DIR
    mkdir -p $MOUNT_DIR/general $MOUNT_DIR/reprobados $MOUNT_DIR/recursadores
    chmod 755 $FTP_DIR/general
    chmod 770 $MOUNT_DIR/reprobados $MOUNT_DIR/recursadores
}

# Función para agregar un usuario
add_user() {
    echo "Ingrese el nombre del usuario:"
    read username
    echo "Ingrese la contraseña para $username:"
    read -s password
    useradd -m -s /usr/sbin/nologin $username
    echo "$username:$password" | chpasswd
    echo "Seleccione el grupo:"
    echo "1) Reprobados"
    echo "2) Recursadores"
    read group_choice
    if [[ "$group_choice" == "1" ]]; then
        usermod -aG $GROUP_REPROBADOS $username
    elif [[ "$group_choice" == "2" ]]; then
        usermod -aG $GROUP_RECURSADORES $username
    else
        echo "Opción inválida. Usuario creado sin grupo."
    fi
    mkdir -p $FTP_USERS_DIR/$username
    mkdir -p $MOUNT_DIR/$username
    chown $username:$username $FTP_USERS_DIR/$username
    chmod 750 $FTP_USERS_DIR/$username
    mount --bind $FTP_USERS_DIR/$username $MOUNT_DIR/$username
    echo "Usuario $username creado y asignado correctamente."
}

# Función para cambiar de grupo a un usuario
change_user_group() {
    echo "Ingrese el nombre del usuario a modificar:"
    read username
    echo "Seleccione el nuevo grupo:"
    echo "1) Reprobados"
    echo "2) Recursadores"
    read new_group_choice
    if [[ "$new_group_choice" == "1" ]]; then
        usermod -g $GROUP_REPROBADOS $username
    elif [[ "$new_group_choice" == "2" ]]; then
        usermod -g $GROUP_RECURSADORES $username
    else
        echo "Opción inválida."
    fi
    echo "Grupo de $username cambiado correctamente."
}

# Menú principal
main_menu() {
    while true; do
        echo "\nSeleccione una opción:"
        echo "1) Instalar y configurar vsftpd"
        echo "2) Configurar red"
        echo "3) Configurar firewall"
        echo "4) Crear grupos y directorios"
        echo "5) Agregar usuario"
        echo "6) Cambiar usuario de grupo"
        echo "7) Salir"
        read choice
        case $choice in
            1) install_vsftpd && configure_vsftpd ;;
            2) configure_network ;;
            3) configure_firewall ;;
            4) setup_groups_and_dirs ;;
            5) add_user ;;
            6) change_user_group ;;
            7) exit 0 ;;
            *) echo "Opción inválida." ;;
        esac
    done
}

main_menu
