# HB Social 2.0 — Roadmap (single development track)

One prompt = one feature = one commit. The CURRENT prompt is named in `docs/STATUS.md`. Work on nothing else.
Acceptance = the test that closes the prompt. A prompt without a passing acceptance is not done.

## Phase 0 — Visual foundation with real data (weeks 1–4) → gate: investor demo (visual)
Order chosen by the owner: graphics first (app, then admin console) with designed empty states and ZERO fake data, then Supabase with the full skeleton schema and sample data, then the screens wired to real tables.
| # | Prompt | Produces | Backend | Acceptance |
|---|---|---|---|---|
| P00 | Project, rules, theme | Project from the Dreamflow dashboard (6 base screens: welcome, login, signup, onboarding, empty home shell, profile), Theme Editor V2, AGENTS.md + docs/, easy_localization with 5 languages, GitHub repo connected, first build in preview | — | Preview works; AGENTS.md in root; first commit on GitHub; no hardcoded strings |
| P01 | App graphics: design system + all main screens | HB* widgets, WebShell (3 columns), MobileShell (5 tabs + FAB), single router; screens with designed empty/loading states: home, groups, forum, pages, marketplace, events, messages, notifications, profile, search; "Oggi a caccia" card as a component; Design System dev page | — (empty states only, no fake data) | Every screen matches its canvas board; no Scaffold in child pages; 5 languages switchable |
| P02 | Admin console graphics | AdminShell (dark sidebar, 23 entries), dashboard with zero KPIs and empty chart, users/reports/approvals tables with empty states, status badges, admin login | — | "Console admin" board reproduced; roles visible as UI only (permissions arrive with P05 and P40) |
| P03 | Supabase + full foundation schema + sample data | Connect `hb-dev`; FULL skeleton schema: identity (profiles with country_code/locale/currency_code, settings, follows, blocks, notifications, push_tokens), content (posts, post_media, reactions, comments, stories), community (groups, members, pages, roles, followers, forums, threads, replies, events, participants), commerce (listings, media, categories), chat (conversations, participants, messages), hunting (countries, regions, hunting_units, species, species_names, hunting_calendars, calendar_rules, hunting_logs, dogs), i18n (currencies, exchange_rates, feature_flags, country_policies); SECURITY DEFINER helpers + RLS; trigger on auth.users; SQL review checklist; Deploy Schema Changes; Dreamflow Sample Data loaded | pending_migrations.sql | Signup from preview creates a profile with country and locale; every table has RLS; no policy queries its own table; sample rows visible in Supabase; pgTAP green (outside lane) |
| P04 | App with real data, read-only | Feed, stories, groups, forum, pages, events, marketplace, messages, notifications, profile, search read the real tables; "Oggi a caccia" from hunting_calendars by region; settings for country/region/language/currency; no writes yet | Riverpod repositories on P03 tables | Every screen renders sample data; changing region changes the card; changing language relabels the whole UI; prices in the user's currency |
| P05 | Admin console with real data | KPIs from real counts, users/reports/listings/calendars lists from tables, role guard on /admin | admin_roles, audit_log | Non-admin cannot open /admin; KPIs are real counts; investor demo |

## Phase 1 — Social core (weeks 5–11) → gate: closed beta ready
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P06 | Full auth + onboarding | Google, Apple, Facebook, MFA TOTP, 18+ gate, interests → suggestions | Login with 4 providers on web and device |
| P07 | Profile edit + badge request | Avatar/cover upload, bio, username uniqueness, verification request to private bucket | Upload works; request visible in DB; doc invisible to non-admins |
| P08 | Rich content | 6 reactions, hashtags, mentions (+notification), polls, share-with-comment, triggers | pgTAP on visibility; counters coherent |
| P09 | Composer + feed complete | Text/photo/video/poll/check-in composer, cursor pagination, Per te / Seguiti / Vicino | 20 posts created from UI; infinite scroll; broken video does not break feed |
| P10 | Comments | Replies (2 levels), likes, mentions, inline on web / sheet on mobile | Reply works; live counter |
| P11 | Stories | Photo + video, viewer, highlights, views | 15s video plays on web and mobile; expires at 24h |
| P12 | Social graph | Follow, friend requests, suggestions by interests/region | Suggestions change with interests |
| P13 | Search | Postgres full-text (tsvector, GIN) over people, posts, hashtags, groups, listings, forums | "beccac" finds all types < 200 ms on 10k posts |
| P14 | Notifications + push | Center, badge, FCM/APNs via Edge Function (outside lane) | Like on phone A → push on phone B within 5 s |
| P15 | Realtime | Live likes/comments/counters, presence | Two browsers: like appears without refresh |
| P16 | Trust & safety | Report, block, mute, hide, strikes, word filter, sensitive-content blur per country policy | Blocked user disappears everywhere; third strike suspends |
| P17 | Seed + demo test | Realistic seed via Admin API, integration test of the demo path | Demo path runs 10× without errors |

