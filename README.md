xamen1-SistemasDistribuidos-ChristianDavidLopezMorcillo

Christian David López Morcillo
A00312096
<b> <p ALIGN=center> EXAMEN 2 - Sistemas Distribuidos <p> </b>

1. Consigne los comandos de linux necesarios para el aprovisionamiento de los servicios solicitados. En este punto no debe incluir archivos tipo Dockerfile solo se requiere que usted identifique los comandos o acciones que debe automatizar.

<b> Para el balanceador de cargas: </b>

* Se escoge usar el programa Nginx balanceando cargas bajo el esquema round robin.

Primero se instala el repositorio necesario para poder instalar Ngix, esto se realiza agregando a los repositorios de yum un archivo. repo que indique la ruta para descargar nginx. El archivo se debe agregar en la ruta “/etc/yum.repos.d/” y debe tener la información:

```text
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

* Se realiza la instalación de Nginx usando yum.
```sh
sudo yum install nginx
```

* Se crea el archivo /etc/nginx/nginx.conf y allí se especifica la ip de los servidores que atenderán las peticione, de la siguiente forma:

```txt
http {
    upstream webservers {
         server 192.168.131.126;
         server 192.168.131.127;
	 server 192.168.131.128;
    }
    server {
        listen 8080;
        location / {
              proxy_pass http://webservers;
        }
    }
}
```

* Se agregan los permisos necesarios para el cortafuego.

```sh
 iptables -I INPUT 5 -p tcp -m state -- NEW -m tcp --dport 8080 -j ACCEPT
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
 service iptables save
```

* Se inicia el servicio Nginx.

```sh
sudo service nginx start
```

<b>Para el servidor web: </b>

* Se instala el servicio web apache:

```sh
sudo yum install httpd
```
* Se agregan los permisos necesarios para el cortafuegos.

```sh
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
 service iptables save
```

* Se agrega el archivo index.html a la ruta var/www/html/. Este archivo tiene la función de consultar la base de datos a través de métodos php. El archivo php debe tener el siguiente código:

```HTML
<HTML>
<BODY>
Servidor X
</BODY>
</HTML>
```

* Se inicia el servicio web.

```sh
sudo service httpd start
```


2. Escriba los archivos Dockerfile para cada uno de los servicios solicitados junto con los archivos fuente necesarios. Tenga en cuenta consultar buenas prácticas para la elaboración de archivos Dockerfile.

<b> Para el balanceador de cargas: </b>

El balanceador de cargas usado para esta infraestructura es nginx. Se crea una carpeta llamada Nginx que servirá de contexto para el contenedor de nginx. Este contenedor utiliza la imagen nginx del dockerhub. Se escribe el archivo Dockerfile que básicamente remplaza el archivo de configuración del servicio nginx y luego inicia el servicio de nginx. También se escribe un archivo nginx.conf que se encarga de mapear las direcciones de los servidores web que atenderán peticiones.

Se escribe el siguiente dockerfile:

```Dockerfile
# Se pasa la imagen base
FROM nginx

# Autor y mantenedor
MAINTAINER Christian David López Morcillo

# Eliminar el archivo de configuración por defecto de Nginx
RUN rm -v /etc/nginx/nginx.conf

# Copiar el archivo de configuración desde el directorio actual
ADD nginx.conf /etc/nginx/

# Agregar "daemon off;" en el comienzo de la configuración
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Setear el comando de defecto para ejecutar
# cuando se crea un nuevo contenedor
CMD service nginx start
```

 Y se escribe el archivo de configuración de nginx:
 
 ```txt
 worker_processes 3;
 
events { worker_connections 1024; }

http {
    sendfile on;
    
    # Lista de los servidores de aplicación
    upstream app_servers {
        server server1;
        server server2;
        server server3;
    }
    
    # Configuración del servidor
    server {

	# Puerto de ejecución
        listen 80;
        
        # Proxy de las conexiones
        location / {
            proxy_pass         http://app_servers;
            proxy_redirect     off;
            proxy_set_header   Host $host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host $server_name;
        }
    }
}
```

<b>Para el servidor web: </b>

Para la instalación de los 3 servidores web, se usa como servidor de aplicaciones apache. Además, se usa confd para inyección de variables en el html del apache. Confd es una aplicación para inyección de variables en archivos de configuración usando templates y variables del sistema.


Primero se escribe el dockerfile para la instalación del apache. Además, se ejecuta el stript start.sh que inyecta variables al html que expondrá el apache.

```Dockerfile
FROM httpd
MAINTAINER Christian López

