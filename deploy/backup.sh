#!/usr/bin/env bash
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${BACKUP_ROOT:-${DEPLOY_DIR}/backups}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET="${BACKUP_ROOT}/${STAMP}"
COMPOSE=(docker compose --env-file "${DEPLOY_DIR}/.env" -f "${DEPLOY_DIR}/compose.prod.yml")
mkdir -p "$TARGET"

"${COMPOSE[@]}" exec -T db pg_dump -U "${POSTGRES_USER}" -Fc "${ODOO_DB}" > "${TARGET}/database.dump"

VOLUME_KEY="$("${COMPOSE[@]}" config --volumes | grep 'odoo-data' | head -n1)"
PROJECT="${COMPOSE_PROJECT_NAME:-odoo-bomberos}"
docker run --rm \
  -v "${PROJECT}_${VOLUME_KEY}:/source:ro" \
  -v "${TARGET}:/backup" \
  alpine:3.22 sh -c 'cd /source && tar czf /backup/filestore.tar.gz .'

printf '%s\n' "${ODOO_IMAGE:-unknown}" > "${TARGET}/image.txt"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d \
  -mtime "+${BACKUP_RETENTION_DAYS:-14}" -exec rm -rf {} +
echo "Backup created: ${TARGET}"
