# Fase 3 — Preparación de registros

## Objetivo

Antes de la implantación del IDS se identifican las principales fuentes de información disponibles en el servidor. El objetivo es poder responder a la siguiente pregunta:

> *Si alguien realiza una acción contra el servidor, ¿dónde podemos encontrar evidencia?*

Las principales fuentes de evidencia identificadas son:
- **Sistema operativo Ubuntu Server.**
- **Servicio SSH.**
- **Aplicación web WordPress/Apache.**
- **Contenedores Docker.**
- **Base de datos MariaDB.**

---

## 9.2 Configuración de fecha y hora

La configuración horaria del servidor se comprobó mediante:
```bash
date
```
y:
```bash
timedatectl
```

* Inicialmente el servidor utilizaba la zona horaria `Etc/UTC`.
* Para utilizar la hora local de España se configuró:
  ```bash
  sudo timedatectl set-timezone Europe/Madrid
  ```

### Configuración final
- **Zona horaria:** Europa/Madrid (`CEST`, `+0200`)
- **Reloj del sistema sincronizado:** Sí
- **Servicio NTP:** Activo

La hora del sistema se encuentra sincronizada mediante NTP.

### Configuración horaria de WordPress
El contenedor WordPress también se configuró para utilizar la zona horaria `Europe/Madrid` mediante la variable:
```yaml
TZ: Europe/Madrid
```

La configuración se verificó con:
```bash
docker exec rotborn-wordpress-1 date
```

**Resultado:**
> Miércoles 16 de septiembre de 2026, 19:39:24 CEST

De esta forma, los registros de Ubuntu y Apache/WordPress utilizan la misma referencia horaria local.

---

## 9.3 Evidencias de SSH

Los registros de autenticación SSH se encuentran en:
`/var/log/auth.log`

### Inicio de sesión SSH correcto
Se generó un acceso SSH válido y posteriormente se buscó en los registros:
```bash
sudo grep "Accepted" /var/log/auth.log | tail
```

Se obtuvo, entre otras, la siguiente entrada:
```text
16 sep 19:02:19 rotborn-server sshd[1372]: Contraseña aceptada para zadmin desde 10.21.4.40 puerto 49934 ssh2
```

### Inicio de sesión SSH incorrecto
Se generó un intento de acceso utilizando el usuario ficticio `usuario_falso`. La evidencia se obtuvo mediante:
```bash
sudo grep -E "Contraseña fallida|Usuario inválido" /var/log/auth.log | tail -5
```

**Resultado:**
```text
16 de septiembre 19:08:17 rotborn-server sshd[1454]: Usuario inválido usuario_falso desde 10.21.4.40 puerto 50573
16 de septiembre 19:08:25 rotborn-server sshd[1454]: Contraseña incorrecta para el usuario inválido usuario_falso desde 10.21.4.40
```

---

## Evidencias HTTP

Los registros de acceso de Apache se consultan mediante los logs del contenedor WordPress:
```bash
docker logs rotborn-wordpress-1
```

### Petición HTTP correcta
Se realizó una petición a la página principal:
`http://10.21.4.36:8080/`

La evidencia obtenida fue:
```text
10.21.4.40 - - [16/Sep/2026:19:41:07 +0200] "GET / HTTP/1.1" 200 12534
```

### Petición HTTP incorrecta
Se realizó una petición a una URL inexistente:
`http://10.21.4.36:8080/esto-no-existe`

La evidencia obtenida fue:
```text
10.21.4.40 - - [16/Sep/2026:19:42:33 +0200] "GET /esto-no-existe HTTP/1.1" 404 59042
```

---

## Registros de Docker

Se comprobó que Docker registra la actividad de los contenedores mediante:
```bash
docker logs rotborn-wordpress-1 --tail 10
```

Los registros mostraron eventos de Apache y solicitudes HTTP, incluyendo códigos `200`, `302` y `404`.

También se comprobó el estado de los servicios mediante:
```bash
docker compose ps
```

**Resultado:**
- `rotborn-mariadb-1` — Arriba
- `rotborn-mariadb-replica-1` — Arriba
- `rotborn-wordpress-1` — Arriba

Por tanto, Docker proporciona una fuente adicional de evidencia sobre la actividad de los servicios.
