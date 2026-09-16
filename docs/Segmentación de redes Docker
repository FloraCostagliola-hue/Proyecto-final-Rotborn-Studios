### Segmentación de redes Docker

Para mejorar la seguridad de la infraestructura se ha implementado una segmentación de red mediante dos redes Docker independientes.

La arquitectura utiliza:

- `rotborn_public`: red destinada a la exposición de la aplicación web.
- `rotborn_private`: red interna utilizada para la comunicación entre WordPress y las bases de datos.

La distribución de los servicios es la siguiente:

| Servicio  | `rotborn_public` | `rotborn_private` |
|---        |---               |---                |
| WordPress |        Sí        |         Sí        |
| MariaDB   |        No        |         Sí        |
| MariaDB   |        No        |         Sí        |
| Replica
De esta forma, WordPress dispone de acceso a ambas redes, mientras que MariaDB y MariaDB Replica permanecen únicamente en la red privada.


#### Configuración de las redes

1)Antes de modificar docker-compose.yml creamos una copia de seguredad:

"cp docker-compose.yml docker-compose.yml.backup"

2) Modificamos docker-compose.yml con nano sostituendo la primera network creada:

networks:
  - rotborn_net

"services:
  wordpress:
    image: wordpress:7.1.0-php8.3-apache
    networks:
       - rotborn_public
       - rotborn_private"

3) Modificamos la red rotborn_net a rotborn_private en :

"mariadb:
   image: mariadb:10.11
   networks:
     - rotborn_private" 
          
4) modificamos el nombre de la red:

networks:
  rotborn_public:
    name: rotborn_public
    driver: bridge

  rotborn_private:
    name: rotborn_private
    driver: bridge

5) comprovamos con 

"docker compose config"

6) creamos y levantamos:

zadmin@rotborn-server:/srv/rotborn$ docker compose up -d
[+] Running 5/5
 ✔ Network rotborn_public               Created                                                                                                                                                             1.1s
 ✔ Network rotborn_private              Created                                                                                                                                                             0.3s
 ✔ Container rotborn-mariadb-replica-1  Started                                                                                                                                                             4.9s
 ✔ Container rotborn-mariadb-1          Started                                                                                                                                                             5.1s
 ✔ Container rotborn-wordpress-1        Started                                                                                                                                                             6.4s
zadmin@rotborn-server:/srv/rotborn$

7) comprobamos si esta en up:

zadmin@rotborn-server:/srv/rotborn$ docker compose ps
NAME                        IMAGE                           COMMAND                  SERVICE           CREATED              STATUS              PORTS
rotborn-mariadb-1           mariadb:10.11                   "docker-entrypoint.s…"   mariadb           About a minute ago   Up About a minute   3306/tcp
rotborn-mariadb-replica-1   mariadb:10.11                   "docker-entrypoint.s…"   mariadb-replica   About a minute ago   Up About a minute   3306/tcp
rotborn-wordpress-1         wordpress:7.1.0-php8.3-apache   "docker-entrypoint.s…"   wordpress         About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
zadmin@rotborn-server:/srv/rotborn$

Tenemos exactamente la arquitectura que queríamos:

```text
Internet / red externa
        │
        │ :8080
        ▼
┌─────────────────┐
│    WordPress    │
│                 │
│ public + private│
└────────┬────────┘
         │
    RED PRIVADA
         │
    ┌────┴─────┐
    ▼          ▼
 MariaDB    MariaDB
 primaria    réplica
 :3306        :3306

Y la salida confirma algo muy importante:

MariaDB           3306/tcp
MariaDB Replica   3306/tcp
WordPress         0.0.0.0:8080->80/tcp

Es decir:

WordPress → accesible desde fuera por 8080 
MariaDB → no publicado hacia la VM/Internet 
Réplica → no publicada hacia la VM/Internet 
WordPress ↔ MariaDB → mediante rotborn_private 

8) Vamos a confirmar que las redes realmente tienen los contenedores correctos.
zadmin@rotborn-server:/srv/rotborn$ docker network inspect rotborn_public

Containers": {
            "ced4300d27e3a837ce248ccf5f09b8bbd9495c4ff538a011efec3d9498e0ffcc": {
                "Name": "rotborn-wordpress-1",
                "EndpointID": "6b32902916bf3d6f701f470ebdd77539a0115bd45bf8dbed918fd4137ed8f2d8",
                "MacAddress": "1e:74:d9:3d:75:c0",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""


zadmin@rotborn-server:/srv/rotborn$ docker network inspect rotborn_private

     "com.docker.compose.version": "2.40.3"
        },
        "Containers": {
            "74be4dbbdc00ddcbceb21d5023a39b204712afb44e1a403e12a2a7d0ee8712c3": {
                "Name": "rotborn-mariadb-1",
                "EndpointID": "06a685ce7e4ef2c7f0287020b5e430b6ead605aed3386fe46f70fcd35b034ba5",
                "MacAddress": "4a:a3:15:76:cb:68",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            },
            "97c704f66d14ab9e631b529caeba3801003b58f39b690d2c74567670d0695c22": {
                "Name": "rotborn-mariadb-replica-1",
                "EndpointID": "f263d8825296b091e299a0b5924f869ebd40d3d0ddb5665543ef3e59d1a0ae22",
                "MacAddress": "d2:62:d5:3e:79:14",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            },
            "ced4300d27e3a837ce248ccf5f09b8bbd9495c4ff538a011efec3d9498e0ffcc": {
                "Name": "rotborn-wordpress-1",
                "EndpointID": "bb8ef03ac38f63ba297a9ec266787643ec5c1c5a8c97cc671b7a8e97ff2cbe6f",
                "MacAddress": "42:e9:35:44:12:67",
                "IPv4Address": "172.20.0.4/16",
                "IPv6Address": ""

9) Ahora comprobamos que la réplica MariaDB sigue funcionando después del cambio de red.

docker exec -it rotborn-mariadb-replica-1 mariadb -uroot -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 6
Server version: 10.11.19-MariaDB-ubu2204 mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SHOW SLAVE STATUS\G

Resultado:

MariaDB [(none)]> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
   
         Slave_IO_Running: Yes
         Slave_SQL_Running: Yes

        Y :

         Slave_IO_State: Waiting for master to send event
         Master_Host: mariadb
         Master_Port: 3306

Esto confirma que la réplica puede comunicarse con la MariaDB principal por la red privada, usando el nombre Docker mariadb y el puerto interno 3306.
