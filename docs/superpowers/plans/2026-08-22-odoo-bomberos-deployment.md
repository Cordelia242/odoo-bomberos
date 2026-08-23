# Odoo Bomberos Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible Odoo 19 monorepo deployed through GHCR and SSH.

**Architecture:** GitHub Actions validates and builds an immutable image containing addons, then copies only operational files to the server and runs an explicit backup/migration/start/healthcheck sequence.

**Tech Stack:** Odoo 19, PostgreSQL 17, Docker Compose v2, GitHub Actions, GHCR, Bash, Python.

**Spec:** `docs/superpowers/specs/2026-08-22-odoo-bomberos-deployment-design.md`

## Global Constraints
- No production `git pull`.
- SHA-tagged immutable images.
- Persistent DB and filestore.
- Backup before migrations.
- Verified SSH host keys.
- No committed production secrets.

---

### Task 1: Addon tooling
- [x] Detect new vs modified modules from Git.
- [x] Validate addon manifests.
- [x] Add tests.

### Task 2: Immutable image
- [x] Pin Odoo.
- [x] Embed addons outside `/mnt/extra-addons`.
- [x] Support pinned Python requirements.

### Task 3: Server operations
- [x] Pin PostgreSQL.
- [x] Persist DB/filestore.
- [x] Generate Odoo config from server secrets.
- [x] Backup, initialize/migrate, start and healthcheck.

### Task 4: CI/CD
- [x] Validate on PR/branches.
- [x] Push SHA image to GHCR on main.
- [x] Deploy over SSH.

### Task 5: Documentation
- [x] Document bootstrap, secrets, GHCR, backups and module lifecycle.
