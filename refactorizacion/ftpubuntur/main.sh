#!/bin/bash

# Incluir el archivo de funciones
source funciones.sh

# Verificar que el script se ejecuta como root
verificar_root

# Instalar vsftpd si no está instalado
instalar_vsftpd

# Configurar estructura de directorios y permisos
configurar_estructura

# Configurar firewall
configurar_firewall

# Reiniciar el servicio FTP
reiniciar_servicio

# Mostrar el menú de administración
mostrar_menu
