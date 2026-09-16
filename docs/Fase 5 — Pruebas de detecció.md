#  Fase 5 — Pruebas de detección y línea base

##  Objetivo

En esta fase se comprueba el funcionamiento conjunto de la infraestructura, los servicios desplegados y el sistema de monitorización mediante pruebas controladas desde otra máquina del laboratorio.

El objetivo es observar qué información queda registrada en las diferentes fuentes de logs y comprobar la diferencia entre una actividad registrada, una alerta de seguridad y un posible incidente.

Las pruebas se realizaron sobre la máquina Rotborn Studios utilizando la red del laboratorio mediante hotspot móvil.

### IP del servidor durante las pruebas
- **Servidor Rotborn:** `10.54.254.214/24`
- **Interfaz monitorizada por Suricata:** `enp0s3`
- **Equipo Kali utilizado para las pruebas:** `10.54.254.20`

---

## 1Prueba d Nmap

Desde Kali se realizó un escaneo controlado contra la máquina Rotborn:
```bash
nmap -p 22,8080 10.54.254.214
```

**Resultado obtenido:**
```text
PORT     STATE  SERVICE
22/tcp   open   ssh
8080/tcp open   http-proxy
```

El resultado confirma que los servicios expuestos externamente durante la prueba fueron:
* **`22/TCP`:** SSH
* **`8080/TCP`:** Aplicación web WordPress

Los servicios de base de datos no aparecen expuestos directamente en la red, ya que los contenedores MariaDB utilizan la red privada de Docker.

---

## Infrmación registrada por Suricata

El escaneo Nmap generó tráfico TCP que fue observado por Suricata. En `/var/log/suricata/eve.json` se registró un flujo TCP con:
```json
{
  "in_iface": "enp0s3",
  "src_ip": "10.54.254.20",
  "dest_ip": "10.54.254.214",
  "dest_port": 22,
  "proto": "TCP",
  "alerted": false
}
```

Este resultado es importante porque demuestra que Suricata está capturando y registrando tráfico de red aunque dicho tráfico no genere necesariamente una alerta. 

La ausencia de una alerta es esperada en este caso porque la regla personalizada implementada en `local.rules` está diseñada para detectar tráfico ICMP:
```suricata
alert icmp any any -> $HOME_NET any
```

Por tanto, el Nmap realizado genera un evento de red registrado, pero no una alerta de la regla personalizada de ICMP.

---

## 11.4 Comprobación de los registros SSH

Durante las pruebas anteriores se realizó tanto un acceso SSH correcto como un intento incorrecto.

### Acceso correcto
En `/var/log/auth.log` se registró:
```text
Accepted password for zadmin from 10.54.254.170
```
Este registro permite identificar:
- Usuario utilizado.
- Dirección IP de origen.
- Servicio utilizado.
- Resultado de la autenticación.

### Acceso incorrecto
También se registró un intento de autenticación incorrecto:
```text
Invalid user usuario_falso from 10.21.4.40
```
Este tipo de registro permite identificar intentos de acceso no válidos contra el servicio SSH.

---

## 11.5 Comprobación de los registros web

Se realizaron dos solicitudes HTTP para comprobar el comportamiento normal y el comportamiento ante un recurso inexistente.

### Solicitud web válida
Al acceder a la página principal se registró:
```text
"GET / HTTP/1.1" 200
```
El código HTTP `200` indica que la solicitud fue atendida correctamente.

### Solicitud a un recurso inexistente
Se realizó una solicitud contra `/esto-no-existe`. Apache registró:
```text
"GET /esto-no-existe HTTP/1.1" 404
```
El código `404` indica que el recurso solicitado no existe.

Estas pruebas permiten establecer una referencia de comportamiento normal de la aplicación web.

---

## 11.6 Comprobación de Docker

Durante la prueba de Nmap los servicios Docker estaban activos. El estado de los contenedores era:
- `rotborn-mariadb-1`
- `rotborn-mariadb-replica-1`
- `rotborn-wordpress-1`

Los tres contenedores se encontraban en estado:
> **`Up`**

La comprobación se realizó mediante:
```bash
docker compose ps
```

