﻿# examen1-SistemasDistribuidos-ChristianDavidLopezMorcillo

Christian David Lopez Morcillo
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

* Se realiza la instalación de Nginx usando yum y se inicia el servicio.
```sh
sudo yum install nginx
```

* Se crea el archivo /etc/nginx/nginx.conf y allí se especifica la ip de los servidores que atenderán las peticione, de la siguiente forma:
```txt
http {
    upstream webservers {
         server 192,168,131,126;
         server 192,168,131,127;
    }
    server {
        listen 8080;
        location / {
              proxy_pass http://webservers;
        }
    }
}

```
* Se agregan los permisos necesarios para el cortafuegos.
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
* Se instala el servicio php:
```sh
sudo yum install php
```
* Se instala el servicio php-mysql:
```sh
sudo yum install php-mysql
```
* Se instala el servicio mysql:
```sh
sudo yum install mysql
```
* Se agregan los permisos necesarios para el cortafuegos.
```sh
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
 service iptables save
```
* Se habilita el acceso a ejecución de scripts php en código html. Se agrega el archivo .htaccess a la carpeta: /var/www/html/ con la siguiente información:

```txt
AddType php-script .php .htm .html
```
* Se agrega el archivo index.php a la ruta var/www/html/. Este archivo tiene la función de consultar la base de datos a través de métodos php. El archivo php debe tener el siguiente código:

```php
<HTML>
	<HEAD>
	<TITLE>Servidor <%=@idServer%></TITLE>
	</HEAD>
<BODY>
<H1>Servidor <%=@idServer%></H1>
<H2>La base de datos tiene la siguiente información:</H2>

	<?php
	$con = mysql_connect("<%=@ip_web%>","<%=@usuarioweb_web%>","<%=@passwordweb_web%>");
	if (!$con)
	  {
	  die('Could not connect: ' . mysql_error());
	  }

	mysql_select_db("database1", $con);

	$result = mysql_query("SELECT * FROM example");

	while($row = mysql_fetch_array($result))
	  {
	  echo $row['name'] . " " . $row['age'];
	  echo "<br />";
	  }

	mysql_close($con);
	?>
</BODY>
</HTML>
```

* Se inicia el servicio web.

```sh
sudo service httpd start
```

<b>Para el servidor de base de datos: </b>

 * Se instala el servidor de mysql
 
```sh
sudo service httpd start
```

* Se agregan los permisos necesarios para el cortafuegos.
```sh
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
 service iptables save 
```
* Se inicia el servicio de base de datos:

```sh
 sudo service mysqld start
 ```
* Se hace la configuración inicial del servicio mysql con el archivo /usr/bin/mysql_secure_installation.

* Se introducen datos a la base de datos y se da permisos a los servidores web a consultar la base de datos. Se crea y luego ejecuta el archivo create_schema.sql con la siguiente información:

```sql
CREATE database database1;
USE database1;
CREATE TABLE example(
 id INT NOT NULL AUTO_INCREMENT, 
 PRIMARY KEY(id),
 name VARCHAR(30), 
 age INT);
INSERT INTO example (name,age) VALUES ('Christian',23),('Luisa',23),('Pineros',23), ('Emmanuel',23);
-- http://www.linuxhomenetworking.com/wiki/index.php/Quick_HOWTO_:_Ch34_:_Basic_MySQL_Configuration
GRANT ALL PRIVILEGES ON *.* to '<%=@usuarioweb_db%>'@'<%=@ip_db%>' IDENTIFIED by '<%=@passwordweb_db%>';
GRANT ALL PRIVILEGES ON *.* to '<%=@usuarioweb_db%>'@'<%=@ip_db1%>' IDENTIFIED by '<%=@passwordweb_db%>';
```

2. Escriba los archivos Dockerfile para cada uno de los servicios solicitados junto con los archivos fuente necesarios. Tenga en cuenta consultar buenas prácticas para la elaboración de archivos Dockerfile.

