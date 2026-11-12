# 00 — Index

**Purpose:** Read this first for the intended order of the skill documents and the current verified state of the ecosystem.

**Confidence note:** verified against the empty repository state in `moth-gold-api`, `moth-gold-web`, and `moth-gold-android` on 2026-11-12. The code wins (see 16).

## Current state

At the time of this bootstrap, none of the application repositories contain checked-in source files or commit history beyond Git metadata. This folder is initialized as a working specification scaffold so the team can add real project guidance as code appears.

## Reading order

| Order | Document | Purpose |
|---|---|---|
| 1 | 01_ARCHITECTURE | One-paragraph system model and ownership boundaries |
| 2 | 02_PROJECT_STRUCTURE | Layout, naming, and where new code belongs |
| 3 | 03_CODE_STYLE | Formatting, comments, and code conventions |
| 4 | 04_CHANGE_RULES | Lockstep files, risky areas, and retest expectations |
| 5 | 05_DEBUGGING_PLAYBOOK | Symptom-to-cause playbook and commands |
| 6 | 06_FAILURE_STORIES | Incidents and lessons learned |
| 7 | 07_DATABASE | Schema, migration, and invariants |
| 8 | 08_API | Routing, auth, validation, and error envelope |
| 9 | 09_SECURITY | Threat model, auth, and change checklist |
| 10 | 10_DEPLOYMENT | Release order and rollout checklist |
| 11 | 11_TESTING | Test strategy and regression safety |
| 12 | 12_PERFORMANCE | Limits and profiling guidance |
| 13 | 13_DEPENDENCIES | Policy, upgrades, and exceptions |
| 14 | 14_DEVELOPER_WORKFLOWS | Setup and everyday recipes |
| 15 | 15_KNOWN_LIMITATIONS | Deferred work and design tradeoffs |
| 16 | 16_ENGINEERING_PRINCIPLES | The rules that explain the rest |
| 17 | INBOX | Contribution and unverified notes |

## Changelog

### 2026-11-12
- Bootstrapped the `moth-gold-specs/skills` folder with empty-repo placeholders.
- Documented the current verified state: no tracked application code is present yet.
- Added the required `NN_TOPIC.md` scaffold set for future project knowledge.

## Contributing

Add or revise a document directly in this folder when you verify new behavior in code. When a fact is unverified, record it in `INBOX.md` with evidence and confidence.