Además, los registros de WordPress permitieron comprobar las solicitudes HTTP recibidas por Apache. Docker se considera en esta línea base principalmente como fuente de información sobre el estado operativo de los servicios y de los registros generados por los contenedores.

---

## Prueba ICMP

Se realizó una prueba de conectividad mediante `ping` desde otro equipo hacia el servidor. La regla personalizada de Suricata:
```suricata
alert icmp any any -> $HOME_NET any (msg:"MF0488 - ICMP detectado"; sid:1000001; rev:1;)
```

generó una alerta real en `/var/log/suricata/fast.log`:
```text
[1:1000001:1] MF0488 - ICMP detectado
{ICMP} 10.21.4.40:8 -> 10.21.4.36:0
```

También se obtuvo el evento correspondiente en `/var/log/suricata/eve.json`. La alerta demuestra que Suricata está activo, inspecciona el tráfico de la interfaz `enp0s3` y carga correctamente la regla personalizada.

---

## Línea base de actividad

A partir de las pruebas realizadas se establece la siguiente línea base:

| Acción | Fuente | Detectada / Registrada | Información obtenida |
| :--- | :--- | :--- | :--- |
| **SSH correcto** | `/var/log/auth.log` | Sí | Usuario, IP de origen y autenticación aceptada |
| **SSH incorrecto** | `/var/log/auth.log` | Sí | IP de origen e intento de usuario no válido |
| **Web válida** | Logs de Apache / Docker | Sí | Solicitud HTTP y código `200` |
| **Web 404** | Logs de Apache / Docker | Sí | Solicitud HTTP y código `404` |
| **Docker** | `docker compose ps` / logs | Sí | Estado de los servicios y actividad de WordPress |
| **Ping** | Suricata `fast.log` / `eve.json` | Sí, con alerta | Tráfico ICMP, IP origen/destino y SID de la regla |
| **Nmap** | Suricata `eve.json` + salida Nmap | Sí, como evento de red | Tráfico TCP y puertos accesibles |

---

## Diferencia entre evento, alerta e incidente

Durante las pruebas se ha podido diferenciar entre tres conceptos:

### Evento
Un evento es una actividad que queda registrada por un sistema. Por ejemplo:
- Una conexión SSH correcta.
- Una solicitud HTTP.
- Un flujo TCP observado por Suricata.
- Una consulta realizada mediante Nmap.

Un evento no implica necesariamente que exista una amenaza.

### Alerta
Una alerta se genera cuando una regla o mecanismo de detección identifica una actividad que cumple determinados criterios. En este proyecto, el tráfico ICMP generó una alerta de Suricata mediante la regla `sid:1000001`. Sin embargo, el tráfico TCP generado por Nmap fue registrado en `eve.json` sin generar una alerta de la regla personalizada, ya que dicha regla está diseñada específicamente para ICMP.

### Incidente
Un incidente requiere una valoración adicional para determinar si una actividad representa un problema de seguridad que necesita respuesta.

> **Evento $
eq$ Alerta $
eq$ Incidente**

Una actividad puede quedar registrada como evento sin generar una alerta, y una alerta debe analizarse antes de determinar si constituye un incidente de seguridad.

---

##  Conclusiones de la Fase 5

Las pruebas realizadas permiten comprobar el funcionamiento conjunto de la infraestructura y los mecanismos de monitorización. Se ha verificado que:

- ✅ Nmap puede identificar los servicios expuestos.
- ✅ SSH registra accesos correctos e intentos incorrectos.
- ✅ Apache registra solicitudes HTTP válidas y errores `404`.
- ✅ Docker permite consultar el estado y los registros de los servicios.
- ✅ Suricata captura tráfico de red mediante la interfaz `enp0s3`.
- ✅ El tráfico ICMP genera una alerta mediante la regla personalizada.
- ✅ El tráfico TCP de Nmap puede aparecer como evento en `eve.json` sin generar una alerta.
- ✅ Las diferentes fuentes de información pueden compararse para obtener una visión conjunta de la actividad de la máquina.

La línea base obtenida en esta fase servirá como referencia para las fases posteriores de protección, análisis de actividad sospechosa y análisis del incidente.
