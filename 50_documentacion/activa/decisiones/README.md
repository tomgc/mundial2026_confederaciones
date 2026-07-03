# Handoff: Modelo de evaluación del desempeño de selecciones (Mundial 2026)

## Overview
Dashboard de análisis de datos para evaluar el desempeño de las 48 selecciones del Mundial 2026 por confederación. Audiencia: analista de datos. Tono: sobrio, denso en datos, legible, sin elementos decorativos. Interfaz 100% en español, retrospectiva (nunca predictiva — se actualiza a medida que hay más partidos jugados).

## About the design files
The file in this bundle (`Dashboard Mundial 2026.dc.html`) is a **design reference built in HTML** — a high-fidelity prototype of look, layout, states and interaction, not production code to copy verbatim. The task is to **recreate this design in the target codebase's existing stack** (React, Vue, Svelte, native, etc.) using its established component patterns, data layer and design system — or, if no stack exists yet, to pick the most suitable framework and implement it there. Do not ship the HTML file itself; treat it as the spec.

The file is self-contained (single HTML file, loads only IBM Plex Mono from Google Fonts) and can be opened directly in a browser to interact with the real thing.

## Fidelity
**High-fidelity.** Colors, typography, spacing, states and copy are final. Reproduce pixel-for-pixel where reasonable; the numeric data itself is partly illustrative (see "Data & derivation" below) and should be replaced with the real feed.

## Views

The app is a single page with client-side tab state (no routing needed) — 5 views:

### 1. Confederaciones (default landing view)
**Purpose:** compare the 6 confederations' aggregate performance at a glance.
**Layout:** intro block (eyebrow + h1 + description, max-width 74ch) → responsive card grid (`grid-template-columns: repeat(auto-fill, minmax(322px, 1fr))`, gap 15px) → a full-width bar-chart card below.

**Card anatomy** (border `1px solid #E4DCC9`, top border `3px solid <conf color>`, background `#fff`, padding `16px 18px`):
- Header row: 11×11px color dot + confederation name (15px/700) + team count, right-aligned, muted (11px/`#6E6A61`).
- Rating line: `<initial> → <current>` (13px muted → 26px/700 bold) + Δ chip (arrow + signed number, colored green/red/grey).
- Caption: "Rating promedio · inicial → actual" (11px, `#6E6A61`).
- Two-column stat row (divider `1px solid #EFE8D6` above): **Observado / esperado** (points actually transferred vs. model-expected, in cross-confederation matches) and **Transferencia neta** (net rating points gained/ceded in those cross matches).

