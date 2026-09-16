Fase 4 — Implantación de Suricata

## Instalación

Suricata se instaló directamente sobre la máquina virtual Ubuntu Server de Rotborn Studios.

Comando utilizado:
```bash
sudo apt install suricata
```

La instalación finalizó correctamente. La versión instalada fue:
> **Suricata 6.0.4**

El paquete también creó y habilitó el servicio `suricata.service`.

---

## Identificación de la interfaz de red

Antes de configurar Suricata se identificaron las interfaces disponibles mediante:
```bash
ip -br address
```

La interfaz utilizada para la red principal de la máquina virtual es:
```text
enp0s3    UP    10.21.4.36/24
```

Por tanto, la interfaz seleccionada para la captura de tráfico de Suricata es:
> **`enp0s3`**

Las interfaces `br-*`, `docker0` y `veth*` corresponden a redes e interfaces virtuales utilizadas por Docker y no se utilizan como interfaz principal de captura en esta fase.

---

## 10.3 Configuración de la interfaz en Suricata

La configuración de captura `af-packet` de Suricata estaba utilizando inicialmente una interfaz denominada `eth0`, que no existe en esta máquina virtual. El registro del servicio mostró:
```text
Failure when trying to get MTU via ioctl for 'eth0': No such device
```

Se modificó la configuración `/etc/suricata/suricata.yaml` para utilizar la interfaz real:
```yaml
af-packet:
  - interface: enp0s3
```

---

## Configuración de HOME_NET

La red protegida se definió a partir de la dirección de la interfaz `enp0s3`:
> `10.21.4.36/24`

Por tanto, se estableció:
```yaml
HOME_NET: "[10.21.4.0/24]"
```

La elección se justifica porque `10.21.4.0/24` corresponde al segmento de red en el que se encuentra la máquina virtual Rotborn.

La variable `EXTERNAL_NET` se mantiene como:
```yaml
EXTERNAL_NET: "!$HOME_NET"
```

De esta forma representa las redes que no pertenecen a la red protegida.

---

## Regla propia

Se creó el archivo:
`/etc/suricata/rules/local.rules`

con la siguiente regla:
```suricata
alert icmp any any -> $HOME_NET any (msg:"MF0488 - ICMP detectado"; sid:1000001; rev:1;)
```

La regla permite detectar tráfico ICMP dirigido hacia la red protegida.

### Parámetros de la regla

| Parámetro | Función |
| :--- | :--- |
| `alert` | Genera una alerta cuando el tráfico coincide con la regla |
| `icmp` | Protocolo que se desea detectar |
| `any` | Cualquier dirección IP de origen |
| `any` | Cualquier puerto de origen |
| `->` | Dirección del tráfico hacia el destino |
| `$HOME_NET` | Red protegida |
| `any` | Cualquier puerto de destino |
| `msg` | Mensaje asociado a la alerta |
| `sid` | Identificador único de la regla |
| `rev` | Número de revisión de la regla |

---

## Carga de la regla

En `/etc/suricata/suricata.yaml` se configuró:
```yaml
rule-files:
  - local.rules
```

De esta manera Suricata carga nuestra regla personalizada desde:
`/etc/suricata/rules/local.rules`

---

## Validación de la configuración

