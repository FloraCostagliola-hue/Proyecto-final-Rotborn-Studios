# Rotborn Studios — Session Script 

Guion cronológico de los comandos utilizados durante la construcción y las pruebas de Rotborn Studios.

> Las contraseñas y secretos reales se han omitido. Cuando el comando literal completo no quedó conservado, se indica expresamente.

---

# SESIÓN 01 — Ubuntu inicial

## Sistema
```bash
lsb_release -a
uname -a
free -h
df -H
whoami
id
sudo whoami
```

## Red y conectividad
```bash
ip -br address
ip route
ping -c 4 8.8.8.8
```

---

# SESIÓN 02 — SSH

```bash
sudo systemctl status ssh --no-pager
ss -tuln
```

Desde otro equipo:
```bash
ssh zadmin@IP_DEL_SERVIDOR
```

> La IP fue dinámica durante el proyecto: se utilizaron `10.21.4.82`, `10.21.4.36` y posteriormente `10.54.254.214`.

---

# SESIÓN 03 — Docker

```bash
sudo apt update
sudo apt install docker.io
docker --version
sudo systemctl status docker --no-pager
sudo systemctl enable docker
sudo usermod -aG docker zadmin
```

Después de cerrar sesión y volver a entrar:
```bash
docker ps
```

---

# SESIÓN 04 — Docker Compose

```bash
sudo apt install docker-compose-v2
docker compose version
```

---

# SESIÓN 05 — Preparación de Rotborn

```bash
sudo mkdir -p /srv/rotborn
sudo mkdir -p /srv/rotborn/db
sudo mkdir -p /srv/rotborn/db-replica
sudo mkdir -p /srv/rotborn/config/mariadb
sudo mkdir -p /srv/rotborn/config/mariadb-replica
cd /srv/rotborn
ls -la
```

---

# SESIÓN 06 — Docker Compose

```bash
docker compose config
docker compose ps -a
docker compose up -d
docker compose ps
```

---

# SESIÓN 07 — WordPress

```bash
docker logs rotborn-wordpress-1
docker logs rotborn-wordpress-1 --tail 20
docker compose logs --tail 50
```

Acceso:
```text
http://IP_DEL_SERVIDOR:8080
```

---

# SESIÓN 08 — MariaDB Primary

```bash
docker exec -it rotborn-mariadb-1 mariadb -u root -p
```

En MariaDB:
```sql
SHOW DATABASES;
USE rotborn;
SHOW TABLES;
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'rotborn';
```

---

# SESIÓN 09 — Replicación MariaDB: Primary

```bash
docker exec -it rotborn-mariadb-1 mariadb -u root -p
```

En MariaDB:
```sql
CREATE USER 'replicator'@'%' IDENTIFIED BY 'CONTRASEÑA_DE_REPLICACIÓN';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
```

> La contraseña real y los valores reales del binlog se han omitido.

---

# SESIÓN 10 — Replicación MariaDB: Replica

```bash
docker exec -it rotborn-mariadb-replica-1 mariadb -u root -p
```

En MariaDB:
```sql
CREATE DATABASE rotborn;
```

Configuración de replicación:
```sql
CHANGE MASTER TO
  MASTER_HOST='mariadb',
  MASTER_USER='replicator',
  MASTER_PASSWORD='CONTRASEÑA_DE_REPLICACIÓN',
  MASTER_LOG_FILE='FICHERO_BINLOG',
  MASTER_LOG_POS=POSICION;

START SLAVE;
SHOW SLAVE STATUS\G
```

Valores esperados:
```text
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
```

---

# SESIÓN 11 — Prueba de replicación

En Primary:
```sql
CREATE TABLE prueba_replicacion (
    id INT PRIMARY KEY,
    dato VARCHAR(100)
);

INSERT INTO prueba_replicacion VALUES (1, 'prueba');
```

En Replica:
```sql
USE rotborn;
SELECT * FROM prueba_replicacion;
```

Limpieza en Primary:
```sql
DROP TABLE prueba_replicacion;
```

Comprobación:
```sql
SHOW TABLES;
```

---

# SESIÓN 12 — Redes Docker

```bash
docker network ls
docker network inspect rotborn_public
docker network inspect rotborn_private
```

Arquitectura real:
```text
rotborn_public
└── WordPress

rotborn_private
├── WordPress
├── MariaDB Primary
└── MariaDB Replica
```

---

# SESIÓN 13 — Persistencia

```bash
docker compose ps
docker compose down
docker compose up -d
docker compose ps
```

Comprobación:
```bash
docker exec -it rotborn-mariadb-1 mariadb -u root -p
```

```sql
USE rotborn;
SHOW TABLES;
```

> Esta prueba confirmó persistencia después de detener y volver a iniciar los servicios.

---

# SESIÓN 14 — Zona horaria

```bash
date
timedatectl
sudo timedatectl set-timezone Europe/Madrid
timedatectl
docker exec rotborn-wordpress-1 date
```

