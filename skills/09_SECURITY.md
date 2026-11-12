# 09 — Security

**Purpose:** Define the expected security boundary and change checklist for the Moth Gold product as implementation appears.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No security controls or app code are present. This is a placeholder with the expected practices to adopt when the product becomes runnable.

## Threat model

- Protect all authenticated endpoints behind explicit authorization checks.
- Treat environment variables as secrets and never hard-code them in source.
- Validate all inbound parameters before using them in queries, commands, or business logic.
- Ensure errors do not leak stack traces or internal implementation details to clients.

## Auth and authz layers

- Authn checks should happen at the edge and before business logic.
- Authz should be route-specific and explicit.
- Shared permission logic should live in one place, not be copied across clients.

## Secrets handling

- Keep secrets in environment configuration, platform secret stores, or deployment-managed secret files.
- Never commit real credentials or tokens.
- Require secret rotation and least-privilege access for any service account.

## Change checklist

- Confirm the route requires the correct auth level.
- Confirm validation rejects malformed input.
- Confirm error details are sanitized.
- Confirm logs do not expose secrets or sensitive identifiers.
- Confirm a security test or regression check is added.

This document should be strengthened with specific implementation evidence once the API and clients exist.
