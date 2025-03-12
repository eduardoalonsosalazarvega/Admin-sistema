#!/bin/bash

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Archivo de configuración
groups_dir="/home/ftp/grupos"
users_dir="/home/ftp/users"
public_dir="/home/ftp/publica"

# Crear estructura de directorios si no existe
setup_directories() {
    echo "Creando estructura de directorios..."
    sudo mkdir -p "$public_dir" "$users_dir" "$groups_dir/reprobados" "$groups_dir/recursadores"
    sudo chmod 770 "$groups_dir/reprobados" "$groups_dir/recursadores"
    sudo chown root:reprobados "$groups_dir/reprobados"
    sudo chown root:recursadores "$groups_dir/recursadores"
    sudo chmod 775 "$public_dir"
}

# Agregar usuario FTP
agregar_usuario() {
    read -p "Ingrese el nombre del usuario FTP: " FTP_USER
    if id "$FTP_USER" &>/dev/null; then
        echo "Error: El usuario ya existe."
        return
    fi
    read -p "Ingrese el grupo principal del usuario (reprobados, recursadores): " FTP_GROUP
    if [[ "$FTP_GROUP" != "reprobados" && "$FTP_GROUP" != "recursadores" ]]; then
        echo "Error: Grupo inválido."
        return
    fi
    sudo useradd -m -s /usr/sbin/nologin "$FTP_USER"
    read -s -p "Ingrese una contraseña para el usuario: " FTP_PASS
    echo "$FTP_USER:$FTP_PASS" | sudo chpasswd
    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo mkdir -p "$users_dir/$FTP_USER/$FTP_GROUP"
    sudo mount --bind "$groups_dir/$FTP_GROUP" "$users_dir/$FTP_USER/$FTP_GROUP"
    sudo chown "$FTP_USER:$FTP_GROUP" "$users_dir/$FTP_USER/$FTP_GROUP"
    echo "Usuario $FTP_USER agregado correctamente."
}

# Cambiar grupo de usuario
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario: " FTP_USER
    if ! id "$FTP_USER" &>/dev/null; then
        echo "El usuario no existe."
        return
    fi
    read -p "Ingrese el nuevo grupo (reprobados, recursadores): " NUEVO_GRUPO
    if [[ "$NUEVO_GRUPO" != "reprobados" && "$NUEVO_GRUPO" != "recursadores" ]]; then
        echo "Grupo inválido."
        return
    fi
    sudo usermod -g "$NUEVO_GRUPO" "$FTP_USER"
    echo "Usuario $FTP_USER cambiado al grupo $NUEVO_GRUPO."
}

# Reiniciar servicio FTP
reiniciar_vsftpd() {
    echo "Reiniciando vsftpd..."
    sudo systemctl restart vsftpd
}

setup_directories