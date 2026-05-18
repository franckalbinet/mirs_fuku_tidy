# CLAUDE.md — mirs_fuku_tidy

> Read before touching any file. One task at a time.
> If anything here is ambiguous, ask — don't assume.
> Full project rationale and experiment roadmap: `our-plan-so-far.md`

VERY IMPORTANT: 
- DON'T WRITE OR UPDATE FILES WITHOUT MY REVIEW AND GREEN LIGHT
- I ALWAYS WANT TO UNDERSTAND WHAT I WRITE. I AM VERY CAUTIOUS ABOUT VIBE CODING AND AFRAID TO ACCUMULATE TECHNICAL DEBT

---

## Project in one sentence

Predict soil radioactivity and chemistry from MIR spectra (~1320 Fukushima
samples, 650–4000 cm⁻¹). Targets: `cs137_ratio`, `total_cs137`, `ex_cs137`,
`k2o`. This is a research project — a paper will be published.

**Current stage: Stage 1 — exploring in `.qmd` files.**
`R/` functions are promoted from `.qmd` only when stable and reused.

---

## Style

- `snake_case` everywhere — no camelCase, no dots in names
- Native pipe `|>` — never `%>%`
- No `dplyr::` prefixes inside pipelines
- `library()` not `require()`
- `here::here()` for all paths — never `./` or `~/`
- Nouns for objects, verbs for functions
- Every `.qmd` chunk has a `#| label:`
- Figures: `#| label: fig-<description>`

## Naming — Huffman + lifecycle

Name length matches symbol lifetime:

| Scope | Convention | Examples |
|---|---|---|
| Loop body, lambda | Single letter or aggressive abbr. | `x`, `i`, `f`, `fn` |
| Function argument | Common abbreviation | `df`, `idx`, `n`, `cfg` |
| Function / column name | Full words or light abbr. | `fit_plsr`, `n_comp`, `spec_mat` |
| Module-level object | Full, unambiguous | `spectra_train`, `wet_data` |

Useful abbreviations: `df` · `idx` · `n` · `fn` · `cfg` · `src` · `dst` ·
`spec` · `pred` · `res` · `val` · `tfm` · `proc`

Prefer clarity over brevity at module level; brevity over clarity inside
function bodies.

## No literals

Never introduce bare numeric or string literals in code. Where constants are
defined (setup chunk, function argument default, config file) is decided per
context — flag if unclear rather than inventing placement.

## Documentation

- Plain `#` comment above each function — one line, describes what it does
  and what it returns if not obvious
- No roxygen (`#'`) — this is not a package
- No `@param`, `@return` tags
- Example: `# Load raw spectra from .rds; returns data frame with integer sample_id`

---

## Modularity map — what lives where

| Concern                   | `R/` file  | Notes                                                          |
|---|---|---|
| Load spectra + wet data   | `load.R`   | Pure, no side effects                                          |
| Wavenumber column helpers | `utils.R`  | `get_wn_cols()`, `get_wns()`, `get_non_spc_names()`            |
| Custom recipe steps       | `steps.R`  | `step_snv`, `step_sg`, `step_resample` — tidymodels-compatible |
| Train/val/test split      | `split.R`  | Kennard-Stone only (`ks_split()`)                              |

Per-target config (transform, cap, filter) lives in the experiment setup chunk
until it stabilises across 3+ experiments — do not create a config file speculatively.

## Rules for Claude Code

- Do exactly what was asked — nothing more
- Show diffs, never auto-apply
- Flag style issues — fix only if asked
- Read existing `R/` files before writing new ones
- Ask before touching any file not mentioned in the request
- Stop and ask if task requires more than ~20 new lines
- Never touch `data-raw/`