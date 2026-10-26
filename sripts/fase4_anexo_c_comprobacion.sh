#!/usr/bin/env bash
# ============================================================
# MF0489 - Fase 4 - Anexo C
# Comprobaciones TLS, HTTP y HTTPS desde Kali Linux
# ============================================================

set -u
set -o pipefail

# Configuración
DOMINIO="portal.rotborn.test"
IP_SERVIDOR="${1:-10.21.4.53}"
CA_CERT="/home/nyx/ca_root-pki/ca/ca.crt"

# Comprobar dependencias y certificado
if ! command -v openssl >/dev/null 2>&1 ||
   ! command -v curl >/dev/null 2>&1; then
    echo "[ERROR] Se necesita openssl y curl."
    exit 1
fi

if [[ ! -f "$CA_CERT" ]]; then
    echo "[ERROR] No se encuentra el certificado: $CA_CERT"
    exit 1
fi

echo "============================================================"
echo "MF0489 - Fase 4 - Anexo C"
echo "Dominio: $DOMINIO"
echo "IP del servidor: $IP_SERVIDOR"
echo "CA: $CA_CERT"
echo "============================================================"
echo

# 1. Comprobar versiones TLS
for v in tls1_2 tls1_3 tls1_1; do
    echo "== ${v} =="

    openssl s_client \
        -connect "${IP_SERVIDOR}:443" \
        -servername "$DOMINIO" \
        -CAfile "$CA_CERT" \
        -verify_hostname "$DOMINIO" \
        -verify_return_error \
        "-${v}" \
        -brief \
        </dev/null 2>&1 |
        grep -Ei 'Protocol version|Ciphersuite|Verification|Verified peername|alert|error|refused|unsupported protocol' \
        || true

    echo
done

# 2. Comprobar redirección HTTP a HTTPS
echo "== HTTP -> HTTPS =="

if ! curl -sSI --connect-timeout 5 \
    --resolve "${DOMINIO}:80:${IP_SERVIDOR}" \
    "http://${DOMINIO}/"; then
    echo "[ERROR] No se pudo completar la petición HTTP."
else
    curl -sSI --connect-timeout 5 \
        --resolve "${DOMINIO}:80:${IP_SERVIDOR}" \
        "http://${DOMINIO}/" |
        grep -Ei '^(HTTP|location)' || true
fi

echo

# 3. Comprobar HTTPS validando el certificado
echo "== HTTPS con verificación =="

curl -sSI --connect-timeout 5 \
    --cacert "$CA_CERT" \
    --resolve "${DOMINIO}:443:${IP_SERVIDOR}" \
    "https://${DOMINIO}/" |
    head -n 1

echo
echo "============================================================"
echo "Fin de las comprobaciones del Anexo C"
echo "============================================================"
