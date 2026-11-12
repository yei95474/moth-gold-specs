# 07 — Database

**Purpose:** Define the expected data-layer conventions and migration discipline for the Moth Gold ecosystem.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No database schema or migrations exist in the workspace. This is a placeholder to be replaced by a real schema map as soon as the API repository includes persistence work.

## Principles

- One schema change should have one migration story.
- Every persisted field should have an owner and an expected lifecycle.
- Avoid silent data-loss paths, especially soft-delete or hard-delete handling.
- Use constraints and indexes to protect correctness, not just performance.

## Database safety checklist

- Confirm migration ordering and rollback plan
- Confirm reference integrity with foreign keys or equivalent rules
- Confirm all reads and writes are covered by tests
- Confirm staging validation before production rollout

## Dangerous operations

- Dropping or renaming columns without a compatibility plan
- Applying destructive deletes without a retention review
- Changing identity semantics in place

This document will become concrete when the first data model and migration files exist.
