# HB Social 2.0 — Architecture

## Stack
- Flutter stable, one codebase: web (canvaskit), iOS, Android.
- Supabase: Postgres + RLS, Auth, Storage, Realtime. Edge Functions are deployed OUTSIDE Dreamflow (push, Stripe webhooks, weather, translations, LiveKit tokens) and called from the app via `supabase.functions.invoke`.
- State: Riverpod. Routing: go_router with ONE `StatefulShellRoute` for the social shell, a separate `ShellRoute` for `/admin/*`.
- i18n: easy_localization (JSON assets). Money: `MoneyFormatter` on top of `intl`.

## Three surfaces, one codebase
| Surface | Entry | Shell | Who |
| --- | --- | --- | --- |
| Social app | `/` | `WebShell` (>= 900px: header + left rail + center + right rail) / `MobileShell` (< 900px: bottom bar 5 slots, FAB center) | every user |
| Ads Manager | `/ads/*` | `WebShell` variant with ads sidebar | advertisers |
| Admin console | `/admin/*` | `AdminShell` (dark sidebar, dense enterprise layout) | admin roles only; separate login with mandatory MFA |

## Folder layout
```
lib/
  core/
    config/        env.dart (flavor: dev|prod), app_constants.dart
    router/        app_router.dart, routes.dart, guards.dart
    theme/         app_colors.dart, app_typography.dart, app_radius.dart, app_shadows.dart, app_spacing.dart, app_theme.dart
    widgets/       hb_card.dart, hb_button.dart, hb_input.dart, hb_chip.dart, hb_segmented_tabs.dart, hb_empty_state.dart, hb_badge.dart, hb_avatar.dart, hb_status_chip.dart
    services/      supabase_client.dart, storage_service.dart, error_mapper.dart
    i18n/          locale_provider.dart, money_formatter.dart, country_provider.dart
  features/
    <feature>/
      data/        <feature>_repository.dart
      domain/      <model>.dart (fromJson/toJson by hand)
      presentation/ screens + widgets
      providers/   riverpod providers
  shell/           web_shell.dart, mobile_shell.dart, admin_shell.dart
  supabase/        supabase_config.dart, supabase_tables.sql, supabase_policies.sql, pending_migrations.sql
assets/translations/ it.json en.json fr.json es.json de.json
docs/              ROADMAP.md STATUS.md DECISIONS.md DESIGN_SYSTEM.md
```
Features (one folder each): auth, onboarding, profile, feed, comments, stories, social_graph, search, notifications, trust_safety, groups, pages, forums, events, chat, albums, hunting (calendar, diary, weather, map, dogs, sightings), marketplace, orders, wallet, ads, admin, i18n_settings.

## Domain model — international by design
Every hunting-domain and content table carries `country_code` (ISO 3166-1 alpha-2). Italian concepts are instances of generic ones:

| Generic table | IT | FR | ES | DE/AT | UK | US |
| --- | --- | --- | --- | --- | --- | --- |
| `hunting_units` | ATC / CA | ACCA, département | coto, reserva | Revier, Hegering | estate, shoot | WMU |
| `hunting_calendars` + `calendar_rules` | calendario regionale | arrêté préfectoral | orden de vedas | Jagdzeiten per Land | game seasons | seasons per state |
| `licenses` | licenza + tesserino | permis + validation | licencia autonómica | Jagdschein | shotgun/firearm certificate | license + hunter ed |
| `quotas` | piani di abbattimento | plan de chasse / bracelets | precintos | Abschussplan | — | tags / draw |

Reference tables: `countries`, `regions` (regione / département / Land / state), `species` (scientific name as key, common names per language in `species_names`), `currencies`, `exchange_rates` (daily), `country_policies` (moderation and legal rules per country), `feature_flags` (per module, per country, per rollout percentage).

Users: `user_profiles.country_code`, `home_region_id`, `locale`, `currency_code`. Content inherits the author's `country_code`. "Nearby" feeds filter by `hunting_unit` and radius (PostGIS).

## Data rules
- Identifiers `uuid default gen_random_uuid()`. Timestamps `timestamptz`. Soft state via `status` text + check constraint, never boolean flags for lifecycle.
- Denormalized counters (`reaction_count`, `comment_count`, `member_count`…) maintained by triggers only.
- Membership tables (`group_members`, `forum_members`, `page_roles`, `conversation_participants`, `ad_account_members`, `event_participants`) each have `is_<x>_member(id, uid)` and `is_<x>_manager(id, uid)` as `security definer stable` SQL functions; every policy uses them.
- Storage buckets: `avatars`, `covers`, `post-media`, `story-media`, `group-media`, `page-media`, `listing-media`, `event-media`, `chat-media` (public read, owner write under `<user_id>/`); `verification-docs` (private, admin read, 30-day retention).
- Money columns `amount_minor bigint` + `currency_code char(3)`.

## Environments
- `hb-dev`: the Supabase project connected inside Dreamflow. Schema deployed from the Schema Deployment panel after human review of `pending_migrations.sql`.
- `hb-prod`: never connected to Dreamflow. Receives the same SQL files via Supabase CLI from the Git repo at release tags. Edge Functions deployed with `supabase functions deploy` from the repo.
- `lib/core/config/env.dart` selects dev/prod by flavor with dev as default (the app must run without `--dart-define`).

## Outside-Dreamflow lane (handled by the developer with Supabase CLI from the Git clone)
pgTAP tests (`supabase test db`), Edge Functions, CI (analyze, test, build web), prod deploys, store builds when not using Dreamflow's 1-click.
