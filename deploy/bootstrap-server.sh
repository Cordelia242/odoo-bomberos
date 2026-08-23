#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-/opt/odoo-bomberos}"
command -v docker >/dev/null || { echo "Docker is required" >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required" >&2; exit 1; }

sudo mkdir -p "$TARGET"
sudo chown "$(id -u):$(id -g)" "$TARGET"
mkdir -p "$TARGET/backups" "$TARGET/runtime"

if [[ ! -f "$TARGET/.env" ]]; then
  cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env.server.example" "$TARGET/.env"
  chmod 600 "$TARGET/.env"
fi

cat <<EOF
Prepared: $TARGET
1. Edit $TARGET/.env
2. If GHCR is private, login once:
   echo '<PAT_WITH_READ_PACKAGES>' | docker login ghcr.io -u '<github-user>' --password-stdin
3. Configure GitHub secrets:
   SERVER_HOST, SERVER_PORT, SERVER_USER, SERVER_SSH_KEY, SERVER_KNOWN_HOSTS
EOF