* Se crea el siguiente archivo vagrantfile. En él se crean 4 máquinas. 1 máquina que servirá como balanceador de carga, usando nginx, llamada centos-nginx. 2 máquinas que servirán como servidores web, utilizando apache, llamadas centos-webX. 1 máquina que se usará como servidor de base de datos, usando mysql-server, llamada centos-db. A continuación, se ilustra el código y se muestra la configuración dada.

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  config.vm.define :centos_nginx do |web|
    web.vm.box = "Centos64"
    web.vm.network :private_network, ip: "192.168.33.12"
    web.vm.network "public_network", bridge: "enp5s0" , ip: "192.168.131.128"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512","--cpus", "1", "--name", "centos-nginx" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "nginx"
    end
  end
  config.vm.define :centos_web1 do |web|
    web.vm.box = "Centos64_updated"
    web.vm.network :private_network, ip: "192.168.33.13"
    web.vm.network "public_network", bridge: "enp5s0" , ip: "192.168.131.127"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512","--cpus", "1", "--name", "centos-web1" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "web"
      chef.json ={"web" => {"idServer" => "1"}}
    end
  end
  config.vm.define :centos_web2 do |web|
    web.vm.box = "Centos64_updated"
    web.vm.network :private_network, ip: "192.168.33.14"
    web.vm.network "public_network", bridge: "enp5s0" , ip: "192.168.131.126"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512","--cpus", "1", "--name", "centos-web2" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "web"
      chef.json ={"web" => {"idServer" => "2"}}
    end
  end
  config.vm.define :centos_db do |db|
    db.vm.box = "Centos64_updated"
    db.vm.network :private_network, ip: "192.168.33.15"
    db.vm.network "public_network", bridge: "enp5s0" , ip: "192.168.131.125"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512","--cpus", "1", "--name", "centos-db" ]
    end
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "db"
    end
  end  
end
```

3. Escriba el archivo docker-compose.yml necesario para el despliegue de la infraestructura.

Para el despliegue de la infraestructura planteada, se crea en un docker-compose.yml 3 servidores web llamados serverX y un balanceador de cargas llamado nginx. 

Los servidores web utilizan el dockerfile del contexto Web-Apache2 y el balanceador de cargas utiliza el dockerfile del contexto Nginx. 

Para los contenedores web se hace apertura del pueto 5000. Para el balanceador de cargas se hace mapeo del puerto 8080 del host con el 80 del contenedor.

Para cada uno de los servidores web se crea la variable id_server que se usa como variable de entorno del sistema para inyectar variables al html respuesta de apache2.

Adionalmente se crean y se asignan 2 volumenes, un volumen para el balanceador de cargas llamadao nginx_volume y otro compartido por todos los servidores web llamdao apache_volume.

Se detalla el docker-compose final a continuacion:

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

4. Publicar en un repositorio de github los archivos para el aprovisionamiento junto con un archivo de extensión .md donde explique brevemente como realizar el aprovisionamiento (15%)

Se publica el examen en el repositorio https://github.com/phalcon30964/examen1-SistemasDistribuidos-ChristianDavidLopezMorcillo


5. Incluya evidencias que muestran el funcionamiento de lo solicitado (15%)

Se muestra capturas de 2 accesos a al balanceador, podemos ver como el balanceador redirige la petición a un servidor diferente en cada ocasión.


Figura 1: Primer acceso al balanceador

Figura 2: Segundo acceso al balanceador

6. Documente algunos de los problemas encontrados y las acciones efectuadas para su solución al aprovisionar la infraestructura y aplicaciones (10%)

Problema 1: Los servidores web no podían ser accedidos desde otras máquinas. 
Solución 1: Se agregó a iptables las configuraciones necesarias para abrir los puertos que apache necesita para recibir peticiones.

Problema 2: Los servidores web no estaban autorizados para acceder a la base de datos y salía un problema de autenticación. 
Solución 2: Se ejecutó un script sql, en el servidor de base de datos, con el comando GRANT ALL PRIVILEGES para garantizar permisos a las ip de los servidores web.

Problema 3: Se requería ejecutar código php en el índex de los servidores web, pero no se podía ejecutar.
Solución 3: Se modificó el archivo .htaccess para dar permiso a que ese ejecutará código php en archivos con formato html.

Problema 4: Nginx no estaba en el repositorio local, por tanto, no podía descargase.
Solución 4: Se agregó a la lista del repositorio de yum el link de descarga de nginx.

Problema 5: Nginx arrojaba error al tratar de inicializar el servicio de balanceo de cargas.
Solución 5: En el archivo nginx.conf se cambió el puerto que venía por defecto, el 80, por el 8080 ya que el 80 estaba siendo usado por otro proceso.



