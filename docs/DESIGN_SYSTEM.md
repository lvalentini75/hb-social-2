# HB Social 2.0 — Design System V2

Reference boards: canvas "HB Social — Mockup Schermate V2" (feed desktop, welcome, groups, mobile feed, components, home app, home desktop Full HD, admin console). Attach the relevant board image to the agent when building a screen.

## Principles
White first · green as accent (one primary CTA per screen) · content first · soft depth (shadows, never borders) · large radius · editorial hierarchy · no dead grey emptiness · premium density · subtle motion (160–220 ms) · reusable components, never screen-by-screen hacks.

## Tokens (lib/core/theme/)
### Colors (AppColors)
| Token | Hex | Use |
|---|---|---|
| backgroundPage | #F6F7F8 | page background |
| surface | #FFFFFF | cards, header |
| backgroundSoft | #F2F4F5 | inputs, chips, rails blocks |
| backgroundHover | #EEF2EF | hover |
| divider | #E7EBE8 | 1px rules inside cards |
| border | #E3E7E4 | secondary buttons only |
| textPrimary | #111715 | body, titles |
| textSecondary | #66706B | meta |
| textTertiary | #8A948F | tiny labels, placeholders |
| primary | #2E7D45 | primary CTA, active icons |
| primaryDeep | #225E34 | active text, dark panels |
| primarySoft | #EAF5EE | active nav background, soft chips |
| primaryOutline | #A7CCB4 | focus ring, dashed "create" cards |
| success / warning / error / info | #22A06B / #C98912 / #D14343 / #2E6BDE | status |
| adminSidebar | #151C18 | admin console only |

### Typography (Inter via google_fonts)
display 32/700 · sectionTitle 24/700 (-0.02em) · screenTitle 18/700 · cardTitle 16/600 · body 15/400 (1.55) · bodyStrong 15/600 · meta 13/400 (textSecondary) · tiny 11/700 uppercase, letterSpacing 0.06em.

### Radius (AppRadius)
xs 10 · sm 14 (inputs, chips) · md 18 (cards, buttons) · lg 22 (large cards) · xl 28 (modals) · full 999.

### Shadows (AppShadows) — never borders on cards
level1 `0 1px 2px rgba(16,24,20,.04), 0 6px 20px rgba(16,24,20,.03)` cards ·
level2 `0 2px 8px rgba(16,24,20,.05), 0 12px 30px rgba(16,24,20,.04)` hover, menus ·
level3 `0 8px 30px rgba(16,24,20,.08), 0 20px 60px rgba(16,24,20,.06)` modals, dock.

### Spacing (base 4): 4 8 12 16 20 24 32 40 48. Cards padding 16–20; sections gap 16–24.

## Layout
Web shell: header 60–64 · left rail 232–280 · center 760–880 · right rail 300–360 · page padding 24–40, gap 24–32, centered block.
Mobile shell: top bar with logo + 3 icon buttons; bottom bar 5 slots, 56px green FAB raised in the middle; safe areas respected; no fake status bar.
Admin shell: dark sidebar 248 with grouped nav + badges, white content, top bar with breadcrumb, environment chip, search, date range.

## Shared widgets (lib/core/widgets/) — use these, never raw Material for these roles
- HBCard(child, padding, radius=lg, shadow=level1)
- HBButton.primary / .secondary / .soft / .ghost / .icon — height 44 (40 compact), radius md
- HBInput — soft background, no visible border, focus: 1.5px primaryOutline + 4px primarySoft ring, radius 16
- HBChip(selected) — pill, selected = primaryDeep bg white text; unselected soft bg
- HBSegmentedTabs — soft container radius 14/16, active white pill with level1 shadow, primaryDeep text
- HBEmptyState(icon, title, message, cta?) — 64px primarySoft circle icon, title 17/700, message 13 secondary, centered
- HBBadge — verified (green), gun shop (blue), guide (amber), association (grey)
- HBStatusChip(kind) — pending amber, approved green, rejected red, info blue, neutral grey; admin roles: moderator blue, admin green, superadmin solid deep green
- HBAvatar(size, initials/url, online dot)

## Patterns
- Stories: vertical 9:16 cards, cover full bleed, avatar top-left with 2.5px ring (green unseen / grey seen), name bottom-left; first card "Crea story" dashed primaryOutline on primarySoft.
- Post card: header (avatar 44, bold name + verified + group chip, meta line) → text 15 → media edge-to-edge with location chip → stats row → action bar (like red when active, comment, share, save).
- "Oggi a caccia" card: the ONLY solid primaryDeep card: species chips, weather, sunrise/sunset/moon, CTAs white/outline.
- Empty state everywhere a list can be empty. Loading = soft skeleton blocks, never spinners in lists.
- Sponsored card: native look + "Sponsorizzato · Perché vedo questo?".
