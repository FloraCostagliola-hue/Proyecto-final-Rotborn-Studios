
cd /srv/rotborn

sudo tee scripts/recuperacion.sh > /dev/null <<'EOF'
#!/usr/bin/env bash

# ============================================================
# Proyecto Rotborn Studios - MF0489
# Script: recuperacion.sh
# Objetivo: verificar copias de seguridad antes de una
#           posible recuperación.
# IMPORTANTE: no restaura ni modifica datos.
# ============================================================

set -u
set -o pipefail

PROJECT_DIR="/srv/rotborn"
BACKUP_DIR="$PROJECT_DIR/backups/fase3-20261021-115929"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
REPORT_DIR="$PROJECT_DIR/docs"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
REPORT="$REPORT_DIR/recuperacion-$TIMESTAMP.log"

ERRORS=0
WARNINGS=0

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: ejecuta el script con sudo."
    exit 1
fi

mkdir -p "$REPORT_DIR"
chmod 750 "$REPORT_DIR"

# Registrar la salida en pantalla y en el informe.
exec > >(tee "$REPORT") 2>&1

echo "============================================================"
echo " ROTBORN STUDIOS - COMPROBACIÓN DE RECUPERACIÓN"
echo " Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "============================================================"
echo "Modo: SOLO COMPROBACIÓN. No se restaurarán datos."
echo

check_file() {
    local file="$1"

    if [[ -f "$file" && -s "$file" ]]; then
        echo "[OK] Archivo presente y no vacío: $file"
    else
        echo "[ERROR] Archivo inexistente o vacío: $file"
        ((ERRORS+=1))
    fi
}

echo "1. Comprobación de archivos"
echo "---------------------------"

check_file "$COMPOSE_FILE"
check_file "$BACKUP_DIR/docker-compose.yml"
check_file "$BACKUP_DIR/.env"
check_file "$BACKUP_DIR/mariadb-principal.sql.gz"
check_file "$BACKUP_DIR/mariadb-replica.sql.gz"

echo
echo "2. Integridad de los volcados comprimidos"
echo "-----------------------------------------"

for dump in \
    "$BACKUP_DIR/mariadb-principal.sql.gz" \
    "$BACKUP_DIR/mariadb-replica.sql.gz"
do
    if [[ -f "$dump" && -s "$dump" ]]; then
        if gzip -t -- "$dump"; then
            echo "[OK] gzip no detecta errores: $(basename "$dump")"
        else
            echo "[ERROR] Falló la prueba gzip: $(basename "$dump")"
            ((ERRORS+=1))
        fi
    else
        echo "[OMITIDO] No se puede validar: $dump"
    fi
done

echo
echo "3. Espacio disponible"
echo "---------------------"
df -h "$PROJECT_DIR"

AVAILABLE_KB="$(df -Pk "$PROJECT_DIR" | awk 'NR==2 {print $4}')"
if [[ "$AVAILABLE_KB" =~ ^[0-9]+$ ]]; then
    if (( AVAILABLE_KB < 524288 )); then
        echo "[AVISO] Quedan menos de 512 MiB. No iniciar una restauración."
        ((WARNINGS+=1))
    else
        echo "[OK] Espacio disponible superior a 512 MiB."
    fi
else
    echo "[AVISO] No se pudo determinar el espacio disponible."
    ((WARNINGS+=1))
fi

echo
echo "4. Estado de Docker Compose"
echo "--------------------------"

if docker compose -f "$COMPOSE_FILE" ps; then
    echo "[INFO] Estado de los servicios consultado."
else
    echo "[AVISO] No se pudo consultar Docker Compose."
    ((WARNINGS+=1))
fi

echo
echo "5. Comprobación de archivos de WordPress"
echo "----------------------------------------"

if find "$BACKUP_DIR" -type d -name wp-content -print -quit | grep -q .; then
    echo "[OK] Se encontró un directorio wp-content dentro de la copia."
else
    echo "[AVISO] No se encontró wp-content dentro de esta copia."
    echo "La recuperación completa de los archivos de WordPress no está verificada."
    ((WARNINGS+=1))
fi

echo
echo "6. Límites de esta comprobación"
echo "-------------------------------"
echo "- gzip -t comprueba la integridad de la compresión, no la validez SQL."
echo "- No se ha restaurado ninguna base de datos."
echo "- No se ha modificado ningún contenedor ni volumen."
echo "- La recuperación completa requiere validar también los archivos web."
echo "- No se muestra ni se copia el contenido de .env."

echo
echo "============================================================"
echo " RESULTADO"
echo " Errores: $ERRORS"
echo " Avisos:  $WARNINGS"
echo " Informe: $REPORT"
echo "============================================================"

if (( ERRORS > 0 )); then
    exit 2
fi

exit 0
EOF