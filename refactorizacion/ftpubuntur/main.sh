#!/bin/bash

# Importar funciones
source ./funciones.sh

# Verificar permisos
check_root

# Instalar y configurar vsftpd
install_vsftpd
setup_vsftpd
setup_directories
setup_security
restart_vsftpd

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
            *) echo "Opción no válida, intente de nuevo." ;;
        esac
    done
}

mostrar_menu
