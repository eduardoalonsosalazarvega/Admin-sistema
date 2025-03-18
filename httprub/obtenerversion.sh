#!/bin/bash
obtener_version(){
    local service="$1"
    case "$service" in
        Apache)
            versions=$(curl -s "https://downloads.apache.org/httpd/" |  grep -oP '(?<=Apache HTTP Server )\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        Nginx)
            versions=$(curl -s "https://nginx.org/en/download.html" |  grep -oP '(?<=nginx-)\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        OpenLiteSpeed)
            versions=$(curl -s "https://openlitespeed.org/downloads/" | grep -oP '(openlitespeed-)\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        *)
            echo "Servicio no soportado"
            exit 1
            ;;
    esac

    echo "$versions"
}
#todo v