# 07 — Database

**Purpose:** Define the expected data-layer conventions and migration discipline for the Moth Gold ecosystem.

**Confidence note:** verified against the empty application repositories on 2026-11-12; baseline schema added 2026-11-19 (`db-schema/v1.0.0.sql`). The code wins (see 16).

## Current verified state

The MVP baseline is checked in at `moth-gold-specs/db-schema/v1.0.0.sql`, with the design rationale in `moth-gold-specs/db-design-choices.md`. The application repos are still empty, so runtime access patterns remain unverified.

| Area | Tables in v1.0.0 |
|---|---|
| Identity & onboarding | `account`, `credential`, `consent`, `policy`, `policy_acceptance`, `pilot_area`, `staff_role_assignment` |
| Configuration | `category`, `setting`, `backup_run`, `account_deletion_request` |
| Listings | `photo`, `offer`, `request`, `request_reply` |
| Inbox & trust | `conversation`, `message`, `exchange`, `exchange_confirmation`, `review` |
| Moderation | `report`, `moderation_action`, `account_block` |

## Principles

- One schema change should have one migration story.
- `*_uuid` columns are the foreign keys on local and server; the server-only `id` is only a primary-key index (see `db-design-choices.md` §2–3).
- Schema file versions follow `db-design-choices.md` §10: patch = forward migration, minor = full Supabase snapshot.
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

Schema files are additive and idempotent; read the header of `db-schema/v1.0.0.sql` before changing any table.
