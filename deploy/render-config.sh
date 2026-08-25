#!/usr/bin/env bash
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${DEPLOY_DIR}/runtime"

: "${ODOO_ADMIN_PASSWORD:?required}"
: "${POSTGRES_HOST:?required}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
: "${POSTGRES_USER:?required}"
: "${POSTGRES_PASSWORD:?required}"
: "${ODOO_DB:?required}"

if [[ ! "$POSTGRES_PORT" =~ ^[0-9]+$ ]]; then
  echo "POSTGRES_PORT must be numeric" >&2
  exit 1
fi

# Secrets may legitimately contain symbols. Escape only the characters that
# have special meaning in the sed replacement expression.
sed_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

ODOO_ADMIN_PASSWORD_ESCAPED="$(sed_escape "$ODOO_ADMIN_PASSWORD")"
POSTGRES_HOST_ESCAPED="$(sed_escape "$POSTGRES_HOST")"
POSTGRES_USER_ESCAPED="$(sed_escape "$POSTGRES_USER")"
POSTGRES_PASSWORD_ESCAPED="$(sed_escape "$POSTGRES_PASSWORD")"
ODOO_DB_ESCAPED="$(sed_escape "$ODOO_DB")"

mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
umask 077
sed \
  -e "s|__ODOO_ADMIN_PASSWORD__|${ODOO_ADMIN_PASSWORD_ESCAPED}|g" \
  -e "s|__POSTGRES_HOST__|${POSTGRES_HOST_ESCAPED}|g" \
  -e "s|__POSTGRES_PORT__|${POSTGRES_PORT}|g" \
  -e "s|__POSTGRES_USER__|${POSTGRES_USER_ESCAPED}|g" \
  -e "s|__POSTGRES_PASSWORD__|${POSTGRES_PASSWORD_ESCAPED}|g" \
  -e "s|__ODOO_DB__|${ODOO_DB_ESCAPED}|g" \
  "${DEPLOY_DIR}/odoo.conf.template" > "${RUNTIME_DIR}/odoo.conf"

# The bind-mounted file must be readable by the non-root `odoo` user inside
# the container. The parent directory remains 0700 on the host so other local
# users cannot traverse to the config file.
chmod 644 "${RUNTIME_DIR}/odoo.conf"
