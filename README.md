# Proyecto final — Rotborn Studios

## Descripción

Rotborn Studios es una empresa ficticia dedicada al desarrollo de videojuegos de supervivencia con temática zombi.

Este proyecto representa la infraestructura tecnológica interna utilizada por la empresa para gestionar sus recursos y servicios informáticos.

La infraestructura dispone de un servidor Ubuntu Server que proporciona diferentes servicios, entre ellos acceso remoto mediante SSH, una aplicación web y una base de datos. La infraestructura también incorpora mecanismos de monitorización y detección de actividad sospechosa mediante Suricata.

El portal web interno permitirá consultar información relacionada con el desarrollo del videojuego, como versiones, personajes, mapas, documentación técnica y registros de errores.

Posteriormente, esta infraestructura será utilizada como escenario para realizar pruebas de seguridad controladas, analizar vulnerabilidades y simular un incidente de ciberseguridad desde una perspectiva SOC.

---

## Objetivos del proyecto

- Diseñar y desplegar una infraestructura Linux funcional.
- Implementar servicios mediante Docker.
- Desplegar una aplicación web y una base de datos.
- Configurar acceso remoto seguro mediante SSH.
- Implementar monitorización y detección mediante Suricata.
- Registrar y analizar eventos de seguridad.
- Introducir vulnerabilidades controladas para crear un escenario CTF.
- Analizar las evidencias generadas durante un incidente de seguridad.

---

## Tecnologías

- Ubuntu Server 22.04 LTS
- OpenSSH
- Docker
- Docker Compose
- Aplicación web
- Base de datos
- Suricata
- Git / GitHub

---

## Arquitectura inicial

```text

  CLIENT
    │
    ▼
Ubuntu Server
    │
┌───┼───────────┐
│   │           │
SSH Suricata   Docker
                │
       ┌────────┴────────┐
       │                 │
      WEB               DB
