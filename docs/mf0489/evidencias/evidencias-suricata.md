# Evidencias de Suricata – MF0489

## 1. Objetivo

Documentar la configuración, validación y funcionamiento de las reglas locales de Suricata utilizadas en el proyecto Rotborn Studios.

Se comprueba que las reglas publicadas en el repositorio coinciden con las configuradas en el servidor y que Suricata es capaz de detectar tráfico ICMP y conexiones HTTPS.

## 2. Reglas locales configuradas

**Archivo:** `/etc/suricata/rules/local.rules`

Contenido de las reglas activas en el servidor:

```text
alert icmp any any -> $HOME_NET any (msg:"MF0488 - ICMP detectado"; sid:1000001; rev:1;)
alert tcp any any -> $HOME_NET 443 (msg:"MF0489 Fase 4 - Conexion HTTPS observada"; flow:to_server; flags:S; sid:1000002; rev:2;)
```

### Descripción de las reglas

| SID | Descripción | Revisión |
|---|---|---|
| 1000001 | Detección de tráfico ICMP dirigido a HOME_NET | 1 |
| 1000002 | Detección de conexiones HTTPS TCP dirigidas al puerto 443 | 2 |

La regla HTTPS comprueba los paquetes TCP SYN dirigidos al puerto 443 y utiliza `flow:to_server` para identificar el sentido de la conexión.

## 3. Sincronización con GitHub

Se compararon las reglas locales del servidor con el archivo `suricata/local.rules` del repositorio GitHub.

Durante la revisión se detectó una diferencia en la segunda regla: GitHub contenía `rev:1`, mientras que el servidor utilizaba `rev:2`.

Se actualizó el archivo del repositorio para incorporar la revisión 2 y añadir la condición `flow:to_server`.

Después de la corrección, ambas versiones quedaron sincronizadas.

## 4. Validación de la configuración

**Comando ejecutado:**

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

**Resultado obtenido:**

```text
9/11/2026 -- 19:53:36 - <Info> - Running suricata under test mode
9/11/2026 -- 19:53:36 - <Notice> - This is Suricata version 6.0.4 RELEASE running in SYSTEM mode
9/11/2026 -- 19:53:37 - <Notice> - Configuration provided was successfully loaded. Exiting.
```

**Conclusión:** Suricata validó correctamente la configuración y cargó las reglas sin errores.

## 5. Estado del servicio Suricata

**Comando ejecutado:**

```bash
sudo systemctl status suricata --no-pager
```

**Resultado relevante:**

```text
Active: active (running) since Mon 2026-11-09 19:26:56 CET
Main PID: 860 (Suricata-Main)
```

**Conclusión:** El servicio Suricata se encuentra activo y en ejecución.

## 6. Prueba de conectividad desde Kali Linux

Se utilizó Kali Linux como máquina cliente para generar tráfico HTTPS hacia el servidor Ubuntu.

**Servidor Ubuntu:** `10.21.4.81`

### 6.1. Comprobación de conectividad

Desde Kali se ejecutó:

```bash
ping -c 4 10.21.4.81
```

Resultado:

```text
4 packets transmitted, 4 received, 0% packet loss
```

La comunicación entre Kali y Ubuntu se realizó correctamente.

### 6.2. Comprobación del puerto HTTPS

```bash
nc -zv 10.21.4.81 443
```

Resultado:

```text
(UNKNOWN) [10.21.4.81] 443 (https) open
```

El puerto 443 se encontraba abierto y aceptaba conexiones.

### 6.3. Prueba HTTPS contra WordPress

Se utilizó el parámetro `--resolve` para asociar temporalmente el dominio del laboratorio con la IP del servidor:

```bash
curl -k -I --resolve portal.rotborn.test:443:10.21.4.81 https://portal.rotborn.test
```

Resultado:

```text
HTTP/1.1 200 OK
Server: nginx/1.30.6
Content-Type: text/html; charset=UTF-8
X-Powered-By: PHP/8.3.33
```

**Conclusión:** La petición HTTPS llegó correctamente a Nginx y WordPress respondió con código HTTP 200 OK.

## 7. Detección de conexiones HTTPS por Suricata

Se consultó el registro de alertas:

```bash
sudo tail -n 10 /var/log/suricata/fast.log
```

Se identificaron dos alertas HTTPS recientes:

```text
11/09/2026-20:30:38.616570
[**] [1:1000002:2] MF0489 Fase 4 - Conexion HTTPS observada [**]
{TCP} 10.21.4.43:53054 -> 10.21.4.81:443

11/09/2026-20:31:37.680074
[**] [1:1000002:2] MF0489 Fase 4 - Conexion HTTPS observada [**]
{TCP} 10.21.4.43:53057 -> 10.21.4.81:443
```

### Interpretación

- IP de origen: `10.21.4.43` (Kali Linux).
- IP de destino: `10.21.4.81` (Ubuntu / Rotborn Server).
- Puerto de destino: `443` (HTTPS).
- Protocolo: TCP.
- SID: `1000002`.
- Revisión: `2`.

Las alertas están fechadas el 9 de noviembre de 2026 y son posteriores al inicio del servicio Suricata registrado ese mismo día.

**Conclusión:** Suricata detectó conexiones HTTPS dirigidas al servidor Rotborn utilizando la regla `MF0489`, SID `1000002`, revisión `2`.

## 8. Conclusión general

Las pruebas realizadas permiten confirmar:

1. La sincronización de las reglas locales entre GitHub y el servidor Ubuntu.
2. La validación correcta de la configuración mediante `suricata -T`.
3. El funcionamiento del servicio Suricata.
4. La conectividad entre Kali Linux y el servidor Rotborn.
5. La detección de conexiones HTTPS mediante la regla local `sid:1000002`, `rev:2`.

Por tanto, se ha comprobado el funcionamiento de la regla de detección HTTPS mediante tráfico generado desde una máquina cliente independiente.

## 9. Evidencias gráficas

- [reglas-locales.png](capturas/suricata/suricata-reglas-locales.png)
- [validacion-suricata.png](capturas/suricata/suricata-validacion.png)
- [estado-servicio.png](capturas/suricata/suricata-estado-servicio.png)
- [prueba-https.png](capturas/suricata/suricata-prueba-https.png)
- [alertas-https.png](capturas/suricata/suricata-alertas-https.png)


