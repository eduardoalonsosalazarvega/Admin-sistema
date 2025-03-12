#!/bin/bash

# Cargar funciones
source ./funciones.sh

# Menú principal
while true; do
    echo "===== MENÚ DE ADMINISTRACIÓN FTP ====="
    echo "1) Agregar un usuario FTP"
    echo "2) Cambiar de grupo a un usuario FTP"
    echo "3) Reiniciar servicio FTP"
    echo "4) Salir"
    read -p "Seleccione una opción: " opcion

    case $opcion in
        1) agregar_usuario ;;
        2) cambiar_grupo ;;
        3) reiniciar_vsftpd ;;
        4) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida, intente de nuevo." ;;
    esac
done
