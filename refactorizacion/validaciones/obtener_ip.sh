#!/bin/bash
source ./validaciones/validaciones.sh

while true; do
    read -p "Ingrese la dirección IP del servidor DNS: " ip_address
    if validate_ip "$ip_address"; then
        echo "$ip_address"
        break
    else
        echo "La dirección IP ingresada no es válida. Intente nuevamente."
    fi
done
