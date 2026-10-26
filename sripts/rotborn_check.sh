#!/usr/bin/env bash
# ==========================================================
# ROTBORN STUDIOS - AUDITORIA AMPLIADA FASE 5
# Diagnostico de infraestructura, seguridad, TLS y servicios
# Modo: comprobaciones de lectura y pruebas de conectividad
# No reinicia servicios ni modifica la configuracion.
# ==========================================================

set -uo pipefail

PROJECT_DIR="/srv/rotborn"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
NGINX_CONF="$PROJECT_DIR/nginx/default.conf"
NGINX_LOG_FORMAT="$PROJECT_DIR/nginx/00-log-format.conf"
PRIMARY_CONF="$PROJECT_DIR/config/mariadb/primary.cnf"
REPLICA_CONF="$PROJECT_DIR/config/mariadb-replica/replica.cnf"

CA_CERT="/etc/ssl/mf0489/ca.crt"
SERVER_CERT="/etc/ssl/certs/servidor.crt"
PRIVATE_KEY="/etc/ssl/private/servidor.key"
HOSTNAME_TLS="portal.rotborn.test"

SURICATA_DIR="/var/log/suricata"
BACKUP_DIR="$PROJECT_DIR/backups"

PASS=0
WARN=0
FAIL=0

ok() {
    printf '[OK]      %s\n' "$1"
    PASS=$((PASS + 1))
}

warn() {
    printf '[AVISO]   %s\n' "$1"
    WARN=$((WARN + 1))
}

fail() {
    printf '[ERROR]   %s\n' "$1"
    FAIL=$((FAIL + 1))
}

section() {
    printf '\n==================================================\n'
    printf '%s\n' "$1"
    printf '==================================================\n'
}

info() {
    printf '  %-23s %s\n' "$1" "$2"
}

check_file() {
    local path="$1"
    local description="$2"

    if [[ -f "$path" ]]; then
        ok "$description"
        info "Ruta:" "$path"
    else
        warn "$description: no encontrado"
        info "Ruta esperada:" "$path"
    fi
}

check_directory() {
    local path="$1"
    local description="$2"

    if [[ -d "$path" ]]; then
        ok "$description"
        info "Ruta:" "$path"
    else
        warn "$description: no encontrado"
        info "Ruta esperada:" "$path"
    fi
}

# ----------------------------------------------------------
# 0. INFORMACION GENERAL
# ----------------------------------------------------------

section "0. INFORMACION Y RUTAS DEL PROYECTO"

info "Fecha:" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
info "Servidor:" "$(hostname)"
info "Usuario de ejecucion:" "$(id -un)"
info "Proyecto:" "$PROJECT_DIR"
info "Docker Compose:" "$COMPOSE_FILE"
info "Nombre TLS:" "$HOSTNAME_TLS"

if [[ ! -d "$PROJECT_DIR" ]]; then
    fail "No existe el directorio del proyecto"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

if sudo docker info >/dev/null 2>&1; then
    ok "Docker disponible"
else
    fail "Docker no disponible"
    exit 1
fi

if [[ -f "$COMPOSE_FILE" ]]; then
    ok "Archivo Docker Compose presente"
else
    fail "No existe el archivo Docker Compose"
    exit 1
fi

if sudo docker compose -f "$COMPOSE_FILE" config --quiet \
    >/dev/null 2>&1; then
    ok "Sintaxis y configuracion Compose validas"
else
    fail "Compose no valida; revisar configuracion sin publicar secretos"
fi

# ----------------------------------------------------------
# 1. CONTENEDORES Y SERVICIOS
# ----------------------------------------------------------

section "1. DOCKER: ESTADO DE LOS SERVICIOS"

printf 'Se comprueba que cada servicio tenga un contenedor en ejecucion.\n'
printf 'La imagen y la fecha de inicio son informativas.\n\n'

for service in reverse-proxy wordpress mariadb mariadb-replica; do
    container_id=$(sudo docker compose -f "$COMPOSE_FILE" \
        ps -q "$service" 2>/dev/null || true)

    if [[ -z "$container_id" ]]; then
        fail "No se encuentra el contenedor del servicio $service"
        continue
    fi

    details=$(sudo docker inspect -f \
        '{{.State.Status}}|{{.Config.Image}}|{{.State.StartedAt}}' \
        "$container_id" 2>/dev/null || true)

    IFS='|' read -r state image_name started_at <<< "$details"

    if [[ "$state" == "running" ]]; then
        ok "$service esta en ejecucion"
    else
        fail "$service no esta en ejecucion (estado: ${state:-desconocido})"
    fi

    info "Servicio:" "$service"
    info "Contenedor:" "$(sudo docker inspect -f '{{.Name}}' "$container_id" 2>/dev/null | sed 's#^/##')"
    info "Imagen:" "${image_name:-desconocida}"
    info "Inicio:" "${started_at:-desconocido}"
