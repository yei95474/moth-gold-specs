# Database design choices: offline-first client–server

How the database is designed for an **offline-first** app: clients write to a local SQLite
database without a network and later sync through an API to a central Postgres server. This
document covers each choice, why it was made, and what it costs.

## Constraints that drive every choice

1. **Rows are created offline.** Clients can't ask the server for an ID, and two clients must
   never produce the same one.
2. **Rows arrive in any order and in pieces.** A child may sync before its parent, and a client
   only holds the rows its user may see.
3. **The same row can be edited on two clients before either syncs.**
4. **Deletes must travel.** A row deleted on one client must disappear everywhere.

## Terms

| Term | Meaning here |
|---|---|
| **UUID** | 128-bit ID any machine can generate without coordinating. The row's global identity. |
| **Surrogate key** | The `id` column: a database-generated number with no business meaning, never shared. |
| **Foreign key** | A `<parent>_uuid` column holding the parent's `uuid`. Usually **not** declared as a constraint on the server. |
| **uuid-native table** | A table that refers to parents only by `*_uuid`, never by a local integer id. |
| **Attribution columns** | Who and when: `created_by`, `created_at`, `updated_at`, `archived_at`. |
| **Soft delete** | Setting `archived_at` instead of `DELETE`, so the deletion can sync. |
| **Change column** | `updated_at`: bumped on every edit, compared for last-write-wins. |
| **Dirty** | A client row with edits not yet pushed. |
| **Push / Pull / Sync** | Client → server / server → client / push then pull. |
| **Last-write-wins (LWW)** | When two copies differ, the newer change column wins. |
| **Gating** | `WHERE` conditions that decide which rows a query touches (live rows, dirty rows, a user's scope). |
| **Link table / Placement** | A table whose rows connect two records; one such row is a placement and can carry its own data (e.g. `rank`). |
| **Forward migration / Backfill** | An idempotent script applied on top of the current schema / filling a new column from existing data. |
| **Snapshot** | A full schema export from Supabase that can build a fresh database on its own; not a delta. |
| **Legacy column** | An old column kept for older clients, no longer written, dropped later. |

---

## 1. Sample tables

### Server (Postgres)

```sql
CREATE TABLE IF NOT EXISTS public.note (
  id            bigint GENERATED ALWAYS AS IDENTITY NOT NULL,  -- server-only surrogate (§2)
  uuid          uuid NOT NULL UNIQUE,                          -- global identity (§3)
  notebook_uuid uuid,                                          -- parent by uuid, no REFERENCES (§3)
  title         text,
  body          text,
  rank          integer,
  created_by    uuid,                                          -- author's account uuid (§4)
  created_at    timestamptz,
  updated_at    timestamptz,                                   -- change column (§6)
  archived_at   timestamptz,                                   -- soft delete (§5)
  CONSTRAINT note_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_note_notebook ON public.note (notebook_uuid);

-- Link table: a note can carry many tags, a tag can sit on many notes.
CREATE TABLE IF NOT EXISTS public.note_tag (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid        uuid NOT NULL UNIQUE,
  note_uuid   uuid NOT NULL,
  tag_uuid    uuid NOT NULL,
  rank        integer,                                         -- data on the placement (§7)
  created_by  uuid,
  created_at  timestamptz,
  updated_at  timestamptz,
  archived_at timestamptz,
  CONSTRAINT note_tag_pkey PRIMARY KEY (id)
);
-- One live link per pair; archived links don't count (§5).
CREATE UNIQUE INDEX IF NOT EXISTS idx_note_tag_live
  ON public.note_tag (note_uuid, tag_uuid) WHERE archived_at IS NULL;
```

### Client (SQLite)

```sql
CREATE TABLE IF NOT EXISTS note (
  id              INTEGER PRIMARY KEY,       -- local rowid, never sent
  uuid            TEXT NOT NULL UNIQUE,
  notebook_uuid   TEXT,
  title           TEXT,
  body            TEXT,
  rank            INTEGER,
  created_by      TEXT,                      -- account uuid (pulled; the server stamps it)
  created_at      TEXT,                      -- ISO-8601 UTC
  updated_at      TEXT,
  archived_at     TEXT,
  synchronized_at TEXT                       -- client-only sync marker (§6)
);
CREATE INDEX IF NOT EXISTS idx_note_notebook_live ON note (notebook_uuid, archived_at);
```

The two tables use the **same table and column names**, so sync maps them by name. The only
differences are `id` (separate on each side, never synced) and `synchronized_at` (client only).

---

## 2. Server-only `id bigint`

`id bigint GENERATED ALWAYS AS IDENTITY` is the primary key, but **it never leaves the server**.
The client has its own `INTEGER PRIMARY KEY`, so the two numbers are unrelated.

**Why have it:**
- **Small, ordered primary-key index.** It is 8 bytes and always appends at the right edge of the
  B-tree, so pages stay dense. A random UUID v4 primary key (16 bytes) inserts all over the tree,
  causing page splits and fragmentation.
- **Arrival order for free.** `ORDER BY id` shows insert order without trusting client clocks.
- **`bigint`, not `integer`:** high-volume tables (events, logs, answers) can pass 2.1 billion rows.
- **`GENERATED ALWAYS`** rejects any insert that supplies an `id`, so a client value can never
  slip in. Strip `id` from every sync payload.

**Why it must not be shared:** each database counts from 1, so ids collide across machines. They
can't be known offline, and sequential ids in URLs invite enumeration.

**Cost:** every table maintains two unique indexes (`id` and `uuid`), and the `uuid` index still
takes random inserts. Sync looks rows up by `uuid`, so that index does the real work.
*Option:* UUID v7 (time-ordered) makes the `uuid` index append-mostly as well, with no schema change.

---

## 3. UUID identity and `*_uuid` foreign keys

The **creating client mints the `uuid`**, and every relationship stores the parent's `uuid`. The
reference means the same thing on every machine.

**Most server foreign keys are not declared** (`REFERENCES`), because:
- With a declared constraint, a child batch that arrives before its parent **fails, along with
  the rest of the batch**. Without one, the child lands and becomes consistent once the parent syncs.
- Clients hold partial, permission-scoped datasets, so a parent may legitimately be missing.
- Soft deletes never physically remove parents, so cascade rules have nothing to protect.
- Tables can be re-parented later without rebuilding constraints on live data.

Declare a real `REFERENCES` only where both rows are always written online, in order
(for example, admin-only configuration tables).

**Where integrity is enforced instead:**
1. **On the client:** turn foreign keys on in SQLite.
2. **Orphan guard on pull:** if a new row's parent `uuid` is unknown locally, skip it and retry
   on the next sync.
3. **Natural-key adoption:** if a pulled row has an unknown `uuid` but matches a local row's
   natural key (e.g. `(note_uuid, tag_uuid)`), update that local row instead of inserting a
   duplicate. This repairs two clients creating "the same" record under different UUIDs.

**Keep client tables uuid-native.** Mirroring each `*_uuid` into a local integer `*_id` speeds up
joins a little, but it is a second copy of every relationship. It must be translated on every
pull and push, and it breaks when a table is rebuilt.

**Cost:** the server can hold orphans, so reads must tolerate a missing parent. Index every
`*_uuid` column that scoped pulls walk.

---

## 4. Attribution columns

| Column | Meaning | Set by |
|---|---|---|
| `created_by` | Account `uuid` of the author | **Server**, from the authenticated session, on insert |
| `created_at` | Creation time | Client |
| `updated_at` | Last change (the change column) | Client, on every edit |
| `archived_at` | Soft-delete time | Client |
| `rated_by`, `approved_by`, … | Actor of a specific action | Server, from the session |
| `submitted_at`, `published_at`, `locked_at`, … | Lifecycle steps | Client or server, by rule |

**Choices and reasons:**
- **The server stamps the actor columns and never accepts them from a client.** They decide
  ownership ("authors edit only their own notes"), so a client-supplied value would let anyone
  claim anything. Exclude them from the push allowlist.
- **They are stored as `uuid`, not as a foreign key.** The account may be outside a client's
  dataset, and attribution must survive the account being archived.
- **Action-specific actors instead of a generic `updated_by`.** "Who approved this?" matters;
  "who last touched the row?" is overwritten by every sync.
- **`timestamptz` on the server, ISO-8601 UTC on the client**, so timestamps compare correctly
  across time zones.

**Cost:** there's no per-edit history, only the creator and the last change time. If you need
"who changed what", add an append-only audit table; don't widen every table.

---

## 5. Soft delete (`archived_at`)

A delete sets `archived_at` and bumps `updated_at`. The row becomes a **tombstone** that syncs
like any other edit. A real `DELETE` leaves nothing to sync, so the other clients would push the
row straight back.

- **Gate every normal read** on `archived_at IS NULL`. Pulls *do* send archived rows, so the
  deletion reaches every client.
- **Make uniqueness apply to live rows only**, with partial unique indexes
  (`… WHERE archived_at IS NULL`; see `idx_note_tag_live`). Archived history then never blocks a
  new row.
- **Exclude archived rows from aggregates.**
- **Never mass-unarchive.** Every unarchived row comes back on every client.

---

## 6. Dirty synchronization

```sql
-- A client row is dirty (has unpushed edits):
synchronized_at IS NULL OR synchronized_at <> updated_at

-- Local edit: bump the change column, leave synchronized_at alone.
UPDATE note SET title = ?, updated_at = ? WHERE uuid = ?;

-- Push accepted: mark clean.
UPDATE note SET synchronized_at = COALESCE(updated_at, CURRENT_TIMESTAMP) WHERE uuid IN (...);

-- Pull: write the server row with synchronized_at = its updated_at (clean).
```

**Server side, last-write-wins on push:**

```sql
INSERT INTO public.note (uuid, notebook_uuid, title, body, rank, created_by,
                         created_at, updated_at, archived_at)
VALUES (...)                                   -- created_by comes from the session, not the client
ON CONFLICT (uuid) DO UPDATE SET
  notebook_uuid = EXCLUDED.notebook_uuid,
  title         = EXCLUDED.title,
  body          = EXCLUDED.body,
  rank          = EXCLUDED.rank,
  updated_at    = EXCLUDED.updated_at,
  archived_at   = EXCLUDED.archived_at        -- created_by is never updated
WHERE note.updated_at < EXCLUDED.updated_at
   OR (EXCLUDED.archived_at IS NOT NULL       -- a delete wins a same-second tie
       AND note.archived_at IS NULL
       AND note.updated_at <= EXCLUDED.updated_at);
```

**Rules:**
- **On pull, never overwrite a dirty row.** Otherwise newer wins, and ties go to the server.
- **On push, only strictly newer rows are written**, except a delete, which wins a tie (SQLite
  timestamps have one-second precision, so an edit and a delete in the same second share a stamp).
- **Acknowledge a row with an empty change stamp** that the server already has, or the client
  retries it forever.
- **A pushed `NULL` doesn't clear columns the server filled itself** (backfills), so an older client
  can't erase data it never had.
- The dirty check uses `<>`, not `>`, so it doesn't break on timestamp format differences.

**Why:** most rows have one natural editor, so row-level last-write-wins is enough, and it needs
only one timestamp per row. "What to push" is a **gating** `WHERE` clause over the tables, not
a separate queue, so it can't drift out of step with the rows.

**Cost:**
- Concurrent edits lose the older one, for the whole row.
- A client with a fast clock wins conflicts it should lose.
- Without delta pulls, every sync re-reads the whole scoped dataset.
- Any manual server edit must bump `updated_at`, or a client push may overwrite it.

**Two rules that must never break:** every local mutation bumps `updated_at`, and only sync
writes `synchronized_at`. Break either and that row silently stops syncing.

---

## 7. Normalization

The core model is roughly third normal form: each fact lives once and is referenced by `*_uuid`.

- **Split entities by concern:** for example, keep `account` (identity) apart from `credential`
  (secrets), so secrets sync only to their owner.
- **Use parent → child hierarchies,** each level with its own rank, lifecycle, and soft delete.
- **Use link tables instead of copies:** one record can sit under many parents, and one edit
  shows everywhere. Unlinking archives the link row, never the record.
- **Put data on the placement,** not the record, when it differs per parent: `note_tag.rank`,
  or per-placement answers when one question is reused in several quizzes.
- **Use enums for closed vocabularies:** Postgres enums on the server; `TEXT` + `CHECK` on the
  client. Validate them in the UI, because an old client can accept a value the server rejects.
- **Keep settings as rows** (`feature`, `name`, `value`), so they change without a schema change.

**Guard:** freeze a shared record (with a trigger) while more than one parent links to it, if
editing it would silently change another parent's results. To edit it, duplicate it.

**Cost:** more joins, and on a client with partial data a join can miss its parent. That is
what the denormalizations below address.

---

## 8. Denormalization

| Kind | Example | Why |
|---|---|---|
| **Read shortcut** | `note.workspace_uuid`, although `note → notebook → workspace` already gives it | Lists without walking the chain, even when the middle row isn't on the client. |
| **Snapshot** | `order_line.unit_price` copied from the product | Records the value when the action happened. Later edits must not rewrite history. |
| **Stored aggregate** | `order.total` = sum of its lines | One-row reads for lists and reports. Also a record of what was given. |
| **Write-before-parent** | An event row carries `item_uuid` + `account_uuid`, and its `answer_uuid` is filled later | The event happens before its parent row exists. |
| **Transitional** | An old column kept beside its replacement | Old and new clients run side by side until everyone upgrades (§9). |
| **Document column** | `jsonb` content of a question | Read and written whole, with a shape that varies by type. |

**Rules:**
- Before changing a duplicated fact, **find every copy** and update them in one client transaction.
- **Snapshots are not bugs.** Don't "fix" them to match the source.
- Record which column is canonical, and when the transitional one will be dropped.

---

## 9. Schema evolution

New migrations reach the server before every client has upgraded, so all changes are
**additive, idempotent, and gated**.

### Adding a column (server forward migration)

```sql
BEGIN;

-- 1. Add (idempotent).
ALTER TABLE public.note ADD COLUMN IF NOT EXISTS is_pinned      boolean NOT NULL DEFAULT false;
ALTER TABLE public.note ADD COLUMN IF NOT EXISTS workspace_uuid uuid;

-- 2. Backfill from existing data; touch only rows not yet filled.
UPDATE public.note n
SET    workspace_uuid = nb.workspace_uuid
FROM   public.notebook nb
WHERE  nb.uuid = n.notebook_uuid
  AND  n.workspace_uuid IS NULL;

-- 3. Index the new lookup path.
CREATE INDEX IF NOT EXISTS idx_note_workspace ON public.note (workspace_uuid);

COMMIT;
```

### The same column on the client (SQLite)

SQLite has no `ADD COLUMN IF NOT EXISTS`, so guard each step in code:

```sql
-- Run only when PRAGMA table_info(note) has no 'is_pinned' column.
ALTER TABLE note ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0;
-- Run only when it has no 'workspace_uuid' column.
ALTER TABLE note ADD COLUMN workspace_uuid TEXT;
CREATE INDEX IF NOT EXISTS idx_note_workspace ON note (workspace_uuid);
```

### Rules

- **Apply the migration before deploying code that reads it.** Never edit an applied script;
  write a new one. Keep a periodic full-schema snapshot for reading. File version numbers for
  both kinds of change are defined in §10.
- **Additive first, removal later.** Add and backfill, mark the old column legacy, and drop it in a
  separate migration only after every client has upgraded.
- **Tolerate old clients.** Drop columns they still send that the server no longer has, and
  ignore their `NULL`s for columns they don't know yet.
- **Client upgrades are a re-entrant chain** (`if (oldVersion < N) migrateN()`), additive only.
  SQLite table rebuilds are the riskiest operation; prefer new tables. Run every migration on
  **fresh installs and upgrades alike**, and test the upgrade path with real data.
- **When a new change column is added, backfill it from `created_at`,** so existing rows read as
  clean instead of being pushed all over again.

---

## 10. Schema file versioning (`db-schema/`)

`moth-gold-specs/db-schema/` holds one SQL file per published state of the server schema. The
version in the filename is a **schema-document version**, not an application release tag (those
use `git-guidelines.md`). The baseline is `v1.0.0.sql`.

| Change | Who makes it | Version bump | Example |
| --- | --- | --- | --- |
| Add or alter a table, column, index, constraint, enum value, or policy (forward migration) | Developer or AI agent | **Patch** +1 | `v1.0.0` → `v1.0.1` → `v1.0.2` |
| Export the full schema from Supabase to local (snapshot) | Developer | **Minor** +1, patch reset to `0` | `v1.0.0` → `v1.1.0` → `v1.2.0` |

**Why two counters:** a forward migration is a small *delta* that must be applied in order on top of
the current schema; a snapshot is a *complete replacement* that can build a fresh database on its
own. Mixing them makes it impossible to tell which statements an environment has already run.

**Rules:**

1. **Patch = forward migration.** Each additive, idempotent change to a table gets its own patch
   file, bumping the patch number from the current file. Never edit an applied file; write the next
   patch (§9). Apply patch files in filename order.
2. **Minor = snapshot.** A Supabase export becomes `v1.<minor>.0` and replaces the readable
   baseline for new environments. Snapshots are not deltas: they create the whole schema and must
   be runnable on an empty database.
3. **Do not bump a minor for local edits.** If a developer only changes a table by hand, that is a
   patch. The minor moves only when a real Supabase export is checked in.
4. **Snapshots already contain their earlier patches.** When reconstructing a database, start from
   the newest snapshot and apply only the patch files numbered after it; do not replay patches the
   snapshot absorbed.
5. **Keep every file.** Patches are the history between snapshots; snapshots are the restore
   points. Deleting either breaks the audit trail and the upgrade path.
6. **Never reuse a version number.** A reused name lets two different schemas claim the same
   version, so environments drift with no way to tell which file was applied.
7. **Major (`v2.0.0`) is reserved** for a breaking change to identity or sync semantics (for
   example, redefining the `uuid`/`*_uuid` contract). It needs an explicit approved decision, not a
   routine migration.

| Miss → consequence |
| --- |
| Forward migration committed as a new minor → the delta history is lost; a database built from the old snapshot silently misses the change. |
| Snapshot committed as a patch → the file is no longer a pure delta; replaying the patch chain conflicts or double-applies it. |
| Editing an applied file → environments that already ran it diverge from those that did not. |
| Reusing a version → nobody can tell which schema an environment actually has. |
