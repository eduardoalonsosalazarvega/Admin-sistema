#!/bin/bash

source "./menu_http.sh"
source "./obtenerversion.sh"
source "./solicitarv.sh"
source "./solicitarpuerto.sh"
source "./configuraciones.sh"
source "./certificados.sh"

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" 
    exit 1
fi

sudo apt install net-tools -y > /dev/null 2>&1

while true; do
    menu_http
    read -p "Selecciona el servicio HTTP que desea instalar (1-3): " op
            
    if [ "$op" -eq 1 ]; then
        versions=$(obtener_version "Apache")
        stable=$(echo "$versions" | head -1)
        menu_http2 "Apache" "$stable" " "
        echo "Selecciona la version que desea instalar:: "
        op2=$(solicitar_ver "Apache") 
        if [ "$op2" -eq 1 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            read -p "¿Desea habilitar SSL? (s/n): " ssl_choice
            if [[ "$ssl_choice" == "s" ]]; then
                conf_apache "$port" "$stable"
                cert_apache "$port"
            else
                conf_apache "$port" "$stable"
            fi
        elif [ "$op2" -eq 2 ]; then
            continue
        fi
    elif [ "$op" -eq 2 ]; then
        versions=$(obtener_version "Nginx")
        stable=$(echo "$versions" | tail -n 2 | head -1)
        mainline=$(echo "$versions" | tail -1)
        menu_http2 "Nginx" "$stable" "$mainline"
        echo "Selecciona la version que desea instalar:: "
        op2=$(solicitar_ver "Nginx")
        if [ "$op2" -eq 1 ]; then  
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            read -p "¿Desea habilitar SSL? (s/n): " ssl_choice
            if [[ "$ssl_choice" == "s" ]]; then
                conf_nginx "$port" "$stable"
                cert_nginx "$port"
            else
                conf_nginx "$port" "$stable"
            fi
        elif [ "$op2" -eq 2 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            read -p "¿Desea habilitar SSL? (s/n): " ssl_choice
            if [[ "$ssl_choice" == "s" ]]; then
                conf_nginx "$port" "$mainline"
                cert_nginx "$port"
            else
                conf_nginx "$port" "$mainline"
            fi
        elif [ "$op2" -eq 3 ]; then
            continue
        fi
    elif [ "$op" -eq 3 ]; then
        versions=$(obtener_version "OpenLiteSpeed")
        stable=$(echo "$versions" | tail -n 2 | head -1)
        mainline=$(echo "$versions" | tail -1)
        menu_http2 "OpenLiteSpeed" "$stable" "$mainline"
        echo "Selecciona la version que desea instalar: "
        op2=$(solicitar_ver "OpenLiteSpeed")
        if [ "$op2" -eq 1 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            read -p "¿Desea habilitar SSL? (s/n): " ssl_choice
            if [[ "$ssl_choice" == "s" ]]; then
                conf_litespeed "$port" "$stable"
                cert_ols "$port"
            else
                conf_litespeed "$port" "$stable"
            fi
        elif [ "$op2" -eq 2 ]; then 
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            read -p "¿Desea habilitar SSL? (s/n): " ssl_choice
            if [[ "$ssl_choice" == "s" ]]; then
                conf_litespeed "$port" "$mainline"
                cert_ols "$port"
            else
                conf_litespeed "$port" "$mainline"
            fi
        elif [ "$op2" -eq 3 ]; then
            continue
        fi
    elif [ "$op" -eq 4 ]; then
        echo "Saliendo..."
        exit 0
    else
        echo "Opción no valida.Vuelve a intentar"
    fi
done
