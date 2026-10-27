# 🧟 ROTBORN STUDIOS

### La seguridad también es sobrevivir

*En un mundo infectado, la seguridad es la última línea de defensa.*



---

## 🏚️ Búnker de documentación

### 📋 Ficha del proyecto

1. **Nombre del proyecto:** Rotborn Studios
2. **Integrante:** Flora Costagliola
3. **Modalidad:** Individual
4. **Temática:** Ciberseguridad aplicada a la infraestructura de una empresa ficticia de desarrollo de videojuegos.
5. **Tecnologías:** Ubuntu Server 22.04.5 LTS, OpenSSH, Docker, Docker Compose, WordPress, MariaDB y Suricata.


------------------------------------------------------------------------

## 🧭 Sobre el proyecto

Rotborn Studios es una empresa ficticia de desarrollo de videojuegos de
supervivencia. Este proyecto implementa y documenta una infraestructura
de laboratorio centrada en la seguridad de sistemas y servicios web.

**Entorno principal:** Ubuntu Server 22.04.5 LTS\
**Tecnologías:** Docker, Docker Compose, Nginx, WordPress, MariaDB,
PKI/TLS y Suricata.

La infraestructura incluye un portal WordPress detrás de un proxy
inverso Nginx, una base de datos MariaDB con réplica, certificados TLS
para el acceso HTTPS y monitorización de red con Suricata.


## 🗺️ Mapa del repositorio

Los enlaces llevan a las carpetas o documentos correspondientes en
GitHub.

  -------------------------------------------------------------------------------
  Área                                        Contenido
  ------------------------------------------- -----------------------------------
  [🪖                                         Definición de los servicios del
  `docker-compose.yml`](docker-compose.yml)   proyecto.

  [🕸️ `nginx/`](nginx/)                       Configuración del proxy inverso y
                                              HTTPS.

  [⚙️ `scripts/`](scripts/)                   Scripts de inicio, comprobación y
                                              auditoría, si están incluidos en el
                                              repositorio.

  [📡 `suricata/`](suricata/)                 Reglas locales de detección.

  [🧿`pki/`](pki/)                           Material público de PKI autorizado
                                              para publicación.

  [📚 `docs/mf0489/`](docs/mf0489/)           Documentación técnica y evidencias
                                              por fases.

  [🧪 `.env.example`](.env.example)           Plantilla de variables de entorno
                                              sin secretos reales.

  [⛔ `.gitignore`](.gitignore)               
  -------------------------------------------------------------------------------

## 📚 Documentación por fases 



### 🧟 MF0488 — Supervivencia, infraestructura y monitorización

Documentación de la arquitectura del servidor, la segmentación de redes Docker, la preparación de registros y la implantación de Suricata para detectar amenazas.

- [Fase 0 — Arquitectura](docs/00-arquitectura.md)
- [Fase 1 — Construcción inicial](docs/01-costruccion-inicial.md)
- [Fase 2 — Segmentación de redes Docker](docs/02-segmentacion%20de%20redes%20Docker.md)
- [Fase 3 — Preparación de registros](docs/Fase%203%20—%20Preparación%20de%20registros.md)
- [Fase 4 — Implantación de Suricata](docs/Fase%204%20—Implantación%20de%20Suricata.md)
- [Fase 5 — Entrega final](docs/mf0489/fase5-entrega-final.md)

### ☣️ MF0489 — Zona segura: PKI, HTTPS y auditoría TLS

Documentación de la infraestructura de clave pública, la creación y validación de certificados digitales, la protección de las comunicaciones mediante HTTPS y la auditoría de seguridad TLS.

- [Fase 1 — Arquitectura](docs/mf0489/fase1-arquitectura.md)
- [Fase 2 — PKI](docs/mf0489/fase2-pki.md)
- [Fase 3 — HTTPS y Docker](docs/mf0489/fase3-https-docker.md)
- [Fase 4 — Auditoría TLS y monitorización](docs/mf0489/fase4-auditoria-tls-monitorizacion.md)
- [Fase 5 — Entrega final](docs/mf0489/fase5-entrega-final.md)

---



🧟 **ROTBORN STUDIOS**

*Sobrevivir. Detectar. Proteger.*


