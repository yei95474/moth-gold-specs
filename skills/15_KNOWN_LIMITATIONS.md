# 15 — Known Limitations

**Purpose:** Record the gaps and assumptions that are known to be unverified until real code exists.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Ranked known limitations

1. There are no checked-in source files, so the architecture is unverified.
2. There are no environment manifests, build scripts, or runtime dependencies to validate.
3. There are no authentic API contracts, feature flags, or data models yet.
4. The actual deployment pipeline and hosting model are unknown.

## Design candidates to revisit

- Consolidated shared contract repo versus per-repo contract duplication
- API-first design with client-generated models versus server-owned domain contracts
- Single-codebase monorepo versus polyrepo setup for the ecosystem

This file should become a living list of proven limitations as soon as code is present.