**Bar chart card:** title + subtitle, then one row per confederation (sorted by Δ desc): color dot + code (left, fixed 112px column) → diverging horizontal bar from a center zero-axis (bar grows left for negative, right for positive, using the confederation's color) → signed value (right, fixed 54px column, tabular-nums). Axis legend above: "↤ desciende · 0 · asciende ↦".

### 2. Rankings
**Purpose:** dense sortable table of all 48 selections ranked by the model.
**Layout:** intro block → toolbar (search input + confederation filter chips + result count, `display:flex;gap:12px;flex-wrap:wrap`) → scrollable table (`max-height:66vh`, sticky header) → footnote.

**Toolbar:**
- Search `<input type="search">`, 220px wide, filters by team name or code (case-insensitive substring).
- Filter chips: "Todas" + 6 confederation chips (color dot + code), toggle style — active chip is filled (`background:<conf/#10294F>`, white text), inactive is outlined (`1px solid #C7BEAD`, white background).
- Live result count, right-aligned, muted.

**Table columns** (all sortable by clicking the header — click again to flip direction; active column shows a small triangle `▲`/`▼` in accent red and sets `aria-sort`): `#` (model rank), `Selección` (name + 3-letter code, muted), `Confederación` (dot + name), `Rank FIFA` (`#N`), `Elo`, `Rating modelo` (bold), `Cambio` (signed value with colored arrow — see "Change encoding" below).
Row striping: even rows `#fff`, odd rows `#FCFAF4`. Header row: sticky, background `#F1EADB`, bottom border `2px solid #10294F`.

### 3. Equipo (línea de tiempo)
**Purpose:** match-by-match drill-down for one selection.
**Layout:** header row (eyebrow/title + team `<select>`) → team summary bar → rating line chart card → match table card → footnote.

**Team selector:** a native `<select>` (not buttons/tabs) labelled "Seleccionar equipo", grouped into `<optgroup>`s by confederation (6 groups × up to 16 teams), alphabetical within each group. This must stay a real dropdown — the earlier iteration used 3 buttons and was explicitly rejected in favor of a dropdown covering all 48 teams.

**Team summary bar:** border-left 4px in the team's confederation color; 52×52px color badge with the 3-letter code; name (18px/700) + confederation dot + group; then 4 stat blocks (Rating actual, Rank modelo, Cambio torneo, Partidos), each an 11px muted label over a 22px/700 tabular-numeric value.

**Line chart:** inline SVG (viewBox `0 0 880 210`), one point per match plus an "Inicial" (pre-tournament) point, y-axis gridlines at min/mid/max, area fill under the line at the team's confederation color (7% opacity), 2px stroke line. Cross-confederation matches get a larger ringed marker (gold `#E0A81E` stroke, cream fill) vs. a small solid dot for same-confederation matches — a legend chip above the chart explains this.

**Match table columns:** Fase, Rival (dot + name + code + `⇄` badge on cross-confederation matches), Marcador, Importancia, Factor de goles, `W−We` (surprise, signed), Cambio de rating (signed), Rating (bold), Rank. Cross-confederation rows get a subtle gold-tinted background (`#FBF6E4`) and a 3px inset left accent.

### 4. Metodología
**Purpose:** plain-language glossary so a data analyst can trust every number without asking. Three cards ("Rankings y ratings", "Confederaciones", "Equipo · línea de tiempo"), each a list of term (12.5px/700) + definition (12px, muted, 1.55 line-height). Exact definitions are in the HTML — copy them verbatim, they were carefully worded to avoid the word "predicción" (everything is retrospective).

### 5. Tokens
**Purpose:** a living style guide so the palette/type/spacing can be replicated outside this file. Four cards (confederation colors, functional colors, typography scale, spacing scale) plus a "Notas de derivación de datos" block explaining which numbers are real vs. illustrative. Keep this view (or fold its content into your own design-system docs) — it is the source of truth for the tokens below.

## Interactions & behavior
- **Tabs**: 5 nav items, client-state only, no page reload. Active tab: white text, bold, 4px bottom border in gold `#F2D34E`. Inactive: `#9DB3D0`, weight 500. Tabs are intentionally large (padding `16px 24px`, font-size 14.5px) — this was bumped up once already from a smaller size, keep them generously sized.
- **Table sort**: click header → sort by that column; click the same header again → flip direction. Default: Rankings sorted by `Rating modelo` descending.
- **Search + filter**: combine (AND) — search matches name or code substring, confederation filter is exact match, "Todas" clears it.
- **Team dropdown**: changes the whole Equipo view (summary bar, chart, match table) to the selected team; no page transition/animation needed, instant swap.
- **Change encoding (accessibility-critical)**: every Δ/change value in the app is triple-encoded — color (green `#1C7A44` positive / red `#C8202B` negative / grey `#6E6A61` zero) **+** a `▲`/`▼`/`–` glyph **+** an explicit signed number. Never drop the glyph or the sign even if you keep the color; this is the app's answer to "don't rely on color alone."
- **Focus states**: every interactive element (buttons, inputs, select, sortable headers) gets a 2px solid `#C8202B` outline with 2px offset on `:focus-visible`.
- **Hover**: not heavily styled beyond the browser default in this prototype — feel free to add conventional hover states (darken by ~10%) consistent with the rest of the system when implementing.
- **Responsive**: card grids use `auto-fill`/`auto-fit` with `minmax()` so they reflow from 1 to 3 columns; tables scroll horizontally on narrow viewports (`overflow:auto`, `min-width` set per table so columns don't crush).

## State management
Minimal local UI state, no backend calls in the prototype:
- `view`: one of `confederaciones | rankings | equipo | metodologia | tokens` (default `confederaciones`).
- `sortKey`, `sortDir`: Rankings table sort state.
- `query`: Rankings search string.
- `conf`: Rankings confederation filter (`ALL` or a confederation code).
- `team`: currently selected team code in Equipo view (default `ARG`).

In a real implementation, `teams` (48 rows) and each team's match timeline would come from your data layer instead of being computed client-side; everything else (sort/filter/search/tab/team-select) is pure UI state.

## Design tokens

### Colors — confederations (one consistent color per confederation across all views)
| Confederación | Hex |
|---|---|
| UEFA | `#10294F` |
| CONMEBOL | `#C77D0E` |
| CONCACAF | `#C8202B` |
| CAF | `#1C7A44` |
| AFC | `#0E7C86` |
| OFC | `#6A3D7A` |

Palette derived from the World Cup 2026 emblem (red/navy/green), extended with three harmonious additions (amber, teal, plum) for full 6-way distinctness.

### Colors — functional
| Token | Hex | Use |
|---|---|---|
| `--ink` | `#16181D` | Primary text |
| `--paper` | `#FFFFFF` | Table/card backgrounds |
| `--bg` | `#FCFBF7` | Page background (warm paper, never pure white) |
| `--header` | `#10294F` | Header background |
| `--accent` | `#C8202B` | Accent / focus ring / active eyebrow color |
| `--pos` | `#1C7A44` | Positive change |
| `--neg` | `#C8202B` | Negative change |
| `--cross` | `#E0A81E` | Cross-confederation highlight |
| `--line` | `#E4DCC9` | Card/table borders |
| `--line-soft` | `#EFE8D6` / `#F1ECDE` / `#F3EEE0` | Internal dividers (rows, card sections) |
| `--muted` | `#6E6A61` | Secondary text — chosen for ≥4.5:1 contrast on white/cream; do not use anything lighter (an earlier `#9A9384` muted tone failed contrast review and was replaced everywhere) |
| `--footer-bg` | `#F6F1E6` | Footer background |
| `--selection-bg` | `#F2D34E` | `::selection` background |
| header secondary text | `#9DB3D0` | Eyebrow/meta text on the navy header |

### Typography
Single family: **IBM Plex Mono**, weights 300/400/500/600/700. All tabular data uses `font-variant-numeric: tabular-nums`.

| Use | Size | Weight |
|---|---|---|
| Page H1 | 19px | 700 |
| Section H2 (card titles) | 13–15px | 700 |
| Body / description | 12.5px | 400 |
| Table cells | 12–12.5px | 400 (tabular-nums) |
| Table header labels | 11px | 700, letter-spacing 0.02–0.03em |
| Eyebrow labels | 11–12px | 600, letter-spacing 0.12em, color `--accent` |
| Stat values (team summary) | 22px | 700 (tabular-nums) |
| Confederation card rating | 26px | 700 (tabular-nums) |
| Nav tabs | 14.5px | 500/700 |
| **Minimum font size anywhere in the app: 11px** | | |

### Spacing
Base-4px scale: `--space-1: 4px`, `--space-2: 8px`, `--space-3: 12px`, `--space-4: 16px`, `--space-5: 24px`, `--space-6: 32px`, `--space-7: 48px`. Used for all padding/gap/margin.

### Borders & radius
Card/table border: `1px solid #E4DCC9`. Confederation cards add a `3px solid <conf-color>` top border. Radius is minimal: `2px` on inputs/chips/badges, none on cards (flat, print-like).

### Logo mark
Header logo is 3 overlapping, slightly rotated squares (playful, per explicit design direction) — not a static flag block:
- Container 44×44px, `position:relative`.
- Three 21×21px squares, `border-radius:1px`, `border:1px solid rgba(124,138,160,0.4)` (deliberately subtle/near-invisible), rotated -10°/22°/9°, colors red `#C8202B` → cream `#F4F1E8` → green `#1C7A44` back-to-front.

## Data & derivation — what's real vs. illustrative
- **Real data**: all 48 teams' names, confederations, groups, and FIFA ranking (position + points, cut at 2026-06-11) — sourced from `data/equipos_mundial2026.csv` and `data/ranking_fifa_20260611.csv` in this bundle.
- **Illustrative / to replace with real feed**:
  - **Elo**: `round(1300 + (fifa_points − 1275) × 1.15)` — a linear rescale of FIFA points, not a real Elo history.
  - **Rating del modelo**: `fifa_points + deterministic_form_adjustment` where the adjustment (±40) is a hash of the team code — a stand-in for a real trained model. Model rank = sort by this rating descending.
  - **Cambio (Δ, Rankings table)**: a small deterministic hash-based integer (−6..6), standing in for "change since last update."
  - **Confederación aggregates** (Observado/esperado, Transferencia neta): hand-set illustrative constants per confederation, not computed from real cross-confederation match results.
  - **Equipo timelines**: Argentina, Marruecos and España have hand-authored, narratively coherent match sequences (real rivals from their actual groups + plausible knockout opponents, through the quarterfinals). The other 45 teams get a **generated** timeline: real group-stage rivals from the CSV data, then a knockout run whose depth is tied to model-rank tier (top 4 → semifinal, top 8 → quarterfinal, top 16 → round of 16, top 32 → round of 32, else group-stage only), with match scores/importance/surprise/rating-change computed from a seeded pseudo-random formula weighted by an Elo-style expected-win-probability curve.

When wiring real data, the UI contract per team row is: `{ code, name, conf, group, fifaPos, fifaPoints, elo, modelRating, modelRank, delta }`, and per match: `{ fase, rivalCode, rivalName, rivalConf, golesFavor, golesContra, importancia, factorGoles, sorpresa (W−We), cambioRating, ratingDespues, rankDespues }`. `cross` (cross-confederation flag) is simply `rivalConf !== team.conf`.

## Assets
No image/icon assets — the only "graphic" elements are CSS-drawn (the 3-square logo mark, color dots, the SVG line chart, the CSS bar chart). Font: IBM Plex Mono via Google Fonts (`https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@300;400;500;600;700&display=swap`).

## Files in this bundle
- `Dashboard Mundial 2026 (standalone).html` — **open this one.** A single self-contained file (fonts + runtime inlined) that renders correctly offline in any browser, double-click to open.
- `Dashboard Mundial 2026.dc.html` + `support.js` — the same design reference, split into its source form (references `support.js` via a relative `<script src>`). Keep both files together in the same folder if you use this version instead.
- `data/equipos_mundial2026.csv` — real team/confederation/group data.
- `data/ranking_fifa_20260611.csv` — real FIFA ranking data (position + points) as of 2026-06-11.
