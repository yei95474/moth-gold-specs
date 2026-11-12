# 16 — Engineering Principles

**Purpose:** Capture the core rules that explain the rest of the skill set and remain true even before implementation exists.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Principles

1. Trust the code over any document, including this one.
2. Shared contracts must have a single source of truth.
3. Changes that affect multiple repositories must be planned and validated together.
4. Failures are evidence; write down the why and the fix.
5. Prefer explicit, readable code over clever shortcuts.
6. Security and correctness are non-negotiable; performance is a later optimization.

## Reasoning

The Moth Gold ecosystem is intentionally split across repositories. This makes shared contracts and boundary definitions more important than in a single app. Without a clear source of truth, drift and silent breakage become the default failure mode.

## Source story

The current workspace contains Git metadata without application source, so this file is intentionally conservative. Once real code is checked in, the principles should be expanded with verified engineering lessons from code and incidents.

Trust the code over any document, including this one.
