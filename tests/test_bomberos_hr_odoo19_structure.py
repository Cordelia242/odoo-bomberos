from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
EMPLOYEE_VIEWS = ROOT / "addons" / "bomberos_hr" / "views" / "hr_employee_views.xml"


def test_visa_block_selector_matches_odoo19_structure():
    root = ET.parse(EMPLOYEE_VIEWS).getroot()
    xpath_exprs = [node.attrib.get("expr", "") for node in root.findall(".//xpath")]

    assert "//page[@name='personal_information']//group[label[@for='visa_no']]" in xpath_exprs
    assert "//page[@name='personal_information']//group[field[@name='visa_no']]" not in xpath_exprs