done

printf '\nPuertos publicados por Docker:\n'
sudo docker compose -f "$COMPOSE_FILE" ps 2>/dev/null |
    awk 'NR==1 || /0\.0\.0\.0:|:::/' |
    sed 's/^/  /'

# ----------------------------------------------------------
# 2. REDES DOCKER
# ----------------------------------------------------------

section "2. REDES Y CONECTIVIDAD INTERNA"

printf 'Se inspeccionan las redes previstas sin crearlas ni eliminarlas.\n'

for network in rotborn_public rotborn_private; do
    if sudo docker network inspect "$network" >/dev/null 2>&1; then
        ok "Red Docker disponible: $network"

        driver=$(sudo docker network inspect -f '{{.Driver}}' \
            "$network" 2>/dev/null || echo desconocido)
        info "Driver:" "$driver"
        info "Contenedores conectados:" ""

        sudo docker network inspect -f \
            '{{range .Containers}}  {{.Name}} ({{.IPv4Address}}){{"\n"}}{{else}}  Ninguno{{"\n"}}{{end}}' \
            "$network" 2>/dev/null || true
    else
        fail "No existe la red Docker $network"
    fi
done

printf '\nOtras redes presentes (solo informativo; no se modifican):\n'
sudo docker network ls --format '  {{.Name}} | {{.Driver}}' 2>/dev/null ||
    warn "No se pudo consultar el listado de redes"

# ----------------------------------------------------------
# 3. NGINX
# ----------------------------------------------------------

section "3. NGINX: CONFIGURACION Y PROXY INVERSO"

check_file "$NGINX_CONF" "Configuracion principal de Nginx"
check_file "$NGINX_LOG_FORMAT" "Configuracion del formato de registros"

if sudo docker compose -f "$COMPOSE_FILE" exec -T reverse-proxy \
    nginx -t >/dev/null 2>&1; then
    ok "Nginx acepta su configuracion"
else
    fail "Nginx no supera nginx -t; comprobar el contenedor"
fi

info "Configuracion en el host:" "$NGINX_CONF"
info "Configuracion en contenedor:" "/etc/nginx/conf.d/default.conf"
info "Funcion:" "Recibe HTTP/HTTPS y reenvia las peticiones a WordPress"

if [[ -f "$NGINX_CONF" ]]; then
    if grep -Eq 'listen[[:space:]]+80' "$NGINX_CONF" &&
       grep -Eq 'return[[:space:]]+301[[:space:]]+https://' "$NGINX_CONF"; then
        ok "Configuracion de redireccion HTTP a HTTPS encontrada"
    else
        warn "No se reconoce la redireccion HTTP esperada en la configuracion"
    fi

    if grep -Fq 'proxy_pass http://wordpress:80' "$NGINX_CONF"; then
        ok "Proxy configurado hacia WordPress"
    else
        fail "No se encuentra el proxy esperado hacia WordPress"
    fi
fi

# ----------------------------------------------------------
# 4. CERTIFICADOS Y CLAVE PRIVADA
# ----------------------------------------------------------

section "4. PKI: CERTIFICADOS, CA Y CLAVE PRIVADA"

info "Certificado servidor:" "$SERVER_CERT"
info "Certificado CA:" "$CA_CERT"
info "Clave privada:" "$PRIVATE_KEY"

if [[ -r "$SERVER_CERT" ]] &&
   sudo openssl x509 -in "$SERVER_CERT" -noout >/dev/null 2>&1; then
    ok "Certificado del servidor legible y X.509 valido"

    info "Sujeto:" "$(sudo openssl x509 -in "$SERVER_CERT" -noout -subject 2>/dev/null | sed 's/^subject=//')"
    info "Emisor:" "$(sudo openssl x509 -in "$SERVER_CERT" -noout -issuer 2>/dev/null | sed 's/^issuer=//')"
    info "Valido desde:" "$(sudo openssl x509 -in "$SERVER_CERT" -noout -startdate 2>/dev/null | cut -d= -f2-)"
    info "Valido hasta:" "$(sudo openssl x509 -in "$SERVER_CERT" -noout -enddate 2>/dev/null | cut -d= -f2-)"

    if sudo openssl x509 -in "$SERVER_CERT" -checkend 0 -noout \
        >/dev/null 2>&1; then
        ok "Certificado no caducado"
    else
        fail "Certificado caducado o no valido temporalmente"
    fi

    if sudo openssl x509 -in "$SERVER_CERT" -noout -ext subjectAltName \
        2>/dev/null | grep -Fq "DNS:$HOSTNAME_TLS"; then
        ok "SAN incluye $HOSTNAME_TLS"
    else
        fail "El SAN no incluye $HOSTNAME_TLS"
    fi
