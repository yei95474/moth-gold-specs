# 12 — Performance

**Purpose:** Set the guardrails for performance work so the team does not optimize the wrong thing when the product is still empty.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

No runtime profiles, hot paths, or benchmarks exist in the workspace. This file is a placeholder until real usage data is available.

## Principles

- Measure before optimizing.
- Fix the expensive path first.
- Do not trade correctness for small speed gains.
- Keep caches and background jobs explicit and inspectable.

## Typical hotspots to watch

- API database queries
- Large list rendering in web and mobile
- Network retries and payload size
- background sync loops that can stampede a service

## Profiling checklist

- Reproduce under a realistic load.
- Capture a before/after measurement.
- Keep the fix scoped to the bottleneck.
- Retest correctness after optimization.

This file will become implementation-specific once real performance measurements are available.
