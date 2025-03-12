#!/bin/bash

# Verificar que se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Instalar vsftpd si no está instalado
install_vsftpd() {
    if systemctl list-unit-files | grep -q "vsftpd"; then
        echo "vsftpd ya está instalado."
    else
        echo "Instalando vsftpd..."
        sudo apt update && sudo apt install -y vsftpd
        sudo groupadd reprobados
        sudo groupadd recursadores
        sudo groupadd ftpusers
    fi
}

# Configurar vsftpd
setup_vsftpd() {
    sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(local_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(write_enable=YES\)/\1/' /etc/vsftpd.conf
    sudo sed -i 's/^#\(chroot_local_user=YES\)/\1/' /etc/vsftpd.conf
    echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd.conf
    echo "anon_root=/home/ftp/anon" | sudo tee -a /etc/vsftpd.conf
}

# Crear estructura de directorios
setup_directories() {
    local FTP_ROOT="/home/ftp"
    local PUBLIC_DIR="$FTP_ROOT/publica"
    local USERS_DIR="$FTP_ROOT/users"
    local GROUPS_DIR="$FTP_ROOT/grupos"

    sudo mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR"
    sudo mkdir -p "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores" "$FTP_ROOT/anon/publica"

    sudo chmod 770 "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores"
    sudo chown root:reprobados "$GROUPS_DIR/reprobados"
    sudo chown root:recursadores "$GROUPS_DIR/recursadores"
}

# Agregar un usuario FTP
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

    local local_root="/srv/ftp/$FTP_USER"
    sudo useradd -m -d "$local_root" -s /usr/sbin/nologin "$FTP_USER"

    while true; do
        read -s -p "Ingrese una contraseña: " FTP_PASS
        echo
        read -s -p "Confirme la contraseña: " FTP_PASS2
        echo
        if [[ "$FTP_PASS" != "$FTP_PASS2" ]]; then
            echo "Error: Las contraseñas no coinciden."
        else
            echo "$FTP_USER:$FTP_PASS" | sudo chpasswd
            break
        fi
    done

    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo mkdir -p "$local_root/publica" "$local_root/$FTP_GROUP"
    sudo chmod 750 "$local_root"
    sudo chown -R "$FTP_USER:ftpusers" "$local_root"

    echo "Usuario $FTP_USER agregado correctamente."
}

# Cambiar de grupo a un usuario FTP
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario: " nombre
    if ! id "$nombre" &>/dev/null; then
        echo "Error: El usuario no existe."
        return
    fi

    grupo_actual=$(id -Gn "$nombre" | grep -Eo "reprobados|recursadores")
    if [[ -z "$grupo_actual" ]]; then
        echo "Error: El usuario no tiene grupo asignado."
        return
    fi

    nuevo_grupo=$([[ "$grupo_actual" == "reprobados" ]] && echo "recursadores" || echo "reprobados")

    if [[ "$grupo_actual" == "$nuevo_grupo" ]]; then
        echo "El usuario ya pertenece a $nuevo_grupo."
        return
    fi

    sudo usermod -G "$nuevo_grupo" "$nombre"
    echo "Usuario $nombre ahora pertenece a $nuevo_grupo."
}

# Configuración de seguridad y firewall
setup_security() {
    sudo chmod 755 /home/ftp
    sudo ufw allow 21/tcp
}

# Reiniciar vsftpd
restart_vsftpd() {
    sudo systemctl reload vsftpd
    sudo systemctl enable vsftpd
}

