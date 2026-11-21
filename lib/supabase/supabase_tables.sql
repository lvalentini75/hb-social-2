-- ============================================================================
-- HB Social 2.0 — Foundation schema (P03 / part a1)
-- Tables, indexes, functions, triggers. Policies live in supabase_policies.sql,
-- storage buckets in storage.sql, reference rows in seed_reference.sql.
-- Deploy order: supabase_tables.sql → supabase_policies.sql → storage.sql → seed_reference.sql
-- Idempotent: every statement can be re-run. No data rows in this file.
-- Conventions: uuid pks, timestamptz, status text + check (no lifecycle booleans),
-- country_code char(2) on every content / community / commerce / hunting table,
-- money as amount_minor bigint + currency_code char(3), counters maintained by triggers only.
-- ============================================================================

-- Extensions: if the project already has them in schema "extensions" these are no-ops;
-- every security definer function below searches public, extensions so both layouts work.
create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists pg_trgm;

-- ============================================================================
-- 1. REFERENCE TABLES (no dependency on users)
-- ============================================================================

create table if not exists currencies (
  code        char(3) primary key,
  name        text not null,
  symbol      text not null,
  minor_units smallint not null default 2 check (minor_units between 0 and 4),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists countries (
  code             char(2) primary key,
  name             text not null,
  default_currency char(3) not null references currencies(code),
  default_locale   text not null default 'en' check (default_locale in ('it','en','fr','es','de')),
  unit_system      text not null default 'metric' check (unit_system in ('metric','imperial')),
  is_active        boolean not null default true,
  sort_order       smallint not null default 100,
  created_at       timestamptz not null default now()
);

create table if not exists regions (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code) on delete cascade,
  code         text not null,
  name         text not null,
  kind         text not null default 'region',          -- region | province | department | land | state | nation
  istat_code   text,
  sort_order   smallint not null default 100,
  created_at   timestamptz not null default now(),
  unique (country_code, code)
);
create index if not exists idx_regions_country on regions(country_code);

create table if not exists hunting_units (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code) on delete cascade,
  region_id    uuid references regions(id) on delete cascade,
  unit_type    text not null,                             -- atc | ca | acca | coto | revier | estate | wmu | other
  code         text,
  name         text not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_hunting_units_region on hunting_units(region_id);
create index if not exists idx_hunting_units_country on hunting_units(country_code);
create unique index if not exists uq_hunting_units_region_code on hunting_units(region_id, code) where code is not null;

create table if not exists species (
  id              uuid primary key default gen_random_uuid(),
  scientific_name text not null unique,
  category        text not null default 'other'
                  check (category in ('ungulate','small_game','migratory','waterfowl','predator','other')),
  created_at      timestamptz not null default now()
);

create table if not exists species_names (
  id         uuid primary key default gen_random_uuid(),
  species_id uuid not null references species(id) on delete cascade,
  locale     text not null check (locale in ('it','en','fr','es','de')),
  name       text not null,
  created_at timestamptz not null default now(),
  unique (species_id, locale)
);
create index if not exists idx_species_names_species on species_names(species_id);

create table if not exists categories (
  id            uuid primary key default gen_random_uuid(),
  kind          text not null check (kind in ('marketplace','page','event')),
  slug          text not null,
  name_key      text not null,                            -- translation key, e.g. marketplace.category.optics
  parent_id     uuid references categories(id) on delete set null,
  is_restricted boolean not null default false,          -- true: firearms & ammunition (mediated showcase)
  sort_order    smallint not null default 100,
  created_at    timestamptz not null default now(),
  unique (kind, slug)
);

-- ============================================================================
-- 2. IDENTITY
-- ============================================================================

