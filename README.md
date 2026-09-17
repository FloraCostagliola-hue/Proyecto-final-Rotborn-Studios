# Rotborn Studios

* **Nombre del proyecto:** Rotborn Studios
* **Integrante:** Flora Costagliola [cite: topic-Demographics Information]
* **Modalidad:** Individual
* **Temática:** Ciberseguridad aplicada a la infraestructura de una empresa ficticia de desarrollo de videojuegos.
* **Tecnologías:** Ubuntu Server 22.04.5 LTS, OpenSSH, Docker, Docker Compose, WordPress, MariaDB, Suricata y Nmap.

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
| :--- | :--- | :--- |
| **Login SSH correcto** | `/var/log/auth.log` | Identificación de usuario, IP de origen y aceptación de clave/credencial. |
| **Login SSH incorrecto** | `/var/log/auth.log` | Registro de intentos de acceso fallidos o no autorizados. |
| **Solicitud Web exitosa** | Logs de Apache / Docker | Petición HTTP recibida con código de respuesta `200`. |
| **Error Web 404** | Logs de Apache / Docker | Petición a recursos inexistentes con código de respuesta `404`. |
| **Estado de Contenedores** | `docker compose ps` | Comprobación del ciclo de vida y estado operativo de los servicios. |
| **Logs de Contenedores** | `docker logs` | Trazas de ejecución y depuración de las aplicaciones internas. |
| **Tráfico ICMP / Ping** | `/var/log/suricata/fast.log` | Alerta disparada mediante la regla personalizada de Suricata. |
| **Eventos de Red Global** | `/var/log/suricata/eve.json` | Flujos de red detallados y telemetría capturada por el IDS. |
| **Análisis de Puertos** | Nmap + Suricata | Verificación de puertos accesibles y correlación con los registros de tráfico. |
| **Persistencia de Datos** | `/srv/rotborn/db` | Comprobación de la retención de información de MariaDB tras reinicios. |
| **Replicación Activa** | MariaDB Primary / Replica | Validación de la consistencia de datos replicados entre servidores. |
