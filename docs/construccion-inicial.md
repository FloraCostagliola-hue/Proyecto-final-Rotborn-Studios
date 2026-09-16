# Construcción inicial de la infraestructura

## 1. Máquina virtual

El proyecto se desarrolla sobre una máquina virtual creada con VirtualBox.

### Configuración

- Sistema operativo: Ubuntu Server 22.04.5 LTS (Jammy)
- Arquitectura: 64 bits
- CPU: 1 vCPU
- Memoria RAM: 2 GB
- Disco virtual: 20 GB
- Red: Bridged Adapter
- Hostname: `rotborn-server`
- Usuario administrativo: `zadmin`

La máquina virtual se mantiene en Ubuntu Server 22.04.5 LTS durante todo el proyecto para garantizar la estabilidad y reproducibilidad del entorno.

## 2. Conectividad y acceso remoto

Se instaló y configuró OpenSSH para permitir la administración remota del servidor.

Se comprobó que el servicio SSH está activo y funcionando.

También se verificó la conectividad externa mediante:

ping -c 4 8.8.8.8

La prueba obtuvo un 0 % de pérdida de paquetes.

## 3. Docker Engine

Se instaló Docker Engine para proporcionar la plataforma de contenedores utilizada por los servicios de la infraestructura.

Versión instalada:

Docker 29.1.3

Se comprobó que el servicio Docker está activo y funcionando correctamente.

## 4. Docker Compose

Se instaló Docker Compose para gestionar los diferentes servicios de la infraestructura mediante un archivo de configuración reproducible.

Versión instalada:

Docker Compose 2.40.3

La instalación se verificó mediante:

docker compose version

## 5. Directorio del proyecto

Se creó el directorio principal del proyecto:

/srv/rotborn

El directorio pertenece al usuario zadmin y será utilizado para almacenar los archivos de configuración, documentación y posteriormente los datos persistentes de los servicios.

## 6. Protección de información sensible

Se creó un archivo .env para almacenar las credenciales utilizadas por los servicios de Docker.

El archivo .env no debe subirse al repositorio de GitHub.

Se configuró .gitignore para evitar que archivos que puedan contener información sensible sean añadidos accidentalmente al repositorio.

La protección se comprobó mediante:

git check-ignore -v .env

El resultado confirmó que .env está siendo ignorado por Git.

## 7. Configuración de Docker Compose

Se creó el archivo:

/srv/rotborn/docker-compose.yml

Docker Compose se utiliza para definir de forma reproducible los servicios que forman parte de la infraestructura.

Actualmente se han definido los siguientes servicios:

- `wordpress`: aplicación web.
- `mariadb`: base de datos principal.
- `mariadb-replica`: base de datos réplica.

### Red Docker

Los tres servicios utilizan una red privada denominada:

`rotborn_net`

La red permite la comunicación entre los contenedores sin necesidad de publicar sus puertos de base de datos directamente en el servidor.

### WordPress

El servicio WordPress utiliza la imagen:

`wordpress:7.1.0-php8.3-apache`

Se configuró para utilizar la MariaDB principal como servidor de base de datos.

La comunicación se realiza mediante el nombre del servicio Docker:

`mariadb`

El puerto HTTP del contenedor se publica en el servidor mediante:

`8080:80`

Por tanto, el servicio web será accesible desde:

`http://IP_DEL_SERVIDOR:8080`

### MariaDB principal

El servicio utiliza:

`mariadb:10.11`

La base de datos se configura mediante las variables definidas en el archivo `.env`.

Los datos se almacenan de forma persistente mediante un bind mount:

`/srv/rotborn/db:/var/lib/mysql`

También se monta la configuración específica de replicación:

`/srv/rotborn/config/mariadb/primary.cnf:/etc/mysql/conf.d/primary.cnf:ro`

El puerto 3306 no se publica directamente en el servidor y queda disponible para la comunicación interna de Docker.

### MariaDB réplica

El servicio utiliza:

`mariadb:10.11`

Los datos se almacenan mediante:

`/srv/rotborn/db-replica:/var/lib/mysql`

La configuración específica de la réplica se monta mediante:

`/srv/rotborn/config/mariadb-replica/replica.cnf:/etc/mysql/conf.d/replica.cnf:ro`

La réplica utiliza la misma red Docker `rotborn_net` y se comunica con la MariaDB principal mediante el nombre del servicio `mariadb`.

### Comprobación de la configuración

Antes del despliegue se verificó la configuración de Docker Compose mediante:

docker compose config

La configuración fue validada correctamente.

Posteriormente se iniciaron las bases de datos mediante:

docker compose up -d mariadb mariadb-replica

Y se comprobó el estado de los servicios mediante:

docker compose ps

## 8. Infraestructura Docker y base de datos

Se configuró Docker Compose para desplegar la infraestructura de base de datos del proyecto.

### 8.1 Red Docker

Se creó una red privada para permitir la comunicación entre los contenedores:

docker network ls

La red utilizada por los servicios es:

rotborn_net

### 8.2 Directorios para persistencia

Se crearon directorios independientes para almacenar los datos de las dos instancias MariaDB:

