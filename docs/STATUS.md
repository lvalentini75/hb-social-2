# HB Social 2.0 — Status (read this FIRST on every task)

## Current prompt
**P00 — Project, rules, theme** (Phase 0). Scope and acceptance: see `docs/ROADMAP.md`, row P00.
Do only P00. Do not start P01 (app graphics) until STATUS names it.

## Phase 0 order (fixed)
P00 project → P01 app graphics (empty states) → P02 admin graphics → P03 Supabase schema + sample data → P04 app wired to real data → P05 admin wired to real data → investor demo.

## Done
| Prompt | Date | Files touched (summary) | Open issues |
|---|---|---|---|
| — | — | — | — |

## Removed / forbidden (never reintroduce)
- Any mock, fake, sample or in-memory data in `lib/` (sample data lives ONLY in Supabase, loaded via Dreamflow Sample Data).
- Scaffold inside child pages; `SingleChildScrollView` as page root.
- Hardcoded UI strings (everything via easy_localization keys in all 5 languages).
- Secrets in code; service_role key anywhere in the app.

## How to update this file (end of every task)
1. Move the current prompt into "Done" with date, files touched, open issues.
2. Set the next prompt from `docs/ROADMAP.md` as "Current prompt".
3. If a decision was taken, add one line to `docs/DECISIONS.md` (date — decision — why).