En `docker-compose.yml` se añadió:
```yaml
TZ: Europe/Madrid
```

---

# SESIÓN 15 — Logs SSH

```bash
sudo grep "Accepted" /var/log/auth.log | tail
sudo grep -E "Failed password|Invalid user" /var/log/auth.log | tail -5
```

---

# SESIÓN 16 — Logs WordPress / Apache

```bash
docker logs rotborn-wordpress-1
docker logs rotborn-wordpress-1 --tail 20
docker logs rotborn-wordpress-1 --since "2026-09-17T01:15:00"
```

Pruebas reales:
```text
GET /               → 200
GET /esto-no-existe → 404
```

---

# SESIÓN 17 — Suricata: instalación

```bash
sudo apt install suricata
ip -br address
sudo systemctl status suricata --no-pager
```

---

# SESIÓN 18 — Suricata: configuración

```bash
sudo nano /etc/suricata/suricata.yaml
```

Configuración realizada:
```yaml
af-packet:
  - interface: enp0s3

HOME_NET: "[10.21.4.0/24,10.54.254.0/24]"

rule-files:
  - local.rules
```

---

# SESIÓN 19 — Suricata: regla propia

```bash
sudo nano /etc/suricata/rules/local.rules
```

Regla:
```text
alert icmp any any -> $HOME_NET any (msg:"MF0488 - ICMP detectado"; sid:1000001; rev:1;)
```

---

# SESIÓN 20 — Validación y servicio Suricata

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
sudo systemctl restart suricata
sudo systemctl status suricata --no-pager
```

---

# SESIÓN 21 — Logs Suricata

```bash
sudo ls -lh /var/log/suricata/
sudo tail -n 20 /var/log/suricata/fast.log
sudo tail -n 20 /var/log/suricata/eve.json
sudo grep '10.54.254.20' /var/log/suricata/eve.json | tail -n 10
```

---

# SESIÓN 22 — Prueba ICMP

Desde otro equipo:
```text
ping IP_DEL_SERVIDOR
```

En el servidor:
```bash
sudo tail -n 20 /var/log/suricata/fast.log
```

Comprobar alertas en `eve.json`:
```bash
sudo grep '"event_type":"alert"' /var/log/suricata/eve.json | tail
```

Regla detectada:
```text
[1:1000001:1] MF0488 - ICMP detectado
```

---

# SESIÓN 23 — Fase 5: Nmap

Desde Kali:
```bash
nmap 10.54.254.214
nmap -p 22,8080 10.54.254.214
```

Resultado real de la prueba específica:
```text
22/tcp    open    ssh
8080/tcp  open    http-proxy
```

---

# SESIÓN 24 — Nmap y Suricata

```bash
sudo tail -n 20 /var/log/suricata/fast.log
sudo tail -n 20 /var/log/suricata/eve.json
```

Se observó tráfico TCP en `eve.json`, incluyendo tráfico hacia el puerto 22, con `alerted:false`.

> No se esperaba una alerta de Nmap porque nuestra regla personalizada es ICMP.

---

# SESIÓN 25 — Comprobaciones finales

```bash
docker compose ps
docker network ls
ip -br address
sudo systemctl status ssh --no-pager
sudo systemctl status suricata --no-pager
docker logs rotborn-wordpress-1 --tail 20
sudo tail -n 20 /var/log/suricata/fast.log
sudo tail -n 20 /var/log/suricata/eve.json
```

---

# SESIÓN 26 — Recuperación rápida Docker

```bash
cd /srv/rotborn
docker compose up -d
docker compose ps
```

Reinicio:
```bash
docker compose restart
```

Reconstrucción de contenedores:
```bash
docker compose down
docker compose up -d
```

**NO usar si queremos conservar datos:**
```bash
docker compose down -v
```

---

# SESIÓN 27 — Diagnóstico rápido

```bash
docker ps -a
docker ps
docker compose logs --tail 50
docker network ls
ip -br address
ip route
ss -tuln
ping -c 4 8.8.8.8
```

---

# RESUMEN DE RECUPERACIÓN

Punto de partida Docker:
```text
/srv/rotborn/docker-compose.yml
```

Comandos principales:
```bash
cd /srv/rotborn
docker compose config
docker compose up -d
docker compose ps
```

Después comprobar:
```bash
docker network ls
ip -br address
```

Y verificar:
```text
WordPress
MariaDB Primary
MariaDB Replica
Replicación
Persistencia
```

## Notas

- Ubuntu utilizado: 22.04.5 LTS.
- Docker Compose es el punto de partida de la infraestructura Docker.
- `.env` contiene credenciales y no se publica.
- `/srv/rotborn/db` y `/srv/rotborn/db-replica` contienen datos persistentes.
- No usar `docker compose down -v` si queremos conservar los datos.
- Suricata se ejecuta directamente sobre Ubuntu.
- La interfaz de captura de Suricata es `enp0s3`.
- La regla personalizada es ICMP.
- Nmap se realizó de forma controlada contra la VM propia.
