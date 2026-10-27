# Segmentación de redes Docker

> **Proyecto:** Rotborn Studios  


---

## 1. Arquitectura de red

Para mejorar la seguridad de la infraestructura se implementó una segmentación mediante **dos redes Docker independientes**:

| Red | Finalidad |
|:--|:--|
| `rotborn_public` | Red destinada a la exposición de la aplicación web. |
| `rotborn_private` | Red interna destinada a la comunicación entre WordPress y las bases de datos. |

### Distribución de los servicios

| Servicio | `rotborn_public` | `rotborn_private` |
|:--|:---:|:---:|
| WordPress |  Sí |  Sí |
| MariaDB Primary |  No |  Sí |
| MariaDB Replica |  No |  Sí |

De esta forma, **WordPress dispone de acceso a ambas redes**, mientras que MariaDB Primary y MariaDB Replica permanecen únicamente en la red privada.

```text
                         RED EXTERNA
                              │
                            :8080
                              │
                              ▼
                    ┌──────────────────┐
                    │    WordPress     │
                    │                  │
                    │ public + private │
                    └────────┬─────────┘
                             │
                       rotborn_private
                             │
                    ┌────────┴─────────┐
                    │                  │
                    ▼                  ▼
             ┌─────────────┐    ┌─────────────┐
             │   MariaDB   │    │   MariaDB   │
             │   Primary   │───▶│   Replica   │
             │    :3306    │    │    :3306    │
             └─────────────┘    └─────────────┘
```

---

## 2. Configuración de las redes

### 2.1 Copia de seguridad

Antes de modificar `docker-compose.yml`, se realizó una copia de seguridad:

```bash
cp docker-compose.yml docker-compose.yml.backup
```

Esto permitió conservar una versión anterior de la configuración en caso de necesitar recuperarla.

---

### 2.2 Configuración de WordPress

Se modificó el servicio `wordpress` para conectarlo a las dos redes:

```yaml
services:
  wordpress:
    image: wordpress:7.1.0-php8.3-apache
    networks:
      - rotborn_public
      - rotborn_private
```

De esta forma, WordPress puede:

- recibir conexiones desde la red pública;
- comunicarse con MariaDB a través de la red privada.

---

### 2.3 Configuración de MariaDB Primary

Se modificó el servicio `mariadb` para utilizar únicamente la red privada:

```yaml
mariadb:
  image: mariadb:10.11
  networks:
    - rotborn_private
```

MariaDB Primary no está conectado a `rotborn_public`.

---

### 2.4 Configuración de MariaDB Replica

La réplica también utiliza exclusivamente la red privada:

```yaml
mariadb-replica:
  image: mariadb:10.11
  networks:
    - rotborn_private
```

Esto mantiene la comunicación entre las bases de datos dentro de la red interna.

---

### 2.5 Definición de las redes

Finalmente se definieron las dos redes en `docker-compose.yml`:

```yaml
networks:
  rotborn_public:
    name: rotborn_public
    driver: bridge

  rotborn_private:
    name: rotborn_private
    driver: bridge
```

Las redes utilizan el controlador `bridge` de Docker.

---

## 3. Validación de la configuración

Una vez realizadas las modificaciones, se comprobó que el archivo Compose fuera válido:

```bash
docker compose config
```

La configuración se cargó correctamente.

---

## 4. Creación y puesta en marcha

Se levantó la infraestructura:

```bash
docker compose up -d
```

### Resultado obtenido

```text
[+] Running 5/5
 ✔ Network rotborn_public               Created
 ✔ Network rotborn_private              Created
 ✔ Container rotborn-mariadb-replica-1  Started
 ✔ Container rotborn-mariadb-1          Started
 ✔ Container rotborn-wordpress-1        Started
```

A continuación se comprobó el estado de los servicios:

```bash
docker compose ps
```

### Resultado obtenido

```text
NAME                        IMAGE                           STATUS
rotborn-mariadb-1           mariadb:10.11                   Up
rotborn-mariadb-replica-1   mariadb:10.11                   Up
rotborn-wordpress-1         wordpress:7.1.0-php8.3-apache   Up
```

WordPress quedó publicado mediante:

```text
0.0.0.0:8080 -> 80/tcp
```

