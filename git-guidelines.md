# Git Guidelines

Combined reference for commit messages and release versioning.

> **Customizing this document:** replace `code-name` with your project's code
> name, and replace `<feature1>`, `<feature2>`, … with the feature or
> subsystem names that apply to your project.

## Contents

- [Part 1 — Commit Message Standard](#part-1--commit-message-standard)
  - [Required Format](#required-format)
  - [Format Breakdown](#format-breakdown)
  - [Full Commit Structure](#full-commit-structure)
  - [Good vs Bad Examples](#good-vs-bad-examples)
  - [Breaking Changes](#breaking-changes)
  - [Quick Reference](#quick-reference)
  - [The One-Sentence Test](#the-one-sentence-test)
- [Part 2 — Versioning Guidelines](#part-2--versioning-guidelines)
  - [Notes](#notes)
  - [Branching Models](#branching-models)
  - [Release Testing and Approval](#release-testing-and-approval)
  - [Production Support and Maintenance](#production-support-and-maintenance)
  - [Format](#format)
  - [Rules](#rules)
  - [Release Tags](#release-tags)

---

## Part 1 — Commit Message Standard

### Required Format

Every commit message **must** begin with:

```
scope: Imperative summary
```

---

### Format Breakdown

#### `scope:`

The part of the codebase this commit affects. Prefer a product and major
subsystem scope for changes to the actual applications. Use lowercase names;
use `product/subsystem:` when the change is focused, and `product:` when it
spans multiple subsystems within that application.

#### Preferred application scopes

Choose the most specific scope that still describes the whole commit:

| Scope | When to use |
|---|---|
| `code-name-api/<feature>:` | Back-end API feature or major subsystem |
| `code-name-web/<feature>:` | Front-end web app feature or major subsystem |
| `code-name-app/<feature>:` | Android app feature or major subsystem |
| `code-name-specs/<feature>:` | Specification content for a feature or major subsystem (the documents themselves, not code) |
| `code-name-api:` | Cross-feature back-end API change |
| `code-name-web:` | Cross-feature front-end web app change |
| `code-name-app:` | Cross-feature Android app change |
| `code-name-specs:` | Cross-feature specification change (shared conventions, structure, or templates) |

Use established feature names where applicable. Because every product belongs
to one ecosystem, feature scopes are listed once and shared by all products
(`code-name-api/auth:`, `code-name-web/auth:`, `code-name-app/auth:`, and so
on). Add your own as `<feature1>`, `<feature2>`, and so on:

`auth`, `sync`, `security`, `backup`, `restore`, `<feature1>`, `<feature2>`, …

`code-name-specs` is a version-controlled repository of specifications, so
its commits change the spec documents themselves, not code. A feature scope
there (`code-name-specs/auth:`) means the specification *of* that feature. It
also accepts spec-kind scopes that name the type of document being changed:
`requirements`, `design`, `schema`, `contracts`. Use the feature scope when
the change belongs to one feature, and the spec-kind scope when it applies
across features.

Examples:

```
code-name-app/<feature1>: Preserve drafts when switching tabs
code-name-app/sync: Retry failed record pulls
code-name-web/<feature1>: Show feedback on detail pages
code-name-web/auth: Keep password errors beside the field
code-name-web: Align shared page spacing across routes
code-name-specs/auth: Define password reset flow
code-name-specs/design: Add spacing tokens to the style guide
code-name-specs/schema: Clarify soft-delete columns
```

Do not use generic scopes such as `ui:`, `api:`, or `core:` when a
product/feature scope communicates the affected application more clearly.
For changes that genuinely span products or are not application-specific, use
the general scopes below. If a commit genuinely touches multiple independent
scopes, split it.

#### General scopes

Use these only when a product/feature scope does not fit:

| Scope | When to use |
|---|---|
| `code-name-specs` | Cross-repository specifications, design specs, schema snapshots, migration docs |
| `code-name-api` | Backend/API changes in the server repository |
| `db` | Database-only changes not specific to one application |
| `config` | Shared configuration or environment conventions |
| `test` | Cross-cutting test utilities or test infrastructure |
| `docs` | Documentation not specific to an application or subsystem |
| `ci` | Cross-repository CI/CD or build infrastructure |
| `deps` | Dependency updates not scoped to one application |

---

#### `Imperative summary`

- Written in imperative mood: reads as *"If applied, this commit will — [summary]"*
- Sentence case — capitalize only the first word
- No period at the end
- **50 characters or fewer** (hard limit for display in tools)
- Describes **what** the commit does, not what you did
- For specification changes, describes the change to the spec itself (for example `Define`, `Clarify`, `Revise`, `Deprecate`), not the implementation it will drive

```
auth: Add OAuth2 PKCE flow for mobile clients    ✓
auth: Added OAuth2 PKCE flow                     ✗  (past tense)
auth: oauth pkce                                 ✗  (too vague)
auth: TT-4821                                    ✗  (ticket number only)
```

---

### Full Commit Structure

The first line is the only required field. Everything below is optional but encouraged for non-trivial changes.

```
scope: Imperative summary

Why this change was necessary and what problem it solves. Wrap
at 72 characters. Focus on the reasoning, not the mechanics —
the diff already shows what changed.

Fixes #1234 — Short description of the ticket
See-also #1201 — Related prior change
```

#### Section rules

| Section | Required | Placement | Notes |
|---|---|---|---|
| `scope: Summary` | **Yes** | Line 1 | The entire format above applies |
| Blank line | If body follows | Line 2 | Never skip this — tools break without it |
| Body | No | Lines 3+ | Explain why; wrap at 72 chars |
| References | No | After body | Always include a human-readable description beside the ticket number |

---

### Good vs Bad Examples

#### Bad — vague summary
```
ui: mod
```
#### Good
```
ui: Replace dropdown with combobox on filter panel
```

---

#### Bad — ticket number as summary
```
api: TT-9021
```
#### Good
```
api: Fix 500 error on concurrent token refresh requests

Serialized the expiry check and renewal with a mutex to prevent
a race condition that caused ~1% of requests to fail under load.

Fixes #9021 — "High-load 500 errors on /auth/refresh"
```

---

#### Bad — metadata first, no summary
```
external=no
TT-7712
RelReq
```
#### Good
```
core: Rearrange session map to prevent crash on duplicate keys

Switched from a linked list to a map. Better performance and
no crash on duplicate session entries.

Fixes #7712 — SEGV in session manager under concurrent logins
external=no
```

---

#### Bad — one commit doing too many things
```
ui: Fix three things: frobnicate fjords, update error text, fix string bugs
```
#### Good — split into three commits
```
core: Frobnicate fjords to stabilize fleezle accumulator rates
ui:   Update "replace muffler bearings" error message text
core: Use safe string handling to prevent buffer overruns
```

---

### Breaking Changes

If a commit introduces a breaking change, add `!` after the scope bracket and include a `BREAKING CHANGE:` trailer.

```
api:! Remove deprecated /v1/login endpoint

BREAKING CHANGE: /v1/login is no longer available. Clients must
migrate to /v2/auth before this version is deployed.
```

---

### Quick Reference

```
scope: Imperative summary                 ← required, ≤50 chars
                                          ← blank line if body follows
Why this was necessary. Wrap at 72.       ← optional body

Fixes #NNN — ticket description           ← optional references
```

---

### The One-Sentence Test

> Read the summary alone, with no context. Would a developer who joins the team next year understand what this commit did and why it mattered?

If not, rewrite it.

---

### Exclusion of AI Agent

> Any AI agent should not be added as author of any commits, tags, releases, or PRs.

---

## Part 2 — Versioning Guidelines

### Notes

#### Ecosystem-wide identity

All products share one identity, so a tag shows which product it belongs to
from its prefix alone.

- **Code Name**: Code Name
- **Short Code**: `CN`

#### Product prefixes

The prefix is one letter for the product followed by the ecosystem short code.

| Product | Prefix | Formula |
|---|---|---|
| Web App Front-end (`code-name-web`) | `WCN` | `W` + `CN` |
| Server/Back-end API (`code-name-api`) | `BCN` | `B` + `CN` |
| Android App (`code-name-app`) | `ACN` | `A` + `CN` |
| Specifications (`code-name-specs`) | `SCN` | `S` + `CN` |

### Branching Models

#### Maturity-based branching model

The project follows a **maturity-based branching model**. The branches represent
controlled workflow stages, and code is promoted only after it passes the gate
for its current stage:

`main` → `beta` → `release` → production

| Branch | Role | Permitted work |
|---|---|---|
| `main` | Development | Feature development, integration of completed changes, and developer unit testing. |
| `beta` | QA / system testing | System testing against major product claims, defect correction, and stabilization of the development build. |
| `release` | Bundled release testing | Builds published to the release website for independent integration testing, candidate iteration, and final production approval. |

The `release` branch is the controlled **release-testing** branch; it does not
mean that every commit on it is already approved for production. Production
approval is a separate decision made after the applicable release candidate
passes testing.

#### Promotion rules

1. **Develop on `main`.** Developers commit and push ongoing development to `main` and perform unit testing. Code on `main` is not eligible for independent release testing.
2. **Promote `main` to `beta`.** Once the development build is ready for system testing, promote the reviewed changes from `main` to `beta`. QA evaluates the system against major product claims.
3. **Gate promotion on QA results.** Only after system testing is accepted may the tested code be promoted from `beta` to `release`. Do not send unapproved development code directly to the independent test team.
4. **Build and publish release code.** Bundle the promoted code and publish the build to the designated release website. The published bundle is the release code that independent integration testers evaluate; testers must not test unreleased development code.
5. **Run candidate testing on `release`.** Alpha (`a`), beta (`b`), and release-candidate (`rc`) labels identify the stage of a candidate within the release-testing cycle. A candidate with defects must be corrected, rebuilt, and assigned the next candidate identifier for that stage.
6. **Approve production separately.** The designated final approver determines whether an `rc` candidate is ready for production. Deploy the exact approved candidate; do not treat presence on `release` alone as production approval.
7. **Tag release candidates from `release`.** Release and pre-release tags must identify the exact commits/builds on `release` that were published for testing. Do not create these tags from `main` or `beta`, and never move or reuse an existing tag.
8. **Preserve promotable history.** Use reviewed merges or equivalent controlled promotions. When a correction made during stabilization or release testing must also exist in ongoing development, merge or cherry-pick it back into the appropriate upstream branch and review the result.

A promotion advances code to the next controlled stage; it does not automatically
make the code production-ready. Each receiving branch must contain the reviewed
changes being promoted, and each gate must be satisfied in order.

### Release Testing and Approval

Release testing begins only after planned development work is complete and the
release bundle has been published for testing. The WBS/Gantt chart should show
100% completion of planned development tasks; remaining work is limited to
testing, regression testing, and defect correction.

Testing responsibilities are separated by stage:

| Stage | Responsible group | Purpose / gate |
|---|---|---|
| Unit testing | Developers (`main`) | Verify individual units and developer changes before QA/system testing. |
| System testing | QA (`beta`) | Validate major product claims and determine whether code may enter the release-testing stage. |
| Integration testing | Independent testers (`release`) | Test the published release bundle through alpha, beta, and release-candidate iterations. |
| Production approval | Designated final approver | Decide whether the final release candidate is acceptable for production deployment. |

Independent integration testers test only published release bundles, not
unreleased code on development branches. A failed candidate does not advance to
the next stage until its blocking defects have been corrected and the revised
candidate has passed the current stage's required checks.

The pre-release suffix identifies the candidate stage and iteration:

- `a` — alpha testing.
- `b` — beta testing.
- `rc` — release-candidate testing, including final internal and regression testing.
- If a candidate has defects, append an iteration number to the same stage label: `a2`, `a3`, `b2`, `rc2`, and so on. Do not append `1` to the first candidate.
- When a candidate passes its stage, advance to the next stage using that stage's base label. For example, `a2` passing advances to `b`; `b2` passing advances to `rc`.
- When an `rc` candidate passes and is approved, deploy that exact candidate to production.

Example for build `WCN.01.0.017`:

| Result | Next candidate/action |
|---|---|
| Begin alpha testing | `WCN.01.0.017a` |
| Alpha candidate has defects | `WCN.01.0.017a2` |
| `a2` passes alpha | `WCN.01.0.017b` |
| Beta candidate has defects | `WCN.01.0.017b2` |
| `b2` passes beta | `WCN.01.0.017rc` |
| RC candidate has defects | `WCN.01.0.017rc2` |
| `rc2` passes and is approved | Deploy the exact `rc2` candidate to production |

The suffix does not increment `0X`, `Y`, or `00Z`. A corrected candidate is a
new iteration of the same stage and build lineage, not a new development cycle.

### Production Support and Maintenance

Defects reported after production deployment are handled through the production
support and maintenance lifecycle, not by reopening the normal alpha/beta/RC
sequence for the already-deployed release.

The standard escalation path is:

1. **Tier 1 — Customer Service:** Receive the report and attempt initial resolution.
2. **Tier 2 — Technical Support:** Investigate issues requiring deeper technical expertise, including enterprise application behavior and administration or security configuration.
3. **Tier 3 — Support Engineer:** Investigate and reproduce suspected software defects, then document and report them to the sustaining team.
4. **Sustaining team:** Triage and prioritize confirmed or reproducible defects and determine which require a dedicated maintenance lifecycle.

When post-production defects are accepted for maintenance, open a separate
maintenance branch/lifecycle. Increment the Minor component `Y` for that
maintenance lifecycle and reset the Patch/build component `00Z` to `001`, while
retaining the Major component `0X` unless a newly approved set of breaking
requirements starts a new major cycle. Apply the same controlled development,
testing, candidate, and approval gates to the maintenance release before it is
deployed.

Do not mix maintenance work into the normal development cycle without an
explicit promotion decision. The maintenance branch must preserve the production
baseline it is intended to correct, and any fix that should also exist in active
development must be carried forward through a reviewed merge or cherry-pick.

### Format

`<prefix>.0X.Y.00Z`

Each component is separated by a period. Components are written exactly as
shown and are not normalized (for example, never collapse `01.0.001` into
`010.001` or `1.0.1`).

Example, the first two weekly release tags of the web app:

```
WCN.01.0.001   ← first weekly release tag
WCN.01.0.002   ← second weekly release tag
```

- `<prefix>` — product prefix: `WCN`, `BCN`, `ACN`, or `SCN`
- `0X` — Major, always zero-padded to 2 digits, starts at `01`
- `Y` — Minor (maintenance branch), a single digit, starts at `0`. Reaching
  `9` is rare.
- `00Z` — Patch (weekly build release), always zero-padded to 3 digits,
  starts at `001`. A year has 52 weeks and a lifecycle is only 3 to 12
  months, so exceeding `052` is unusual; the faster the cycle, the better.

First release tags: `WCN.01.0.001`, `BCN.01.0.001`, `ACN.01.0.001`,
`SCN.01.0.001`.

### Rules

#### Major version (`0X`)

- Increments only when a new set of breaking requirements is approved, marking the start of a new development cycle.
- Incrementing `0X` resets `Y` to `0` and `00Z` to `001`.

#### Minor / maintenance lifecycle (`Y`)

- Identifies a maintenance lifecycle opened to address prioritized defects reported after a production deployment.
- When a maintenance lifecycle is opened, increment `Y` and reset `00Z` to `001`; retain `0X` unless a newly approved set of breaking requirements starts a new major cycle.
- Each maintenance lifecycle branches from the applicable production baseline and addresses the prioritized fixes accepted for that lifecycle.
- A maintenance release follows the same controlled development, QA/system-testing, release-bundle integration-testing, candidate, and production-approval gates described above.
- Do not use the standard development cycle's pre-release candidates as a substitute for the separately approved maintenance lifecycle.

#### Patch / build release (`00Z`)

- Increments weekly during a single development phase, with at least one commit per increment.
- During development, each weekly increment records the build progression. Independent integration testers may test only bundles that have been published to the release website after QA/system-testing approval.
- Once planned development is complete, publish release bundles for alpha, beta, and release-candidate testing. Candidate iterations use the pre-release suffixes described above; increment `00Z` for a new build/release cycle, not merely to represent the `a`, `b`, or `rc` stage.
- The exact final candidate that passes testing and receives production approval is deployed publicly.

#### Pre-release label (`Label`)

- Appended directly to the Patch / build release (`00Z`) to identify the final testing stage of a development cycle.
- These identifiers are equivalent to **GitHub tags** attached to specific commits (for example, `WCN.01.0.017a`, `WCN.01.0.017b`, and `WCN.01.0.017rc`); they are **not actual GitHub Releases**. A GitHub Release is a separate published entry that can be created from a selected tag. Applying a pre-release label does not itself create a GitHub Release.
- Used only after all planned development work is complete and the WBS/Gantt chart is 100% complete. Remaining work is limited to testing, regression testing, and fixing defects.
- Labels are used in this order:
  - `a` — Alpha testing.
  - `b` — Beta testing.
  - `rc` — Release-candidate testing, including final internal and regression testing.
- The first candidate in a stage uses the label without a numeric suffix. If defects are found, issue another candidate in the same stage by appending a numeric suffix. Continue incrementing the suffix for each subsequent candidate.
- Once a candidate passes testing with no remaining bugs requiring a fix, advance to the next stage. The numeric suffix does not carry over to the next stage.
- Once an `rc` candidate passes final testing with no remaining bugs requiring a fix, deploy that release to production.

Examples, using `WCN.01.0.017`:

| Situation | Next release |
|---|---|
| Development is complete; begin alpha testing | `WCN.01.0.017a` |
| `a` has bugs; issue another alpha candidate | `WCN.01.0.017a2` |
| `a2` has bugs; issue another alpha candidate | `WCN.01.0.017a3` |
| Alpha testing passes; begin beta testing | `WCN.01.0.017b` |
| `b` has bugs; issue another beta candidate | `WCN.01.0.017b2` |
| Beta testing passes; begin release-candidate testing | `WCN.01.0.017rc` |
| `rc` has bugs; issue another release candidate | `WCN.01.0.017rc2` |
| An `rc` candidate passes final testing | Deploy that candidate to production |

The pre-release label is part of the release identifier and does not increment `0X`, `Y`, or `00Z`. A defect-fix candidate remains within the same stage and build number; the next development cycle or maintenance release follows the Major, Minor, and Patch rules above.

#### Applying the rules to specifications (code-name-specs)

A specification repository follows the same format and weekly cadence, but
nothing in it is deployed or run. Read the rules above as follows:

- **Major version (`0X`)**: a new approved set of breaking requirements
  starts a new revision cycle of the specs, the same as for code.
- **Maintenance branch (`Y`)**: increments when a spec baseline is approved
  and handed off to implementation, in place of a production deployment.
  The maintenance branch then holds corrections to that baseline.
- **Build release (`00Z`)**: the weekly spec revision, with at least one
  commit per increment.
- **Golden code candidates**: review candidates. They are validated against
  the implementation and by stakeholder review instead of regression
  testing, until no priority issues remain. The final candidate is the
  approved baseline.

### Release Tags

On **2026-07-04** the weekly release tags were reconstructed retroactively from each
repository's commit history, so the `00Z` build numbers reflect the actual development
timeline rather than starting from the day tagging began.

#### Creating a release

Follow these rules whenever you create release tags for a repository:

1. **Start at the first commit's week.** The first tag (`001`) always goes on
   the ISO week of the repository's first commit.
2. **No commits, no tag.** If a week after the first one has no commits, it
   gets no tag and does not use a build number. This applies to any gap
   between weeks that have commits.
3. **Never tag an ongoing week.** Do not create a tag for the current ISO
   week until it is **Friday 5:00 PM or later on your local clock**. Before
   then, the week's commits stay untagged. For example, on a Wednesday no
   tag is created for the current week.
4. **Bundle commits into the week they fall in.** Each tag covers all the
   commits of its ISO week and points to that week's last commit. Commits are
   never bundled into the tag of a different week.
5. **Only tag weeks that don't have a tag yet.** Never retag or move an
   existing tag. When several finished weeks are missing tags, create them
   one by one, from the earliest week to the latest.
6. **Tags are always chronological.** Build numbers increase with the ISO
   week order. Never create a tag for an earlier week after a tag for a later
   week exists.

#### How the tags were derived

- **Week boundaries** follow ISO-8601 (Monday–Sunday) in a standard 52-week year.
- **`00Z` build `001`** is anchored to the ISO week of each repo's **first commit** ("the very first week of the initial push"); it then increments by one for **each subsequent ISO week that contains at least one commit**. Weeks with no commits are skipped and do **not** consume a build number (see the gaps below).
- **Releases are cut on Friday.** Each tag is annotated, points to the **last commit of its ISO week** (that week's release cut), and is dated on the week's Friday — clamped forward to the commit date on the rare week whose work only landed on the weekend, so a tag never predates the commit it marks.
- **`0X` stayed `01` and `Y` stayed `0`** across every tag: the history carries no approved new-major cycle and no production-deployment marker that would bump either. When a production deploy does happen, bump `Y` and reset `00Z` to `001` per the rules above.
- Bucketing uses each commit's **committer date**.

#### code-name-android — Android (ACN)

| Tag | ISO week | Release date | Commit |
| --- | --- | --- | --- |
|  |  |  |  |

Next release: **`ACN.01.0.001`**.

#### code-name-web — web front-end (WCN)

| Tag | ISO week | Release date | Commit |
| --- | --- | --- | --- |
|  |  |  |  |

Next release: **`WCN.01.0.001`**.

#### code-name-api — back-end api (BCN)

| Tag | ISO week | Release date | Commit |
| --- | --- | --- | --- |
|  |  |  |  |

Next release: **`BCN.01.0.001`**.

#### code-name-specs — specifications (SCN)

| Tag | ISO week | Release date | Commit |
| --- | --- | --- | --- |
|  |  |  |  |

Next release: **`SCN.01.0.001`**.

Tags follow the same derivation rules above. Once the first weekly release is
cut, record it here in the same format.

\* The release date is clamped forward from Friday because the last commit in
that ISO week landed on a weekend. ISO 2026-W41 is still in progress on
2026-10-05; its release tags, including the first release of a new
code-name-app, should be cut after the Friday 2026-10-09 weekly cutoff.
