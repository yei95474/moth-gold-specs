# 01 — Architecture

**Purpose:** A one-paragraph model of the system and how ownership is expected to be split when the application code appears.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No source tree or application code is present in this workspace. The repositories are empty placeholders with Git metadata only. This document therefore acts as a bootstrap architecture note: it describes how the ecosystem should be organized once the application code is checked in.

## System model

The Moth Gold ecosystem is intended to be a multi-repository product with a shared specification layer (`moth-gold-specs`), an API backend (`moth-gold-api`), a web frontend (`moth-gold-web`), and an Android app (`moth-gold-android`). In the expected shape, each repository owns its domain boundary, while the specs repository records the shared contracts, schemas, and developer standards.

## Ownership boundaries

1. `moth-gold-api` owns business logic, persistence, external integrations, auth, and server-side validation.
2. `moth-gold-web` owns user-facing views, client-side state, and browser orchestration.
3. `moth-gold-android` owns mobile state, native UI, and OS-specific integrations.
4. `moth-gold-specs` owns contract definitions, schema snapshots, developer workflow rules, and shared product documentation.

## Data flow

Requests flow from the mobile or web clients into the API, where validation and domain logic decide whether data is persisted or rejected. The API then returns a normalized response envelope so product clients can handle errors consistently.

## Decision records

- Decision records should live in the specs documentation set once real product decisions are made.
- Until then, architecture is intentionally lightweight and should be refilled only when code proves a pattern.

## Ranked debt register

1. No application code exists yet, so the architecture is unverified.
2. Repo boundaries lack runtime evidence until implementation exists.
3. Contracts, schemas, and IDs have not been defined yet.

This file should be replaced with a real architecture document as soon as the first application implementation is committed.
