# Rotborn Studios

* **Nombre del proyecto:** Rotborn Studios
* **Integrante:** Flora Costagliola 
* **Modalidad:** Individual
* **Temática:** Ciberseguridad aplicada a la infraestructura de una empresa ficticia de desarrollo de videojuegos.
* **Tecnologías:** Ubuntu Server 22.04.5 LTS, OpenSSH, Docker, Docker Compose, WordPress, MariaDB, Suricata.

---

## Descripción Breve del Sistema

Rotborn Studios es una empresa ficticia dedicada al desarrollo de videojuegos de supervivencia. 

La infraestructura representa el entorno tecnológico de la compañía y se encuentra desplegada sobre un servidor **Ubuntu Server 22.04.5 LTS**. Sus características principales son:

* **Acceso y Administración:** El servidor proporciona acceso administrativo seguro mediante **OpenSSH**.
* **Infraestructura Contenedorizada:** Se ejecuta un entorno Docker gestionado mediante **Docker Compose**.
* **Aplicación Web:** Portal corporativo basado en **WordPress**, empleado para la gestión de contenidos e información de la empresa.
* **Gestión de Bases de Datos:** WordPress utiliza **MariaDB** como base de datos principal, complementada con una segunda instancia configurada como réplica.
* **Segmentación de Red:** La arquitectura implementa redes Docker separadas para aislar la aplicación web de los servicios internos de base de datos.
* **Almacenamiento Persistente:** Los datos de las bases de datos se almacenan en volúmenes persistentes para evitar pérdidas ante paradas o reinicios de contenedores.
* **Seguridad y Monitorización:** **Suricata** se encuentra instalado directamente sobre el sistema operativo base para monitorizar el tráfico de red en tiempo real y detectar eventos mediante reglas personalizadas.
* **Auditoría:** Durante las fases de validación, se emplearon diversas fuentes de registros y herramientas de análisis como SSH, logs de Apache/Docker, Suricata y Nmap.

---

## Arquitectura Inicial

El siguiente esquema representa la infraestructura tecnológica desarrollada durante las diferentes fases del proyecto:

```text
                              CLIENTES / LABORATORIO
                                      │
                       ┌──────────────┼──────────────┐
                       │              │              │
                      SSH            HTTP           ICMP
                    TCP/22         TCP/8080        Tráfico
                       │              │              │
                       └──────────────┼──────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │      UBUNTU SERVER      │
                         │    Rotborn Studios      │
                         │    Ubuntu 22.04.5 LTS   │
                         └────────────┬────────────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
              OPENSSH              SURICATA              DOCKER
               :22                   IDS                   │
                                    │                      │
                                    │          ┌───────────┴───────────┐
                                    │          │                       │
                                    │          ▼                       ▼
                                    │    RED PÚBLICA              RED PRIVADA
                                    │  (`rotborn_public`)      (`rotborn_private`)
                                    │          │                       │
                                    │          ▼                       │
                                    │      WORDPRESS                   │
                                    │       (:8080)                    │
                                    │          │                       │
                                    │          └───────────┬───────────┘
                                    │                      │
                                    │                      ▼
                                    │              ┌───────────────┐
                                    │              │MariaDB Primary│
                                    │              └───────┬───────┘
                                    │                      │
                                    │                 Replicación
                                    │                      │
                                    │                      ▼
                                    │              ┌───────────────┐
                                    │              │MariaDB Replica│
                                    │              └───────────────┘
                                    │
                                    ▼
                              LOGS / ALERTAS
                              - fast.log
                              - eve.json
                              - auth.log
                              - Apache / Docker
```

---

## Redes Docker

La infraestructura Docker utiliza dos redes independientes para aislar los componentes de la aplicación:

* **`rotborn_public`**: Red dedicada exclusivamente a la comunicación de la aplicación web WordPress con el exterior.
* **`rotborn_private`**: Red interna reservada para el tráfico exclusivo entre WordPress y los servicios de base de datos MariaDB. Las instancias principal y de réplica **no tienen el puerto 3306 publicado** hacia el exterior.

---

## Servidor e Infraestructura de Contenedores

| Servicio / Componente | Puerto Expuesto | Función Principal |
| :--- | :---: | :--- |
| **SSH / OpenSSH** | `22/TCP` | Administración remota segura del servidor Ubuntu. |
| **WordPress / Apache** | `8080/TCP` | Aplicación web y portal corporativo de Rotborn Studios. |
| **MariaDB Primary** | `3306/TCP` (Oculto) | Base de datos principal de WordPress. |
| **MariaDB Replica** | `3306/TCP` (Oculto) | Instancia de réplica de la base de datos principal. |
| **Docker Engine** | — | Plataforma de ejecución y gestión de servicios mediante contenedores. |
| **Suricata IDS** | — | Monitorización pasiva y activa de amenazas e inspección de tráfico de red. |

