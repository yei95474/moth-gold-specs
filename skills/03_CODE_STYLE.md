# 03 — Code Style

**Purpose:** Describe the project standards for formatting, naming, comments, and safe coding patterns before implementation exists.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current verified state

There is no source code to lint or format yet. This is a placeholder standard that should be replaced with repository-specific rules as soon as the first project languages and tooling are present.

## Preferred principles

1. Favor explicit names over clever ones. A new engineer should understand the purpose of a symbol without reading the whole file.
2. Comment the why, not the what. If a line of code is obvious, it does not need a comment.
3. Fail loudly and early. Validate inputs and guard against ambiguous states before they propagate.
4. Prefer small, testable units over giant abstractions.

## Expected repository-specific rules

- Keep each repository's language conventions consistent with its stack (for example, TypeScript/React conventions in web, Kotlin/Jetpack conventions in Android, and backend conventions in the API service).
- Preserve commit readability by matching the repo's formatting and linting configuration rather than using ad hoc formatting.
- Treat comments as a risk signal, not decoration. If a workaround exists, explain the cause and the expected end state.

## Anti-patterns to avoid

- Hidden state without a clear owner
- Unbounded `any` / loose dynamic types where a schema or domain type exists
- Silent catch-and-continue branches that hide real failures
- Copy-pasted validation logic across repositories

## Commit conventions

Follow the commit message standard in `moth-gold-specs/git-guidelines.md` once the project becomes active. Keep scope names aligned with product and subsystem names rather than generic labels.

This document should be updated in the first code change that introduces a real language/tooling baseline.
