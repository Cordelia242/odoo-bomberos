#!/usr/bin/env bash
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${DEPLOY_DIR}/.env"
[[ -f "$ENV_FILE" ]] || { echo "Missing ${ENV_FILE}" >&2; exit 1; }

set -a
source "$ENV_FILE"
set +a

: "${ODOO_IMAGE:?ODOO_IMAGE must be provided by the workflow}"
: "${POSTGRES_USER:?required}"
: "${POSTGRES_PASSWORD:?required}"
: "${ODOO_DB:?required}"

INSTALL_MODULES="${INSTALL_MODULES:-}"
UPDATE_MODULES="${UPDATE_MODULES:-}"
COMPOSE=(docker compose --env-file "$ENV_FILE" -f "${DEPLOY_DIR}/compose.prod.yml")

"${DEPLOY_DIR}/render-config.sh"
"${COMPOSE[@]}" pull
"${COMPOSE[@]}" up -d db

DB_EXISTS="$("${COMPOSE[@]}" exec -T db psql -U "$POSTGRES_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='${ODOO_DB}'" | tr -d '[:space:]')"

if [[ "$DB_EXISTS" != "1" ]]; then
  "${COMPOSE[@]}" run --rm odoo \
    odoo -d "$ODOO_DB" -i base --without-demo=all --stop-after-init
else
  "${DEPLOY_DIR}/backup.sh"
fi

if [[ -n "$INSTALL_MODULES" ]]; then
  "${COMPOSE[@]}" run --rm odoo \
    odoo -d "$ODOO_DB" -i "$INSTALL_MODULES" --without-demo=all --stop-after-init
fi

if [[ -n "$UPDATE_MODULES" ]]; then
  "${COMPOSE[@]}" run --rm odoo \
    odoo -d "$ODOO_DB" -u "$UPDATE_MODULES" --stop-after-init
fi

"${COMPOSE[@]}" up -d --remove-orphans odoo

for _ in $(seq 1 40); do
  CID="$("${COMPOSE[@]}" ps -q odoo)"
  STATUS="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$CID" 2>/dev/null || true)"
  [[ "$STATUS" == "healthy" ]] && { echo "Deployment healthy: ${ODOO_IMAGE}"; exit 0; }
  if [[ "$STATUS" == "unhealthy" ]]; then
    "${COMPOSE[@]}" logs --tail=200 odoo >&2
    exit 1
  fi
  sleep 5
done

"${COMPOSE[@]}" logs --tail=200 odoo >&2
echo "Timed out waiting for Odoo healthcheck." >&2
exit 1