---

## Persistencia y Replicación

* **Almacenamiento de Datos:**
  * La base de datos principal utiliza el directorio del host: `/srv/rotborn/db`
  * La instancia de réplica utiliza el directorio del host: `/srv/rotborn/db-replica`
* **Sincronización:** La replicación de MariaDB se configuró correctamente entre ambos nodos y fue comprobada mediante pruebas empíricas de creación, inserción y eliminación de registros.

---

## Mapa de Evidencias

| Acción o Evento | Fuente / Ubicación | Información Obtenida / Resultado |
|:--|:--|:--|
| Login SSH correcto | `/var/log/auth.log` | Identificación del usuario, IP de origen y aceptación de credenciales. |
| Login SSH incorrecto | `/var/log/auth.log` | Registro de intentos de acceso con usuarios o credenciales no válidos. |
| Solicitud Web exitosa | `docker logs rotborn-wordpress-1` | Peticiones HTTP procesadas correctamente y códigos de respuesta. |
| Error Web 404 | `docker logs rotborn-wordpress-1` | Peticiones a recursos inexistentes y código HTTP 404. |
| Estado de Contenedores | `docker compose ps` | Estado operativo de WordPress, MariaDB Primary y MariaDB Replica. |
| Logs de Contenedores | `docker logs` | Actividad y registros generados por los servicios Docker. |
| Tráfico ICMP / Ping | `/var/log/suricata/fast.log` | Alertas generadas por la regla personalizada de ICMP. |
| Eventos de Red | `/var/log/suricata/eve.json` | Flujos y tráfico de red observados por Suricata, incluidos eventos sin alerta. |
| Análisis de Puertos | Nmap + `/var/log/suricata/eve.json` | Puertos accesibles y tráfico generado durante el escaneo controlado. |
| Persistencia de Datos | `/srv/rotborn/db` y `/srv/rotborn/db-replica` | Almacenamiento persistente utilizado por las bases de datos. |
| Replicación Activa | MariaDB Primary / Replica | Comprobación de la sincronización entre las dos bases de datos. |

---

# Línea Base de Actividad y Monitorización

A partir de las pruebas y auditorías realizadas sobre la infraestructura de **Rotborn Studios**, se establece la siguiente línea base de comportamiento y registro de eventos:

| Acción o Evento | Fuente Detectada / Registrada | Estado | Información Obtenida | Resultado real obtenido |
|:--|:--|:--:|:--|:--|
| **SSH Correcto** | `/var/log/auth.log` |  Sí | Identificación del usuario, dirección IP de origen y aceptación de credenciales. | `16/Sep/2026 19:02:19` — `Accepted password for zadmin from 10.21.4.40`, puerto origen `49934`. |
| **SSH Incorrecto** | `/var/log/auth.log` |  Sí | Registro de la IP de origen e intentos de acceso con usuarios no válidos. | `16/Sep/2026 19:08:17` — `Invalid user usuario_falso from 10.21.4.40`, puerto origen `50573`. |
| **Solicitud Web Válida** | Logs de Apache / Docker |  Sí | Petición HTTP correcta y código de respuesta `200`. | `16/Sep/2026 19:41:07` — `GET /` desde `10.21.4.40` → **HTTP 200**. |
| **Petición Web 404** | Logs de Apache / Docker | Sí | Solicitud a un recurso inexistente y código de respuesta `404`. | `16/Sep/2026 19:42:33` — `GET /esto-no-existe` desde `10.21.4.40` → **HTTP 404**. |
| **Estado de Contenedores** | `docker compose ps` / logs |  Sí | Verificación del ciclo de vida, estado de los servicios y actividad de WordPress. | `rotborn-wordpress-1`, `rotborn-mariadb-1` y `rotborn-mariadb-replica-1` aparecen en estado **Up**. WordPress expone `8080→80`. |
| **Tráfico ICMP (Ping)** | Suricata (`fast.log` / `eve.json`) |  Sí (Alerta) | Detección de tráfico ICMP, direcciones IP de origen/destino y disparo del SID de la regla. | `16/Sep/2026 22:49:35` — alerta **SID 1000001**, `MF0488 - ICMP detectado`, desde `10.21.4.40` hacia `10.21.4.36`. |
| **Escaneo de Red (Nmap)** | Nmap + Suricata (`eve.json`) | Sí | Identificación de puertos accesibles y registro del tráfico TCP observado por Suricata. | Desde Kali (`10.54.254.20`) se comprobó el servidor `10.54.254.214`: **22/tcp open (SSH)** y **8080/tcp open (HTTP)**. Suricata registró tráfico TCP hacia el puerto 22 con `alerted:false`. |
