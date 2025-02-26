#!/bin/bash
source ./validaciones/validaciones.sh

while true; do
    read -p "Ingrese el dominio: " domain
    if validate_domain "$domain"; then
        echo "$domain"
        break
    else
        echo "El dominio ingresado no es válido. Intente nuevamente."
    fi
done
