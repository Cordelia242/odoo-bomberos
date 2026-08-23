# Odoo Bomberos Deployment Design

## Goal
Deploy Odoo Community 19 to a privately managed Linux server with frequent custom-addon development while keeping production deterministic.

## Decisions
- One monorepo contains addons, Docker definition, deployment scripts, tests, and Actions.
- Production never pulls addon source from Git.
- Addons are embedded in an SHA-tagged production image published to GHCR.
- GitHub Actions deploys over verified SSH.
- PostgreSQL and the Odoo filestore remain persistent volumes.
- Server-only secrets live in `/opt/odoo-bomberos/.env`.
- Existing databases are backed up before migrations.
- New addon manifests trigger `-i`; changed existing addons trigger `-u`.
- Odoo binds to loopback behind a reverse proxy.
