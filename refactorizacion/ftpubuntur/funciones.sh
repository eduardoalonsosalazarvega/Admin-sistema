#!/bin/bash

# Verificar que se ejecute como root
verificar_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Instalar vsftpd si no está instalado
instalar_vsftpd() {
    if ! systemctl list-unit-files | grep -q "vsftpd"; then
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
    else
        echo "vsftpd ya está instalado."
    fi
}

# Configurar estructura de directorios y permisos
configurar_estructura() {
    FTP_ROOT="/home/ftp"
    PUBLIC_DIR="$FTP_ROOT/publica"
    USERS_DIR="$FTP_ROOT/users"
    GROUPS_DIR="$FTP_ROOT/grupos"

    echo "Creando estructura de directorios..."
    sudo mkdir -p "$PUBLIC_DIR" "$USERS_DIR" "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores" "$FTP_ROOT/anon/publica"

    echo "Configurando permisos..."
    sudo chmod 770 "$GROUPS_DIR/reprobados" "$GROUPS_DIR/recursadores"
    sudo chown root:reprobados "$GROUPS_DIR/reprobados"
    sudo chown root:recursadores "$GROUPS_DIR/recursadores"
    sudo chmod 755 /home/ftp
    sudo chmod 775 "$PUBLIC_DIR"
    sudo chown root:ftpusers "$PUBLIC_DIR"
}

# Agregar usuario FTP
agregar_usuario() {
    read -p "Ingrese el nombre del usuario FTP: " FTP_USER
    if [[ -z "$FTP_USER" || "$FTP_USER" =~ [^a-zA-Z0-9_.-] || ${#FTP_USER} -lt 4 || ${#FTP_USER} -gt 16 || "$FTP_USER" =~ ^[^a-zA-Z] ]]; then
        echo "Error: Nombre de usuario no válido."
        return
    fi
    read -p "Ingrese el grupo principal del usuario (reprobados, recursadores): " FTP_GROUP
    if [[ "$FTP_GROUP" != "reprobados" && "$FTP_GROUP" != "recursadores" ]]; then
        echo "Error: Grupo inválido."
        return
    fi

    local_root="/srv/ftp/$FTP_USER"
    sudo useradd -m -d "$local_root" -s /usr/sbin/nologin "$FTP_USER"
    read -s -p "Ingrese una contraseña: " FTP_PASS
    echo "$FTP_USER:$FTP_PASS" | sudo chpasswd
    sudo usermod -aG "$FTP_GROUP" "$FTP_USER"
    sudo usermod -aG "ftpusers" "$FTP_USER"
    
    sudo mkdir -p "$local_root/publica" "$local_root/$FTP_GROUP"
    sudo chown -R "$FTP_USER:$FTP_USER" "$local_root"
}

# Cambiar de grupo a un usuario FTP
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario a cambiar de grupo: " nombre
    if ! id "$nombre" &>/dev/null; then
        echo "El usuario no existe."
        return
    fi
    nuevo_grupo=$([[ "$grupo_actual" == "reprobados" ]] && echo "recursadores" || echo "reprobados")
    sudo usermod -G "$nuevo_grupo" "$nombre"
    echo "Usuario $nombre ahora pertenece a $nuevo_grupo."
}

# Reiniciar servicio FTP
reiniciar_servicio() {
    echo "Reiniciando servicio FTP..."
    sudo systemctl restart vsftpd
    sudo systemctl enable vsftpd
}

# Configurar firewall
configurar_firewall() {
    echo "Configurando firewall..."
    sudo ufw allow 21/tcp
}

# Mostrar menú
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
            *) echo "Opción no válida." ;;
        esac
    done
}
