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
    #sudo tee -a /etc/vsftpd.conf > /dev/null <<EOF
#allow_writeable_chroot=YES
#anon_root=/home/ftp/anon
#EOF
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
cambiar_grupo() {
    read -p "Escriba el usuario a quien desea cambiar de grupo: " user
    read -p "Escriba el nuevo grupo de ese usuario: " group

    # Verificar si el usuario existe
    if ! id "$user" &>/dev/null; then
        echo "Error: El usuario $user no existe."
        exit 1
    fi

    # Verificar si la carpeta del usuario existe
    if [ ! -d "/srv/ftp/$user" ]; then
        echo "Error: La carpeta /srv/ftp/$user no existe."
        exit 1
    fi

    grupos_actuales=$(id -Gn "$user" | tr ' ' '\n')

    # Desmontar todas las carpetas de grupos anteriores
    for grupo in $grupos_actuales; do
        if [ "$grupo" != "ftpusers" ] && [ "$grupo" != "$group" ] && [ -d "/srv/ftp/$user/$grupo" ]; then
            if mountpoint -q "/srv/ftp/$user/$grupo"; then
                echo "Desmontando /srv/ftp/$user/$grupo"
                sudo umount "/srv/ftp/$user/$grupo" || echo "Error al desmontar $grupo"
            fi
        fi
    done

    # Eliminar los grupos anteriores excepto ftpusers y el nuevo grupo
    for grupo in $grupos_actuales; do
        if [ "$grupo" != "ftpusers" ] && [ "$grupo" != "$group" ]; then
            sudo gpasswd -d "$user" "$grupo"
        fi
    done

    # Asignar el nuevo grupo
    sudo usermod -aG "$group" "$user"

    # Crear la carpeta del nuevo grupo si no existe
    if [ ! -d "/srv/ftp/$user/$group" ]; then
        sudo mkdir -p "/srv/ftp/$user/$group"
    fi

    # Montar la nueva carpeta del grupo
    sudo mount --bind "/home/ftp/grupos/$group" "/srv/ftp/$user/$group"

    # Cambiar permisos y dueño de la carpeta del usuario
    sudo chown -R "$user:ftpusers" "/srv/ftp/$user"
    sudo chmod 750 "/srv/ftp/$user"

    echo "El usuario $user ahora pertenece al grupo $group y su carpeta ha sido configurada correctamente."
}





# Función para mostrar el menú
mostrar_menu() {
    while true; do
        echo "===== MENÚ DE ADMINISTRACIÓN FTP ====="
        echo "1) Agregar un usuario FTP"
        echo "2) Cambiar un usuario de grupo"
        echo "3) Salir"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) agregar_usuario ;;
            2) cambiar_grupo;;
            3) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción no válida, intente de nuevo." ;;
        esac
    done
}



# Reiniciar servicio vsftpd
echo "Reiniciando servicio FTP..."
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

# Configuración de seguridad
echo "Configurando seguridad..."
sudo chmod 755 /home/ftp

# Configuración del firewall
echo "Configurando firewall..."
sudo ufw allow 21/tcp

# Mostrar menú
mostrar_menu