# 🧟 ROTBORN STUDIOS

### La seguridad también es sobrevivir

*En un mundo infectado, la seguridad es la última línea de defensa.*



---

## 🏚️ Búnker de documentación

### 📋 Ficha del proyecto

1. **Nombre del proyecto:** Rotborn Studios
2. **Integrante:** Flora Costagliola
3. **Modalidad:** Individual
4. **Temática:** Ciberseguridad aplicada a la infraestructura de una empresa ficticia de desarrollo de videojuegos.
5. **Tecnologías:** Ubuntu Server 22.04.5 LTS, OpenSSH, Docker, Docker Compose, WordPress, MariaDB y Suricata.


------------------------------------------------------------------------

## 🧭 Sobre el proyecto

Rotborn Studios es una empresa ficticia de desarrollo de videojuegos de
supervivencia. Este proyecto implementa y documenta una infraestructura
de laboratorio centrada en la seguridad de sistemas y servicios web.

**Entorno principal:** Ubuntu Server 22.04.5 LTS\
**Tecnologías:** Docker, Docker Compose, Nginx, WordPress, MariaDB,
PKI/TLS y Suricata.

La infraestructura incluye un portal WordPress detrás de un proxy
inverso Nginx, una base de datos MariaDB con réplica, certificados TLS
para el acceso HTTPS y monitorización de red con Suricata.


## 🗺️ Mapa del repositorio

Los enlaces llevan a las carpetas o documentos correspondientes en
GitHub.

  -------------------------------------------------------------------------------
  Área                                        Contenido
  ------------------------------------------- -----------------------------------
  [🪖                                         Definición de los servicios del
  `docker-compose.yml`](docker-compose.yml)   proyecto.

  [🕸️ `nginx/`](nginx/)                       Configuración del proxy inverso y
                                              HTTPS.

  [⚙️ `scripts/`](scripts/)                   Scripts de inicio, comprobación y
                                              auditoría, si están incluidos en el
                                              repositorio.

  [📡 `suricata/`](suricata/)                 Reglas locales de detección.

  [🧿`pki/`](pki/)                           Material público de PKI autorizado
                                              para publicación.

  [📚 `docs/mf0489/`](docs/mf0489/)           Documentación técnica y evidencias
                                              por fases.

  [🧪 `.env.example`](.env.example)           Plantilla de variables de entorno
                                              sin secretos reales.

  [⛔ `.gitignore`](.gitignore)               
  -------------------------------------------------------------------------------

## 📚 Documentación por fases 



### 🧟 MF0488 — Supervivencia, infraestructura y monitorización

Documentación de la arquitectura del servidor, la segmentación de redes Docker, la preparación de registros y la implantación de Suricata para detectar amenazas.

- [Fase 0 — Arquitectura](docs/00-arquitectura.md)
- [Fase 1 — Construcción inicial](docs/01-costruccion-inicial.md)
- [Fase 2 — Segmentación de redes Docker](docs/02-segmentacion%20de%20redes%20Docker.md)
- [Fase 3 — Preparación de registros](docs/Fase%203%20—%20Preparación%20de%20registros.md)
- [Fase 4 — Implantación de Suricata](docs/Fase%204%20—Implantación%20de%20Suricata.md)
- [Fase 5 — Entrega final](docs/mf0489/fase5-entrega-final.md)

### ☣️ MF0489 — Zona segura: PKI, HTTPS y auditoría TLS

Documentación de la infraestructura de clave pública, la creación y validación de certificados digitales, la protección de las comunicaciones mediante HTTPS y la auditoría de seguridad TLS.

- [Fase 1 — Arquitectura](docs/mf0489/fase1-arquitectura.md)
- [Fase 2 — PKI](docs/mf0489/fase2-pki.md)
- [Fase 3 — HTTPS y Docker](docs/mf0489/fase3-https-docker.md)
- [Fase 4 — Auditoría TLS y monitorización](docs/mf0489/fase4-auditoria-tls-monitorizacion.md)
- [Fase 5 — Entrega final](docs/mf0489/fase5-entrega-final.md)

---



🧟 **ROTBORN STUDIOS**

*Sobrevivir. Detectar. Proteger.*