else
    fail "Certificado ausente, ilegible o no valido"
fi

if [[ -r "$CA_CERT" ]] &&
   sudo openssl x509 -in "$CA_CERT" -noout >/dev/null 2>&1; then
    ok "Certificado de la CA legible y valido"
else
    fail "Certificado de la CA ausente o no valido"
fi

if [[ -r "$SERVER_CERT" && -r "$CA_CERT" ]]; then
    verify_output=$(sudo openssl verify -CAfile "$CA_CERT" \
        "$SERVER_CERT" 2>&1 || true)

    if grep -q ': OK$' <<< "$verify_output"; then
        ok "Certificado del servidor validado con la CA"
    else
        fail "No se ha validado el certificado con la CA"
        info "Resultado OpenSSL:" "$verify_output"
    fi
fi

if [[ -f "$PRIVATE_KEY" ]]; then
    key_mode=$(sudo stat -c '%a' "$PRIVATE_KEY" 2>/dev/null || echo desconocido)
    key_owner=$(sudo stat -c '%U' "$PRIVATE_KEY" 2>/dev/null || echo desconocido)

    info "Modo de la clave:" "$key_mode"
    info "Propietario de la clave:" "$key_owner"

    if [[ "$key_mode" == "600" && "$key_owner" == "root" ]]; then
        ok "Clave privada protegida con modo 600 y propietario root"
    else
        warn "Revisar permisos y propietario de la clave privada"
    fi
else
    fail "No existe la clave privada"
fi

# ----------------------------------------------------------
# 5. HTTP, HTTPS Y WORDPRESS
# ----------------------------------------------------------

section "5. PRUEBAS HTTP, HTTPS Y WORDPRESS"

printf 'Las peticiones se dirigen a localhost usando el nombre TLS correcto.\n'
printf 'HTTPS se verifica con la CA; no se desactiva la validacion TLS.\n'

HTTP_CODE=$(curl -sS -o /dev/null -w '%{http_code}' \
    --max-time 8 \
    --resolve "$HOSTNAME_TLS:80:127.0.0.1" \
    "http://$HOSTNAME_TLS/" 2>/dev/null || true)

info "URL HTTP:" "http://$HOSTNAME_TLS/"
info "Codigo HTTP:" "${HTTP_CODE:-sin respuesta}"

if [[ "$HTTP_CODE" == "301" ]]; then
    ok "HTTP redirige con codigo 301"
else
    fail "Se esperaba redireccion HTTP 301"
fi

LOCATION=$(curl -sSI --max-time 8 \
    --resolve "$HOSTNAME_TLS:80:127.0.0.1" \
    "http://$HOSTNAME_TLS/" 2>/dev/null |
    awk 'BEGIN { IGNORECASE=1 } /^Location:/ {print $2}' |
    tr -d '\r' || true)

info "Destino de redireccion:" "${LOCATION:-no detectado}"

if [[ "$LOCATION" == "https://$HOSTNAME_TLS/" ]]; then
    ok "Destino de redireccion HTTPS correcto"
else
    warn "No se ha detectado exactamente el destino HTTPS esperado"
fi

if [[ -r "$CA_CERT" ]]; then
    TLS_RESULT=$(curl -sS -o /dev/null \
        -w '%{http_code} %{ssl_verify_result}' \
        --max-time 12 \
        --cacert "$CA_CERT" \
        --resolve "$HOSTNAME_TLS:443:127.0.0.1" \
        "https://$HOSTNAME_TLS/" 2>/dev/null || true)

    HTTPS_CODE=$(awk '{print $1}' <<< "$TLS_RESULT")
    SSL_VERIFY=$(awk '{print $2}' <<< "$TLS_RESULT")

    info "URL HTTPS:" "https://$HOSTNAME_TLS/"
    info "Codigo HTTPS:" "${HTTPS_CODE:-sin respuesta}"
    info "Resultado de verificacion TLS:" "${SSL_VERIFY:-no disponible}"

    if [[ "$HTTPS_CODE" == "200" && "$SSL_VERIFY" == "0" ]]; then
        ok "HTTPS validado y WordPress responde con HTTP 200"
    else
        fail "Fallo en HTTPS, validacion TLS o respuesta de WordPress"
    fi
