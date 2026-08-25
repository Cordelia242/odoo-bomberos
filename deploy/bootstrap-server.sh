#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-/opt/odoo-bomberos}"
RUNNER_USER="${2:-$USER}"

command -v docker >/dev/null || { echo "Docker is required" >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required" >&2; exit 1; }

echo "Preparing $TARGET for GitHub self-hosted runner user: $RUNNER_USER"
sudo mkdir -p "$TARGET/backups" "$TARGET/runtime"
sudo chown -R "$RUNNER_USER":"$RUNNER_USER" "$TARGET"

if [[ ! -f "$TARGET/.env" ]]; then
  cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env.server.example" "$TARGET/.env"
  chmod 600 "$TARGET/.env"
fi

cat <<EOF
Prepared: $TARGET

Next steps:
1. Edit $TARGET/.env and set POSTGRES_HOST to the container/service name of your existing PostgreSQL on home-network.
2. Make sure $RUNNER_USER can run 'docker ps' without sudo.
3. Add this server as a repository self-hosted GitHub Actions runner with label: odoo-bomberos
4. Run the runner as a system service.

No inbound SSH from GitHub and no SERVER_* GitHub secrets are required.
EOF
