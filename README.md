# Proyecto final — Rotborn Studios

## Descripción

Rotborn Studios es una empresa ficticia dedicada al desarrollo de videojuegos de supervivencia con temática zombi.

Este proyecto representa la infraestructura tecnológica interna utilizada por la empresa para gestionar sus recursos y servicios informáticos.

La infraestructura dispone de un servidor Ubuntu Server que proporciona diferentes servicios, entre ellos acceso remoto mediante SSH, una aplicación web y una base de datos. La infraestructura también incorpora mecanismos de monitorización y detección de actividad sospechosa mediante Suricata.

El portal web interno permitirá consultar información relacionada con el desarrollo del videojuego, como versiones, personajes, mapas, documentación técnica y registros de errores.

Posteriormente, esta infraestructura será utilizada como escenario para realizar pruebas de seguridad controladas, analizar vulnerabilidades y simular un incidente de ciberseguridad desde una perspectiva SOC.

---

## Servidor e infraestructura Docker

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

                          CLIENTE
                            |
                            |
                      Ubuntu Server
                            |
                    ┌───────┴───────┐
                    |               |
                  SSH          WordPress
                 :22            :8080
                                    |
                         ┌──────────┴──────────┐
                         |                     |
                  rotborn_public       rotborn_private
                         |                     |
                    WordPress       ┌──────────┴──────────┐
                                    |                     |
                                 MariaDB          MariaDB Replica
                                  :3306                 :3306
                                interno                interno


### Tabla de puertos

| Servicio        | Puerto   | Expuesto | Función               |
|                 |          |          |                       |
| SSH             | 22/TCP   | Sí       | Administración remota |
| WordPress       | 8080/TCP | Sí       | Aplicación web        |
| MariaDB         | 3306/TCP | No       | Base de datos interna |
| MariaDB Replica | 3306/TCP | No | Réplica de base de datos    |

