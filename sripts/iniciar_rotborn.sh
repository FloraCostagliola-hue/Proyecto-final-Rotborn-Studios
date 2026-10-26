
#!/bin/bash

# ==========================================
# ROTBORN STUDIOS - INICIO DEL LABORATORIO
# ==========================================

set -u

PROJECT_DIR="/srv/rotborn"
CHECK_SCRIPT="/srv/rotborn/scripts/rotborn-check.sh"

echo "=========================================="
echo " ROTBORN STUDIOS - INICIO DEL LABORATORIO"
echo "=========================================="

# Comprobar que Docker está disponible
if ! sudo docker info >/dev/null 2>&1; then
    echo "[ERROR] Docker no está disponible."
    exit 1
fi

echo "[OK] Docker está activo."

# Acceder al directorio del proyecto
cd "$PROJECT_DIR" || exit 1

# Arrancar los servicios existentes
echo
echo "[INFO] Iniciando los contenedores..."

if ! sudo docker compose up -d; then
    echo "[ERROR] No se han podido iniciar los contenedores."
    exit 1
fi

echo
echo "[OK] Orden de inicio completada."

# Esperar a que los servicios se estabilicen
echo
echo "[INFO] Esperando 15 segundos para que los servicios se preparen..."
sleep 15

# Ejecutar la comprobación funcional existente
echo
echo "[INFO] Comprobando el laboratorio..."

if [ -x "$CHECK_SCRIPT" ]; then
    sudo bash "$CHECK_SCRIPT"
else
    echo "[ERROR] No se encuentra $CHECK_SCRIPT"
    exit 1
fi

echo
echo "=========================================="
echo " FIN DEL PROCESO DE INICIO"
echo "=========================================="