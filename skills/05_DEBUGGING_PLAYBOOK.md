# 05 — Debugging Playbook

**Purpose:** Capture the expected investigation flow and common failure patterns when the system is implemented.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

There are no logs, tracing systems, or runtime services checked in yet. This is a placeholder playbook for the first operational implementation.

## Investigation order

1. Reproduce the symptom under the same request path or user flow.
2. Check the exact API request and response envelopes.
3. Confirm whether the failure is backend, frontend, or mobile-specific.
4. Check environment variables, feature flags, and migrations.
5. Trace the narrowest failing interaction before broadening the search.

## Common failure classes

- Authentication/authorization mismatch
- Null or missing fields after a schema change
- Retry loops that hide payload errors
- Browser or Android caches holding stale data
- Migration drift between environments

## Useful commands

```bash
# Example repo-level checks once code exists
git status

git log --oneline --decorate -n 20

# API smoke testing pattern
git -C moth-gold-api status

git -C moth-gold-web status

git -C moth-gold-android status
```

## Rule

Do not debug by guessing from symptoms alone; reconstruct the exact failing path and validate one hypothesis at a time.

This playbook should be replaced by a concrete app-level guide when runtime logs and services are available.
