#!/bin/bash

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" 
    exit 1
fi

# Variables principales
FTP_ROOT="/home/ftp"
PUBLIC_DIR="$FTP_ROOT/publica"
USERS_DIR="$FTP_ROOT/users"
GROUPS_DIR="$FTP_ROOT/grupos"
VSFTPD_CONF="/etc/vsftpd.conf"

# Verificar si vsftpd está instalado
if ! systemctl list-unit-files | grep -q "vsftpd"; then
    echo "Instalando vsftpd..."
    sudo apt update && sudo apt install -y vsftpd 
    sudo groupadd reprobados
    sudo groupadd recursadores
    sudo groupadd ftpusers  

    # Modificar configuración de vsftpd
    sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/' $VSFTPD_CONF
    sudo sed -i 's/^#\(local_enable=YES\)/\1/' $VSFTPD_CONF
    sudo sed -i 's/^#\(write_enable=YES\)/\1/' $VSFTPD_CONF
    sudo sed -i 's/^#\(chroot_local_user=YES\)/\1/' $VSFTPD_CONF

    # Agregar opciones si no existen
    sudo grep -qxF "allow_writeable_chroot=YES" $VSFTPD_CONF || echo "allow_writeable_chroot=YES" | sudo tee -a $VSFTPD_CONF
    sudo grep -qxF "anon_root=$FTP_ROOT/anon" $VSFTPD_CONF || echo "anon_root=$FTP_ROOT/anon" | sudo tee -a $VSFTPD_CONF

    # Crear estructura de carpetas
    echo "Creando estructura de directorios..."
    sudo mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR"
    sudo mkdir -p "$GROUPS_DIR/reprobados"
    sudo mkdir -p "$GROUPS_DIR/recursadores"
    sudo mkdir -p "$FTP_ROOT/anon/publica"

    # Configurar permisos
    sudo chmod 770 "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores"
    sudo chown root:reprobados "$GROUPS_DIR/reprobados"
    sudo chown root:recursadores "$GROUPS_DIR/recursadores"
    sudo chmod 755 /home/ftp
    sudo chmod 775 "$PUBLIC_DIR"
    sudo chown root:ftpusers "$PUBLIC_DIR"

    # Reiniciar servicio vsftpd
    sudo systemctl restart vsftpd
    sudo systemctl enable vsftpd

    # Configurar firewall
    sudo ufw allow 21/tcp
fi

# Función para agregar un usuario FTP
agregar_usuario() {
    read -p "Ingrese el nombre del nuevo usuario FTP: " FTP_USER
    read -p "Ingrese el grupo principal del usuario (reprobados/recursadores): " FTP_GROUP

    # Crear usuario y directorios
    echo "Creando usuario $FTP_USER..."
    sudo useradd -m -d "$USERS_DIR/$FTP_USER" -s /usr/sbin/nologin "$FTP_USER"
    sudo passwd "$FTP_USER"
    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo usermod -aG "ftpusers" "$FTP_USER"

    # Crear carpetas del usuario
    echo "Configurando carpetas para $FTP_USER..."
    sudo mkdir -p "$USERS_DIR/$FTP_USER/publica"
    sudo mkdir -p "$USERS_DIR/$FTP_USER/$FTP_GROUP"

    # Enlazar carpetas
    sudo mkdir -p "$USERS_DIR/$FTP_USER/$FTP_USER"
    sudo chmod 700 "$USERS_DIR/$FTP_USER/$FTP_USER"
    sudo chown -R "$FTP_USER:$FTP_USER" "$USERS_DIR/$FTP_USER/"
    sudo mount --bind "$GROUPS_DIR/$FTP_GROUP" "$USERS_DIR/$FTP_USER/$FTP_GROUP"
    sudo mount --bind "$PUBLIC_DIR" "$USERS_DIR/$FTP_USER/publica"

    # Configurar permisos
    sudo chmod 750 "$USERS_DIR/$FTP_USER"
    sudo chown -R "$FTP_USER:ftpusers" "$USERS_DIR/$FTP_USER"

    echo "Usuario $FTP_USER creado exitosamente."
}

# Función para cambiar el grupo de un usuario existente
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario FTP a modificar: " FTP_USER
    read -p "Ingrese el nuevo grupo del usuario (reprobados/recursadores): " NEW_GROUP

    if id "$FTP_USER" &>/dev/null; then
        sudo usermod -g "$NEW_GROUP" "$FTP_USER"
        echo "Grupo del usuario $FTP_USER cambiado a $NEW_GROUP."
    else
        echo "El usuario $FTP_USER no existe."
    fi
}

# Menú interactivo
while true; do
    clear
    echo "========== Menú de Administración FTP =========="
    echo "1) Agregar usuario FTP"
    echo "2) Cambiar grupo de un usuario FTP"
    echo "3) Salir"
    echo "==============================================="
    read -p "Seleccione una opción: " OPCION

    case $OPCION in
        1) agregar_usuario ;;
        2) cambiar_grupo ;;
        3) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida, intente de nuevo." ;;
    esac

    read -p "Presione Enter para continuar..."
done