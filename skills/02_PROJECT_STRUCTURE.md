# 02 — Project Structure

**Purpose:** Describe the intended repository layout and naming conventions for new code in the Moth Gold ecosystem.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

There is no checked-in application code, so this file defines the expected layout for when real implementations are added. It is intentionally conservative.

## Repository layout

```text
moth-gold-ecosystem/
├── AGENTS.md
├── handoff.md
├── moth-gold-specs/
│   ├── AGENTS.md
│   ├── git-guidelines.md
│   └── skills/
│       ├── 00_INDEX.md
│       ├── INBOX.md
│       └── NN_TOPIC.md files
├── moth-gold-api/
│   └── source tree added by the backend team
├── moth-gold-web/
│   └── source tree added by the frontend team
└── moth-gold-android/
    └── source tree added by the mobile team
```

## Naming conventions

- Use descriptive folder names for domains, not technical labels alone.
- Keep the API, web, and mobile repos isolated by responsibility.
- Keep shared contracts in `moth-gold-specs` rather than duplicating them inside each app.
- Prefer feature names over generic folders such as `misc` or `shared` unless the code is truly cross-cutting.

## What lives where

- `moth-gold-api`: server routes, domain logic, persistence models, background jobs, validators, and auth middleware.
- `moth-gold-web`: page routes, components, hooks, state, and browser-specific logic.
- `moth-gold-android`: screens, view models, adapters, native services, and platform integration code.
- `moth-gold-specs`: schemas, contracts, and engineering guidance that the apps share.

## What must not go here

- Do not duplicate product contracts across multiple repositories without a single source of truth.
- Do not add application logic to the specs repo except for shared schema and workflow definitions.
- Do not create arbitrary root-level app code outside the repository boundaries.

This structure should be refreshed once the real source tree exists and can be verified against the code.
