#!/usr/bin/env bash
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${DEPLOY_DIR}/runtime"
: "${ODOO_ADMIN_PASSWORD:?required}"
: "${POSTGRES_USER:?required}"
: "${POSTGRES_PASSWORD:?required}"
: "${ODOO_DB:?required}"

for name in ODOO_ADMIN_PASSWORD POSTGRES_USER POSTGRES_PASSWORD ODOO_DB; do
  value="${!name}"
  if [[ ! "$value" =~ ^[A-Za-z0-9._~@%+=:-]+$ ]]; then
    echo "$name contains unsupported characters" >&2
    exit 1
  fi
done

mkdir -p "$RUNTIME_DIR"
umask 077
sed \
  -e "s|__ODOO_ADMIN_PASSWORD__|${ODOO_ADMIN_PASSWORD}|g" \
  -e "s|__POSTGRES_USER__|${POSTGRES_USER}|g" \
  -e "s|__POSTGRES_PASSWORD__|${POSTGRES_PASSWORD}|g" \
  -e "s|__ODOO_DB__|${ODOO_DB}|g" \
  "${DEPLOY_DIR}/odoo.conf.template" > "${RUNTIME_DIR}/odoo.conf"
chmod 600 "${RUNTIME_DIR}/odoo.conf"