Mientras que MariaDB Primary y MariaDB Replica mantienen el puerto `3306/tcp` únicamente dentro de Docker.

---

## 5. Comprobación de `rotborn_public`

Se comprobó el contenido de la red pública:

```bash
docker network inspect rotborn_public
```

### Resultado obtenido

WordPress aparece conectado a esta red con la dirección:

```text
172.19.0.2/16
```

La red pública contiene únicamente:

```text
rotborn-wordpress-1
```

Esto confirma que MariaDB Primary y MariaDB Replica **no están conectadas a la red pública**.

---

## 6. Comprobación de `rotborn_private`

Se comprobó la red privada:

```bash
docker network inspect rotborn_private
```

### Resultado obtenido

Los servicios conectados fueron:

| Contenedor | Dirección Docker |
|:--|:--|
| `rotborn-mariadb-1` | `172.20.0.3/16` |
| `rotborn-mariadb-replica-1` | `172.20.0.2/16` |
| `rotborn-wordpress-1` | `172.20.0.4/16` |

Por tanto, la red privada contiene los tres servicios necesarios para la comunicación interna:

```text
rotborn_private
       │
       ├── WordPress
       ├── MariaDB Primary
       └── MariaDB Replica
```

---

## 7. Puertos y exposición

La separación de redes se complementa con la configuración de puertos:

| Servicio | Puerto | Exposición | Función |
|:--|:---:|:---:|:--|
| WordPress | `8080 → 80` | Expuesto | Aplicación web |
| MariaDB Primary | `3306` |  No publicado | Base de datos |
| MariaDB Replica | `3306` |  No publicado | Réplica de base de datos |

Por tanto:

```text
Exterior
   │
   ▼
:8080
   │
   ▼
WordPress
   │
   ▼
rotborn_private
   │
   ├── MariaDB Primary :3306
   │
   └── MariaDB Replica :3306
```

---

## 8. Comprobación de la replicación

Después de modificar la arquitectura de red, se comprobó que la replicación de MariaDB continuaba funcionando.

Se accedió a la réplica:

```bash
docker exec -it rotborn-mariadb-replica-1 mariadb -uroot -p
```

Dentro de MariaDB:

```sql
SHOW SLAVE STATUS\G
```

### Resultado obtenido

```text
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Slave_IO_State: Waiting for master to send event
Master_Host: mariadb
Master_Port: 3306
```

Esto confirma que la réplica puede comunicarse con MariaDB Primary mediante la red privada utilizando:

```text
Host: mariadb
Puerto: 3306
```

---

## 9. Resultado final

La segmentación implementada quedó de la siguiente manera:

```text
                    RED EXTERNA
                         │
                       :8080
                         │
                         ▼
                ┌────────────────┐
                │    WordPress   │
                └───────┬────────┘
                        │
              ┌─────────┴─────────┐
              │ rotborn_private   │
              │                   │
              ▼                   ▼
       ┌─────────────┐     ┌─────────────┐
       │   MariaDB   │────▶│   MariaDB   │
       │   Primary   │     │   Replica   │
       └─────────────┘     └─────────────┘
```

### Comprobaciones realizadas

- `rotborn_public` creada correctamente.
- `rotborn_private` creada correctamente.
-  WordPress conectado a ambas redes.
-  MariaDB Primary conectada únicamente a la red privada.
-  MariaDB Replica conectada únicamente a la red privada.
-  WordPress publicado en el puerto `8080`.
-  MariaDB no publicado hacia el exterior.
-  MariaDB Replica no publicada hacia el exterior.
-  Replicación MariaDB funcionando después del cambio de red.

---

## 10. Comandos utilizados

### Configuración

```bash
cp docker-compose.yml docker-compose.yml.backup
docker compose config
```

### Despliegue

```bash
docker compose up -d
docker compose ps
```

### Comprobación de redes

```bash
docker network ls
docker network inspect rotborn_public
docker network inspect rotborn_private
```

### Comprobación de replicación

```bash
docker exec -it rotborn-mariadb-replica-1 mariadb -uroot -p
```

```sql
SHOW SLAVE STATUS\G
```

---

> **Conclusión:** la infraestructura Docker quedó segmentada en una red pública para WordPress y una red privada para la comunicación interna con las bases de datos, manteniendo MariaDB Primary y MariaDB Replica fuera de la exposición directa.
