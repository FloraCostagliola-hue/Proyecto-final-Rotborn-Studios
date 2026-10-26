#!/usr/bin/env bash
# Requiere DOMINIO, IP_SERVIDOR y CA_CERT definidos (ver "Variables").
set -u
: "${DOMINIO:?}" "${IP_SERVIDOR:?}" "${CA_CERT:?}"

echo "== HTTP debe redirigir a HTTPS =="
curl -sI --resolve "${DOMINIO}:80:${IP_SERVIDOR}" "http://${DOMINIO}/" | grep -Ei '^(HTTP|location)'

echo "== HTTPS con CA (debe dar 200) =="
curl -sS -o /dev/null -w '%{http_code}\n' --cacert "$CA_CERT" \
  --resolve "${DOMINIO}:443:${IP_SERVIDOR}" "https://${DOMINIO}/"

echo "== HTTPS sin CA (debe FALLAR con el error 60) =="
curl -sS -o /dev/null --resolve "${DOMINIO}:443:${IP_SERVIDOR}" "https://${DOMINIO}/"
echo "código de curl: $?"

echo "== openssl s_client =="
openssl s_client -connect "${IP_SERVIDOR}:443" -servername "$DOMINIO" \
  -CAfile "$CA_CERT" -verify_hostname "$DOMINIO" -verify_return_error -brief </dev/null 2>&1 \
  | grep -E 'Protocol version|Ciphersuite|Verification|Verified peername'