#!/bin/bash

#Importar las funciones desde su archivo
source ./funciones.sh

Instalar_Docker

while true; do
    echo ""
    echo "MENÚ PRACTICA DE DOCKER"
    echo "1. Montar imagen de Apache"
    echo "2. Modificar la imagen de Apache"
    echo "3. Crear una imagen personalizada en base a la de Apache"
    echo "4. Comunicación entre contenedores"
    echo "5. Salir"
    
    read -p "Opción: " opcion

    case "$opcion" in
        1) 
            Montar_Apache
            ;;
        2) 
            Modificar_Imagen_Apache
            ;;
        3) 
            Imagen_Personalizada
            ;;
        4) 
            Comunicacion_Contenedores
            ;;
        5) 
            echo "Saliendo del script..."
            break
            ;;
        *) 
            echo "OPCION INVÁLIDA, intente de nuevo."
            ;;
    esac
done