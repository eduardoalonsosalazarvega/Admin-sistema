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
    read -p "Ingrese el grupo principal del usuario (ej: reprobados, recursadores): " FTP_GROUP

    # Definir variables del usuario
    user_sub_token=$FTP_USER
    local_root="/srv/ftp/$FTP_USER"

    echo "Creando usuario $FTP_USER..."
    sudo useradd -m -d "$local_root" -s /usr/sbin/nologin "$FTP_USER"
    sudo passwd "$FTP_USER"
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
    # Cerrar sesión del usuario para evitar bloqueos
    sudo pkill -KILL -u "$nombre"
    read -p "Ingrese el nombre del usuario a cambiar de grupo: " nombre
    
    if ! id "$nombre" &>/dev/null; then
        echo "El usuario no existe."
        return
    fi
    
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
    sudo systemctl reload vsftpd
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
