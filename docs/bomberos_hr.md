# Módulo `bomberos_hr`

## Objetivo

`bomberos_hr` adapta el módulo estándar de Recursos Humanos de Odoo 19 a la gestión de una estación de bomberos voluntarios. El módulo **no modifica el core de Odoo** ni crea un reemplazo incompatible del módulo `hr`.

Internamente se conservan los modelos estándar, principalmente `hr.employee` y `hr.department`. Para el usuario, la aplicación utiliza la terminología **Voluntarios** y **Secciones**.

## Decisiones de arquitectura

- `bomberos_hr` depende de `hr`.
- No se hace un fork de Odoo ni se modifica código dentro de `addons/hr`.
- La personalización se realiza con herencia de vistas y actualización explícita de menús y acciones.
- El modelo sigue siendo `hr.employee`, por lo que otros módulos de Odoo pueden seguir relacionándose con los voluntarios sin adaptadores especiales.
- `hr.department` se conserva internamente y se presenta como **Sección**.
- Las futuras personalizaciones de personal de bomberos deben añadirse a este addon o a addons `bomberos_*` especializados, no al core de Odoo.

## Terminología visible

| Odoo estándar | Odoo Bomberos |
| --- | --- |
| Employee / Employees | Voluntario / Voluntarios |
| Department / Departments | Sección / Secciones |
| Job Position | Cargo |
| Manager | Responsable |
| Work | Institucional |
| Resume | Capacitación y habilidades |

## Simplificación inicial

La primera versión mantiene la información que aporta valor para la estación:

- nombre y fotografía;
- correo y teléfonos;
- estado activo/archivado;
- sección;
- cargo;
- responsable;
- fecha de ingreso;
- datos personales básicos;
- documento de identidad y licencia de conducir disponibles en `hr`;
- dirección personal;
- contacto de emergencia;
- educación;
- notas;
- base de currículum/habilidades para módulos que amplíen esa funcionalidad.

Se ocultan de la experiencia normal los elementos orientados a una empresa tradicional que generan ruido:

- nómina y salario;
- cuentas bancarias y distribución salarial;
- tipos y categorías de contrato;
- fecha de fin de contrato en el listado;
- visas y permisos laborales;
- estado familiar;
- configuración de aplicaciones de RR. HH.;
- horarios laborales desde la ficha del voluntario;
- ubicación/oficina de trabajo;
- planes de onboarding/offboarding desde las vistas principales.

Ocultar estas funciones **no elimina datos ni cambia los modelos de Odoo**. Si otro módulo las necesita en el futuro, siguen existiendo técnicamente y la personalización se puede revisar.

## Estructura

```text
addons/bomberos_hr/
├── __init__.py
├── __manifest__.py
└── views/
    ├── hr_employee_views.xml
    └── hr_department_views.xml
```

## Evolución prevista

Cuando se definan los campos institucionales propios de la estación, `bomberos_hr` podrá extender `hr.employee` con datos como número de voluntario, grado, antigüedad, especialidades, licencias, certificaciones y otros atributos operativos. Esos campos no forman parte de esta primera versión para evitar fijar lógica de negocio antes de definirla.
