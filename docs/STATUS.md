# HB Social 2.0 — Status (read this FIRST on every task)

## Current prompt
**P01 — App graphics: design system + all main screens** (Phase 0). Scope and acceptance: see `docs/ROADMAP.md`, row P01.
Do only P01. Do not connect Supabase, do not create tables, do not start P02 (admin console) until STATUS names it.

## Phase 0 order (fixed)
P00 project → P01 app graphics (empty states) → P02 admin graphics → P03 Supabase schema + sample data → P04 app wired to real data → P05 admin wired to real data → investor demo.

## Done
| Prompt | Date | Files touched (summary) | Open issues |
|---|---|---|---|
| P00 — Project, rules, theme | 2026-10-02 | `lib/main.dart`, `lib/core/` (theme → `app_theme.dart`, router → `app_router.dart`), `lib/shell/`, `lib/features/` (welcome, login, signup, onboarding, home shell, profile), `assets/translations/{it,en,fr,es,de}.json`, `pubspec.yaml` (easy_localization, go_router, riverpod), `AGENTS.md`, `ARCHITECTURE.md`, `docs/`, GitHub repo connected | Welcome screen shows the HB logo twice (keep only the top one); feature rows on Welcome are not aligned in one column; analyzer: 1 warning, 2 infos → all fixed inside P01 |

## Removed / forbidden (never reintroduce)
- Any mock, fake, sample or in-memory data in `lib/` (sample data lives ONLY in Supabase, loaded via Dreamflow Sample Data from P03).
- Scaffold inside child pages; `SingleChildScrollView` as page root.
- Hardcoded UI strings (everything via easy_localization keys in all 5 languages).
- Secrets in code; service_role key anywhere in the app.
- A second theme file or a second router: `lib/core/theme/app_theme.dart` and `lib/core/router/app_router.dart` are the only ones.

## How to update this file (end of every task)
1. Move the current prompt into "Done" with date, files touched, open issues.
2. Set the next prompt from `docs/ROADMAP.md` as "Current prompt".
3. If a decision was taken, add one line to `docs/DECISIONS.md` (date — decision — why).