sudo mkdir -p /srv/rotborn/db
sudo mkdir -p /srv/rotborn/db-replica

Estos directorios se utilizan como bind mounts para mantener los datos aunque los contenedores sean recreados.

### 8.3 Configuración de MariaDB principal

Se creó el archivo:

/srv/rotborn/config/mariadb/primary.cnf

Con la siguiente configuración:

[mariadb]
server-id=1
log-bin=mariadb-bin
binlog-format=ROW

El parámetro `server-id` identifica de forma única a la instancia principal y `log-bin` permite registrar los cambios realizados en la base de datos para su replicación.

### 8.4 Configuración de MariaDB réplica

Se creó el archivo:

/srv/rotborn/config/mariadb-replica/replica.cnf

Con la configuración:

[mariadb]
server-id=2
relay-log=mariadb-relay-bin
read-only=1

El `server-id` permite identificar la réplica y el relay log almacena temporalmente los cambios recibidos desde el servidor principal.

### 8.5 Despliegue de las bases de datos

Se iniciaron los dos servicios mediante Docker Compose:

docker compose up -d mariadb mariadb-replica

Se comprobó posteriormente el estado de los contenedores:

docker compose ps

Resultado:

- `rotborn-mariadb-1` → Up
- `rotborn-mariadb-replica-1` → Up

### 8.6 Configuración del usuario de replicación

En la MariaDB principal se creó el usuario técnico utilizado por la réplica:

CREATE USER 'replicator'@'%' IDENTIFIED BY '[CONTRASEÑA]';

Se concedieron permisos específicos de replicación:

GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';

FLUSH PRIVILEGES;

Las contraseñas utilizadas no se incluyen en la documentación ni en el repositorio.

### 8.7 Obtención de la posición del binlog

En la MariaDB principal se ejecutó:

SHOW MASTER STATUS;

Resultado obtenido durante la configuración:

File: mariadb-bin.000002
Position: 802

Estos valores se utilizaron para indicar a la réplica desde qué posición comenzar la replicación.

### 8.8 Configuración de la réplica

En la MariaDB réplica se configuró la conexión con el servidor principal mediante:

CHANGE MASTER TO
  MASTER_HOST='mariadb',
  MASTER_USER='replicator',
  MASTER_PASSWORD='[CONTRASEÑA]',
  MASTER_LOG_FILE='mariadb-bin.000002',
  MASTER_LOG_POS=802;

Posteriormente se inició la replicación:

START SLAVE;

### 8.9 Verificación de la replicación

Se comprobó el estado mediante:

SHOW SLAVE STATUS\G

El resultado confirmó:

Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
Last_Error:

Esto confirma que la réplica está conectada al servidor principal, procesa correctamente los cambios y no presenta errores.

### 8.10 Prueba real de replicación

Para comprobar que la replicación funcionaba realmente se creó una tabla de prueba en la base de datos principal:

CREATE TABLE prueba_replicacion (
    id INT PRIMARY KEY,
    mensaje VARCHAR(100)
);

Se insertó un registro:

INSERT INTO prueba_replicacion (id, mensaje)
VALUES (1, 'Prueba de replicacion Rotborn');

Posteriormente se accedió a la réplica y se comprobó el contenido:

USE rotborn;

SELECT * FROM prueba_replicacion;

El registro apareció correctamente en la réplica:

id: 1
mensaje: Prueba de replicacion Rotborn

La prueba confirma que los cambios realizados en la MariaDB principal son replicados automáticamente en la MariaDB réplica.

### 8.11 Limpieza de la prueba

Una vez verificada la replicación, se eliminó la tabla utilizada para la prueba desde la base de datos principal.

Primero se seleccionó la base de datos:

USE rotborn;

Posteriormente se eliminó la tabla:

DROP TABLE prueba_replicacion;

Se comprobó en la MariaDB réplica que la eliminación también había sido replicada:

USE rotborn;

SHOW TABLES;

El resultado fue:

Empty set

Esto confirmó que la eliminación realizada en la base de datos principal también fue aplicada correctamente en la réplica, dejando ambas bases de datos limpias después de la prueba.

## 9. Aplicación web — WordPress

Se configuró WordPress como aplicación web de la infraestructura mediante Docker Compose.

### 8.1 Configuración en Docker Compose

Se definió el servicio `wordpress` en:

`/srv/rotborn/docker-compose.yml`

Se utilizó la imagen:

`wordpress:7.1.0-php8.3-apache`

El contenedor WordPress se configuró para utilizar la MariaDB principal como base de datos mediante la red Docker `rotborn_net`.

La conexión con la base de datos se definió mediante las variables de entorno de Docker Compose:

`WORDPRESS_DB_HOST=mariadb`

`WORDPRESS_DB_NAME=rotborn`

`WORDPRESS_DB_USER=rotborn`

La contraseña de acceso a la base de datos se obtiene mediante el archivo `.env`, que no se incluye en el repositorio.

La configuración completa de Docker Compose se validó mediante:

