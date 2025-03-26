#!/bin/bash

cert_apache() {
    local port="$1"
    echo "Generando certificado SSL para Apache en el puerto $port..."

    sudo mkdir -p /usr/local/apache2/conf/ssl
    cd /usr/local/apache2/conf/ssl || exit 1

    sudo sed -i 's|#LoadModule ssl_module|LoadModule ssl_module|' /usr/local/apache2/conf/httpd.conf
    sudo sed -i 's|#LoadModule socache_shmcb_module|LoadModule socache_shmcb_module|' /usr/local/apache2/conf/httpd.conf

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout apache-selfsigned.key -out apache-selfsigned.crt \
        -subj "/C=MX/ST=Sinaloa/L=LosMochis/O=Org/OU=IT/CN=localhost"

    sudo tee /usr/local/apache2/conf/extra/httpd-ssl.conf > /dev/null <<EOL
<VirtualHost *:$port>
    ServerName localhost
    DocumentRoot "/usr/local/apache2/htdocs"
    SSLEngine on
    SSLCertificateFile "/usr/local/apache2/conf/ssl/apache-selfsigned.crt"
    SSLCertificateKeyFile "/usr/local/apache2/conf/ssl/apache-selfsigned.key"
    <Directory "/usr/local/apache2/htdocs">
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/usr/local/apache2/logs/error_log"
    CustomLog "/usr/local/apache2/logs/access_log" common
</VirtualHost>
EOL

    sudo sed -i 's|#Include conf/extra/httpd-ssl.conf|Include conf/extra/httpd-ssl.conf|' /usr/local/apache2/conf/httpd.conf
    sudo ufw allow 443/tcp
    sudo /usr/local/apache2/bin/apachectl restart
}

cert_nginx() {
    local port="$1"
    local nginx_ssl_dir="/etc/nginx/ssl"
    local nginx_conf="/etc/nginx/nginx.conf"

    echo "Generando certificado SSL para Nginx en el puerto $port..."
    sudo mkdir -p "$nginx_ssl_dir"

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$nginx_ssl_dir/nginx-selfsigned.key" \
        -out "$nginx_ssl_dir/nginx-selfsigned.crt" \
        -subj "/C=MX/ST=Sinaloa/L=LosMochis/O=Org/OU=IT/CN=localhost"

    if ! grep -q "listen ${port} ssl;" "$nginx_conf"; then
        sudo sed -i "/http {/a \
        server {\n\
            listen ${port} ssl;\n\
            server_name localhost;\n\
            ssl_certificate $nginx_ssl_dir/nginx-selfsigned.crt;\n\
            ssl_certificate_key $nginx_ssl_dir/nginx-selfsigned.key;\n\
            ssl_session_cache shared:SSL:1m;\n\
            ssl_session_timeout 5m;\n\
            ssl_ciphers HIGH:!aNULL:!MD5;\n\
            ssl_prefer_server_ciphers on;\n\
            location / {\n\
                root html;\n\
                index index.html index.htm;\n\
            }\n\
        }" "$nginx_conf"
    fi

    sudo /usr/local/nginx/sbin/nginx -t && sudo /usr/local/nginx/sbin/nginx -s reload
    sudo ufw allow 443/tcp
}

cert_ols() {
    local port="$1"
    local ols_dir="/usr/local/lsws/conf/ssl"
    local ols_conf="/usr/local/lsws/conf/httpd_config.conf"
    local vh_conf="/usr/local/lsws/conf/vhosts/Example/vhconf.conf"

    echo "Generando certificado SSL para OpenLiteSpeed en el puerto $port..."
    sudo mkdir -p "$ols_dir"
    cd "$ols_dir" || exit 1

    if [[ ! -f "litespeed-selfsigned.crt" || ! -f "litespeed-selfsigned.key" ]]; then
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout litespeed-selfsigned.key -out litespeed-selfsigned.crt \
            -subj "/C=MX/ST=Sinaloa/L=LosMochis/O=Org/OU=IT/CN=localhost"
    fi

    if ! grep -q "listener SSL" "$ols_conf"; then
        sudo tee -a "$ols_conf" > /dev/null <<EOL
listener SSL {
    address *:$port
    secure 1
    keyFile $ols_dir/litespeed-selfsigned.key
    certFile $ols_dir/litespeed-selfsigned.crt
    map Example *
}
EOL
    fi

    if [[ -f "$vh_conf" ]]; then
        sudo sed -i '/virtualHost Example {/a\
    vhssl {\n\
        enable                 1\n\
        keyFile                '$ols_dir/litespeed-selfsigned.key'\n\
        certFile               '$ols_dir/litespeed-selfsigned.crt'\n\
    }\n\
    docRoot /var/www/html\n\
    indexFiles index.html\n\
    ' "$vh_conf"
    fi

    sudo ufw allow $port/tcp
    sudo /usr/local/lsws/bin/lswsctrl restart
}
