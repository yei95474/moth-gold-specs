# 13 — Dependencies

**Purpose:** Preserve a clear dependency policy and upgrade discipline as the product matures.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No dependency manifests or package lock files exist in the workspace. This is a placeholder policy until the platform ecosystems are introduced.

## Policy

- Keep dependency upgrades intentional and reviewable.
- Prefer a single dependency source of truth per repository.
- Treat major-version upgrades as product changes that require validation and documentation.
- Record reasons for any dependency that exists outside the default ecosystem stack.

## Dependency review checklist

- Why is this dependency needed?
- What breakage risk does it add?
- Is there a supported alternative with fewer compatibility risks?
- Does the repo have an upgrade and rollback plan?

## Deliberate rejections

- Unnecessary package proliferation
- Hidden transitive dependencies with weak maintenance history
- Directly vendored code that bypasses the package manager

This file should be replaced with concrete dependency inventories once the actual product repositories contain manifests.
