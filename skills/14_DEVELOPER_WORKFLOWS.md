# 14 — Developer Workflows

**Purpose:** Capture how contributors should walk through setup and common tasks as the project comes online.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No setup scripts, build files, or runtime workflow artifacts exist yet. This is intentionally a bootstrap workflow document.

## Setup checklist

1. Clone the repository or submodule set.
2. Validate that each app repo has its expected tooling installed.
3. Confirm env vars and local secrets are loaded before running the stack.
4. Run the smallest smoke test for the changed repo.

## Common recipes

- Update shared contract in `moth-gold-specs`
- Implement server change in `moth-gold-api`
- Update client parsing in `moth-gold-web` and `moth-gold-android`
- Validate migration and auth paths before merge

## Workflow rule

Do not change the shared contract without updating the consumers that depend on it.

Add what surprised you to `INBOX.md`.
