ARG ODOO_BASE_IMAGE=odoo:19.0-20260817
FROM ${ODOO_BASE_IMAGE}

USER root
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ]; then \
      pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt; \
    fi

# /mnt/extra-addons is a VOLUME in the official image; production code is
# embedded elsewhere so the image remains self-contained and immutable.
COPY --chown=odoo:odoo addons/ /opt/odoo/custom-addons/
USER odoo
