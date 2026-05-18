# mirs_fuku — Project Plan
> MIR Spectroscopy + Machine Learning for soil radioactivity analysis (Fukushima dataset)
> Use this file as context when starting a new Claude chat session on this project.

---

## 1. Project Overview

**Goal:** Predict multiple soil properties from MIR spectra using PLSR and alternative
models. Results will be published in a peer-reviewed journal — reproducibility is a
first-class requirement throughout.

**Dataset:** ~1320 soil samples, Fukushima region, 2013–2020.
**Spectra:** MIR, wavenumber range ~650–4000 cm⁻¹.

### Response variables

| ID | Raw column | Provisional transform | Notes |
|---|---|---|---|
| `cs137_ratio` | `exCs137_totalCs137`     | `log10` | Primary target — exchangeability ratio |
| `total_cs137` | `X2022_soil_total_Cs137` | `log10` | Absolute contamination level |
| `ex_cs137`    | `X2022_soil_ex_Cs137`    | `log10` | Exchangeable fraction (absolute) |
| `k2o`         | `soil_ex_K2O`            | `log10` | Check distribution before deciding |


---

## 2. Project Structure

```
mirs_fuku_tidy/
├── CLAUDE.md                            # Claude Code instructions — always loaded
├── our-plan-so-far.md                   # this file — project reference
├── mirs_fuku.Rproj                      # To be created?
│
├── R/                                   # Shared functions
│   ├── load.R                           # load_spectra(), load_wet_data()
│   ├── split.R                          # [Tidymodels' Resample](https://rsample.tidymodels.org) compatible kennard-stone splitter
│   └── steps.R                          # [Tidymodels' Recipes](https://recipes.tidymodels.org/) custom steps
│   └── utils.R                          # Various utils
│
├── data-raw/                            # raw data — never modified, never touched by code
│   ├── 1320_Jumpei_spectra_outlier_full.rds
│   └── WetData_2013_2023.csv
│
├── data/
│   └── spectra_joined.rds               # preprocessed spectra + all wet columns joined
│
├── fig/                                 # saved figures — subdirs by experiment
├── reports/                             # rendered .html outputs
└── renv.lock                            # always committed
```

---

## 3. Approach

All modelling follows the [tidymodels](https://www.tmwr.org) framework end-to-end —
from data spending to model explanation. Each experiment lives in a `.qmd` file;
`R/` functions are promoted only when stable and reused across experiments.

### Pipeline template

| Stage               | Tidymodels primitive                          | Notes                                                          |
|---|---|---|
| Data spending       | `ks_split()` → `initial_validation_split`     | Kennard-Stone; fixed `SEED`                                    |
| Feature engineering | `recipe()` + custom steps                     | `step_snv`, `step_sg`, `step_resample`                         |
| Modelling           | parsnip spec + `workflow()`                   | PLSR, Cubist, Random Forest, XGBoost, LS-SVM — one workflow per model |
| Tuning              | `tune_grid()` over `validation_set(split)`    | Grid or random search                                          |
| Finalisation        | `finalize_workflow()` + `last_fit()`          | Train+val fit, test evaluation                                 |
| Evaluation          | `collect_metrics()` + `collect_predictions()` | RMSE, R², RPIQ (custom yardstick metric)                       |
| Explanation         | Per-model importance                          | Cubist usage, PLS VIP                                          |

Ensembling across models is of interest once individual results are assessed.

The reference pipeline is `cs137_ratio.qmd`.

## 4. Evaluation Metrics

Ideally, we'd like: 

| Metric | Interpretation |
|---|---|
| RMSEP | Primary — model and hyperparameter selection |
| R² | Variance explained |
| RPIQ | Robust to outliers — preferred over RPD in soil science |
| Lin's CCC values|  |
| Bias|  |

---

## 5. Environment
- `renv` — `renv::restore()` to reproduce
- `renv::snapshot(type = "all")` when adding packages

---