## Phase 2 — Community & chat (weeks 12–16)
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P18 | Groups full | Create, join/approval, feed, studio (members, roles, bans, requests) | Non-owner opens studio without RLS errors |
| P19 | Pages full | Create, closed categories, team, post as page | Page post appears in followers' feed |
| P20 | Forums full | Create, categories, threads, replies, solution, pin/lock, studio | 20 nested replies; moderator locks thread |
| P21 | Events full | Create, RSVP, QR ticket + check-in, map/distance, paid events | RSVP → QR; admin check-in validates |
| P22 | Chat full | 1:1 + group, typing, read receipts, media + voice, desktop dock | Voice note iOS → web; no RLS recursion |
| P23 | Albums | Albums with privacy, cover, grid, viewer | Private album invisible to others |

## Phase 3 — Hunting vertical (weeks 12–19, parallel) → gate: closed beta 500 users
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P24 | Hunting data, multi-country | Full calendars for IT (3 regions at least), ISTAT municipalities, admin editor minimum; FR/ES/DE unit types seeded | "What can I hunt today in Lombardia" correct |
| P25 | Calendar + "Oggi a caccia" live | Rules engine `hunting_day(region, species, date)` | Card changes with region and date |
| P26 | Weather | Edge Function Open-Meteo with cache per municipality | Data < 1 s, cache 30 min |
| P27 | Diary | Outings, zone, auto weather, dogs, harvests, season stats, PDF export | 14 outings; stats coherent; PDF |
| P28 | Map | PostGIS layers (units, zones), private points, check-in from post | Private point invisible to others (pgTAP) |
| P29 | Dogs & cynology | Dog profile, pedigree, trials, link to breeders (pages) and meets (events) | Dog linked to diary and posts |
| P30 | Sightings | Geolocated sightings per species, heatmap, zone alerts | 50 sightings → heatmap; alert fires |
| P31 | Specialized trust | License / gun shop / guide / association verification, 30-day retention job | Doc invisible to non-admins; deleted after 30 days |

## Phase 4 — Commerce, monetization, ads (weeks 20–27) → gate: public launch
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P32 | Marketplace full | Closed categories, municipalities, filters, guided create, detail, my listings, seller reviews, multi-currency display | Listing from mobile visible on web with converted price |
| P33 | Firearms as mediated showcase | No in-app payment on arms/ammo, contact only via verified gun shop, license badge required, per-country policy | User without badge sees no contacts |
| P34 | Orders + payments | Stripe Checkout, order states, disputes, platform fee, Stripe Connect payouts in seller currency | Test order paid → shipped → completed; idempotent webhook |
| P35 | Wallet + Pro | User wallet, Pro via RevenueCat (stores) and Stripe (web), benefits | Sandbox subscription activates benefits < 1 min |
| P36 | Ads schema | Accounts, members, campaign/adset/ad, creatives, audiences, placements, wallet billing, review, tracking | pgTAP on account roles |
| P37 | Ads Manager UI | 6-step wizard, KPI dashboard, campaigns, audiences, creatives, billing, reports | Campaign created from wizard visible in admin review |
| P38 | Ads delivery | Selection, ranking, frequency cap, pacing, budget consumption, client+server tracking, "Why this ad" | Impressions/clicks decrement wallet; cap respected |
| P39 | Boost + placements | 1-click boost; native sponsored cards in feed, marketplace, events, right rail | Boosted post shown as sponsored to another user |

## Phase 5 — Admin console (weeks 6–27, parallel)
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P40 | Admin shell, roles, audit | Mandatory MFA admin login, roles (superadmin, admin, moderator, ads reviewer, finance, hunting-data editor), audit log | Moderator cannot reach payments; every action audited |
| P41 | Users, content, moderation | Paginated tables, user detail, timed bans, GDPR export, cascade delete, report queue with SLA and assignment, strikes | GDPR export zip; queue sorted by SLA |
| P42 | Commerce & ads admin | Listing approval per category, orders/disputes/refunds, plans & coupons, creative review, revenue report | Refund from admin updates order and wallet |
| P43 | Platform admin | Feature flags (module × country × rollout %), localization editor, email templates, push broadcast, Sentry, pg_cron jobs, support tickets | Flag "reels" at 10% shows tab only to that share |
| P44 | Hunting-data admin | Calendars per country/region/species with validity, map layers, species | Admin edit changes "Oggi" card within 1 min |

## Phase 6 — Media & scale (weeks 28–36)
| # | Prompt | Produces | Acceptance |
|---|---|---|---|
| P45 | Reels | Vertical short-video feed, Cloudflare Stream transcoding | 60 s iOS upload plays HLS on web |
| P46 | Live + calls | LiveKit live with chat, 1:1 audio/video | Live with 2 viewers; iOS ↔ web call |
| P47 | Advanced content | Articles for pages, scheduled posts (pg_cron), memories, GIF (Tenor) | Scheduled post publishes on time |
| P48 | Full i18n + auto-translation | Complete IT/EN/FR/ES/DE, DeepL translation of posts/messages with cache | Lint: 0 hardcoded strings; German post readable in Italian |
| P49 | Release | PWA, performance, accessibility, store listing 18+, privacy, final review | TestFlight + Play Internal approved; Lighthouse > 90 |