ADD files/confd-0.10.0-linux-amd64 /usr/local/bin/confd
ADD files/start.sh /start.sh

RUN chmod +x /usr/local/bin/confd
RUN chmod +x /start.sh

ADD files/confd /etc/confd

CMD ["/start.sh"]
```


Luego se escribe el archivo start.sh que se encarga de inyectar la variable encargada de escribir el id del servidor apache a un htlm para poder identificar el servidor de aplicaciones cuando se le hagan peticiones.

start.sh
```sh
#!/bin/bash
set -e  

# if $proxy_domain is not set, then default to $HOSTNAME
export id_server=${id_server:-"Error, no se pudo setear el parámetro"}

# ensure the following environment variables are set. exit script and container if not set.
test $id_server

/usr/local/bin/confd -onetime -backend env

echo "Starting Apache"
exec httpd -DFOREGROUND
```

Luego se escribe un archivo .toml que se encarga de definir donde deberá ser ubicado el template del htlm.

index.html.toml
```toml
[template]
src = "index.html.tmpl"
dest = "/usr/local/apache2/htdocs/index.html"
```

Tambien se escribe un template del index.html.

index.html.tmpl
```tmpl
Este es el servidor numero: {{ getenv "id_server" }}
```


3. Escriba el archivo docker-compose.yml necesario para el despliegue de la infraestructura.

* Para el despliegue de la infraestructura planteada, se crea en un docker-compose.yml para 3 servidores web llamados cada uno serverX , donde X es el id del servidor, y un balanceador de cargas llamado nginx. 

* Los servidores web utilizan el dockerfile del contexto Web-Apache2 y el balanceador de cargas utiliza el dockerfile del contexto Nginx. 

* Para los contenedores web se hace apertura del puerto 5000. Para el balanceador de cargas se hace mapeo del puerto 8080 del host con el 80 del contenedor.

* Para cada uno de los servidores web se crea la variable id_server que se usa como variable de entorno del sistema para inyectar variables al html que se instalará en el apache2.

* Adicionalmente se crean y se asignan 2 volumenes, un volumen para el balanceador de cargas llamadao nginx_volume y otro compartido por todos los servidores web llamado apache_volume.

Se detalla el docker-compose final a continuación:

```yml
version: '2'

services:
  server1:
    build:
      context:  ./Web-Apache2
      dockerfile: Dockerfile
    environment:
      - id_server=1
    expose:
      - "5000"
    volumes:
      - apache_volume:/apache_volume

  server2:
    build:
      context:  ./Web-Apache2
      dockerfile: Dockerfile
    environment:
       - id_server=2
    expose:
       - "5000"
    volumes:
       - apache_volume:/apache_volume

  server3:
    build:
      context:  ./Web-Apache2
      dockerfile: Dockerfile
    environment:
      - id_server=3
    expose:
      - "5000"
    volumes:
      - apache_volume:/apache_volume

  nginx:
    build:
      context:  ./Nginx
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    links:
      - server1
      - server2
      - server3
    volumes:
      - nginx_volume:/nginx_volume

volumes:
    apache_volume:

    nginx_volume:
```

4. Publicar en un repositorio de github los archivos para el aprovisionamiento junto con un archivo de extensión .md donde explique brevemente como realizar el aprovisionamiento.

* Se publica el examen en el repositorio https://github.com/phalcon30964/examen2-SistemasDistribuidos-ChristianDavidLopezMorcillo


5. Incluya evidencias que muestran el funcionamiento de lo solicitado

* Se muestra capturas de 3 accesos a al balanceador en la carpeta evidencias, podemos ver como el balanceador redirige la petición a un servidor diferente en cada ocasión.

Figura 1: Primer acceso al balanceador

Figura 2: Segundo acceso al balanceador

Figura 3: Tercer acceso al balanceador

6. Documente algunos de los problemas encontrados y las acciones efectuadas para su solución al aprovisionar la infraestructura y aplicaciones 

* Problema 1: Los servidores web no podían ser accedidos desde otras máquinas. 
  Solución 1: Se agregó a iptables las configuraciones necesarias para abrir los puertos que apache necesita para recibir peticiones.