```bash
docker compose config

El comando confirmó que la configuración era válida.

### 9.2 Despliegue de WordPress

WordPress se inició mediante:

`docker compose up -d wordpress`

Durante el despliegue, Docker comprobó que la MariaDB principal ya estaba funcionando y posteriormente inició el contenedor WordPress.

Se comprobó el estado de los servicios mediante:

`docker compose ps`

El resultado mostró los siguientes servicios en ejecución:

`rotborn-mariadb-1 → Up`
`rotborn-mariadb-replica-1 → Up`
`rotborn-wordpress-1 → Up`

El puerto del contenedor WordPress se publicó mediante:

8080:80

Esto permite acceder al servicio web desde el cliente mediante:

http://IP_DEL_SERVIDOR:8080

En este proyecto, la dirección utilizada fue:

http://10.21.4.82:8080

8.3 Instalación de WordPress

Se accedió desde un navegador a:

http://10.21.4.82:8080

El acceso mostró correctamente la pantalla inicial de instalación de WordPress.

Se completó la instalación utilizando:

Título del sitio: Rotborn Studios
Usuario administrador: rotborn_admin

La instalación finalizó correctamente y se pudo acceder al panel de administración de WordPress.

El acceso correcto al panel confirma que WordPress ha podido comunicarse con la MariaDB principal configurada en Docker.

### 9.4 Comprobación del montaje de WordPress

El estado del contenedor se comprobó mediante:

`docker compose ps`

El contenedor rotborn-wordpress-1 permaneció en estado Up, confirmando que la aplicación web está funcionando dentro de la infraestructura Docker.

### 10 Comprobación de persistencia de la base de datos

Una vez iniciados nuevamente los contenedores de la infraestructura, se comprobó que los datos de la base de datos de WordPress seguían disponibles.

Se comprobó primero el estado de los contenedores:

```bash
docker compose ps

Los tres servicios aparecieron en estado Up:

rotborn-mariadb-1           Up
rotborn-mariadb-replica-1   Up
rotborn-wordpress-1         Up

A continuación, se accedió a la MariaDB principal:

`docker exec -it rotborn-mariadb-1 mariadb -uroot -p`

Se seleccionó la base de datos utilizada por WordPress:

`USE rotborn;`

Después se comprobaron las tablas existentes:

`SHOW TABLES;`

El resultado mostró las 12 tablas de WordPress:

wp_commentmeta
wp_comments
wp_links
wp_options
wp_postmeta
wp_posts
wp_term_relationships
wp_term_taxonomy
wp_termmeta
wp_terms
wp_usermeta
wp_users

También se realizó una comprobación mediante una consulta sobre information_schema:

SELECT COUNT(*) AS tablas
FROM information_schema.tables
WHERE table_schema = 'rotborn';

Resultado:

+--------+
| tablas |
+--------+
|     12 |
+--------+

Esta comprobación confirma que la base de datos rotborn y las 12 tablas de WordPress continúan disponibles después de volver a iniciar los contenedores.

Los datos de MariaDB se almacenan mediante un bind mount:

/srv/rotborn/db
        ↓
/var/lib/mysql

Por tanto, la infraestructura dispone de almacenamiento persistente para la base de datos.

### 11 Comprobación de puertos y servicios

Una vez comprobado el funcionamiento de la infraestructura, se verificaron los puertos utilizados tanto por la máquina virtual como por los contenedores Docker.

Primero se comprobaron los puertos publicados por Docker mediante:

```bash
`docker compose ps`

El resultado mostró:

rotborn-mariadb-1           3306/tcp
rotborn-mariadb-replica-1   3306/tcp
rotborn-wordpress-1         0.0.0.0:8080->80/tcp

Esto indica que:

WordPress publica el puerto 8080/TCP de la máquina virtual hacia el puerto 80/TCP del contenedor.
MariaDB utiliza el puerto 3306/TCP, pero no está publicado directamente en la máquina virtual.
La réplica MariaDB utiliza también el puerto 3306/TCP, pero permanece accesible únicamente dentro de la red Docker.

También se comprobaron los puertos en escucha de la máquina virtual mediante:

`sudo ss -tulnp | grep -E ':22|:8080'`

El resultado mostró:

tcp   LISTEN   0   4096   0.0.0.0:8080   0.0.0.0:*   users:(("docker-proxy",pid=1692,fd=7))
tcp   LISTEN   0    128   0.0.0.0:22     0.0.0.0:*   users:(("sshd",pid=705,fd=3))
tcp   LISTEN   0   4096   [::]:8080      [::]:*      users:(("docker-proxy",pid=1700,fd=7))
tcp   LISTEN   0    128   [::]:22        [::]:*      users:(("sshd",pid=705,fd=4))

La comprobación confirma que la máquina virtual tiene los siguientes servicios accesibles:

Servicio        Puerto  Expuesto        Función
SSH     22/TCP  Sí      Administración remota de la VM
WordPress       8080/TCP        Sí      Aplicación web
MariaDB 3306/TCP        No      Base de datos interna
MariaDB réplica 3306/TCP        No      Réplica interna

La configuración mantiene la base de datos y su réplica sin exposición directa hacia el exterior, mientras que únicamente los servicios necesarios para la administración y la aplicación web están publicados.
