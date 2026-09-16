# Construcción inicial de la infraestructura

## 1. Máquina virtual

El proyecto se desarrolla sobre una máquina virtual creada con VirtualBox.

### Configuración

- **Sistema operativo:** Ubuntu Server 22.04.5 LTS (Jammy)
- **Arquitectura:** 64 bits
- **CPU:** 1 vCPU
- **Memoria RAM:** 2 GB
- **Disco virtual:** 20 GB
- **Red:** Bridged Adapter
- **Hostname:** `rotborn-server`
- **Usuario administrativo:** `zadmin`

La máquina virtual se mantiene en Ubuntu Server 22.04.5 LTS durante todo el proyecto para garantizar la estabilidad y reproducibilidad del entorno.

---

## 2. Conectividad y acceso remoto

Se instaló y configuró OpenSSH para permitir la administración remota del servidor.

Se comprobó que el servicio SSH está activo y funcionando.

También se verificó la conectividad externa mediante:

```bash
ping -c 4 8.8.8.8

La prueba obtuvo un 0 % de pérdida de paquetes.

3. Docker Engine

Se instaló Docker Engine para proporcionar la plataforma de contenedores utilizada por los servicios de la infraestructura.

Versión instalada:
Plaintext

Docker 29.1.3

Se comprobó que el servicio Docker está activo y funcionando correctamente.

4. Docker Compose

Se instaló Docker Compose para gestionar los diferentes servicios de la infraestructura mediante un archivo de configuración reproducible.

Versión instalada:
Plaintext

Docker Compose 2.40.3

La instalación se verificó mediante:
Bash

docker compose version

5. Directorio del proyecto

Se creó el directorio principal del proyecto:
Bash

/srv/rotborn

El directorio pertenece al usuario zadmin y será utilizado para almacenar los archivos de configuración, documentación y posteriormente los datos persistentes de los servicios.
6. Protección de información sensible

Se creó un archivo .env para almacenar las credenciales utilizadas por los servicios de Docker.


7. Infraestructura Docker y bases de datos

Se configuró Docker Compose para desplegar la infraestructura de base de datos del proyecto.

7.1 Red Docker

Se creó una red privada denominada rotborn_net para permitir la comunicación entre los contenedores sin necesidad de publicar sus puertos de base de datos directamente en el servidor:
Bash

docker network ls

7.2 Directorios para persistencia

Se crearon directorios independientes para almacenar los datos de las dos instancias MariaDB:
Bash

sudo mkdir -p /srv/rotborn/db
sudo mkdir -p /srv/rotborn/db-replica

Estos directorios se utilizan como bind mounts para mantener los datos aunque los contenedores sean recreados.
7.3 Configuración de MariaDB principal

Se creó el archivo /srv/rotborn/config/mariadb/primary.cnf con la siguiente configuración:
Ini, TOML

[mariadb]
server-id=1
log-bin=mariadb-bin
binlog-format=ROW

El parámetro server-id identifica de forma única a la instancia principal y log-bin permite registrar los cambios realizados en la base de datos para su replicación.
7.4 Configuración de MariaDB réplica

Se creó el archivo /srv/rotborn/config/mariadb-replica/replica.cnf con la configuración:
Ini, TOML

[mariadb]
server-id=2
relay-log=mariadb-relay-bin
read-only=1

El server-id permite identificar la réplica y el relay-log almacena temporalmente los cambios recibidos desde el servidor principal.

7.5 Configuración en Docker Compose

Se creó el archivo /srv/rotborn/docker-compose.yml. Actualmente se han definido los siguientes servicios:

    wordpress: aplicación web.

    mariadb: base de datos principal.

    mariadb-replica: base de datos réplica.

MariaDB principal

    Imagen: mariadb:10.11

    Configuración: Variables definidas en el archivo .env.

    Volúmenes:

        /srv/rotborn/db:/var/lib/mysql

        /srv/rotborn/config/mariadb/primary.cnf:/etc/mysql/conf.d/primary.cnf:ro

    Puertos: El puerto 3306 no se publica directamente en el servidor y queda disponible para la comunicación interna de Docker.

MariaDB réplica

    Imagen: mariadb:10.11

    Volúmenes:

        /srv/rotborn/db-replica:/var/lib/mysql

        /srv/rotborn/config/mariadb-replica/replica.cnf:/etc/mysql/conf.d/replica.cnf:ro

    Red: Utiliza la misma red Docker rotborn_net y se comunica con la MariaDB principal mediante el nombre del servicio mariadb.

Comprobación de la configuración

Antes del despliegue se verificó la configuración de Docker Compose mediante:
Bash

docker compose config

La configuración fue validada correctamente.

7.6 Despliegue de las bases de datos

Se iniciaron los servicios mediante Docker Compose:
Bash

docker compose up -d mariadb mariadb-replica

Se comprobó posteriormente el estado de los contenedores:
Bash

docker compose ps

Resultado:

    rotborn-mariadb-1 → Up

    rotborn-mariadb-replica-1 → Up

7.7 Configuración del usuario de replicación

En la MariaDB principal se creó el usuario técnico utilizado por la réplica:
SQL

CREATE USER 'replicator'@'%' IDENTIFIED BY '[CONTRASEÑA]';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;

    Nota: Las contraseñas utilizadas no se incluyen en la documentación ni en el repositorio.

7.8 Obtención de la posición del binlog

En la MariaDB principal se ejecutó:
SQL

SHOW MASTER STATUS;

Resultado obtenido durante la configuración:

    File: mariadb-bin.000002

    Position: 802

Estos valores se utilizaron para indicar a la réplica desde qué posición comenzar la replicación.
7.9 Configuración de la réplica

En la MariaDB réplica se configuró la conexión con el servidor principal mediante:
SQL

CHANGE MASTER TO
  MASTER_HOST='mariadb',
  MASTER_USER='replicator',
  MASTER_PASSWORD='[CONTRASEÑA]',
  MASTER_LOG_FILE='mariadb-bin.000002',
  MASTER_LOG_POS=802;

Posteriormente se inició la replicación:

SQL

START SLAVE;

7.10 Verificación de la replicación

Se comprobó el estado mediante:
SQL

SHOW SLAVE STATUS\G

El resultado confirmó:

    Slave_IO_Running: Yes

    Slave_SQL_Running: Yes

    Seconds_Behind_Master: 0

    Last_Error: (vacío)

Esto confirma que la réplica está conectada al servidor principal, procesa correctamente los cambios y no presenta errores.
7.11 Prueba real de replicación

Para comprobar que la replicación funcionaba realmente se creó una tabla de prueba en la base de datos principal:
SQL

CREATE TABLE prueba_replicacion (
    id INT PRIMARY KEY,
    mensaje VARCHAR(100)
);

INSERT INTO prueba_replicacion (id, mensaje)
VALUES (1, 'Prueba de replicacion Rotborn');

Posteriormente se accedió a la réplica y se comprobó el contenido:
SQL

USE rotborn;
SELECT * FROM prueba_replicacion;

Resultado en la réplica:

    id: 1

    mensaje: Prueba de replicacion Rotborn

La prueba confirma que los cambios realizados en la MariaDB principal son replicados automáticamente en la MariaDB réplica.
7.12 Limpieza de la prueba

Una vez verificada la replicación, se eliminó la tabla utilizada para la prueba desde la base de datos principal:
SQL

USE rotborn;
DROP TABLE prueba_replicacion;

Se comprobó en la MariaDB réplica que la eliminación también había sido replicada:
SQL

USE rotborn;
SHOW TABLES;

Resultado: Empty set. Esto confirmó que la eliminación realizada en la base de datos principal también fue aplicada correctamente en la réplica.
8. Aplicación web — WordPress

Se configuró WordPress como aplicación web de la infraestructura mediante Docker Compose.
8.1 Configuración en Docker Compose

Se definió el servicio wordpress en /srv/rotborn/docker-compose.yml.

    Imagen: wordpress:7.1.0-php8.3-apache

    Red: rotborn_net

    Conexión con la base de datos:

        WORDPRESS_DB_HOST=mariadb

        WORDPRESS_DB_NAME=rotborn

        WORDPRESS_DB_USER=rotborn

    Contraseña: Obtenida mediante el archivo .env.

    Puertos: Se publica en el servidor mediante 8080:80.

La configuración se validó mediante:
Bash

docker compose config

8.2 Despliegue de WordPress

WordPress se inició mediante:
Bash

docker compose up -d wordpress

Se comprobó el estado de los servicios mediante:
Bash

docker compose ps

Resultado:

    rotborn-mariadb-1 → Up

    rotborn-mariadb-replica-1 → Up

    rotborn-wordpress-1 → Up

8.3 Instalación de WordPress

El servicio web es accesible desde:
Plaintext

http://IP_DEL_SERVIDOR:8080

(En este proyecto, la dirección utilizada fue http://10.21.4.82:8080)

Se completó la instalación utilizando:

    Título del sitio: Rotborn Studios

    Usuario administrador: rotborn_admin

La instalación finalizó correctamente, confirmando que WordPress se comunica exitosamente con la MariaDB principal.
9. Comprobación de persistencia de la base de datos

Una vez reiniciados los contenedores, se comprobó que los datos de la base de datos de WordPress seguían disponibles.

Se comprobó el estado de los contenedores:
Bash

docker compose ps

A continuación, se accedió a la MariaDB principal:
Bash

docker exec -it rotborn-mariadb-1 mariadb -uroot -p

Se consultaron las tablas de la base de datos rotborn:
SQL

USE rotborn;
SHOW TABLES;

Resultado (12 tablas de WordPress):
wp_commentmeta, wp_comments, wp_links, wp_options, wp_postmeta, wp_posts, wp_term_relationships, wp_term_taxonomy, wp_termmeta, wp_terms, wp_usermeta, wp_users.

También se realizó una comprobación mediante una consulta sobre information_schema:
SQL

SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema = 'rotborn';

Resultado: 12

Los datos se almacenan mediante el bind mount /srv/rotborn/db → /var/lib/mysql, garantizando almacenamiento persistente.
10. Comprobación de puertos y servicios

Se verificaron los puertos utilizados tanto por la máquina virtual como por los contenedores Docker mediante docker compose ps:

    rotborn-mariadb-1 → 3306/tcp (interno)

    rotborn-mariadb-replica-1 → 3306/tcp (interno)

    rotborn-wordpress-1 → 0.0.0.0:8080->80/tcp

También se comprobaron los puertos en escucha de la máquina virtual mediante:
Bash

sudo ss -tulnp | grep -E ':22|:8080'

Resumen de servicios y puertos
Servicio	Puerto	Expuesto	Función
SSH	22/TCP	Sí	Administración remota de la VM
WordPress	8080/TCP	Sí	Aplicación web
MariaDB	3306/TCP	No	Base de datos principal interna
MariaDB réplica	3306/TCP	No	Réplica interna

La configuración mantiene la base de datos y su réplica protegidas sin exposición directa hacia el exterior, exponiendo únicamente los servicios necesarios.
