#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${DEPLOY_DIR}/.env"
[[ -f "$ENV_FILE" ]] || { echo "Missing ${ENV_FILE}" >&2; exit 1; }

set -a
source "$ENV_FILE"
set +a

: "${ODOO_IMAGE:?ODOO_IMAGE must be provided by the workflow}"
: "${POSTGRES_HOST:?required}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
: "${POSTGRES_USER:?required}"
: "${POSTGRES_PASSWORD:?required}"
: "${ODOO_DB:?required}"

INSTALL_MODULES="${INSTALL_MODULES:-}"
UPDATE_MODULES="${UPDATE_MODULES:-}"
POSTGRES_CLIENT_IMAGE="${POSTGRES_CLIENT_IMAGE:-postgres:17.11-bookworm}"
POSTGRES_DOCKER_NETWORK="${POSTGRES_DOCKER_NETWORK:-home-network}"
COMPOSE=(docker compose --env-file "$ENV_FILE" -f "${DEPLOY_DIR}/compose.prod.yml")

pg_client() {
  docker run --rm \
    --network "$POSTGRES_DOCKER_NETWORK" \
    -e PGPASSWORD="$POSTGRES_PASSWORD" \
    "$POSTGRES_CLIENT_IMAGE" "$@"
}

"${DEPLOY_DIR}/render-config.sh"
"${COMPOSE[@]}" pull

# Verify the external PostgreSQL endpoint is reachable before changing Odoo.
pg_client pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres

DB_EXISTS="$(pg_client psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='${ODOO_DB}'" | tr -d '[:space:]')"

if [[ "$DB_EXISTS" != "1" ]]; then
  echo "Database ${ODOO_DB} does not exist; creating it on external PostgreSQL."
  pg_client createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$ODOO_DB"
else
  "${DEPLOY_DIR}/backup.sh"
fi

# A PostgreSQL database can exist without having been initialized by Odoo.
# Detect the core Odoo table instead of treating database existence as enough.
ODOO_INITIALIZED="$(pg_client psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$ODOO_DB" -tAc \
  "SELECT CASE WHEN to_regclass('public.ir_module_module') IS NOT NULL THEN 1 ELSE 0 END" | tr -d '[:space:]')"

if [[ "$ODOO_INITIALIZED" != "1" ]]; then
  echo "Database ${ODOO_DB} exists but is not initialized by Odoo; installing base."
  "${COMPOSE[@]}" run --rm odoo \
    odoo -d "$ODOO_DB" -i base --without-demo=all --stop-after-init
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
