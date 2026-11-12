# 08 — API

**Purpose:** Establish the expected response envelope, route ownership, and change process for the backend contract.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No API source or route definitions exist yet. This is an intentional bootstrap document that prepares the standards for the first backend implementation.

## Expected response envelope

A normalized response envelope should keep client behavior consistent across web and Android. In practice, each response should define status, data, and error metadata in a predictable structure.

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": {
    "requestId": "..."
  }
}
```

## Route inventory

When the API is added, each route should be recorded here with auth requirements, validation rules, and expected side effects.

| Route | Auth | Notes |
|---|---|---|
| `/health` | None | Liveness check |
| `/auth/*` | Required or token-based | Session or identity management |
| `/api/*` | Required | Protected application endpoints |

## How to add an endpoint

1. Define the contract in the specs repository.
2. Add validation rules in the API layer.
3. Match the response envelope exactly.
4. Update consumers in web and Android together.
5. Add integration and regression tests before merging.

## Common mistakes

- Returning raw exceptions to clients
- Inconsistent auth semantics between routes
- Omitting validation or schema enforcement
- Returning different shapes for equivalent errors

This file should be revised once the real API routes and handlers are present.
