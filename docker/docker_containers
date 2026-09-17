# Docker — Contenedores e Infraestructura

La infraestructura Docker de **Rotborn Studios** se define, despliega y administra mediante el uso de **Docker Compose**. La arquitectura se compone de tres contenedores principales, redes aisladas y volúmenes persistentes.

---

## 1. Arquitectura de Servicios

El archivo de configuración principal es `docker-compose.yml`, el cual levanta los siguientes servicios:
* **WordPress**: Aplicación web y portal corporativo.
* **MariaDB Primary**: Base de datos relacional principal.
* **MariaDB Replica**: Instancia secundaria para la replicación y redundancia de datos.

### Despliegue y Comandos de Gestión

1. Situarse en el directorio del proyecto:
   ```bash
   cd /srv/rotborn
   ```
2. Validar la sintaxis de la configuración antes de desplegar:
   ```bash
   docker compose config
   ```
3. Levantar los servicios en segundo plano (*detached mode*):
   ```bash
   docker compose up -d
   ```
4. Comprobar el estado operativo de los contenedores (deben aparecer en estado `Up`):
   ```bash
   docker compose ps
   ```

---

## 2. WordPress (Aplicación Web)

Portal web corporativo de Rotborn Studios encargado de la gestión de contenidos.

* **Imagen Docker:** `wordpress:7.1.0-php8.3-apache`
* **Mapeo de Puertos:** `8080:80` (El puerto `8080` del host redirige al puerto `80` del contenedor).
* **Redes Asignadas:** Conectado simultáneamente a `rotborn_public` y `rotborn_private`. Esto le otorga salida al exterior y acceso interno a las bases de datos.
* **Conexión a Base de Datos:** Se comunica utilizando el nombre del servicio Docker asignado (`mariadb`).

---

## 3. MariaDB Primary (Base de Datos Principal)

Instancia central encargada de gestionar las transacciones y almacenamiento de WordPress.

* **Imagen Docker:** `mariadb:10.11`
* **Red Asignada:** `rotborn_private` (Aislada del exterior).
* **Puertos:** Puerto `3306` **no publicado** hacia el host; únicamente accesible por los servicios de la red privada.
* **Persistencia:** Mapeo de almacenamiento en el host:
  * Directorio local: `/srv/rotborn/db`
  * Directorio en contenedor: `/var/lib/mysql`
* **Configuración:** Utiliza el archivo dedicado `config/mariadb/primary.cnf`.

---

## 4. MariaDB Replica (Instancia de Respaldo)

Segunda instancia de MariaDB configurada como réplica síncrona/asíncrona de la base de datos principal.

* **Imagen Docker:** `mariadb:10.11`
* **Red Asignada:** `rotborn_private` (Aislada del exterior).
* **Puertos:** Puerto `3306` **no publicado** externamente.
* **Persistencia:** Mapeo de almacenamiento en el host:
  * Directorio local: `/srv/rotborn/db-replica`
  * Directorio en contenedor: `/var/lib/mysql`
* **Configuración:** Utiliza el archivo dedicado `config/mariadb-replica/replica.cnf`.

### Verificación de la Replicación
Para comprobar el estado correcto de la sincronización desde el contenedor de la réplica:
```bash
docker exec -it rotborn-mariadb-replica-1 mariadb -u root -p
```
Una vez dentro de la consola SQL, ejecutar:
```sql
SHOW SLAVE STATUS\G
```
**Parámetros clave de validación:**
* `Slave_IO_Running: Yes`
* `Slave_SQL_Running: Yes`
* `Seconds_Behind_Master: 0`

---

## 5. Segmentación de Redes Docker

Docker Compose configura dos redes independientes para aislar el tráfico:

* **`rotborn_public`**: Red externa utilizada exclusivamente por WordPress para atender solicitudes web.
* **`rotborn_private`**: Red interna reservada para la comunicación exclusiva entre WordPress, MariaDB Primary y el flujo de replicación hacia MariaDB Replica.

```text
  [ rotborn_public ] ──> ( WordPress ) 
                                │
  [ rotborn_private] ──> ( WordPress ) ──> ( MariaDB Primary ) ──( Replicación )──> ( MariaDB Replica )
```

Para listar y comprobar las redes activas en el sistema:
```bash
docker network ls
```

---

## 6. Persistencia de Datos

La infraestructura garantiza la retención de la información separando los datos del ciclo de vida de los contenedores mediante directorios dedicados en el host:
* `/srv/rotborn/db` (Principal)
* `/srv/rotborn/db-replica` (Réplica)

> **⚠️ Advertencias importantes:**
> * Detener o reiniciar los servicios con `docker compose down` y `docker compose up -d` **no elimina** los datos.
> * **NO ejecutar** `docker compose down -v` bajo ningún concepto si se desean conservar los volúmenes de datos.
> * **NO eliminar manualmente** las carpetas físicas en `/srv/rotborn/db` o `/srv/rotborn/db-replica` para evitar corrupciones en las bases de datos.

---

## 7. Resumen de Comandos Principales

| Acción | Comando |
| :--- | :--- |
| **Iniciar servicios** | `docker compose up -d` |
| **Detener servicios** | `docker compose down` |
| **Reiniciar servicios** | `docker compose restart` |
| **Comprobar estado** | `docker compose ps` |
| **Ver logs generales** | `docker compose logs --tail 50` |
| **Ver logs de WordPress** | `docker logs rotborn-wordpress-1 --tail 50` |
| **Listar redes Docker** | `docker network ls` |

## 8. Recuperación Rápida y Resolución de Incidencias

Si la infraestructura Docker experimenta fallos o detenciones inesperadas, siga el siguiente procedimiento de recuperación:

1. **Acceder al directorio del proyecto:**
   ```bash
   cd /srv/rotborn
   ```

2. **Validar la integridad del archivo de configuración:**
   ```bash
   docker compose config
   ```

3. **Reanudar o desplegar los servicios si no se detectan errores:**
   ```bash
   docker compose up -d
   ```

4. **Verificar el estado operativo de los contenedores:**
   ```bash
   docker compose ps
   ```

### Validación Post-Recuperación
Asegúrese de que los tres servicios principales aparezcan en estado **`Up`**:
* `rotborn-wordpress-1`
* `rotborn-mariadb-1` (Primary)
* `rotborn-mariadb-replica-1`

Una vez confirmada la ejecución de los contenedores, proceda a validar:
* La accesibilidad de la aplicación web de **Rotborn Studios**.
* El estado correcto de la replicación en **MariaDB** ejecutando `SHOW SLAVE STATUS\G` en la base de datos de respaldo.
