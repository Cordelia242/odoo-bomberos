# Odoo Bomberos

Monorepo para desplegar Odoo Community 19 en un servidor propio usando Docker, GHCR y GitHub Actions.

## Modelo

**Desarrollo:** addons montados como volumen para iterar rápido.

**Producción:** addons incluidos dentro de una imagen Docker inmutable. Producción nunca hace `git pull`.

Cada push a `main` publica:

```text
ghcr.io/<owner>/odoo-bomberos:sha-<commit>
```

El workflow se conecta por SSH, crea backup si la base ya existe, instala módulos nuevos, actualiza módulos modificados, levanta la imagen exacta y espera su healthcheck.

## Estructura

```text
.github/workflows/       CI y deploy
addons/                  addons propios/terceros
docker/Dockerfile        imagen de producción
deploy/                  compose y scripts del servidor
scripts/                 validación/detección de módulos
tests/                   pruebas del repo
```

## Servidor

Requisitos: Linux, Docker Engine, Docker Compose v2 y un usuario SSH con acceso a Docker.

Primera preparación:

```bash
./deploy/bootstrap-server.sh /opt/odoo-bomberos
nano /opt/odoo-bomberos/.env
```

Si GHCR es privado, autentica Docker una sola vez en el servidor con un PAT que tenga `read:packages`:

```bash
echo '<PAT>' | docker login ghcr.io -u '<github-user>' --password-stdin
```

## GitHub Secrets

Configura, idealmente en el environment `production`:

- `SERVER_HOST`
- `SERVER_PORT`
- `SERVER_USER`
- `SERVER_SSH_KEY`
- `SERVER_KNOWN_HOSTS`

Obtén `SERVER_KNOWN_HOSTS` con `ssh-keyscan`, pero verifica la huella por un canal independiente antes de guardarla.

## Addons

Cada addon debe estar directamente bajo `addons/`:

```text
addons/
├── bomberos_base/
│   ├── __init__.py
│   └── __manifest__.py
├── bomberos_personal/
└── bomberos_vehiculos/
```

En un push a `main`, los módulos cuyo `__manifest__.py` aparece por primera vez se pasan a `-i`; los módulos existentes con cambios se pasan a `-u`.

También puedes ejecutar manualmente el workflow `Deploy production` y forzar `install_modules` o `update_modules`.

## Persistencia y backups

Persisten fuera de la imagen:

- PostgreSQL
- `/var/lib/odoo`

Antes de migrar una base existente se guarda:

```text
/opt/odoo-bomberos/backups/<timestamp>/
├── database.dump
├── filestore.tar.gz
└── image.txt
```

Retención por defecto: 14 días.

Un rollback de imagen no revierte una migración de base de datos; para un rollback completo hay que restaurar también DB y filestore.

## Red

Odoo se publica solo en:

```text
127.0.0.1:8069
```

Pon Caddy, Traefik, Nginx o tu proxy habitual delante. `proxy_mode=True` ya está configurado.

## Versiones fijadas

- Odoo `19.0-20260817`
- PostgreSQL `17.11-bookworm`

Actualízalas por PR; no uses `latest`.
