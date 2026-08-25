# Odoo Bomberos

Monorepo para desplegar Odoo Community 19 en un servidor propio usando Docker, GHCR y GitHub Actions.

## Modelo

**Desarrollo:** addons montados como volumen para iterar rápido.

**Producción:** addons incluidos dentro de una imagen Docker inmutable. Producción nunca hace `git pull`.

Cada push a `main` publica:

```text
ghcr.io/<owner>/odoo-bomberos:sha-<commit>
```

El build se ejecuta en un runner hospedado por GitHub. El despliegue se ejecuta en un **GitHub Actions self-hosted runner dentro de la red local del servidor**, por lo que no es necesario exponer SSH ni ningún puerto de administración a Internet.

## Arquitectura

```text
GitHub
  |
  | HTTPS saliente
  v
self-hosted runner en tu servidor
  |
  +--> docker pull de GHCR
  +--> backup
  +--> actualización de módulos
  +--> docker compose up

Odoo ---- home-network ---- PostgreSQL existente
```

## Base de datos

Este repositorio **no despliega PostgreSQL**. Odoo se conecta a tu PostgreSQL existente mediante la red Docker externa:

```text
home-network
```

Configura en `/opt/odoo-bomberos/.env`:

```dotenv
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=odoo
POSTGRES_PASSWORD=tu_password
ODOO_DB=bomberos
```

`POSTGRES_HOST` debe ser el nombre del contenedor, alias DNS o hostname con el que PostgreSQL es accesible desde `home-network`.

El deploy usa un contenedor temporal `postgres:17.11-bookworm` únicamente como cliente para `pg_isready`, `psql`, `createdb` y `pg_dump`. No crea un servidor PostgreSQL adicional.

## Preparar el servidor

Requisitos:

- Linux
- Docker Engine
- Docker Compose v2
- `home-network` ya creada
- PostgreSQL existente accesible desde esa red
- usuario del runner con permiso para ejecutar Docker sin `sudo`

Prepara la carpeta:

```bash
./deploy/bootstrap-server.sh /opt/odoo-bomberos
nano /opt/odoo-bomberos/.env
```

## Instalar el self-hosted runner

En GitHub entra a:

```text
Repositorio -> Settings -> Actions -> Runners -> New self-hosted runner
```

Selecciona Linux x64 y ejecuta en tu servidor los comandos que GitHub te muestre.

Cuando ejecutes `config.sh`, añade la etiqueta específica del proyecto:

```bash
./config.sh --url https://github.com/Cordelia242/odoo-bomberos --token <TOKEN_TEMPORAL> --labels odoo-bomberos
```

Después instálalo como servicio usando los comandos que GitHub muestra para Linux, normalmente:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

Comprueba en GitHub que aparezca como `Idle` y con la etiqueta `odoo-bomberos`.

## GitHub Secrets

Para el despliegue ya **no se necesitan**:

- `SERVER_HOST`
- `SERVER_PORT`
- `SERVER_USER`
- `SERVER_SSH_KEY`
- `SERVER_KNOWN_HOSTS`

El job del self-hosted runner se autentica temporalmente en GHCR con `GITHUB_TOKEN`.

Las credenciales de Odoo y PostgreSQL siguen viviendo solamente en:

```text
/opt/odoo-bomberos/.env
```

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

El repositorio solo administra la persistencia de Odoo en `/var/lib/odoo`. PostgreSQL pertenece a tu infraestructura externa.

Antes de migrar una base existente se guarda:

```text
/opt/odoo-bomberos/backups/<timestamp>/
├── database.dump
├── filestore.tar.gz
└── image.txt
```

El `database.dump` se obtiene conectándose al PostgreSQL externo por `home-network`.

Retención por defecto: 14 días.

Un rollback de imagen no revierte una migración de base de datos; para un rollback completo hay que restaurar también la DB y el filestore.

## Red

Odoo se publica solo en:

```text
127.0.0.1:8069
```

Pon Caddy, Traefik, Nginx o tu proxy habitual delante. `proxy_mode=True` ya está configurado.

## Versiones fijadas

- Odoo `19.0-20260817`
- Cliente PostgreSQL para mantenimiento/backups: `postgres:17.11-bookworm`

No uses `latest`; actualiza las versiones mediante un PR.