Antes de iniciar el servicio se realizó una comprobación de la configuración:
```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

La validación finalizó correctamente con:
> `Configuration provided was successfully loaded. Exiting.`

---

## Activación del servicio

Finalmente se reinició Suricata:
```bash
sudo systemctl restart suricata
```

Y se comprobó su estado:
```bash
sudo systemctl status suricata --no-pager
```

El servicio quedó en estado:
> `Active: active (running)`

---

## Ficheros de registro

Se comprobó el directorio de registros:
```bash
sudo ls -lh /var/log/suricata/
```

Se identificaron, entre otros, los siguientes archivos:
- `/var/log/suricata/fast.log`
- `/var/log/suricata/eve.json`
- `/var/log/suricata/stats.log`
- `/var/log/suricata/suricata.log`

En este momento `fast.log` se encuentra vacío porque todavía no se ha generado el tráfico de prueba correspondiente a nuestra regla ICMP. La prueba de detección y la comprobación de las alertas se realizarán en el siguiente apartado.

---

## Prueba real de detección

Para comprobar el funcionamiento real de Suricata se realizó una prueba desde una segunda máquina de la red.

La prueba se realizó desde Windows, con IP de origen `10.21.4.40`, hacia la máquina Ubuntu Rotborn, con IP `10.21.4.36`.

Se generó tráfico ICMP mediante:
```powershell
ping 10.21.4.36
```

Suricata detectó correctamente el tráfico mediante la regla personalizada SID `1000001`.

### Evidencia en `fast.log`
La alerta quedó registrada en:
`/var/log/suricata/fast.log`

Ejemplo de evento registrado:
```text
09/16/2026-22:49:35.263418  [**] [1:1000001:1] MF0488 - ICMP detectado [**] [Classification: (null)] [Priority: 3] {ICMP} 10.21.4.40:8 -> 10.21.4.36:0
```

La evidencia permite identificar los siguientes parámetros:

| Campo | Valor |
| :--- | :--- |
| **IP origen** | `10.21.4.40` |
| **IP destino** | `10.21.4.36` |
| **Protocolo** | `ICMP` |
| **SID** | `1000001` |
| **Revisión** | `1` |
| **Mensaje** | `MF0488 - ICMP detectado` |
| **Interfaz** | `enp0s3` |

También se registró la respuesta ICMP desde el servidor hacia Windows.

---

### Evidencia en `eve.json`
El mismo evento fue registrado en formato JSON en:
`/var/log/suricata/eve.json`

La información registrada incluye:
```json
{
  "timestamp": "2026-09-16T22:49:35.263418+0200",
  "in_iface": "enp0s3",
  "event_type": "alert",
  "src_ip": "10.21.4.40",
  "dest_ip": "10.21.4.36",
  "proto": "ICMP",
  "alert": {
    "action": "allowed",
    "signature_id": 1000001,
    "rev": 1,
    "signature": "MF0488 - ICMP detectado",
    "severity": 3
  }
}
```

* El campo `event_type` confirma que Suricata registró un evento de tipo `alert`.
* El campo `in_iface` confirma que el tráfico fue capturado mediante la interfaz `enp0s3`.
* El campo `signature_id` identifica nuestra regla personalizada y `signature` muestra el mensaje definido en `local.rules`.
* El valor `action: allowed` es coherente con la función de la regla utilizada en esta fase: `alert`. La regla detecta y registra el tráfico, pero no lo bloquea.

---

## Resultado de la prueba

La prueba demuestra que:
1. Una máquina externa al servidor puede generar tráfico hacia Rotborn.
2. El tráfico ICMP llega a la interfaz `enp0s3`.
3. Suricata inspecciona el tráfico.
4. La regla personalizada `1000001` coincide con el tráfico.
5. Se genera una alerta.
6. La alerta queda registrada en `fast.log`.
7. El evento también queda registrado en `eve.json`.

Por tanto, la implantación de Suricata y la regla de detección propia han sido verificadas mediante tráfico real.

---

## Resumen de la Fase 4

- ✅ Suricata instalado
- ✅ Servicio activo
- ✅ Interfaz correcta: `enp0s3`
- ✅ `HOME_NET` definido: `10.21.4.0/24`
- ✅ Configuración validada
- ✅ `local.rules` configurado
- ✅ Regla propia creada
- ✅ Tráfico de prueba generado desde Windows
- ✅ Alerta real detectada
- ✅ `fast.log` comprobado
- ✅ `eve.json` comprobado

> **Una cosa importante:** no necesitamos documentar todos los mensajes internos de instalación ni cada comando que ejecutamos durante el diagnóstico. Este bloque deja registrado **lo que Ironhack evalúa y la evidencia que demuestra que funciona**.

Después de pegarlo y guardarlo, podemos pasar a **Fase 5 — pruebas de detección y línea base**.
