#!/bin/bash

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" 
    exit 1
fi

# Verificar si ya está instalado
if systemctl list-unit-files | grep -q "vsftpd"; then
    echo "vsftpd ya está instalado."
else
    echo "Instalando vsftpd..."
    sudo apt update && sudo apt install -y vsftpd 
    sudo groupadd reprobados
    sudo groupadd recursadores
    sudo groupadd ftpusers   
    sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(local_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(write_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(chroot_local_user=YES\)/\1/' /etc/vsftpd.conf
    sudo tee -a $VSFTPD_CONF > /dev/null <<EOF
allow_writeable_chroot=YES
anon_root=$FTP_ROOT/anon
EOF
fi

# Variables principales
FTP_ROOT="/home/ftp"
PUBLIC_DIR="$FTP_ROOT/publica"
USERS_DIR="$FTP_ROOT/users"
GROUPS_DIR="$FTP_ROOT/grupos"
VSFTPD_CONF="/etc/vsftpd.conf"

# Crear estructura de carpetas
sudo mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR"
sudo mkdir -p "$GROUPS_DIR/reprobados"
sudo mkdir -p "$GROUPS_DIR/recursadores"
sudo mkdir -p "$FTP_ROOT/anon/publica"

# Asignar permisos a grupos
sudo chmod 770 "$GROUPS_DIR/reprobados"
sudo chmod 770 "$GROUPS_DIR/recursadores"
sudo chown root:reprobados "$GROUPS_DIR/reprobados"
sudo chown root:recursadores "$GROUPS_DIR/recursadores"

# Permisos generales
sudo chmod 755 /home/ftp
sudo chmod 775 "$PUBLIC_DIR"
sudo chown root:ftpusers "$PUBLIC_DIR"

# Función para agregar un usuario FTP
agregar_usuario() {
    read -p "Ingrese el nombre del usuario FTP: " FTP_USER
    read -p "Ingrese el grupo principal del usuario (ej: reprobados, recursadores): " FTP_GROUP
    
    echo "Creando usuario $FTP_USER..."
    sudo useradd -m -d "$USERS_DIR/$FTP_USER" -s /usr/sbin/nologin "$FTP_USER"
    sudo passwd "$FTP_USER"
    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo usermod -aG "ftpusers" "$FTP_USER"
    
    echo "Configurando carpetas para $FTP_USER..."
    sudo mkdir -p "$USERS_DIR/$FTP_USER/publica"
    sudo mkdir -p "$USERS_DIR/$FTP_USER/$FTP_GROUP"
    
    sudo mkdir -p "$USERS_DIR/$FTP_USER/$FTP_USER"
    sudo chmod 700 "$USERS_DIR/$FTP_USER/$FTP_USER"
    sudo chown -R "$FTP_USER:$FTP_USER" "$USERS_DIR/$FTP_USER/"
    sudo mount --bind "$GROUPS_DIR/$FTP_GROUP" "$USERS_DIR/$FTP_USER/$FTP_GROUP"
    sudo mount --bind "$PUBLIC_DIR" "$USERS_DIR/$FTP_USER/publica"
    sudo mount --bind "$PUBLIC_DIR" "$FTP_ROOT/anon/publica"
    
    sudo chmod 750 "$USERS_DIR/$FTP_USER"
    sudo chown -R "$FTP_USER:ftpusers" "$USERS_DIR/$FTP_USER"
    
    sudo passwd -u "$FTP_USER"
    sudo usermod -s /bin/bash "$FTP_USER"
    
    echo "Usuario $FTP_USER agregado correctamente."
}

# Menú principal
while true; do
    echo "\nMenú de configuración FTP:"
    echo "1) Agregar usuario FTP"
    echo "2) Salir"
    read -p "Seleccione una opción: " opcion
    case $opcion in
        1) agregar_usuario ;;
        2) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
done
