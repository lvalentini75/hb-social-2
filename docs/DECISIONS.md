# HB Social 2.0 — Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-10-02 | Rebuild from zero on Dreamflow; old codebase kept only as reference | Two parallel codebases, seven models, database lost |
| 2026-10-02 | Backend first with real sample data in Supabase; no mock in app code | The 2025 Dreamflow build was 85% UI / 0% backend |
| 2026-10-02 | Schema changes only via `pending_migrations.sql` reviewed by a human before deploy | Manual SQL in dashboard caused untracked, half-applied migrations |
| 2026-10-02 | SECURITY DEFINER helpers before any RLS policy on membership tables | RLS infinite recursion (42P17) hit twice in the old project |
| 2026-10-02 | Multi-country, multi-language, multi-currency from the first schema | Target markets IT, FR, ES, DE/AT, UK; refitting later costs a rewrite |
| 2026-10-02 | easy_localization (JSON) instead of gen-l10n | Dreamflow cannot run code generation |
| 2026-10-02 | Edge Functions deployed outside Dreamflow with Supabase CLI | Dreamflow does not support Edge Functions |
| 2026-10-02 | Firearms/ammo in marketplace only as mediated showcase (no in-app payment) | Italian law + App Store / Play policies |
| 2026-10-02 | Phase 0 order: graphics first (P01 app, P02 admin) with empty states and zero fake data, then Supabase schema + sample data (P03), then screens wired to real tables (P04, P05) | Owner wants to see the product before the backend; screens are built against the domain model in ARCHITECTURE.md so wiring in P04 does not restructure them |
| 2026-10-02 | Prompt numbering P00–P49 is fixed; the doc "Roadmap Rebuild da Zero", `docs/ROADMAP.md` and `docs/STATUS.md` always use the same numbers | One development track: a prompt name must mean the same thing everywhere |
