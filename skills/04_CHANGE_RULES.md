# 04 — Change Rules

**Purpose:** Define the project-specific guardrails that protect a multi-repository system from drift and broken contracts.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No application logic exists in the workspace; this file is intentionally a bootstrap set of rules that should become a lockstep inventory once the implementation appears.

## Core rules

1. Keep one source of truth per shared contract. Update specs before partner apps.
2. Update both server and client code together when a request or response shape changes.
3. Treat migrations and schema changes as high-risk work and require a focused regression pass.
4. Validate auth, rate limiting, and error handling in every API contract change.

## Lockstep sets to watch

| Area | Must stay in sync |
|---|---|
| Auth | API routes, frontend requests, Android/native login flows |
| Response formats | API envelope and any client parsing utilities |
| Data model | Database schema, API contracts, and UI model usage |
| Deployment config | env vars, secrets names, and release notes |

## Miss → notes

- Missed API contract update → clients parse stale payloads or reject valid responses.
- Missed schema migration → production writes fail or end users lose data.
- Missed auth rule alignment → mobile or web clients accidentally call unauthorized endpoints.

## High-risk areas

- Any change that touches shared data types
- Any migration that alters a persisted record
- Any change to auth or session handling
- Any endpoint used by both web and Android clients

## Retest checklist

- API contract smoke check
- Browser/mobile happy path
- Error path handling
- Migration validation in a non-production environment

This document becomes authoritative only after source code makes the lockstep sets concrete.
