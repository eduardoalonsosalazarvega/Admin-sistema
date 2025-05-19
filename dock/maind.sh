#!/bin/bash
#Importar las funciones desde su archivo
#!/bin/bash

IMAGEN="httpd"

FLAG_APACHE_MONTADO=".apache_montado"
FLAG_IMAGEN_MODIFICADA=".imagen_modificada"
FLAG_IMAGEN_PERSONALIZADA=".imagen_personalizada"
FLAG_COMUNICACION_CONTENEDORES=".comunicacion_contenedores"

Instalar_Docker()
{
    local USUARIO="eduardo"

    #Validacion para ver si Docker ya está instalado
    if command -v docker &> /dev/null; then
        echo "Docker ya está instalado en el sistema. REGRESANDO AL MENÚ"
        return
    fi

    sudo apt update     #Actualizar repositorios

    #Instalar paquetes necesarios para repositorios HTTPS
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    #Agregar clave GPG y repositorio oficial de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt update

    #Mostrar versiones disponibles de docker y luego instalar
    apt-cache policy docker-ce
    sudo apt install docker-ce
    
    #checar el estado de docker
    sudo systemctl status docker

    #Agregamos usuario al grupo docker
    sudo usermod -aG docker "$USUARIO"
    newgrp docker

    echo "LISTO, Se agregó el usuario '$USUARIO' al grupo docker correctamente."
}

Montar_Apache(){
    local PUERTO=8080
    local NOMBRE_CONTENEDOR="apache-server"
    local IMAGEN="httpd"

    #Validar si Docker está instalado
    if ! command -v docker &> /dev/null; then
        echo "Docker no esta listo"
        return
    fi

    #Verificacion por si ya se ejecutó previamente
    if [ -f $FLAG_APACHE_MONTADO ]; then
        echo "Apache ya está montado. REGRESANDO AL MENÚ"
        return
    fi

    #Buscar la imagen
    docker search "$IMAGEN"
    #Descargar la imagen de Apache
    docker pull "$IMAGEN"
    #Ejecuta el contenedor en segundo plano
    docker run -d --name "$NOMBRE_CONTENEDOR" -p "$PUERTO":80 "$IMAGEN"
    
    #Comando para mostrar los contenedores que están actualmente en ejecución (comprobacion mas q nada)
    docker ps

    echo "Iamegen de apache montada al cien"
    touch $FLAG_APACHE_MONTADO  #Marcar como montado
}

Modificar_Imagen_Apache(){
    local PUERTO=8086 
    local MENSAJE="<h2> Hola profe im tired i cant more </h2>"  #Mensaje HTML

    #Validar si Docker está instalado
    if ! command -v docker &> /dev/null; then
        echo "Docker no está instalado, no se puede continuar :("
        return
    fi

    #Verificar si ya se modificó la imagen
    if [ -f $FLAG_IMAGEN_MODIFICADA ]; then
        echo "La imagen de Apache ya fue modificada. REGRESANDO AL MENÚ"
        return
    fi

    #Crear el archivo HTML con el mensaje personalizado
    echo "$MENSAJE" > index.html

    docker run -d --name apache_duplic -p "$PUERTO":80 -v $(pwd)/index.html:/usr/local/apache2/htdocs/index.html "$IMAGEN"

    echo "LISTO, IMAGEN MODIFICADA CORRECTAMENTE, ejecutandose en :$PUERTO"
    touch $FLAG_IMAGEN_MODIFICADA  #Marcar como modificada
}

Imagen_Personalizada(){
    local PUERTO=8083
    local NOMBRE_CONTENEDOR="apache_clon"

    #Validar si Docker está instalado
    if ! command -v docker &> /dev/null; then
        echo "Docker no está instalado, no se puede continuar :("
        return
    fi

    #Verificar si ya se creó la imagen personalizada
    if [ -f $FLAG_IMAGEN_PERSONALIZADA ]; then
        echo "La imagen personalizada ya ha sido creada. REGRESANDO AL MENÚ"
        return
    fi
    
    cat <<EOF > Dockerfile
    #Dockerfile basado en la imagen oficial de Apache
    FROM httpd
    COPY index.html /usr/local/apache2/htdocs/index.html
EOF

    #Se Construye la nueva imagen personalizada usando el Dockerfile
    docker build -t apache_duplic .

    #Ejecuta un contenedor basado en la nueva imagen personalizada
    docker run -d --name "$NOMBRE_CONTENEDOR" -p "$PUERTO":80 apache_duplic

    echo "Contenedor '$NOMBRE_CONTENEDOR' ejecutándose con la imagen personalizada :$PUERTO"
    touch $FLAG_IMAGEN_PERSONALIZADA
}

