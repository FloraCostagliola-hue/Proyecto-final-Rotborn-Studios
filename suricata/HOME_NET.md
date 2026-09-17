`HOME_NET` es la variable de Suricata que identifica las redes consideradas como entorno protegido. Para este proyecto, se han definido las siguientes subredes:

```yaml
HOME_NET: "[10.21.4.0/24,10.54.254.0/24]"
```

* **`10.21.4.0/24`**: Red utilizada inicialmente durante la fase de configuración y primeras pruebas de laboratorio.
* **`10.54.254.0/24`**: Red incorporada posteriormente para el tráfico gestionado mediante el *hotspot* del laboratorio.

**Interfaz monitorizada:** `enp0s3`

---

## Regla Personalizada

Se ha creado una regla personalizada para detectar tráfico ICMP dirigido hacia los rangos definidos en `$HOME_NET`.

```suricata
alert icmp any any -> $HOME_NET any (msg:"MF0488 - ICMP detectado"; sid:1000001; rev:1;)
```

### Componentes de la regla:
* **`alert`**: Genera una alerta al registrar tráfico coincidente.
* **`icmp`**: Protocolo de red analizado.
* **`any any`**: Permite cualquier dirección y puerto de origen.
* **`->`**: Dirección del tráfico (origen a destino).
* **`$HOME_NET`**: Destino restringido a las redes protegidas de Suricata.
* **`any`**: Cualquier puerto de destino.
* **`msg`**: Mensaje descriptivo incrustado en la alerta.
* **`sid`**: Identificador único de la regla (`1000001`).
* **`rev`**: Versión actual de la regla (`1`).

---

## Evidencia y Validación

La regla fue validada mediante el lanzamiento de tráfico ICMP real desde una máquina externa dentro del entorno de laboratorio.

### Rutas de Registro (Logs)
Las alertas generadas se almacenan correctamente en:
* `/var/log/suricata/fast.log`
* `/var/log/suricata/eve.json`

### Ejemplo de Alerta Obtenida
```text
[1:1000001:1] MF0488 - ICMP detectado
{ICMP} 10.21.4.40:8 -> 10.21.4.36:0
```
