-- ============================================================================
-- Moth Gold - MVP server schema (baseline)
--
-- File:    moth-gold-specs/db-schema/v1.0.0.sql
-- Target:  Supabase PostgreSQL (public schema)
-- Product: moth-gold-specs/business-logic-v1.1.md
-- Design:  moth-gold-specs/db-design-choices.md (sections 2-10)
--
-- This baseline is idempotent: CREATE ... IF NOT EXISTS, guarded enum creation,
-- and guarded RLS enablement make it safe to re-run without duplicating objects.
--
-- Identity rules (deliberate - do not "fix" them):
--   * `id` is a server-only bigint IDENTITY PRIMARY KEY. It is an index key,
--     never a relationship, never sent to a client, never accepted from one.
--     Each database counts from 1, so it cannot be a cross-machine identity (§2).
--   * `uuid` is the global row identity, minted by the creating client (§3).
--   * Relationships are stored as `<parent>_uuid` logical foreign keys. There are
--     intentionally no REFERENCES constraints: a child may sync before its
--     parent, and clients hold partial datasets (§3). The API and the client
--     enforce existence, ownership, and participation.
--   * `created_by` is stamped by the API from the authenticated session and is
--     excluded from client push allowlists (§4). Action-specific actors
--     (`moderator_uuid`, `verified_by`, ...) record who took a specific step.
--   * `updated_at` is the change column for last-write-wins; `archived_at` is the
--     soft delete. Normal reads gate on `archived_at IS NULL` (§5-§6).
--   * `synchronized_at` is client-only and deliberately absent here (§6).
--   * Never hard-delete a synced row: a real DELETE has nothing to sync (§5).
--
-- Versioning (§10): patch = forward migration (v1.0.0 -> v1.0.1 -> v1.0.2);
-- minor = full Supabase export/snapshot (v1.0.0 -> v1.1.0 -> v1.2.0). Never edit
-- an applied file; write the next version.
--
-- Access control: RLS is enabled on every table with no anon/authenticated
-- policies. The API connects with a service-role client (RLS bypass) and enforces
-- role, ownership, and participation per v1.1 "User Levels". Direct client table
-- access is denied by default.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Closed vocabularies: Postgres enums on the server, TEXT + CHECK on clients.
-- CREATE TYPE has no IF NOT EXISTS form, so each type is guarded (§7, §9).
-- Adding a value later is a forward migration:
--   ALTER TYPE public.<type> ADD VALUE IF NOT EXISTS '<value>';
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  CREATE TYPE public.account_role AS ENUM (
    'system_administrator', 'administrator', 'moderator', 'contributor', 'guest'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.account_status AS ENUM ('active', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.eligibility_status AS ENUM ('pending', 'verified', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.auth_provider AS ENUM ('google');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.policy_type AS ENUM (
    'privacy_notice', 'community_rules', 'terms', 'support_contact'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.backup_status AS ENUM (
    'scheduled', 'running', 'succeeded', 'failed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.deletion_request_source AS ENUM ('android', 'web');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.deletion_request_status AS ENUM (
    'pending', 'verified', 'processing', 'completed', 'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.listing_kind AS ENUM ('good', 'service');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.listing_status AS ENUM (
    'active', 'closed', 'expired', 'removed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.request_status AS ENUM (
    'open', 'closed', 'expired', 'removed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.request_reply_status AS ENUM (
    'linked', 'withdrawn', 'removed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.conversation_status AS ENUM ('open', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.exchange_status AS ENUM ('pending', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Shared target vocabulary for reports and moderation actions. Polymorphic
-- targets are intentional: reported content can be removed, but the row stays
-- for the audit trail and for reporting messages received.
DO $$
BEGIN
  CREATE TYPE public.content_type AS ENUM (
    'account', 'offer', 'request', 'request_reply', 'message', 'review', 'photo'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.report_reason AS ENUM (
    'spam', 'scam', 'prohibited_item', 'harassment', 'inappropriate_content', 'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.report_status AS ENUM (
    'open', 'dismissed', 'action_taken'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.moderation_action_type AS ENUM (
    'dismiss_report', 'remove_offer', 'remove_request', 'remove_request_reply',
    'remove_message', 'remove_review', 'remove_photo',
    'suspend_account', 'reinstate_account'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ===========================================================================
-- Identity and onboarding
-- ===========================================================================

-- One member account. `display_name` is the only public profile field: email,
-- phone, and exact location never live here (v1.1 Solution Layers, §1).
CREATE TABLE IF NOT EXISTS public.account (
  id                      bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid                    uuid NOT NULL UNIQUE,
  display_name            text NOT NULL,
  pilot_area_uuid         uuid,
  account_role            public.account_role NOT NULL DEFAULT 'contributor',
  account_status          public.account_status NOT NULL DEFAULT 'active',
  eligibility             public.eligibility_status NOT NULL DEFAULT 'pending',
  eligibility_verified_at timestamptz,
  eligibility_verified_by uuid,
  suspended_at            timestamptz,
  created_by              uuid,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  archived_at             timestamptz,
  CONSTRAINT account_pkey PRIMARY KEY (id),
  CONSTRAINT account_display_name_not_blank CHECK (length(btrim(display_name)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_account_pilot_area
  ON public.account (pilot_area_uuid);
CREATE INDEX IF NOT EXISTS idx_account_live_role_status
  ON public.account (account_role, account_status) WHERE archived_at IS NULL;

-- Google Sign-In secrets. Split from `account` (§7) so secrets sync only to
-- their owner; `provider_subject` and `email` are private, never public profile.
CREATE TABLE IF NOT EXISTS public.credential (
  id                bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid              uuid NOT NULL UNIQUE,
  account_uuid      uuid NOT NULL,
  provider          public.auth_provider NOT NULL DEFAULT 'google',
  provider_subject  text NOT NULL,
  email             text,
  email_verified_at timestamptz,
  created_by        uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  archived_at       timestamptz,
  CONSTRAINT credential_pkey PRIMARY KEY (id),
  CONSTRAINT credential_provider_subject_not_blank
    CHECK (length(btrim(provider_subject)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_credential_account
  ON public.credential (account_uuid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_credential_live_provider_subject
  ON public.credential (provider, provider_subject) WHERE archived_at IS NULL;

-- DPA consent for optional personal information / sharing. `policy_uuid` plus
-- `notice_version` record exactly what the member agreed to (§8 snapshot).
CREATE TABLE IF NOT EXISTS public.consent (
  id             bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid           uuid NOT NULL UNIQUE,
  account_uuid   uuid NOT NULL,
  purpose        text NOT NULL,
  granted        boolean NOT NULL DEFAULT false,
  granted_at     timestamptz,
  revoked_at     timestamptz,
  policy_uuid    uuid,
  notice_version text,
  created_by     uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  archived_at    timestamptz,
  CONSTRAINT consent_pkey PRIMARY KEY (id),
  CONSTRAINT consent_purpose_not_blank CHECK (length(btrim(purpose)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_consent_account
  ON public.consent (account_uuid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_consent_live_account_purpose
  ON public.consent (account_uuid, purpose) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_consent_policy
  ON public.consent (policy_uuid);

-- Public policies: privacy notice, community rules, terms, support contact.
-- Administrators publish new versions instead of rewriting history.
CREATE TABLE IF NOT EXISTS public.policy (
  id           bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid         uuid NOT NULL UNIQUE,
  policy_type  public.policy_type NOT NULL,
  title        text NOT NULL,
  body         text NOT NULL,
  version      text NOT NULL,
  effective_at timestamptz,
  published_at timestamptz,
  published_by uuid,
  created_by   uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  archived_at  timestamptz,
  CONSTRAINT policy_pkey PRIMARY KEY (id),
  CONSTRAINT policy_title_not_blank CHECK (length(btrim(title)) > 0),
  CONSTRAINT policy_body_not_blank CHECK (length(btrim(body)) > 0),
  CONSTRAINT policy_version_not_blank CHECK (length(btrim(version)) > 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_live_type_version
  ON public.policy (policy_type, version) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_policy_live_published
  ON public.policy (policy_type, published_at DESC)
  WHERE archived_at IS NULL AND published_at IS NOT NULL;

-- Explicit acceptance of the rules and terms before posting or messaging.
CREATE TABLE IF NOT EXISTS public.policy_acceptance (
  id             bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid           uuid NOT NULL UNIQUE,
  account_uuid   uuid NOT NULL,
  policy_uuid    uuid NOT NULL,
  policy_version text,
  accepted_at    timestamptz NOT NULL DEFAULT now(),
  created_by     uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  archived_at    timestamptz,
  CONSTRAINT policy_acceptance_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_acceptance_live_account_policy
  ON public.policy_acceptance (account_uuid, policy_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_policy_acceptance_policy
  ON public.policy_acceptance (policy_uuid);

-- One pilot area; no live location is collected. Offers and accounts carry a
-- `pilot_area_uuid` read shortcut so discovery does not walk a chain (§8).
CREATE TABLE IF NOT EXISTS public.pilot_area (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid        uuid NOT NULL UNIQUE,
  name        text NOT NULL,
  description text,
  is_active   boolean NOT NULL DEFAULT true,
  created_by  uuid,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT pilot_area_pkey PRIMARY KEY (id),
  CONSTRAINT pilot_area_name_not_blank CHECK (length(btrim(name)) > 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pilot_area_live_name
  ON public.pilot_area (name) WHERE archived_at IS NULL;

-- Append-only audit of who assigned or revoked a staff role. `account` holds
-- the current role; this table records the decision (same pattern as
-- `moderation_action`). No REFERENCES: assignments are synced like any row (§3).
CREATE TABLE IF NOT EXISTS public.staff_role_assignment (
  id            bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid          uuid NOT NULL UNIQUE,
  account_uuid  uuid NOT NULL,
  assigned_role public.account_role NOT NULL,
  assigned_by   uuid,
  assigned_at   timestamptz NOT NULL DEFAULT now(),
  revoked_at    timestamptz,
  created_by    uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  archived_at   timestamptz,
  CONSTRAINT staff_role_assignment_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_role_live_account_role
  ON public.staff_role_assignment (account_uuid, assigned_role)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_role_assigned_by
  ON public.staff_role_assignment (assigned_by);


-- ===========================================================================
-- Configuration and operations
-- ===========================================================================

-- Deactivating a category hides it from new posts/renewals but leaves it
-- visible on existing offers and requests until they close or expire (v1.1 §2).
CREATE TABLE IF NOT EXISTS public.category (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid        uuid NOT NULL UNIQUE,
  name        text NOT NULL,
  description text,
  is_active   boolean NOT NULL DEFAULT true,
  rank        integer NOT NULL DEFAULT 0,
  created_by  uuid,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT category_pkey PRIMARY KEY (id),
  CONSTRAINT category_name_not_blank CHECK (length(btrim(name)) > 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_category_live_name
  ON public.category (name) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_category_live_active_rank
  ON public.category (is_active, rank) WHERE archived_at IS NULL;

-- Settings are rows (§7), not columns: ('listing', 'expiry_days') holds the
-- expiry duration the API applies at publication and renewal; retention periods
-- for accounts, messages, reports, and backups live here too. No seed data:
-- pilot values are still open decisions in v1.1.
CREATE TABLE IF NOT EXISTS public.setting (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid        uuid NOT NULL UNIQUE,
  feature     text NOT NULL,
  name        text NOT NULL,
  value       text NOT NULL,
  updated_by  uuid,
  created_by  uuid,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT setting_pkey PRIMARY KEY (id),
  CONSTRAINT setting_feature_not_blank CHECK (length(btrim(feature)) > 0),
  CONSTRAINT setting_name_not_blank CHECK (length(btrim(name)) > 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_setting_live_feature_name
  ON public.setting (feature, name) WHERE archived_at IS NULL;

-- Backup schedule/verification. `storage_ref` is an opaque artifact pointer,
-- never a secret; recovery tests cover both records and listing photos (v1.1 §6).
CREATE TABLE IF NOT EXISTS public.backup_run (
  id              bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid            uuid NOT NULL UNIQUE,
  status          public.backup_status NOT NULL DEFAULT 'scheduled',
  scheduled_at    timestamptz,
  started_at      timestamptz,
  finished_at     timestamptz,
  scope           text,
  storage_ref     text,
  records_checked bigint,
  photos_checked  bigint,
  verified_by     uuid,
  verified_at     timestamptz,
  notes           text,
  created_by      uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  archived_at     timestamptz,
  CONSTRAINT backup_run_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_backup_run_live_status_finished
  ON public.backup_run (status, finished_at DESC) WHERE archived_at IS NULL;

-- Account-deletion workflow started in Android or on the public web page and
-- processed by the named support owner under the published retention rules.
CREATE TABLE IF NOT EXISTS public.account_deletion_request (
  id              bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid            uuid NOT NULL UNIQUE,
  account_uuid    uuid NOT NULL,
  source          public.deletion_request_source NOT NULL,
  status          public.deletion_request_status NOT NULL DEFAULT 'pending',
  reason          text,
  requested_at    timestamptz NOT NULL DEFAULT now(),
  assigned_to     uuid,
  verified_by     uuid,
  verified_at     timestamptz,
  processed_by    uuid,
  processed_at    timestamptz,
  retention_until timestamptz,
  resolution_note text,
  created_by      uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  archived_at     timestamptz,
  CONSTRAINT account_deletion_request_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_deletion_request_live_status_requested
  ON public.account_deletion_request (status, requested_at)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_deletion_request_account
  ON public.account_deletion_request (account_uuid);
CREATE INDEX IF NOT EXISTS idx_deletion_request_assigned_to
  ON public.account_deletion_request (assigned_to);


-- ===========================================================================
-- Listings
-- ===========================================================================

-- Optional photo on an offer. `storage_path` is a Supabase Storage object key;
-- it is a child by `offer_uuid` only and may sync before its parent (§3).
CREATE TABLE IF NOT EXISTS public.photo (
  id           bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid         uuid NOT NULL UNIQUE,
  offer_uuid   uuid NOT NULL,
  storage_path text NOT NULL,
  content_type text,
  byte_size    bigint,
  caption      text,
  rank         integer NOT NULL DEFAULT 0,
  created_by   uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  archived_at  timestamptz,
  CONSTRAINT photo_pkey PRIMARY KEY (id),
  CONSTRAINT photo_storage_path_not_blank CHECK (length(btrim(storage_path)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_photo_offer
  ON public.photo (offer_uuid);

-- A good or a service. `price_amount IS NULL` means "request a quote".
-- `expires_at` is stamped from the current `setting` value at publication and
-- renewal. `completed_exchange_uuid` closes a goods offer after its first
-- completed exchange; `removed_*` is moderation, `archived_at` is sync delete.
CREATE TABLE IF NOT EXISTS public.offer (
  id                      bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid                    uuid NOT NULL UNIQUE,
  owner_uuid              uuid NOT NULL,
  category_uuid           uuid NOT NULL,
  pilot_area_uuid         uuid,
  kind                    public.listing_kind NOT NULL,
  title                   text NOT NULL,
  description             text NOT NULL,
  price_amount            numeric(12,2),
  currency_code           text NOT NULL DEFAULT 'PHP',
  status                  public.listing_status NOT NULL DEFAULT 'active',
  published_at            timestamptz,
  expires_at              timestamptz NOT NULL,
  renewed_at              timestamptz,
  closed_at               timestamptz,
  completed_at            timestamptz,
  completed_exchange_uuid uuid,
  removed_at              timestamptz,
  removed_by              uuid,
  created_by              uuid,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  archived_at             timestamptz,
  CONSTRAINT offer_pkey PRIMARY KEY (id),
  CONSTRAINT offer_title_not_blank CHECK (length(btrim(title)) > 0),
  CONSTRAINT offer_description_not_blank CHECK (length(btrim(description)) > 0),
  CONSTRAINT offer_price_nonnegative CHECK (price_amount IS NULL OR price_amount >= 0)
);
-- Keyword search is ILIKE on title/description; add a pg_trgm GIN index in a
-- later patch only if a measured query plan shows it is needed (§12).
CREATE INDEX IF NOT EXISTS idx_offer_live_discovery
  ON public.offer (status, published_at DESC) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_offer_live_expiry
  ON public.offer (expires_at) WHERE archived_at IS NULL AND status = 'active';
CREATE INDEX IF NOT EXISTS idx_offer_owner
  ON public.offer (owner_uuid);
CREATE INDEX IF NOT EXISTS idx_offer_category
  ON public.offer (category_uuid);
CREATE INDEX IF NOT EXISTS idx_offer_pilot_area
  ON public.offer (pilot_area_uuid);
CREATE INDEX IF NOT EXISTS idx_offer_live_owner_status
  ON public.offer (owner_uuid, status) WHERE archived_at IS NULL;

-- A community request ("I need X"). It closes on owner action or at the same
-- expiry duration as offers. `last_reply_at` is a stored aggregate for the
-- pilot metric "requests with a reply" (§8).
CREATE TABLE IF NOT EXISTS public.request (
  id              bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid            uuid NOT NULL UNIQUE,
  owner_uuid      uuid NOT NULL,
  category_uuid   uuid NOT NULL,
  pilot_area_uuid uuid,
  title           text NOT NULL,
  description     text NOT NULL,
  status          public.request_status NOT NULL DEFAULT 'open',
  expires_at      timestamptz NOT NULL,
  closed_at       timestamptz,
  last_reply_at   timestamptz,
  removed_at      timestamptz,
  removed_by      uuid,
  created_by      uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  archived_at     timestamptz,
  CONSTRAINT request_pkey PRIMARY KEY (id),
  CONSTRAINT request_title_not_blank CHECK (length(btrim(title)) > 0),
  CONSTRAINT request_description_not_blank CHECK (length(btrim(description)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_request_live_discovery
  ON public.request (status, created_at DESC) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_request_live_expiry
  ON public.request (expires_at) WHERE archived_at IS NULL AND status = 'open';
CREATE INDEX IF NOT EXISTS idx_request_owner
  ON public.request (owner_uuid);
CREATE INDEX IF NOT EXISTS idx_request_category
  ON public.request (category_uuid);
CREATE INDEX IF NOT EXISTS idx_request_pilot_area
  ON public.request (pilot_area_uuid);

-- Reply to an open request by linking the responder's own active offer. One
-- live reply per (request, offer); "linked offer unavailable" is derived from
-- `offer.status` at read time, not snapshotted here (v1.1 §3).
CREATE TABLE IF NOT EXISTS public.request_reply (
  id             bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid           uuid NOT NULL UNIQUE,
  request_uuid   uuid NOT NULL,
  offer_uuid     uuid NOT NULL,
  responder_uuid uuid NOT NULL,
  note           text,
  status         public.request_reply_status NOT NULL DEFAULT 'linked',
  withdrawn_at   timestamptz,
  removed_at     timestamptz,
  removed_by     uuid,
  created_by     uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  archived_at    timestamptz,
  CONSTRAINT request_reply_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_request_reply_live_request_offer
  ON public.request_reply (request_uuid, offer_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_request_reply_offer
  ON public.request_reply (offer_uuid);
CREATE INDEX IF NOT EXISTS idx_request_reply_responder
  ON public.request_reply (responder_uuid);


-- ===========================================================================
-- Inbox, exchange, and trust
-- ===========================================================================

-- One private conversation per offer and interested contributor. Existing
-- conversations continue after the offer closes or expires (v1.1 §4).
CREATE TABLE IF NOT EXISTS public.conversation (
  id               bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid             uuid NOT NULL UNIQUE,
  offer_uuid       uuid NOT NULL,
  owner_uuid       uuid NOT NULL,
  participant_uuid uuid NOT NULL,
  status           public.conversation_status NOT NULL DEFAULT 'open',
  last_message_at  timestamptz,
  closed_at        timestamptz,
  created_by       uuid,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  archived_at      timestamptz,
  CONSTRAINT conversation_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_no_self CHECK (owner_uuid <> participant_uuid)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversation_live_offer_participant
  ON public.conversation (offer_uuid, participant_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_conversation_offer
  ON public.conversation (offer_uuid);
CREATE INDEX IF NOT EXISTS idx_conversation_live_participant_recent
  ON public.conversation (participant_uuid, last_message_at DESC)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_conversation_live_owner_recent
  ON public.conversation (owner_uuid, last_message_at DESC)
  WHERE archived_at IS NULL;

-- Private text messages. `created_by` is the server-stamped sender (§4).
-- `read_at` is the recipient's marker; the sender knows their own message.
CREATE TABLE IF NOT EXISTS public.message (
  id                bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid              uuid NOT NULL UNIQUE,
  conversation_uuid uuid NOT NULL,
  body              text NOT NULL,
  read_at           timestamptz,
  edited_at         timestamptz,
  created_by        uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  archived_at       timestamptz,
  CONSTRAINT message_pkey PRIMARY KEY (id),
  CONSTRAINT message_body_not_blank CHECK (length(btrim(body)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_message_conversation_created
  ON public.message (conversation_uuid, created_at);
CREATE INDEX IF NOT EXISTS idx_message_live_unread
  ON public.message (conversation_uuid) WHERE archived_at IS NULL AND read_at IS NULL;

-- One exchange per conversation at a time. `offer_kind` is a frozen snapshot
-- of `offer.kind`: the partial unique index below allows exactly one completed
-- exchange for a good, but many for a service (v1.1 §4, §8).
CREATE TABLE IF NOT EXISTS public.exchange (
  id                bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid              uuid NOT NULL UNIQUE,
  conversation_uuid uuid NOT NULL,
  offer_uuid        uuid NOT NULL,
  offer_kind        public.listing_kind NOT NULL,
  status            public.exchange_status NOT NULL DEFAULT 'pending',
  opened_at         timestamptz NOT NULL DEFAULT now(),
  completed_at      timestamptz,
  cancelled_at      timestamptz,
  cancel_reason     text,
  created_by        uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  archived_at       timestamptz,
  CONSTRAINT exchange_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_exchange_one_pending_per_conversation
  ON public.exchange (conversation_uuid)
  WHERE archived_at IS NULL AND status = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS idx_exchange_one_completed_good_per_offer
  ON public.exchange (offer_uuid)
  WHERE archived_at IS NULL AND status = 'completed' AND offer_kind = 'good';
CREATE INDEX IF NOT EXISTS idx_exchange_live_status_opened
  ON public.exchange (status, opened_at DESC) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_exchange_offer
  ON public.exchange (offer_uuid);

-- One confirmation per participant. The API completes the exchange in the
-- same operation as the second confirmation; the unique indexes above keep
-- simultaneous confirmations from producing two completed goods exchanges.
CREATE TABLE IF NOT EXISTS public.exchange_confirmation (
  id               bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid             uuid NOT NULL UNIQUE,
  exchange_uuid    uuid NOT NULL,
  participant_uuid uuid NOT NULL,
  confirmed_at     timestamptz NOT NULL DEFAULT now(),
  created_by       uuid,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  archived_at      timestamptz,
  CONSTRAINT exchange_confirmation_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_exchange_confirmation_live_exchange_participant
  ON public.exchange_confirmation (exchange_uuid, participant_uuid)
  WHERE archived_at IS NULL;

-- One rating + optional short review per participant, unlocked only after the
-- exchange completes (API gate). `published_at` gates public read access.
CREATE TABLE IF NOT EXISTS public.review (
  id             bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid           uuid NOT NULL UNIQUE,
  exchange_uuid  uuid NOT NULL,
  reviewer_uuid  uuid NOT NULL,
  subject_uuid   uuid NOT NULL,
  rating         smallint NOT NULL,
  body           text,
  published_at   timestamptz,
  created_by     uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  archived_at    timestamptz,
  CONSTRAINT review_pkey PRIMARY KEY (id),
  CONSTRAINT review_rating_range CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT review_no_self CHECK (reviewer_uuid <> subject_uuid)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_review_live_exchange_reviewer
  ON public.review (exchange_uuid, reviewer_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_review_live_subject_published
  ON public.review (subject_uuid, published_at DESC)
  WHERE archived_at IS NULL AND published_at IS NOT NULL;


-- ===========================================================================
-- Moderation
-- ===========================================================================

-- Single report queue. Polymorphic `target_uuid` covers accounts, listings,
-- replies, photos, reviews, and messages the reporter received. Access to a
-- reported message is limited to its participants and the assigned moderator.
CREATE TABLE IF NOT EXISTS public.report (
  id              bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid            uuid NOT NULL UNIQUE,
  reporter_uuid   uuid NOT NULL,
  target_type     public.content_type NOT NULL,
  target_uuid     uuid NOT NULL,
  reason_code     public.report_reason NOT NULL,
  details         text,
  status          public.report_status NOT NULL DEFAULT 'open',
  assigned_to     uuid,
  resolved_by     uuid,
  resolved_at     timestamptz,
  resolution_note text,
  created_by      uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  archived_at     timestamptz,
  CONSTRAINT report_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_report_live_status_created
  ON public.report (status, created_at) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_report_target
  ON public.report (target_type, target_uuid);
CREATE INDEX IF NOT EXISTS idx_report_assigned_to
  ON public.report (assigned_to);

-- Append-only record of every moderation decision: action, reason, moderator,
-- and time (v1.1 §5). A reinstatement is a new row, not an edit of suspension.
CREATE TABLE IF NOT EXISTS public.moderation_action (
  id             bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid           uuid NOT NULL UNIQUE,
  report_uuid    uuid,
  action_type    public.moderation_action_type NOT NULL,
  target_type    public.content_type NOT NULL,
  target_uuid    uuid NOT NULL,
  moderator_uuid uuid NOT NULL,
  reason         text,
  note           text,
  action_at      timestamptz NOT NULL DEFAULT now(),
  created_by     uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  archived_at    timestamptz,
  CONSTRAINT moderation_action_pkey PRIMARY KEY (id),
  CONSTRAINT moderation_action_reason_not_blank
    CHECK (reason IS NULL OR length(btrim(reason)) > 0)
);
CREATE INDEX IF NOT EXISTS idx_moderation_action_report
  ON public.moderation_action (report_uuid);
CREATE INDEX IF NOT EXISTS idx_moderation_action_target
  ON public.moderation_action (target_type, target_uuid);
CREATE INDEX IF NOT EXISTS idx_moderation_action_moderator
  ON public.moderation_action (moderator_uuid);
CREATE INDEX IF NOT EXISTS idx_moderation_action_live_recent
  ON public.moderation_action (action_at DESC) WHERE archived_at IS NULL;

-- Blocking prevents direct messages, request replies, and new exchanges between
-- the pair and cancels their pending exchanges. Checked in both directions by
-- the API; prior messages stay readable for reporting (v1.1 §5).
CREATE TABLE IF NOT EXISTS public.account_block (
  id           bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  uuid         uuid NOT NULL UNIQUE,
  blocker_uuid uuid NOT NULL,
  blocked_uuid uuid NOT NULL,
  reason       text,
  blocked_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  archived_at  timestamptz,
  CONSTRAINT account_block_pkey PRIMARY KEY (id),
  CONSTRAINT account_block_no_self CHECK (blocker_uuid <> blocked_uuid)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_account_block_live_pair
  ON public.account_block (blocker_uuid, blocked_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_account_block_blocked
  ON public.account_block (blocked_uuid);


-- ===========================================================================
-- Access control
--
-- RLS is on for every table with no anon/authenticated policies: direct table
-- access is denied by default. All role / ownership / participation checks live
-- in the API, which uses a service-role client (RLS bypass). If a future client
-- connects directly, add scoped policies in a new forward migration (§10).
-- ===========================================================================
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'account', 'credential', 'consent', 'policy', 'policy_acceptance',
    'pilot_area', 'staff_role_assignment',
    'category', 'setting', 'backup_run', 'account_deletion_request',
    'photo', 'offer', 'request', 'request_reply',
    'conversation', 'message', 'exchange', 'exchange_confirmation', 'review',
    'report', 'moderation_action', 'account_block'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

COMMIT;