create table if not exists user_profiles (
  id                 uuid primary key references auth.users(id) on delete cascade,
  username           citext not null unique check (length(username) between 3 and 30 and username ~ '^[a-z0-9_]+$'),
  display_name       text not null check (length(display_name) between 1 and 60),
  bio                text check (bio is null or length(bio) <= 500),
  avatar_url         text,
  cover_url          text,
  country_code       char(2) not null default 'IT' references countries(code),
  home_region_id     uuid references regions(id) on delete set null,
  hunting_unit_id    uuid references hunting_units(id) on delete set null,
  locale             text not null default 'it' check (locale in ('it','en','fr','es','de')),
  currency_code      char(3) not null default 'EUR' references currencies(code),
  unit_system        text not null default 'metric' check (unit_system in ('metric','imperial')),
  status             text not null default 'active' check (status in ('active','suspended','banned','deleted')),
  verification_level text not null default 'none' check (verification_level in ('none','hunter','gun_shop','guide','association')),
  follower_count     integer not null default 0,
  following_count    integer not null default 0,
  post_count         integer not null default 0,
  outing_count       integer not null default 0,
  last_seen_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists idx_user_profiles_country on user_profiles(country_code);
create index if not exists idx_user_profiles_region on user_profiles(home_region_id);
create index if not exists idx_user_profiles_status on user_profiles(status);
create index if not exists idx_user_profiles_display_name_trgm on user_profiles using gin (display_name gin_trgm_ops);

create table if not exists user_settings (
  user_id        uuid primary key references user_profiles(id) on delete cascade,
  theme          text not null default 'system' check (theme in ('light','dark','system')),
  push_enabled   boolean not null default true,
  email_enabled  boolean not null default true,
  digest_weekly  boolean not null default true,
  show_location  boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists user_interests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references user_profiles(id) on delete cascade,
  interest   text not null,
  created_at timestamptz not null default now(),
  unique (user_id, interest)
);

create table if not exists follows (
  id           uuid primary key default gen_random_uuid(),
  follower_id  uuid not null references user_profiles(id) on delete cascade,
  following_id uuid not null references user_profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  unique (follower_id, following_id),
  check (follower_id <> following_id)
);
create index if not exists idx_follows_following on follows(following_id);

create table if not exists blocks (
  id         uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references user_profiles(id) on delete cascade,
  blocked_id uuid not null references user_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index if not exists idx_blocks_blocked on blocks(blocked_id);

create table if not exists notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references user_profiles(id) on delete cascade,
  actor_id    uuid references user_profiles(id) on delete set null,
  kind        text not null,                                -- follow | reaction | comment | mention | group_request | ...
  target_type text,
  target_id   uuid,
  data        jsonb not null default '{}'::jsonb,
  read_at     timestamptz,                                  -- null = unread
  created_at  timestamptz not null default now()
);
create index if not exists idx_notifications_user_created on notifications(user_id, created_at desc, id);
create index if not exists idx_notifications_user_unread on notifications(user_id) where read_at is null;

create table if not exists push_tokens (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references user_profiles(id) on delete cascade,
  token        text not null unique,
  platform     text not null check (platform in ('ios','android','web')),
  last_used_at timestamptz,
  created_at   timestamptz not null default now()
);
create index if not exists idx_push_tokens_user on push_tokens(user_id);

create table if not exists verification_requests (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references user_profiles(id) on delete cascade,
  badge_type       text not null check (badge_type in ('hunter','gun_shop','guide','association')),
  document_path    text,                                    -- storage path inside private bucket verification-docs
  declared_data    jsonb not null default '{}'::jsonb,      -- licence number, issuer, expiry, VAT id...
  status           text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by      uuid references user_profiles(id) on delete set null,
  reviewed_at      timestamptz,
  rejection_reason text,
  expires_at       date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists idx_verification_requests_user on verification_requests(user_id);
create index if not exists idx_verification_requests_status on verification_requests(status, created_at desc);

-- ============================================================================
-- 3. COMMUNITY (groups, pages, forums, events) — before posts, which reference them
-- ============================================================================

create table if not exists groups (
  id           uuid primary key default gen_random_uuid(),
  slug         citext not null unique check (length(slug) between 3 and 60),
  name         text not null check (length(name) between 3 and 80),
  description  text,
  avatar_url   text,
  cover_url    text,
  owner_id     uuid not null references user_profiles(id) on delete restrict,
  visibility   text not null default 'public' check (visibility in ('public','private','secret')),
  join_policy  text not null default 'open' check (join_policy in ('open','approval')),
  category     text,
  country_code char(2) not null default 'IT' references countries(code),
  region_id    uuid references regions(id) on delete set null,
  member_count integer not null default 0,
  post_count   integer not null default 0,
  status       text not null default 'active' check (status in ('active','archived','removed')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_groups_owner on groups(owner_id);
create index if not exists idx_groups_country on groups(country_code);
create index if not exists idx_groups_region on groups(region_id);
create index if not exists idx_groups_created on groups(created_at desc, id);

create table if not exists group_members (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references groups(id) on delete cascade,
  user_id    uuid not null references user_profiles(id) on delete cascade,
  role       text not null default 'member' check (role in ('owner','admin','moderator','member')),
  status     text not null default 'active' check (status in ('active','pending','banned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (group_id, user_id)
);
create index if not exists idx_group_members_user on group_members(user_id);

create table if not exists pages (
  id                  uuid primary key default gen_random_uuid(),
  slug                citext not null unique check (length(slug) between 3 and 60),
  name                text not null check (length(name) between 2 and 80),
  description         text,
  avatar_url          text,
  cover_url           text,
  owner_id            uuid not null references user_profiles(id) on delete restrict,
  category            text not null check (category in ('company','association','breeder','gun_shop','guide','manufacturer','media')),
  verification_status text not null default 'none' check (verification_status in ('none','pending','verified','rejected')),
  website             text,
  phone               text,
  email               text,
  address             text,
  region_id           uuid references regions(id) on delete set null,
  country_code        char(2) not null default 'IT' references countries(code),
  follower_count      integer not null default 0,
  status              text not null default 'active' check (status in ('active','archived','removed')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index if not exists idx_pages_owner on pages(owner_id);
create index if not exists idx_pages_country on pages(country_code);
create index if not exists idx_pages_category on pages(category);

create table if not exists page_roles (
  id         uuid primary key default gen_random_uuid(),
  page_id    uuid not null references pages(id) on delete cascade,
  user_id    uuid not null references user_profiles(id) on delete cascade,
  role       text not null default 'editor' check (role in ('owner','editor','moderator')),
  created_at timestamptz not null default now(),
  unique (page_id, user_id)
);
create index if not exists idx_page_roles_user on page_roles(user_id);

create table if not exists page_followers (
  id         uuid primary key default gen_random_uuid(),
  page_id    uuid not null references pages(id) on delete cascade,
  user_id    uuid not null references user_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (page_id, user_id)
);
create index if not exists idx_page_followers_user on page_followers(user_id);

create table if not exists forums (
  id           uuid primary key default gen_random_uuid(),
  slug         citext not null unique check (length(slug) between 3 and 60),
  name         text not null check (length(name) between 3 and 80),
  description  text,
  category     text,
  visibility   text not null default 'public' check (visibility in ('public','private')),
  owner_id     uuid not null references user_profiles(id) on delete restrict,
  country_code char(2) not null default 'IT' references countries(code),
  member_count integer not null default 0,
  thread_count integer not null default 0,
  status       text not null default 'active' check (status in ('active','archived','removed')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_forums_country on forums(country_code);

create table if not exists forum_members (
  id         uuid primary key default gen_random_uuid(),
  forum_id   uuid not null references forums(id) on delete cascade,
  user_id    uuid not null references user_profiles(id) on delete cascade,
  role       text not null default 'member' check (role in ('owner','moderator','member')),
  status     text not null default 'active' check (status in ('active','pending','banned')),
  created_at timestamptz not null default now(),
  unique (forum_id, user_id)
);
create index if not exists idx_forum_members_user on forum_members(user_id);

create table if not exists forum_threads (
  id                uuid primary key default gen_random_uuid(),
  forum_id          uuid not null references forums(id) on delete cascade,
  author_id         uuid not null references user_profiles(id) on delete cascade,
  title             text not null check (length(title) between 3 and 160),
  content           text,
  is_pinned         boolean not null default false,
  is_locked         boolean not null default false,
  solution_reply_id uuid,                                    -- fk added after forum_replies exists
  reply_count       integer not null default 0,
  view_count        integer not null default 0,
  status            text not null default 'published' check (status in ('published','hidden','removed')),
  country_code      char(2) not null default 'IT' references countries(code),
  last_reply_at     timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists idx_forum_threads_forum_created on forum_threads(forum_id, created_at desc, id);
create index if not exists idx_forum_threads_author on forum_threads(author_id);

create table if not exists forum_replies (
  id             uuid primary key default gen_random_uuid(),
  thread_id      uuid not null references forum_threads(id) on delete cascade,
  author_id      uuid not null references user_profiles(id) on delete cascade,
  parent_id      uuid references forum_replies(id) on delete cascade,
  content        text not null,
  reaction_count integer not null default 0,
  status         text not null default 'published' check (status in ('published','hidden','removed')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists idx_forum_replies_thread_created on forum_replies(thread_id, created_at, id);
create index if not exists idx_forum_replies_author on forum_replies(author_id);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'forum_threads_solution_reply_fk') then
    alter table forum_threads
      add constraint forum_threads_solution_reply_fk
      foreign key (solution_reply_id) references forum_replies(id) on delete set null;
  end if;
end $$;

create table if not exists events (
  id                 uuid primary key default gen_random_uuid(),
  title              text not null check (length(title) between 3 and 120),
  description        text,
  cover_url          text,
  category           text not null check (category in ('meetup','shooting','drive','fair','course')),
  organizer_user_id  uuid references user_profiles(id) on delete cascade,
  organizer_page_id  uuid references pages(id) on delete cascade,
  organizer_group_id uuid references groups(id) on delete cascade,
  starts_at          timestamptz not null,
  ends_at            timestamptz,
  location_name      text,
  address            text,
  lat                double precision,
  lng                double precision,
  region_id          uuid references regions(id) on delete set null,
  hunting_unit_id    uuid references hunting_units(id) on delete set null,
  capacity           integer check (capacity is null or capacity > 0),
  price_minor        bigint not null default 0 check (price_minor >= 0),
  currency_code      char(3) not null default 'EUR' references currencies(code),
  status             text not null default 'draft' check (status in ('draft','published','cancelled')),
  attendee_count     integer not null default 0,
  country_code       char(2) not null default 'IT' references countries(code),
  created_by         uuid not null references user_profiles(id) on delete restrict,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  check (num_nonnulls(organizer_user_id, organizer_page_id, organizer_group_id) = 1),
  check (ends_at is null or ends_at >= starts_at)
);
create index if not exists idx_events_starts on events(starts_at);
create index if not exists idx_events_country on events(country_code);
create index if not exists idx_events_region on events(region_id);
create index if not exists idx_events_page on events(organizer_page_id);
create index if not exists idx_events_group on events(organizer_group_id);
create index if not exists idx_events_created_by on events(created_by);

create table if not exists event_participants (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references events(id) on delete cascade,
  user_id       uuid not null references user_profiles(id) on delete cascade,
  status        text not null default 'going' check (status in ('going','interested','waitlist','checked_in','cancelled')),
  ticket_code   text unique,
  checked_in_at timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (event_id, user_id)
);
create index if not exists idx_event_participants_user on event_participants(user_id);

-- ============================================================================
-- 4. CONTENT
-- ============================================================================

create table if not exists posts (
  id              uuid primary key default gen_random_uuid(),
  author_id       uuid not null references user_profiles(id) on delete cascade,
  group_id        uuid references groups(id) on delete cascade,
  page_id         uuid references pages(id) on delete cascade,
  kind            text not null default 'text' check (kind in ('text','photo','video','poll','checkin')),
  content         text check (content is null or length(content) <= 5000),
  visibility      text not null default 'public' check (visibility in ('public','followers','group')),
  hunting_unit_id uuid references hunting_units(id) on delete set null,
  location_name   text,
  lat             double precision,
  lng             double precision,
  is_sensitive    boolean not null default false,          -- content attribute (blur), not a lifecycle flag
  status          text not null default 'published' check (status in ('published','hidden','removed')),
  country_code    char(2) not null default 'IT' references countries(code),
  reaction_count  integer not null default 0,
  comment_count   integer not null default 0,
  share_count     integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (group_id is null or page_id is null),
  check (visibility <> 'group' or group_id is not null)
);
create index if not exists idx_posts_created on posts(created_at desc, id);
create index if not exists idx_posts_author_created on posts(author_id, created_at desc, id);
create index if not exists idx_posts_group_created on posts(group_id, created_at desc, id) where group_id is not null;
create index if not exists idx_posts_page_created on posts(page_id, created_at desc, id) where page_id is not null;
create index if not exists idx_posts_country on posts(country_code);
create index if not exists idx_posts_unit on posts(hunting_unit_id) where hunting_unit_id is not null;

create table if not exists post_media (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references posts(id) on delete cascade,
  path        text not null,                                -- storage path in bucket post-media
  kind        text not null check (kind in ('image','video')),
  width       integer,
  height      integer,
  duration_ms integer,
  sort_order  smallint not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists idx_post_media_post on post_media(post_id, sort_order);

create table if not exists reactions (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references posts(id) on delete cascade,
  user_id       uuid not null references user_profiles(id) on delete cascade,
  reaction_type text not null default 'like' check (reaction_type in ('like','love','respect','wow','laugh','sad')),
  created_at    timestamptz not null default now(),
  unique (post_id, user_id)
);
create index if not exists idx_reactions_user on reactions(user_id);

create table if not exists comments (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid not null references posts(id) on delete cascade,
  author_id      uuid not null references user_profiles(id) on delete cascade,
  parent_id      uuid references comments(id) on delete cascade,
  content        text not null check (length(content) between 1 and 2000),
  reaction_count integer not null default 0,
  status         text not null default 'published' check (status in ('published','hidden','removed')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists idx_comments_post_created on comments(post_id, created_at, id);
create index if not exists idx_comments_author on comments(author_id);
create index if not exists idx_comments_parent on comments(parent_id) where parent_id is not null;

create table if not exists stories (
  id           uuid primary key default gen_random_uuid(),
  author_id    uuid not null references user_profiles(id) on delete cascade,
  media_path   text not null,                               -- storage path in bucket story-media
  kind         text not null check (kind in ('image','video')),
  caption      text check (caption is null or length(caption) <= 300),
  expires_at   timestamptz not null default (now() + interval '24 hours'),
  view_count   integer not null default 0,
  status       text not null default 'active' check (status in ('active','expired','removed')),
  country_code char(2) not null default 'IT' references countries(code),
  created_at   timestamptz not null default now()
);
create index if not exists idx_stories_author_created on stories(author_id, created_at desc);
create index if not exists idx_stories_expires on stories(expires_at) where status = 'active';

create table if not exists hashtags (
  id         uuid primary key default gen_random_uuid(),
  tag        citext not null unique check (length(tag) between 2 and 60),
  post_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists post_hashtags (
  post_id    uuid not null references posts(id) on delete cascade,
  hashtag_id uuid not null references hashtags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, hashtag_id)
);
create index if not exists idx_post_hashtags_hashtag on post_hashtags(hashtag_id, created_at desc);

-- ============================================================================
-- 5. CHAT
-- ============================================================================

create table if not exists conversations (
  id              uuid primary key default gen_random_uuid(),
  kind            text not null default 'direct' check (kind in ('direct','group')),
  title           text,
  created_by      uuid not null references user_profiles(id) on delete restrict,
  last_message_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists idx_conversations_last_message on conversations(last_message_at desc nulls last);

create table if not exists conversation_participants (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  user_id         uuid not null references user_profiles(id) on delete cascade,
  role            text not null default 'member' check (role in ('owner','member')),
  last_read_at    timestamptz,
  muted_until     timestamptz,
  created_at      timestamptz not null default now(),
  unique (conversation_id, user_id)
);
create index if not exists idx_conversation_participants_user on conversation_participants(user_id);

create table if not exists messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id       uuid not null references user_profiles(id) on delete cascade,
  kind            text not null default 'text' check (kind in ('text','image','voice','system')),
  body            text check (body is null or length(body) <= 4000),
  media_path      text,
  duration_ms     integer,
  reply_to_id     uuid references messages(id) on delete set null,
  status          text not null default 'sent' check (status in ('sent','edited','deleted')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (kind = 'system' or body is not null or media_path is not null)
);
create index if not exists idx_messages_conversation_created on messages(conversation_id, created_at desc, id);
create index if not exists idx_messages_sender on messages(sender_id);

-- ============================================================================
-- 6. COMMERCE
-- ============================================================================

create table if not exists listings (
  id             uuid primary key default gen_random_uuid(),
  seller_id      uuid not null references user_profiles(id) on delete cascade,
  category_id    uuid not null references categories(id) on delete restrict,
  title          text not null check (length(title) between 3 and 120),
  description    text check (description is null or length(description) <= 5000),
  price_minor    bigint not null check (price_minor >= 0),
  currency_code  char(3) not null default 'EUR' references currencies(code),
  condition      text not null default 'good' check (condition in ('new','like_new','good','fair')),
  region_id      uuid references regions(id) on delete set null,
  municipality   text,
  lat            double precision,
  lng            double precision,
  is_mediated    boolean not null default false,            -- set by trigger from categories.is_restricted
  status         text not null default 'draft' check (status in ('draft','active','reserved','sold','removed')),
  country_code   char(2) not null default 'IT' references countries(code),
  view_count     integer not null default 0,
  favorite_count integer not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists idx_listings_created on listings(created_at desc, id);
create index if not exists idx_listings_seller on listings(seller_id);
create index if not exists idx_listings_category_status on listings(category_id, status);
create index if not exists idx_listings_country_region on listings(country_code, region_id);
create index if not exists idx_listings_title_trgm on listings using gin (title gin_trgm_ops);

create table if not exists listing_media (
  id         uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings(id) on delete cascade,
  path       text not null,                                 -- storage path in bucket listing-media
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_listing_media_listing on listing_media(listing_id, sort_order);

-- ============================================================================
-- 7. HUNTING (calendars, logs, dogs)
-- ============================================================================

create table if not exists hunting_calendars (
  id              uuid primary key default gen_random_uuid(),
  country_code    char(2) not null references countries(code),
  region_id       uuid not null references regions(id) on delete cascade,
  hunting_unit_id uuid references hunting_units(id) on delete cascade,
  species_id      uuid not null references species(id) on delete cascade,
  season_label    text not null,                            -- e.g. 2026/27
  valid_from      date not null,
  valid_to        date not null,
  source_name     text,
  source_url      text,
  status          text not null default 'draft' check (status in ('draft','published','archived')),
  published_by    uuid references user_profiles(id) on delete set null,
  published_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (valid_to >= valid_from)
);
create unique index if not exists uq_hunting_calendars_scope
  on hunting_calendars(region_id, coalesce(hunting_unit_id, '00000000-0000-0000-0000-000000000000'::uuid), species_id, valid_from);
create index if not exists idx_hunting_calendars_region_status on hunting_calendars(region_id, status);
create index if not exists idx_hunting_calendars_species on hunting_calendars(species_id);

create table if not exists calendar_rules (
  id           uuid primary key default gen_random_uuid(),
  calendar_id  uuid not null references hunting_calendars(id) on delete cascade,
  kind         text not null check (kind in ('open_period','closed_period','allowed_days','time_rule','bag_limit')),
  date_from    date,
  date_to      date,
  allowed_days smallint[],                                  -- ISO weekday numbers 1 (Mon) .. 7 (Sun)
  time_rule    text,                                        -- e.g. sunrise-1h/sunset+1h or 07:00-17:00
  bag_limit    integer check (bag_limit is null or bag_limit >= 0),
  bag_period   text check (bag_period is null or bag_period in ('day','season')),
  notes        text,
  sort_order   smallint not null default 0,
  created_at   timestamptz not null default now(),
  check (date_to is null or date_from is null or date_to >= date_from)
);
create index if not exists idx_calendar_rules_calendar on calendar_rules(calendar_id, sort_order);

create table if not exists hunting_logs (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references user_profiles(id) on delete cascade,
  hunting_unit_id uuid references hunting_units(id) on delete set null,
  region_id       uuid references regions(id) on delete set null,
  started_at      timestamptz not null,
  ended_at        timestamptz,
  zone_name       text,
  weather         jsonb not null default '{}'::jsonb,
  distance_m      integer check (distance_m is null or distance_m >= 0),
  notes           text,
  visibility      text not null default 'private' check (visibility in ('private','followers','public')),
  country_code    char(2) not null default 'IT' references countries(code),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (ended_at is null or ended_at >= started_at)
);
create index if not exists idx_hunting_logs_user_started on hunting_logs(user_id, started_at desc, id);
create index if not exists idx_hunting_logs_unit on hunting_logs(hunting_unit_id);

create table if not exists hunting_log_species (
  id            uuid primary key default gen_random_uuid(),
  log_id        uuid not null references hunting_logs(id) on delete cascade,
  species_id    uuid not null references species(id) on delete restrict,
  harvest_count integer not null default 0 check (harvest_count >= 0),
  created_at    timestamptz not null default now(),
  unique (log_id, species_id)
);

create table if not exists dogs (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references user_profiles(id) on delete cascade,
  name             text not null check (length(name) between 1 and 40),
  breed            text,
  sex              text check (sex is null or sex in ('male','female')),
  birth_date       date,
  pedigree_number  text,
  microchip_number text unique,
  avatar_url       text,
  cover_url        text,
  status           text not null default 'active' check (status in ('active','retired','deceased')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists idx_dogs_owner on dogs(owner_id);

create table if not exists hunting_log_dogs (
  log_id     uuid not null references hunting_logs(id) on delete cascade,
  dog_id     uuid not null references dogs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (log_id, dog_id)
);

-- ============================================================================
-- 8. I18N / PLATFORM
-- ============================================================================

create table if not exists exchange_rates (
  id         uuid primary key default gen_random_uuid(),
  base_code  char(3) not null references currencies(code),
  quote_code char(3) not null references currencies(code),
  rate       numeric(18,8) not null check (rate > 0),
  valid_on   date not null,
  source     text,
  created_at timestamptz not null default now(),
  unique (base_code, quote_code, valid_on),
  check (base_code <> quote_code)
);
create index if not exists idx_exchange_rates_lookup on exchange_rates(base_code, quote_code, valid_on desc);

create table if not exists feature_flags (
  id                 uuid primary key default gen_random_uuid(),
  module             text not null,
  country_code       char(2) references countries(code) on delete cascade,   -- null = every country
  is_enabled         boolean not null default false,
  rollout_percentage smallint not null default 100 check (rollout_percentage between 0 and 100),
  description        text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create unique index if not exists uq_feature_flags_module_country on feature_flags(module, coalesce(country_code, '**'));

create table if not exists country_policies (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code) on delete cascade,
  policy_type  text not null,                               -- firearms_marketplace | sensitive_content | minimum_age | ...
  policy_data  jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (country_code, policy_type)
);

-- ============================================================================
-- 9. MODERATION & ADMIN
-- ============================================================================

create table if not exists reports (
  id               uuid primary key default gen_random_uuid(),
  reporter_id      uuid references user_profiles(id) on delete set null,
  target_type      text not null check (target_type in ('post','comment','listing','profile','thread','reply','story','message','group','page','event')),
  target_id        uuid not null,
  target_author_id uuid references user_profiles(id) on delete set null,
  reason           text not null check (reason in ('spam','harassment','hate','violence','animal_abuse','illegal','sensitive','scam','other')),
  details          text,
  priority         text not null default 'medium' check (priority in ('high','medium','low')),
  status           text not null default 'pending' check (status in ('pending','in_progress','resolved','removed')),
  assigned_to      uuid references user_profiles(id) on delete set null,
  resolved_at      timestamptz,
  resolution       text,
  country_code     char(2) not null default 'IT' references countries(code),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists idx_reports_status_priority_created on reports(status, priority, created_at);
create index if not exists idx_reports_target on reports(target_type, target_id);
create index if not exists idx_reports_assigned on reports(assigned_to) where assigned_to is not null;

create table if not exists admin_roles (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique check (name in ('superadmin','admin','moderator','ads_reviewer','finance','hunting_data_editor')),
  description text,
  created_at  timestamptz not null default now()
);

create table if not exists admin_role_permissions (
  role_id uuid not null references admin_roles(id) on delete cascade,
  module  text not null,                                    -- slug of the console module (users, reports, ...)
  access  text not null default 'none' check (access in ('none','read','write')),
  primary key (role_id, module)
);

create table if not exists admin_users (
  user_id     uuid primary key references user_profiles(id) on delete cascade,
  role_id     uuid not null references admin_roles(id) on delete restrict,
  mfa_enabled boolean not null default false,
  created_by  uuid references user_profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists idx_admin_users_role on admin_users(role_id);

create table if not exists admin_audit_log (
  id            uuid primary key default gen_random_uuid(),
  admin_id      uuid references user_profiles(id) on delete set null,
  action        text not null,
  resource_type text,
  resource_id   text,
  changes       jsonb,
  created_at    timestamptz not null default now()
);
create index if not exists idx_admin_audit_log_created on admin_audit_log(created_at desc, id);
create index if not exists idx_admin_audit_log_resource on admin_audit_log(resource_type, resource_id);

-- ============================================================================
-- 10. FUNCTIONS
-- ============================================================================

-- updated_at maintenance
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- Block relation in either direction (used by policies and feeds)
create or replace function is_blocked(a uuid, b uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select a is not null and b is not null and exists (
    select 1 from blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  )
$$;

-- Profile creation on signup (metadata keys: username, display_name, country_code, locale)
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare
  meta          jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_username    text;
  v_display     text;
  v_country     char(2);
  v_locale      text;
  v_currency    char(3);
  v_unit_system text;
begin
  v_country := upper(nullif(trim(meta->>'country_code'), ''));
  if v_country is null or not exists (select 1 from countries where code = v_country and is_active) then
    v_country := 'IT';
  end if;

  v_locale := lower(nullif(trim(meta->>'locale'), ''));
  if v_locale is null or v_locale not in ('it','en','fr','es','de') then
    select default_locale into v_locale from countries where code = v_country;
  end if;

  select default_currency, unit_system into v_currency, v_unit_system from countries where code = v_country;

  v_username := lower(regexp_replace(coalesce(nullif(trim(meta->>'username'), ''), split_part(coalesce(new.email, ''), '@', 1)), '[^a-z0-9_]', '_', 'gi'));
  if v_username is null or length(v_username) < 3 then
    v_username := 'user_' || left(replace(new.id::text, '-', ''), 10);
  end if;
  v_username := left(v_username, 24);
  if exists (select 1 from user_profiles where username = v_username) then
    v_username := left(v_username, 20) || '_' || left(replace(new.id::text, '-', ''), 4);
  end if;

  v_display := left(coalesce(nullif(trim(meta->>'display_name'), ''), split_part(coalesce(new.email, ''), '@', 1), 'Cacciatore'), 60);
  if length(v_display) = 0 then v_display := 'Cacciatore'; end if;

  insert into user_profiles (id, username, display_name, country_code, locale, currency_code, unit_system)
  values (new.id, v_username, v_display, v_country, v_locale, v_currency, v_unit_system)
  on conflict (id) do nothing;

  insert into user_settings (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end $$;

-- Counter triggers ------------------------------------------------------------

create or replace function trg_follows_counters()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  perform set_config('hb.internal', 'on', true);
  if tg_op = 'INSERT' then
    update user_profiles set following_count = following_count + 1 where id = new.follower_id;
    update user_profiles set follower_count = follower_count + 1 where id = new.following_id;
    perform set_config('hb.internal', '', true);
    return new;
  elsif tg_op = 'DELETE' then
    update user_profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update user_profiles set follower_count = greatest(follower_count - 1, 0) where id = old.following_id;
    perform set_config('hb.internal', '', true);
    return old;
  end if;
  perform set_config('hb.internal', '', true);
  return null;
end $$;

create or replace function trg_group_members_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare delta integer := 0;
begin
  if tg_op = 'INSERT' and new.status = 'active' then delta := 1;
  elsif tg_op = 'DELETE' and old.status = 'active' then delta := -1;
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status then
    delta := (case when new.status = 'active' then 1 else 0 end) - (case when old.status = 'active' then 1 else 0 end);
  end if;
  if delta <> 0 then
    update groups set member_count = greatest(member_count + delta, 0) where id = coalesce(new.group_id, old.group_id);
  end if;
  return coalesce(new, old);
end $$;

create or replace function trg_forum_members_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare delta integer := 0;
begin
  if tg_op = 'INSERT' and new.status = 'active' then delta := 1;
  elsif tg_op = 'DELETE' and old.status = 'active' then delta := -1;
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status then
    delta := (case when new.status = 'active' then 1 else 0 end) - (case when old.status = 'active' then 1 else 0 end);
  end if;
  if delta <> 0 then
    update forums set member_count = greatest(member_count + delta, 0) where id = coalesce(new.forum_id, old.forum_id);
  end if;
  return coalesce(new, old);
end $$;

create or replace function trg_page_followers_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update pages set follower_count = follower_count + 1 where id = new.page_id;
    return new;
  elsif tg_op = 'DELETE' then
    update pages set follower_count = greatest(follower_count - 1, 0) where id = old.page_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_forum_threads_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update forums set thread_count = thread_count + 1 where id = new.forum_id;
    return new;
  elsif tg_op = 'DELETE' then
    update forums set thread_count = greatest(thread_count - 1, 0) where id = old.forum_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_forum_replies_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update forum_threads set reply_count = reply_count + 1, last_reply_at = new.created_at where id = new.thread_id;
    return new;
  elsif tg_op = 'DELETE' then
    update forum_threads set reply_count = greatest(reply_count - 1, 0) where id = old.thread_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_reactions_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update posts set reaction_count = reaction_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update posts set reaction_count = greatest(reaction_count - 1, 0) where id = old.post_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_comments_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update posts set comment_count = comment_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_posts_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  perform set_config('hb.internal', 'on', true);
  if tg_op = 'INSERT' then
    update user_profiles set post_count = post_count + 1 where id = new.author_id;
    if new.group_id is not null then update groups set post_count = post_count + 1 where id = new.group_id; end if;
    perform set_config('hb.internal', '', true);
    return new;
  elsif tg_op = 'DELETE' then
    update user_profiles set post_count = greatest(post_count - 1, 0) where id = old.author_id;
    if old.group_id is not null then update groups set post_count = greatest(post_count - 1, 0) where id = old.group_id; end if;
    perform set_config('hb.internal', '', true);
    return old;
  end if;
  perform set_config('hb.internal', '', true);
  return null;
end $$;

create or replace function trg_event_participants_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare
  counts_old boolean := tg_op in ('UPDATE','DELETE') and old.status in ('going','checked_in');
  counts_new boolean := tg_op in ('UPDATE','INSERT') and new.status in ('going','checked_in');
  delta integer := (case when counts_new then 1 else 0 end) - (case when counts_old then 1 else 0 end);
begin
  if delta <> 0 then
    update events set attendee_count = greatest(attendee_count + delta, 0) where id = coalesce(new.event_id, old.event_id);
  end if;
  return coalesce(new, old);
end $$;

create or replace function trg_post_hashtags_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if tg_op = 'INSERT' then
    update hashtags set post_count = post_count + 1 where id = new.hashtag_id;
    return new;
  elsif tg_op = 'DELETE' then
    update hashtags set post_count = greatest(post_count - 1, 0) where id = old.hashtag_id;
    return old;
  end if;
  return null;
end $$;

create or replace function trg_hunting_logs_counter()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  perform set_config('hb.internal', 'on', true);
  if tg_op = 'INSERT' then
    update user_profiles set outing_count = outing_count + 1 where id = new.user_id;
    perform set_config('hb.internal', '', true);
    return new;
  elsif tg_op = 'DELETE' then
    update user_profiles set outing_count = greatest(outing_count - 1, 0) where id = old.user_id;
    perform set_config('hb.internal', '', true);
    return old;
  end if;
  perform set_config('hb.internal', '', true);
  return null;
end $$;

create or replace function trg_messages_touch_conversation()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  update conversations set last_message_at = new.created_at, updated_at = now() where id = new.conversation_id;
  return new;
end $$;

-- Listings in a restricted category are always mediated (firearms & ammunition)
create or replace function trg_listings_set_mediated()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  select c.is_restricted into new.is_mediated from categories c where c.id = new.category_id;
  new.is_mediated := coalesce(new.is_mediated, false);
  return new;
end $$;

-- Group owner becomes the first member; forum owner likewise
create or replace function trg_groups_add_owner()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  insert into group_members (group_id, user_id, role, status) values (new.id, new.owner_id, 'owner', 'active')
  on conflict (group_id, user_id) do nothing;
  return new;
end $$;

create or replace function trg_forums_add_owner()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  insert into forum_members (forum_id, user_id, role, status) values (new.id, new.owner_id, 'owner', 'active')
  on conflict (forum_id, user_id) do nothing;
  return new;
end $$;

create or replace function trg_pages_add_owner()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  insert into page_roles (page_id, user_id, role) values (new.id, new.owner_id, 'owner')
  on conflict (page_id, user_id) do nothing;
  return new;
end $$;

create or replace function trg_conversations_add_creator()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  insert into conversation_participants (conversation_id, user_id, role) values (new.id, new.created_by, 'owner')
  on conflict (conversation_id, user_id) do nothing;
  return new;
end $$;

-- ============================================================================
-- 11. TRIGGERS (drop + create keeps the file idempotent)
-- ============================================================================

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

do $$
declare t text;
begin
  foreach t in array array[
    'hunting_units','user_profiles','user_settings','verification_requests','groups','group_members','pages','forums',
    'forum_threads','forum_replies','events','event_participants','posts','comments','conversations','messages',
    'listings','hunting_calendars','hunting_logs','dogs','feature_flags','country_policies','reports','admin_users'
  ] loop
    execute format('drop trigger if exists set_updated_at on %I', t);
    execute format('create trigger set_updated_at before update on %I for each row execute function set_updated_at()', t);
  end loop;
end $$;

drop trigger if exists follows_counters on follows;
create trigger follows_counters after insert or delete on follows for each row execute function trg_follows_counters();

drop trigger if exists group_members_counter on group_members;
create trigger group_members_counter after insert or update or delete on group_members for each row execute function trg_group_members_counter();

drop trigger if exists forum_members_counter on forum_members;
create trigger forum_members_counter after insert or update or delete on forum_members for each row execute function trg_forum_members_counter();

drop trigger if exists page_followers_counter on page_followers;
create trigger page_followers_counter after insert or delete on page_followers for each row execute function trg_page_followers_counter();

drop trigger if exists forum_threads_counter on forum_threads;
create trigger forum_threads_counter after insert or delete on forum_threads for each row execute function trg_forum_threads_counter();

drop trigger if exists forum_replies_counter on forum_replies;
create trigger forum_replies_counter after insert or delete on forum_replies for each row execute function trg_forum_replies_counter();

drop trigger if exists reactions_counter on reactions;
create trigger reactions_counter after insert or delete on reactions for each row execute function trg_reactions_counter();

drop trigger if exists comments_counter on comments;
create trigger comments_counter after insert or delete on comments for each row execute function trg_comments_counter();

drop trigger if exists posts_counter on posts;
create trigger posts_counter after insert or delete on posts for each row execute function trg_posts_counter();

drop trigger if exists event_participants_counter on event_participants;
create trigger event_participants_counter after insert or update or delete on event_participants for each row execute function trg_event_participants_counter();

drop trigger if exists post_hashtags_counter on post_hashtags;
create trigger post_hashtags_counter after insert or delete on post_hashtags for each row execute function trg_post_hashtags_counter();

drop trigger if exists hunting_logs_counter on hunting_logs;
create trigger hunting_logs_counter after insert or delete on hunting_logs for each row execute function trg_hunting_logs_counter();

drop trigger if exists messages_touch_conversation on messages;
create trigger messages_touch_conversation after insert on messages for each row execute function trg_messages_touch_conversation();

drop trigger if exists listings_set_mediated on listings;
create trigger listings_set_mediated before insert or update of category_id on listings for each row execute function trg_listings_set_mediated();

drop trigger if exists groups_add_owner on groups;
create trigger groups_add_owner after insert on groups for each row execute function trg_groups_add_owner();

drop trigger if exists forums_add_owner on forums;
create trigger forums_add_owner after insert on forums for each row execute function trg_forums_add_owner();

drop trigger if exists pages_add_owner on pages;
create trigger pages_add_owner after insert on pages for each row execute function trg_pages_add_owner();

drop trigger if exists conversations_add_creator on conversations;
create trigger conversations_add_creator after insert on conversations for each row execute function trg_conversations_add_creator();