Comunicacion_Contenedores(){
    local RED_DOCKER="comunicacion_postgres_red"  #Nombre de la red Docker
    local POSTGRES1="c_postgres1"  #Nombre del primer contenedor PostgreSQL
    local POSTGRES2="c_postgres2"  #Nombre del segundo contenedor PostgreSQL
    local DB1="database_n1"  #Nombre de la base de datos en el primer contenedor
    local DB2="database_n2"  #Nombre de la base de datos en el segundo contenedor
    local USUARIO1="user1"  #Usuario en el primer contenedor
    local USUARIO2="user2"  #Usuario en el segundo contenedor
    local PASS1="contra123"  #Contraseña para el primer contenedor
    local PASS2="contra456"  #Contraseña para el segundo contenedor

    #Validar si Docker está instalado
    if ! command -v docker &> /dev/null; then
        echo "Docker no está instalado, no se puede continuar :("
        return
    fi

    #Verificar si ya se configuraron los contenedores
    if [ -f $FLAG_COMUNICACION_CONTENEDORES ]; then
        echo "La comunicación entre contenedores ya fue configurada. REGRESANDO AL MENÚ"
        return
    fi

    #Crea la red Docker para la comunicación entre contenedores
    docker network create $RED_DOCKER

    #Ejecuta el primer contenedor PostgreSQL
    docker run -d --name $POSTGRES1 \
        --network $RED_DOCKER \
        -e POSTGRES_USER=$USUARIO1 \
        -e POSTGRES_PASSWORD=$PASS1 \
        -e POSTGRES_DB=$DB1 \
        postgres

    #Ejecuta el segundo contenedor PostgreSQL
    docker run -d --name $POSTGRES2 \
        --network $RED_DOCKER \
        -e POSTGRES_USER=$USUARIO2 \
        -e POSTGRES_PASSWORD=$PASS2 \
        -e POSTGRES_DB=$DB2 \
        postgres

    #Conecta al primer contenedor y acceder a su terminal
    #docker exec -it $POSTGRES1 bash
    #apt install -y postgresql-client  #Instala el cliente PostgreSQL para conectar a otros contenedores

    #Se Conecta al segundo contenedor desde el primero usando psql
    #PGPASSWORD=$PASS2 psql -h $POSTGRES2 -U $USUARIO2 -d $DB2

    #Instalar cliente y conectarse del contenedor 1 al 2
    docker exec $POSTGRES1 bash -c "apt update && apt install -y postgresql-client && PGPASSWORD=$PASS2 psql -h $POSTGRES2 -U $USUARIO2 -d $DB2"

    #-------------------------------------------------------------------

    #Salir del primer contenedor y conectar al segundo
    #docker exec -it $POSTGRES2 bash
    #apt install -y postgresql-client  #Instala el cliente PostgreSQL también en el segundo contenedor

    #Se Conecta al primer contenedor desde el segundo usando psql igual que en el codigo anterior
    #PGPASSWORD=$PASS1 psql -h $POSTGRES1 -U $USUARIO1 -d $DB1

    #Instalar cliente y conectarse del contenedor 2 al 1
    docker exec $POSTGRES2 bash -c "apt update && apt install -y postgresql-client && PGPASSWORD=$PASS1 psql -h $POSTGRES1 -U $USUARIO1 -d $DB1"

    docker network inspect comunicacion_postgres_red	#chequear la red entre contenedores, para verificar la comunicación entre contenedores
    touch $FLAG_COMUNICACION_CONTENEDORES
}


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