else
    warn "No se prueba HTTPS porque no se encuentra la CA"
fi

# ----------------------------------------------------------
# 6. MARIADB PRINCIPAL Y REPLICACION
# ----------------------------------------------------------

section "6. MARIADB: CONEXION Y REPLICACION"

printf 'La prueba consulta la base de datos sin mostrar contrasenas.\n'

DB_RESULT=$(sudo docker compose -f "$COMPOSE_FILE" exec -T mariadb \
    sh -c 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -Nse "SELECT 1"' \
    2>/dev/null || true)

if grep -qx '1' <<< "$DB_RESULT"; then
    ok "MariaDB principal acepta una consulta SELECT 1"
else
    fail "No se ha podido verificar la consulta en MariaDB principal"
fi

info "Configuracion principal:" "$PRIMARY_CONF"
info "Directorio de datos principal:" "$PROJECT_DIR/db"

check_file "$PRIMARY_CONF" "Configuracion de MariaDB principal"
check_directory "$PROJECT_DIR/db" "Directorio de datos de MariaDB principal"

info "Configuracion replica:" "$REPLICA_CONF"
info "Directorio de datos replica:" "$PROJECT_DIR/db-replica"

check_file "$REPLICA_CONF" "Configuracion de MariaDB replica"
check_directory "$PROJECT_DIR/db-replica" "Directorio de datos de MariaDB replica"

REPL_STATUS=$(sudo docker compose -f "$COMPOSE_FILE" exec -T mariadb-replica \
    sh -c 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW SLAVE STATUS\\G"' \
    2>/dev/null || true)

if grep -q 'Slave_IO_Running: Yes' <<< "$REPL_STATUS" &&
   grep -q 'Slave_SQL_Running: Yes' <<< "$REPL_STATUS" &&
   grep -q 'Last_IO_Error: *$' <<< "$REPL_STATUS" &&
   grep -q 'Last_SQL_Error: *$' <<< "$REPL_STATUS"; then
    ok "Hilos IO y SQL de replicacion activos, sin errores registrados"

    REPL_LAG=$(awk -F': ' '/Seconds_Behind_Master:/ {print $2; exit}' <<< "$REPL_STATUS")
    info "Retraso informado:" "${REPL_LAG:-no disponible} segundos"

    if [[ "$REPL_LAG" == "0" ]]; then
        ok "Retraso de replicacion informado: 0 segundos"
    elif [[ "$REPL_LAG" =~ ^[0-9]+$ ]]; then
        warn "La replica informa un retraso de $REPL_LAG segundos"
    else
        warn "No se ha podido determinar el retraso de replicacion"
    fi
else
    if [[ -z "$REPL_STATUS" ]] ||
       ! grep -q 'Slave_IO_Running:' <<< "$REPL_STATUS"; then
        fail "No se ha podido obtener el estado de replicacion"
    else
        fail "Replicacion detenida o con errores; revisar el estado en MariaDB"
        info "Hilo IO:" "$(awk -F': ' '/Slave_IO_Running:/ {print $2; exit}' <<< "$REPL_STATUS")"
        info "Hilo SQL:" "$(awk -F': ' '/Slave_SQL_Running:/ {print $2; exit}' <<< "$REPL_STATUS")"
        info "Error IO:" "$(awk -F': ' '/Last_IO_Error:/ {print substr($0,index($0,": ")+2); exit}' <<< "$REPL_STATUS")"
        info "Error SQL:" "$(awk -F': ' '/Last_SQL_Error:/ {print substr($0,index($0,": ")+2); exit}' <<< "$REPL_STATUS")"
    fi
fi

# ----------------------------------------------------------
# 7. SURICATA Y REGISTROS
# ----------------------------------------------------------

section "7. SURICATA: SERVICIO, REGISTROS Y ALERTAS"

info "Directorio de registros:" "$SURICATA_DIR"

if systemctl is-active --quiet suricata; then
    ok "Servicio Suricata activo"
else
    fail "Servicio Suricata no activo"
fi

for logfile in \
    "$SURICATA_DIR/eve.json" \
    "$SURICATA_DIR/fast.log" \
    "$SURICATA_DIR/stats.log"
do
    if [[ -s "$logfile" ]]; then
        ok "Registro presente y no vacio"
        info "Ruta:" "$logfile"
        info "Tamano:" "$(sudo stat -c '%s bytes' "$logfile" 2>/dev/null || echo desconocido)"
        info "Ultima modificacion:" "$(sudo stat -c '%y' "$logfile" 2>/dev/null || echo desconocida)"
    else
        warn "Registro ausente o vacio: $logfile"
    fi
done

if [[ -s "$SURICATA_DIR/fast.log" ]]; then
    ALERT_COUNT=$(sudo grep -Ec \
        'MF0488 - ICMP detectado|MF0489 Fase 4 - Conexion HTTPS observada' \
        "$SURICATA_DIR/fast.log" 2>/dev/null || true)
    ALERT_COUNT=${ALERT_COUNT:-0}

    info "Alertas de reglas del laboratorio:" "$ALERT_COUNT"

    if [[ "$ALERT_COUNT" =~ ^[0-9]+$ ]] && (( ALERT_COUNT > 0 )); then
        ok "Se encuentran alertas de las reglas del laboratorio"
        printf 'Ultimas alertas coincidentes:\n'
        sudo grep -E \
            'MF0488 - ICMP detectado|MF0489 Fase 4 - Conexion HTTPS observada' \
            "$SURICATA_DIR/fast.log" 2>/dev/null | tail -n 5 |
            sed 's/^/  /'
    else
        warn "No se encontraron alertas coincidentes en fast.log"
    fi
fi

# ----------------------------------------------------------
# 8. COPIAS DE SEGURIDAD Y DOCUMENTACION
# ----------------------------------------------------------

section "8. COPIAS DE SEGURIDAD Y DOCUMENTACION"

check_directory "$BACKUP_DIR" "Directorio de copias de seguridad"

if [[ -d "$BACKUP_DIR" ]]; then
    printf '\nCopias encontradas (hasta dos niveles de profundidad):\n'
    BACKUP_LIST=$(find "$BACKUP_DIR" -maxdepth 2 -type f \
        -printf '%TY-%Tm-%Td %TH:%TM | %s bytes | %p\n' \
        2>/dev/null | sort -r | head -n 20 || true)

    if [[ -n "$BACKUP_LIST" ]]; then
        printf '%s\n' "$BACKUP_LIST" | sed 's/^/  /'
    else
        warn "No se encontraron archivos de copia en los niveles inspeccionados"
    fi

    if [[ -f "$BACKUP_DIR/fase3-20261021-115929/docker-compose.yml" ]]; then
        ok "Copia historica conocida de Docker Compose presente"
        info "Ruta:" "$BACKUP_DIR/fase3-20261021-115929/docker-compose.yml"
    else
        warn "No se encuentra la copia historica esperada de Compose"
    fi
fi

check_file "$PROJECT_DIR/.gitignore" "Archivo .gitignore presente en el proyecto"
check_directory "$PROJECT_DIR/docs" "Directorio de documentacion"

if [[ -d "$PROJECT_DIR/docs" ]]; then
    printf '\nDocumentacion encontrada:\n'
    find "$PROJECT_DIR/docs" -maxdepth 1 -type f \
        \( -name '*.md' -o -name '*.txt' -o -name '*.pdf' \) \
        -printf '  %f\n' 2>/dev/null | sort | head -n 30
fi

check_file "$PROJECT_DIR/scripts/auditoria_fase5.sh" "Script de auditoria presente"

# ----------------------------------------------------------
# 9. RESUMEN
# ----------------------------------------------------------

section "9. RESUMEN FINAL"

printf 'Comprobaciones correctas: %s\n' "$PASS"
printf 'Advertencias:             %s\n' "$WARN"
printf 'Errores:                  %s\n' "$FAIL"

printf '\nInterpretacion:\n'
printf '  OK      = comprobacion superada.\n'
printf '  AVISO   = requiere revision o no pudo confirmarse completamente.\n'
printf '  ERROR   = comprobacion fallida.\n'

printf '\nLimitaciones:\n'
printf '  - No demuestra por si solo que una restauracion de backup funcione.\n'
printf '  - La existencia de alertas no demuestra que se detecten todos los ataques.\n'
printf '  - La replica debe revisarse tambien ante cambios de datos importantes.\n'
printf '  - No se han modificado configuraciones ni eliminado recursos.\n'

if (( FAIL > 0 )); then
    printf '\nRESULTADO: HAY ERRORES QUE REQUIEREN REVISION.\n'
    exit 1
elif (( WARN > 0 )); then
    printf '\nRESULTADO: REVISION COMPLETADA CON ADVERTENCIAS.\n'
    exit 0
else
    printf '\nRESULTADO: TODAS LAS COMPROBACIONES HAN FINALIZADO SIN AVISOS.\n'
    exit 0
fi