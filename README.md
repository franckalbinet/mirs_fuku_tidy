# mirs_fuku_tidy

**Predicting soil radioactivity and chemistry from MIR spectra — Fukushima dataset**

This repository contains the analysis code for a peer-reviewed study investigating
whether mid-infrared (MIR) spectroscopy can predict ¹³⁷Cs exchangeability and
related soil properties in agricultural soils affected by the 2011 Fukushima
nuclear accident.

---

## Background

After the Fukushima Daiichi accident, large quantities of ¹³⁷Cs were deposited on
agricultural soils in the surrounding region. Understanding the exchangeable fraction
of soil ¹³⁷Cs — the portion available for plant uptake and leaching — is critical for
assessing radiological risk and guiding remediation. Wet-chemistry measurements are
accurate but slow and costly. MIR spectroscopy offers a faster, cheaper alternative
if a reliable predictive model can be established.

---

## Dataset

- ~1320 soil samples from Fukushima agricultural fields, 2013–2020
- MIR spectra: 650–4000 cm⁻¹ (~1800 channels at native resolution)
- Paired wet-chemistry measurements: exchangeable ¹³⁷Cs, total ¹³⁷Cs, exchangeable K₂O

Raw data live in `data-raw/` and are never modified by any script.

---

## Research questions

| # | Question | Status |
|---|---|---|
| Q1 | Can MIR predict soil ¹³⁷Cs exchangeability and K₂O? (feasibility) | **Current** |
| Q2 | Can a model trained on known fields generalise to new fields? | Future |
| Q3 | Can a model trained on earlier years predict later years? | Future |
| Q4 | Joint spatial and temporal generalisation? | Future |

This repository currently addresses **Q1**. Splits use Kennard-Stone sampling on
spectral PCA scores to guarantee representative coverage of the spectral space.

---

## Repository structure

```
mirs_fuku_tidy/
├── R/
│   ├── load.R      # load_raw_data() — ingest and join spectra + wet chemistry
│   ├── split.R     # ks_split() — Kennard-Stone three-way split (train/val/test)
│   ├── steps.R     # custom tidymodels recipe steps: step_snv, step_sg, step_resample
│   └── utils.R     # wavenumber column helpers
│
├── data-raw/       # raw inputs — never modified
├── data/           # derived artefacts
├── fig/            # saved figures
│
├── 00_tune_sg.qmd              # Savitzky-Golay hyperparameter search
├── 01_cs137_ratio.qmd          # Full model comparison for log10(exCs137 / totalCs137)
├── 02_soil_ex_k2o.qmd          # Pipeline for log10(K₂O)
├── 03_cs137_ratio_cubist_by_soil.qmd  # Cubist: global vs. per-soil-type models
│
├── renv.lock                   # exact package versions — always committed
└── our-plan-so-far.md          # working notes and experiment roadmap
```

---

## Notebooks

| Notebook | Target | Models | Purpose |
|---|---|---|---|
| `00_tune_sg.qmd` | — | — | Tune Savitzky-Golay window, degree, and derivative order |
| `01_cs137_ratio.qmd` | `log10(exCs137 / totalCs137)` | PLSR, Cubist, RF, XGBoost | Full model benchmark |
| `02_soil_ex_k2o.qmd` | `log10(K₂O)` | PLSR, Cubist, RF, XGBoost | Full model benchmark |
| `03_cs137_ratio_cubist_by_soil.qmd` | `log10(exCs137 / totalCs137)` | Cubist | Global model vs. independent per-soil-type models |

All notebooks follow the same tidymodels pipeline:
`ks_split` → `recipe` → `workflow` → `tune_grid` → `finalize_workflow` → `last_fit` → `collect_metrics`.

---

## Preprocessing

Each model uses the same spectral preprocessing chain, with parameters tuned in `00_tune_sg.qmd`:

1. **log₁₀ transform** of the outcome
2. **Spectral resampling** (every 5 cm⁻¹) to reduce channel count and collinearity
3. **SNV** (Standard Normal Variate) to remove multiplicative scatter
4. **Savitzky-Golay first derivative** (window 15, degree 3) to suppress baseline drift

---

## Reproducing the analysis

```r
# Restore the exact package environment
renv::restore()

# Render any notebook
quarto render 01_cs137_ratio.qmd
```

Requires R ≥ 4.3, Quarto ≥ 1.4, and a working LaTeX installation for PDF output
(`quarto install tinytex` if needed).

---

## Authors

Franck Albinet — Independent Consultant
