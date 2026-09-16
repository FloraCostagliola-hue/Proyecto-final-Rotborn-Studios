Fase 3 — Preparación de registros

## Objetivo

Antes de la implantación del IDS se identificaron las principales fuentes de información disponibles en el servidor.

El objetivo es poder responder a la siguiente pregunta:

> Si alguien realiza una acción contra el servidor, ¿dónde podemos encontrar evidencia?

Las principales fuentes de evidencia identificadas son:

- Sistema operativo Ubuntu Server.
- Servicio SSH.
- Aplicación web WordPress/Apache.
- Contenedores Docker.
- Base de datos MariaDB.

---

## 9.2 Configuración de fecha y hora

La configuración horaria del servidor se comprobó mediante:

date

y:

timedatectl

Inicialmente el servidor utilizaba la zona horaria Etc/UTC.

Para utilizar la hora local de España se configuró:

sudo timedatectl set-timezone Europe/Madrid

La configuración final quedó:

Time zone: Europe/Madrid (CEST, +0200)
System clock synchronized: yes
NTP service: active

La hora del sistema se encuentra sincronizada mediante NTP.

Configuración horaria de WordPress

El contenedor WordPress también se configuró para utilizar la zona horaria Europe/Madrid mediante la variable:

TZ: Europe/Madrid

La configuración se verificó con:

docker exec rotborn-wordpress-1 date

Resultado:

Wed Sep 16 19:39:24 CEST 2026

De esta forma, los registros de Ubuntu y Apache/WordPress utilizan la misma referencia horaria local.

9.3 Evidencias de SSH

Los registros de autenticación SSH se encuentran en:

/var/log/auth.log

##Login SSH correcto

Se generó un acceso SSH válido y posteriormente se buscó en los registros:

sudo grep "Accepted" /var/log/auth.log | tail

Se obtuvo, entre otras, la siguiente entrada:

Sep 16 19:02:19 rotborn-server sshd[1372]: Accepted password for zadmin from 10.21.4.40 port 49934 ssh2

##Login SSH incorrecto

Se generó un intento de acceso utilizando el usuario ficticio usuario_falso.

La evidencia se obtuvo mediante:

sudo grep -E "Failed password|Invalid user" /var/log/auth.log | tail -5

Resultado:

Sep 16 19:08:17 rotborn-server sshd[1454]: Invalid user usuario_falso from 10.21.4.40 port 50573
Sep 16 19:08:25 rotborn-server sshd[1454]: Failed password for invalid user usuario_falso from 10.21.4.40 

##Evidencias HTTP

Los registros de acceso de Apache se consultan mediante los logs del contenedor WordPress:

docker logs rotborn-wordpress-1
Petición HTTP correcta

Se realizó una petición a la página principal:

http://10.21.4.36:8080/

La evidencia obtenida fue:

10.21.4.40 - - [16/Sep/2026:19:41:07 +0200] "GET / HTTP/1.1" 200 12534

##Petición HTTP incorrecta

Se realizó una petición a una URL inexistente:

http://10.21.4.36:8080/esto-no-existe

La evidencia obtenida fue:

10.21.4.40 - - [16/Sep/2026:19:42:33 +0200] "GET /esto-no-existe HTTP/1.1" 404 59042

##Logs de Docker

Se comprobó que Docker registra la actividad de los contenedores mediante:

docker logs rotborn-wordpress-1 --tail 10

Los registros mostraron eventos de Apache y peticiones HTTP, incluyendo códigos 200, 302 y 404.

También se comprobó el estado de los servicios mediante:

docker compose ps

Resultado:

rotborn-mariadb-1           Up
rotborn-mariadb-replica-1   Up
rotborn-wordpress-1         Up

Por tanto, Docker proporciona una fuente adicional de evidencia sobre la actividad de los servicios.
