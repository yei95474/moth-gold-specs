# 10 — Deployment

**Purpose:** Capture the expected deployment sequence and release hygiene for the product ecosystem.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No deployable artifacts, release pipeline, or environment configuration are present. This document acts as a bootstrap deployment checklist.

## Release order

1. Shared specs and contract changes
2. API changes with schema/migration validation
3. Web rollout after API compatibility checks
4. Android rollout after API and web smoke tests
5. Operational verification with logs and error tracking

## Deployment checklist

- Confirm all required env vars are present and named consistently.
- Confirm migrations have been validated against staging data.
- Confirm the release tag or build version is recorded.
- Confirm rollback steps are understood before deployment starts.

## Release hygiene

- Use version tags for each deployable component.
- Keep the changelog tied to the source commit or release artifact.
- Verify the release against a smoke test before wider rollout.

This file should be updated with real process details once the actual deployment paths are in code.
