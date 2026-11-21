# HB Social 2.0 — Schema review (P03, foundation schema)

Written outside Dreamflow (external lane), validated on PostgreSQL 16 with a Supabase stub:
all four files deploy twice in a row without errors (idempotent), 58 behavioural RLS checks pass
(`test/10_rls_tests.sql`), `test/verify_deploy.sql` reports every check "ok".

Files, in deploy order:

| # | File | Content |
|---|---|---|
| 1 | `lib/supabase/supabase_tables.sql` | 3 extensions, 52 tables, indexes, 23 functions, 60 triggers |
| 2 | `lib/supabase/supabase_policies.sql` | 27 SECURITY DEFINER helpers (before any policy), RLS on every table, 141 policies, profile-protection trigger |
| 3 | `lib/supabase/storage.sql` | 10 buckets (9 media + private `verification-docs`), object policies |
| 4 | `lib/supabase/seed_reference.sql` | reference rows only: 4 currencies, 6 countries, 20 Italian regions (ISTAT), 8 marketplace categories, 6 admin roles + permission matrix, 7 feature flags, 18 country policies, 36 species × 5 languages |

## Problems in the generated draft and what changed

| Problem in the auto-generated draft | Fix |
|---|---|
| `profiles` INSERT policy `WITH CHECK (true)`: anyone could create any profile | No client insert; `handle_new_user()` trigger on `auth.users` creates `user_profiles` + `user_settings` |
| `messages` INSERT only checked `user_id = auth.uid()`: anyone could write into any conversation | `is_conversation_participant()` required; conversations/participants visible to participants only |
| `conversation_participants`, `group_members`, `blocks` readable by every authenticated user | Participants only; group members visible to members or for public groups; blocks visible to the blocker only |
| `admin_audit_log` INSERT open to every authenticated user | Admins only, `admin_id = auth.uid()` |
| No `drop policy if exists`: second run failed | Every policy drop + create; every object `if not exists` / `create or replace` |
| Reference tables (calendars, species, categories…) had no write policies | Admin roles write: `superadmin/admin` for platform tables, `+hunting_data_editor` for hunting data, `+finance` for exchange rates |
| Public content readable only by authenticated users | Public content readable by anon too (public web); every write requires auth |
| `profiles`, `hunting_countries`, `hunting_regions` names | Canonical `user_profiles`, `countries`, `regions` as in ARCHITECTURE.md |
| `country_code`/`currency_code` plain text, reference tables defined after users | `char(2)`/`char(3)` with FKs; reference tables first; strict dependency order |
| `species.country_code NOT NULL` | Species are global (scientific name unique); availability per country lives in calendars |
| `hunting_calendars UNIQUE(region_id, species_id)` | Unique on `(region, unit, species, valid_from)`: several seasons and years |
| Missing `forum_members`, `page_roles`, `reports`, `verification_requests`, `user_interests`, `hashtags`, `hunting_log_species`, `hunting_log_dogs`, `admin_role_permissions` | Added |
| `posts` without `group_id`, `page_id`, `visibility`, `kind`, `status`; `comments` without `parent_id`; `reactions` unique per type | Added; reactions unique per `(post, user)` with changeable type |
| Lifecycle booleans (`is_public`, `is_verified`, `is_read`) | `status`/`visibility` text + check constraints; `read_at timestamptz` |
| `price_minor INT` | `bigint`, `check >= 0`, `currency_code` FK |
| No triggers at all | `set_updated_at`, 11 counter triggers, owner auto-membership, `last_message_at`, mediated listings, profile protection |
| No storage buckets | 10 buckets with size and MIME limits, owner-folder policies, private documents |

## Decisions recorded here (add to docs/DECISIONS.md)

- Public content (published posts with `visibility = public`, active groups/pages, published events, active listings, published calendars) is readable without login. Chats, reports, verification requests, settings, notifications never are.
- `user_profiles` protected columns (`status`, `verification_level`, counters) are restored by a BEFORE UPDATE trigger unless the actor is an admin; counter triggers set the session flag `hb.internal` to bypass it. Admin actions in P40/P41 go through SECURITY DEFINER RPCs, not raw updates.
- Listings in a restricted category are forced to `is_mediated = true` by trigger (firearms & ammunition = mediated showcase).
- Security definer helpers search `public, extensions` so they work whether extensions live in `public` or in Supabase's `extensions` schema.
- Species list = art. 18 L. 157/92 reference, to be validated by the hunting-data editor in P24; no calendars are seeded (official regional decrees arrive in P24).

## Review checklist (12 points)

| # | Check | Result |
|---|---|---|
| 1 | Dependency order | ok — currencies → countries → regions → hunting_units → species → categories → user_profiles → community → content → chat → commerce → hunting → platform → admin; the only forward reference (`forum_threads.solution_reply_id`) is added with `alter table` after `forum_replies` |
| 2 | Canonical names | ok — `user_profiles`, `countries`, `regions`, `hunting_units`, `hunting_calendars`, `calendar_rules`, `exchange_rates`, snake_case everywhere |
| 3 | Idempotency | ok — deployed twice locally without errors; `drop policy if exists`, `drop trigger if exists`, `create or replace`, `on conflict do nothing` |
| 4 | Helpers before policies | ok — 27 helpers at the top of `supabase_policies.sql`, all `security definer stable set search_path = public, extensions` |
| 5 | No policy queries its own table | ok — `verify_deploy.sql` query 4 returns 0 rows; membership checks only through helpers |
| 6 | RLS on every table | ok — 52/52 (`verify_deploy.sql` queries 2 and 3 return 0 rows) |
| 7 | `country_code` | ok — on user_profiles, posts, stories, groups, pages, forums, forum_threads, events, listings, hunting_calendars, hunting_logs, reports |
| 8 | Money and dates | ok — `*_minor bigint check >= 0` + `currency_code char(3)` FK; every timestamp `timestamptz` |
| 9 | Counters via trigger | ok — follows, group_members, forum_members, page_followers, forum_threads, forum_replies, reactions, comments, posts, event_participants, post_hashtags, hunting_logs |
| 10 | `handle_new_user` | ok — builds username (metadata → email → `user_<id>`), display name, validated country/locale, currency and unit system from the country; creates `user_settings` |
| 11 | Indexes | ok — every FK, `(created_at desc, id)` on paginated tables, trigram on display_name and listing titles, partial indexes on unread notifications and active stories |
| 12 | No data in schema files | ok — reference rows only in `seed_reference.sql`; sample content comes from Dreamflow Sample Data |

## Known limits (by design, for later prompts)

- No PostGIS yet: `lat/lng double precision` on posts, events, listings; PostGIS layers arrive in P28.
- `comment_reactions`, `story_views`, `albums`, `polls` arrive with P10, P11, P23, P08.
- Column-level privileges are not used; protection relies on the trigger + RPCs. If a later audit prefers `revoke update (…)` per column, do it in a pending migration.
- Helpers are executable by anyone; `group_visibility(gid)` reveals whether a secret group id exists. Acceptable; ids are uuids.
