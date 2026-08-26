from pathlib import Path
import ast
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "bomberos_hr"


def test_bomberos_hr_manifest_depends_on_hr_and_loads_views():
    manifest = ast.literal_eval((ADDON / "__manifest__.py").read_text())
    assert "hr" in manifest["depends"]
    assert manifest["installable"] is True
    assert "views/hr_employee_views.xml" in manifest["data"]
    assert "views/hr_department_views.xml" in manifest["data"]


def test_employee_customization_renames_volunteers_and_hides_noise():
    path = ADDON / "views" / "hr_employee_views.xml"
    root = ET.parse(path).getroot()
    xml = ET.tostring(root, encoding="unicode")

    assert "Voluntarios" in xml
    assert "Voluntario" in xml
    assert "hr.view_employee_form" in xml
    assert "hr.view_employee_tree" in xml
    assert 'page[@name=\'payroll_information\']' in xml
    assert 'page[@name=\'hr_settings\']' in xml
    assert "many2many_tags_salary_bank" not in xml
    assert "Contacto personal" in xml
    assert "visa_no" in xml


def test_employee_customization_keeps_family_information_visible():
    path = ADDON / "views" / "hr_employee_views.xml"
    root = ET.parse(path).getroot()
    xml = ET.tostring(root, encoding="unicode")

    assert "hr_family_group" not in xml


def test_inherited_views_do_not_select_nodes_by_string_attribute():
    for path in (ADDON / "views").glob("*.xml"):
        root = ET.parse(path).getroot()
        for xpath in root.findall(".//xpath"):
            expr = xpath.attrib.get("expr", "")
            assert "@string" not in expr, f"{path}: invalid inherited-view selector: {expr}"


def test_department_customization_uses_sections_language():
    path = ADDON / "views" / "hr_department_views.xml"
    root = ET.parse(path).getroot()
    xml = ET.tostring(root, encoding="unicode")

    assert "Secciones" in xml
    assert "Sección" in xml
    assert "hr.view_department_form" in xml
    assert "hr.view_department_filter" in xml


def test_spanish_vocabulary_overrides_employee_and_department_terms():
    for language in ("es", "es_BO"):
        po = (ADDON / "i18n" / f"{language}.po").read_text()
        assert "Voluntarios" in po
        assert "Secciones" in po
        assert "Directorio" in po


def test_employee_form_replaces_corporate_labels_and_examples():
    xml = (ADDON / "views" / "hr_employee_views.xml").read_text()
    assert "DATOS INSTITUCIONALES" in xml
    assert "Teléfono institucional" in xml
    assert "Celular institucional" in xml
    assert "Nombre del cargo / función" in xml
    assert "Gerente de ventas" not in xml
    assert "Fundador" not in xml


def test_user_facing_documentation_exists():
    doc = (ROOT / "docs" / "bomberos_hr.md").read_text()
    assert "bomberos_hr" in doc
    assert "hr.employee" in doc
    assert "Voluntarios" in doc
    assert "datos familiares" in doc.lower()
    assert "no modifica el core" in doc.lower()
