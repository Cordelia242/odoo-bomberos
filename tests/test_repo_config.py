from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]


def test_production_compose_has_no_addon_bind_mount_or_local_database():
    compose = yaml.safe_load((ROOT / "deploy/compose.prod.yml").read_text())
    assert set(compose["services"]) == {"odoo"}

    odoo = compose["services"]["odoo"]
    assert odoo["image"] == "${ODOO_IMAGE:?ODOO_IMAGE must be set}"
    assert odoo["environment"]["HOST"] == "${POSTGRES_HOST:?POSTGRES_HOST must be set}"
    volumes = "\n".join(odoo.get("volumes", []))
    assert "/mnt/extra-addons" not in volumes
    assert "./addons" not in volumes

    assert compose["networks"]["home-network"]["external"] is True


def test_dockerfile_embeds_addons_and_pins_odoo():
    dockerfile = (ROOT / "docker/Dockerfile").read_text()
    assert "COPY --chown=odoo:odoo addons/ /opt/odoo/custom-addons/" in dockerfile
    assert "odoo:19.0-20260817" in dockerfile


def test_workflow_uses_sha_tag_and_self_hosted_deploy_without_ssh():
    workflow = (ROOT / ".github/workflows/deploy-production.yml").read_text()
    assert "sha-${GITHUB_SHA}" in workflow
    assert "docker/build-push-action@v7" in workflow
    assert "docker/login-action@v4" in workflow
    assert "packages: write" in workflow
    assert "runs-on: [self-hosted, linux, x64, odoo-bomberos]" in workflow
    assert "Configure SSH" not in workflow
    assert "SERVER_SSH_KEY" not in workflow
    assert "SERVER_HOST" not in workflow
    assert "ssh -p" not in workflow


def test_external_database_scripts_do_not_reference_compose_db_service():
    deploy = (ROOT / "deploy/deploy.sh").read_text()
    backup = (ROOT / "deploy/backup.sh").read_text()

    assert "up -d db" not in deploy
    assert "exec -T db" not in deploy
    assert "exec -T db" not in backup
    assert "POSTGRES_HOST" in deploy
    assert "POSTGRES_HOST" in backup
