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
    sudo apt update && sudo apt install -y vsftpd
    sudo groupadd reprobados
    sudo groupadd recursadores
    sudo groupadd ftpusers

    sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(local_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(write_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(chroot_local_user=YES\)/\1/' /etc/vsftpd.conf
    echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd.conf
    echo "anon_root=/home/ftp/anon" | sudo tee -a /etc/vsftpd.conf
fi

# Variables principales
FTP_ROOT="/home/ftp"
PUBLIC_DIR="$FTP_ROOT/publica"
USERS_DIR="$FTP_ROOT/users"
GROUPS_DIR="$FTP_ROOT/grupos"
VSFTPD_CONF="/etc/vsftpd.conf"

# Crear estructura de carpetas si no existe
echo "Creando estructura de directorios..."
sudo mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR"
sudo mkdir -p "$GROUPS_DIR/reprobados"
sudo mkdir -p "$GROUPS_DIR/recursadores"
sudo mkdir -p "$FTP_ROOT/anon/publica"

# Asignar permisos a grupos
echo "Configurando permisos..."
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
    if [[ -z "$FTP_USER" || "$FTP_USER" =~ [^a-zA-Z0-9_] || ${#FTP_USER} -lt 4 || ${#FTP_USER} -gt 16 || "$FTP_USER" =~ ^(.)\1{5,}$ ]]; then
        echo "Error: Nombre de usuario no válido. Debe tener entre 4 y 16 caracteres alfanuméricos o guiones bajos."
        return
    fi
    read -p "Ingrese el grupo principal del usuario (reprobados, recursadores): " FTP_GROUP
    if [[ "$FTP_GROUP" != "reprobados" && "$FTP_GROUP" != "recursadores" ]]; then
        echo "Error: Grupo inválido. Debe ser 'reprobados' o 'recursadores'."
        return
    fi

    # Definir variables del usuario
    local_root="/srv/ftp/$FTP_USER"

    echo "Creando usuario $FTP_USER..."
    if id "$FTP_USER" &>/dev/null; then
        echo "Error: El usuario ya existe."
        return
    fi
    sudo useradd -m -d "$local_root" -s /usr/sbin/nologin "$FTP_USER"
    while true; do
        read -s -p "Ingrese una contraseña para el usuario: " FTP_PASS
        echo
        read -s -p "Confirme la contraseña: " FTP_PASS2
        echo
        if [[ "$FTP_PASS" != "$FTP_PASS2" ]]; then
            echo "Error: Las contraseñas no coinciden."
        elif [[ ${#FTP_PASS} -lt 8 || ! "$FTP_PASS" =~ [A-Z] || ! "$FTP_PASS" =~ [a-z] || ! "$FTP_PASS" =~ [0-9] ]]; then
            echo "Error: La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número."
        else
            echo "$FTP_USER:$FTP_PASS" | sudo chpasswd
            break
        fi
    done
    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo usermod -aG "ftpusers" "$FTP_USER"

    # Crear carpetas del usuario
    echo "Configurando carpetas para $FTP_USER..."
    sudo mkdir -p "$local_root/publica"
    sudo mkdir -p "$local_root/$FTP_GROUP"

    # Enlazar carpetas con mount --bind
    sudo mkdir -p "$local_root/$FTP_USER"
    sudo chmod 700 "$local_root/$FTP_USER"
    sudo chown -R "$FTP_USER:$FTP_USER" "$local_root/"
    sudo mount --bind "$GROUPS_DIR/$FTP_GROUP" "$local_root/$FTP_GROUP"
    sudo mount --bind "$PUBLIC_DIR" "$local_root/publica"
    sudo mount --bind "$PUBLIC_DIR" "$FTP_ROOT/anon/publica"

    sudo chmod 750 "$local_root"
    sudo chown -R "$FTP_USER:ftpusers" "$local_root"

    # Configuración individual del usuario
    sudo passwd -u "$FTP_USER"
    sudo usermod -s /bin/bash "$FTP_USER"

    echo "Usuario $FTP_USER agregado correctamente."
}

# Función para cambiar de grupo a un usuario FTP
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario a cambiar de grupo: " nombre
    
    if [[ -z "$nombre" || "$nombre" =~ [^a-zA-Z0-9_] ]]; then
        echo "Error: Nombre de usuario no válido. Solo se permiten caracteres alfanuméricos y guiones bajos."
        return
    fi
    if ! id "$nombre" &>/dev/null; then
        echo "El usuario no existe."
        return
    fi

    # Cerrar sesión del usuario para evitar bloqueos
    sudo pkill -KILL -u "$nombre"

    grupo_actual=""
    usuario_path="/srv/ftp/$nombre"
    if [[ -d "$usuario_path/reprobados" ]]; then
        grupo_actual="reprobados"
    elif [[ -d "$usuario_path/recursadores" ]]; then
        grupo_actual="recursadores"
    else
        echo "El usuario no tiene grupo asignado."
        return
    fi
    
    nuevo_grupo=""
    if [[ "$grupo_actual" == "reprobados" ]]; then
        nuevo_grupo="recursadores"
    else
        nuevo_grupo="reprobados"
    fi
    
    if [[ -d "$usuario_path/$nuevo_grupo" ]]; then
        echo "Error: La carpeta del nuevo grupo ya existe."
        return
    fi
    sudo mkdir -p "$usuario_path/$nuevo_grupo"
    sudo chown "$nombre:ftp" "$usuario_path/$nuevo_grupo"
    sudo usermod -G "$nuevo_grupo" "$nombre"
    
    # Montar carpetas nuevamente
    sudo fuser -k "$usuario_path/$grupo_actual" || true
    sudo umount -l "$usuario_path/$grupo_actual"
    sleep 1
    # Eliminar directorio solo si ya no está en uso
    if ! mountpoint -q "$usuario_path/$grupo_actual"; then
        sudo rm -r "$usuario_path/$grupo_actual"
    fi
    sudo mount --bind "$GROUPS_DIR/$nuevo_grupo" "$usuario_path/$nuevo_grupo"
    sudo chmod 770 "$usuario_path/$nuevo_grupo"
    sudo chown "$nombre:$nuevo_grupo" "$usuario_path/$nuevo_grupo"
    sync
    
    echo "Usuario $nombre ahora pertenece a $nuevo_grupo."
    if ! systemctl is-active --quiet vsftpd; then
        echo "Error: vsftpd no está activo. Intentando reiniciar..."
        sudo systemctl restart vsftpd
    else
        sudo systemctl reload vsftpd
    fi
}

# Función para mostrar el menú
mostrar_menu() {
    while true; do
        echo "===== MENÚ DE ADMINISTRACIÓN FTP ====="
        echo "1) Agregar un usuario FTP"
        echo "2) Cambiar de grupo a un usuario FTP"
        echo "3) Salir"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) agregar_usuario ;;
            2) cambiar_grupo ;;
            3) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción no válida, intente de nuevo." ;;
        esac
    done
}

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

# Mostrar menú
mostrar_menu
