from pathlib import Path
import yaml
ROOT = Path(__file__).resolve().parents[1]

def test_production_compose_has_no_addon_bind_mount():
    compose = yaml.safe_load((ROOT / "deploy/compose.prod.yml").read_text())
    odoo = compose["services"]["odoo"]
    assert odoo["image"] == "${ODOO_IMAGE:?ODOO_IMAGE must be set}"
    volumes = "\n".join(odoo.get("volumes", []))
    assert "/mnt/extra-addons" not in volumes
    assert "./addons" not in volumes

def test_dockerfile_embeds_addons_and_pins_odoo():
    dockerfile = (ROOT / "docker/Dockerfile").read_text()
    assert "COPY --chown=odoo:odoo addons/ /opt/odoo/custom-addons/" in dockerfile
    assert "odoo:19.0-20260817" in dockerfile

def test_workflow_uses_sha_tag_and_current_actions():
    workflow = (ROOT / ".github/workflows/deploy-production.yml").read_text()
    assert "sha-${GITHUB_SHA}" in workflow
    assert "docker/build-push-action@v7" in workflow
    assert "docker/login-action@v4" in workflow
    assert "packages: write" in workflow
