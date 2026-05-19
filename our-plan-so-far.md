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

## 6. Current task

1. Now: add RF, XGBoost, LS-SVM to cs137_ratio.qmd (same recipe, same validation_set(split))
2. Then: compare all 5 models — this is already a publishable result
3. If motivated by results: open a separate explore_preprocessing.qmd to try PCA/PLS preprocessing (recipes step) variants for the models that
could benefit. The PCA/PLS question is real but it's a second-order experiment. Running it first would be premature optimisation —
you don't yet know which models are worth investing in for this dataset.

## 7. Interpretation

Based on Cubist feature importance while predicting cs137 ratio:

~3500–3700 cm⁻¹ (~70–80%): O-H stretching in clay minerals — kaolinite has characteristic bands at 3620 and 3695
  cm⁻¹, halloysite similarly. Directly relevant: clay mineralogy controls Cs fixation capacity.

  ~3300–3400 cm⁻¹ (~60%): Broader O-H stretch, associated with hydrogen-bonded O-H in organic matter or interlayer
  water.

  ~2300–2500 cm⁻¹ (small cluster, ~20%): Carbonate combination bands or atmospheric CO₂ region (~2349 cm⁻¹) — worth
  checking with domain experts whether this is a real signal or an instrument artefact.

  ~1800 cm⁻¹ (~98%, dominant): C=O stretching — organic matter (carboxylates) or carbonate overtones. As noted,
  physically plausible for Cs exchangeability.

  ~1900–2000 cm⁻¹ (~65–80%): Si-O combination modes or carbonate combination bands.

  ~700–900 cm⁻¹ (~90%, rightmost high peak): Si-O bending in quartz (~800 cm⁻¹) and Al-OH deformation in kaolinite
  (~912, ~937 cm⁻¹). Clay mineral fingerprint region.

  Overall the plot is coherent — clay mineralogy (O-H and Si-O regions) and organic matter (C=O) dominate, both of
  which are physically meaningful drivers of Cs exchangeability in Fukushima soils.