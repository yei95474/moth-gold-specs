# 11 — Testing

**Purpose:** Define the expected test strategy for a multi-repository product before the first source tree exists.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No test suites, test runners, or application logic are present. This is a placeholder standard and should become concrete when the codebase exists.

## Expectations

- Unit tests should cover critical business logic and validation.
- Integration tests should validate API contracts and persistence boundaries.
- Frontend tests should cover interaction flows and error states.
- Mobile tests should cover critical screens and auth flows.

## Minimum safe regression set

- API happy path and validation failure path
- Auth success and rejection path
- Schema migration or create/update path
- Critical user flow in web and Android

## Mocking guidance

- Mock at the service boundary, not inside the domain logic.
- Keep fixtures realistic and close to production payloads.
- Assert on behavior, not implementation details.

This file should be replaced with repository-specific test instructions as soon as implementation is committed.
