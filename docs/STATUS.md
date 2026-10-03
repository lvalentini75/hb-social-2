# HB Social 2.0 — Status (read this FIRST on every task)

## Current prompt
P03: Supabase integration + starter pack.

## Analyzer status
Analyzer and Analysis Issues clean on October 3, 2024 — **0 errors, 0 warnings, 0 info**.
Connect `hb-dev`; build the full foundation schema, RLS helpers and reviewed sample data. P03 is executed with Claude Opus 5 and requires human SQL review before deployment.

**Progress:** P02 complete. Analyzer pulito il 3 ottobre.

**P02 parte a files:** `lib/shell/admin_shell.dart`, `lib/features/admin/`, `lib/core/router/app_router.dart`, `lib/core/widgets/admin_data_table.dart`, `lib/core/widgets/hb_input.dart`, `lib/core/theme/app_colors.dart`, `assets/translations/{it,en,fr,es,de}.json`.

**P02 parte b files:** `lib/features/admin/{domain,data,providers,presentation}/`, `lib/features/admin/presentation/widgets/`, `lib/core/router/app_router.dart`, `lib/core/widgets/{hb_button,hb_input}.dart`, `lib/features/dev/presentation/design_system_page.dart`, `assets/translations/{it,en,fr,es,de}.json`. Open issues: real records, counts, moderation actions and document access remain assigned to P05/P31/P40/P41; complete P02 part c before closing the prompt.

## Phase 0 order (fixed)
P00 project → P01 app graphics (empty states) → P02 admin graphics → P03 Supabase schema + sample data → P04 app wired to real data → P05 admin wired to real data → investor demo.

## Done
| Prompt | Date | Files touched (summary) | Open issues |
|---|---|---|---|
| P00 — Project, rules, theme | 2026-10-02 | `lib/main.dart`, `lib/core/` (theme → `app_theme.dart`, router → `app_router.dart`), `lib/shell/`, `lib/features/` (welcome, login, signup, onboarding, home shell, profile), `assets/translations/{it,en,fr,es,de}.json`, `pubspec.yaml` (easy_localization, go_router, riverpod), `AGENTS.md`, `ARCHITECTURE.md`, `docs/`, GitHub repo connected | Welcome screen shows the HB logo twice (keep only the top one); feature rows on Welcome are not aligned in one column; analyzer: 1 warning, 2 infos → all fixed inside P01 |
| P01 — App graphics: design system + all main screens | 2026-10-04 | `lib/core/{theme,router,widgets,i18n}/`, `lib/shell/`, `lib/features/` (auth, home, groups, forum, pages, messages, notifications, search, profile, marketplace, events, hunting, settings, dev), `assets/translations/{it,en,fr,es,de}.json`, `docs/` | Real data, writes, maps, diary exports and dog management remain assigned to P03/P04 and P21/P27/P28/P29; session settings remain in memory until backend wiring. |
| P02 — Admin console graphics | 2026-10-04 | `lib/features/admin/`, `lib/shell/admin_shell.dart`, `lib/core/router/app_router.dart`, `lib/features/dev/presentation/design_system_page.dart`, `assets/translations/{it,en,fr,es,de}.json`, `docs/STATUS.md` | Real records, counts, review actions, regional calendar editing, roles and permissions remain assigned to P05/P40/P42/P44. |

## Removed / forbidden (never reintroduce)
- Any mock, fake, sample or in-memory data in `lib/` (sample data lives ONLY in Supabase, loaded via Dreamflow Sample Data from P03).
- Scaffold inside child pages; `SingleChildScrollView` as page root.
- Hardcoded UI strings (everything via easy_localization keys in all 5 languages).
- Any fake login, demo user, "remember me" flag or simulated session; social sign-in buttons that do nothing.
- Non-HB duplicates of shared widgets (`AppPrimaryButton`, `AppTextField`, `SocialAuthButtons`, `showComingSoon`).
- Secrets in code; service_role key anywhere in the app.
- A second theme file or a second router: `lib/core/theme/app_theme.dart` and `lib/core/router/app_router.dart` are the only ones.

## How to update this file (end of every task)
1. Move the current prompt into "Done" with date, files touched, open issues.
2. Set the next prompt from `docs/ROADMAP.md` as "Current prompt".
3. If a decision was taken, add one line to `docs/DECISIONS.md` (date — decision — why).

