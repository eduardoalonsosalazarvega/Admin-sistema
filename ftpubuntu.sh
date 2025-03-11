#!/bin/bash

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Verificar si ya está instalado vsftpd
if systemctl list-unit-files | grep -q "vsftpd"; then
    echo "vsftpd ya está instalado."
else
    echo "Instalando vsftpd..."
    apt update && apt install -y vsftpd 
    groupadd reprobados
    groupadd recursadores
    groupadd ftpusers   

    sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/' /etc/vsftpd.conf
    sed -i 's/^#\(local_enable=YES\)/\1/' /etc/vsftpd.conf
    sed -i 's/^#\(write_enable=YES\)/\1/' /etc/vsftpd.conf
    sed -i 's/^#\(chroot_local_user=YES\)/\1/' /etc/vsftpd.conf
    echo "allow_writeable_chroot=YES" | tee -a /etc/vsftpd.conf
    echo "anon_root=/home/ftp/anon" | tee -a /etc/vsftpd.conf
fi

# Variables principales
FTP_ROOT="/home/ftp"
PUBLIC_DIR="$FTP_ROOT/publica"
USERS_DIR="$FTP_ROOT/users"
GROUPS_DIR="$FTP_ROOT/grupos"
VSFTPD_CONF="/etc/vsftpd.conf"

# Crear estructura de carpetas
mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores" "$FTP_ROOT/anon/publica"

# Configurar permisos
chmod 770 "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores"
chown root:reprobados "$GROUPS_DIR/reprobados"
chown root:recursadores "$GROUPS_DIR/recursadores"
chmod 755 /home/ftp
chmod 775 "$PUBLIC_DIR"
chown root:ftpusers "$PUBLIC_DIR"

# Función para agregar usuario
agregar_usuario() {
    read -p "Ingrese el nombre del usuario FTP: " FTP_USER
    
    if [[ -z "$FTP_USER" || "$FTP_USER" =~ [^a-zA-Z0-9_] || ${#FTP_USER} -lt 4 || ${#FTP_USER} -gt 16 || "$FTP_USER" =~ ^(.)\1{5,}$ ]]; then
        echo "Error: Nombre de usuario no válido. Debe tener entre 4 y 16 caracteres alfanuméricos o guiones bajos."
        return
    fi
    
    while true; do
        read -p "Ingrese el grupo principal del usuario (reprobados, recursadores): " FTP_GROUP
        if [[ "$FTP_GROUP" != "reprobados" && "$FTP_GROUP" != "recursadores" ]]; then
            echo "Error: Grupo inválido. Debe ser 'reprobados' o 'recursadores'."
        else
            break
        fi
    done
    
    if id "$FTP_USER" &>/dev/null; then
        echo "Error: El usuario ya existe."
        return
    fi

    useradd -m -s /usr/sbin/nologin "$FTP_USER"
    
    while true; do
        read -s -p "Ingrese una contraseña para el usuario: " FTP_PASS
        echo
        read -s -p "Confirme la contraseña: " FTP_PASS2
        echo
        if [[ "$FTP_PASS" != "$FTP_PASS2" ]]; then
            echo "Error: Las contraseñas no coinciden."
        elif [[ ${#FTP_PASS} -lt 10 || ! "$FTP_PASS" =~ [A-Z] || ! "$FTP_PASS" =~ [a-z] || ! "$FTP_PASS" =~ [0-9] || ! "$FTP_PASS" =~ [@#\$%&*] ]]; then
            echo "Error: La contraseña debe tener al menos 10 caracteres, incluyendo mayúsculas, minúsculas, números y un carácter especial (@, #, $, %, &, *)."
        else
            echo "$FTP_USER:$FTP_PASS" | chpasswd
            break
        fi
    done
    
    usermod -aG "$FTP_GROUP" "$FTP_USER"
    usermod -aG ftpusers "$FTP_USER"
    
    echo "Usuario $FTP_USER agregado correctamente."
}

# Menú
mostrar_menu() {
    while true; do
        echo "===== MENÚ DE ADMINISTRACIÓN FTP ====="
        echo "1) Agregar un usuario FTP"
        echo "2) Salir"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) agregar_usuario ;;
            2) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción no válida." ;;
        esac
    done
}

# Configurar firewall
echo "Configurando firewall..."
ufw allow 21/tcp

# Mostrar menú
mostrar_menu
