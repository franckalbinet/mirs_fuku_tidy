# Research Questions & Modelling Strategy

## Context

Post-Fukushima (2011) soil dataset from Japanese agricultural fields.
MIR spectra (~650–4000 cm⁻¹) paired with wet chemistry measurements
across multiple fields, years, and soil types (2013–2020).

---

## Current Question (Q1) — Feasibility

> **Can MIR spectroscopy predict soil properties (Cs137 exchangeability,
> exchangeable K2O, ...) in Fukushima-affected soils?**

This is a **signal existence** question: is there enough spectral
information correlated with the target property to make prediction
feasible at all?

### Modelling implications

- **Split**: random stratified split (`initial_split()`, strata = target)
- **Resampling**: 10-fold cross-validation on the training set
- **Interpretation**: if a model fails here, there is no spectral signal
  worth pursuing further; if it succeeds, Q2 becomes relevant

### Limitations to document

- Random splitting ignores temporal and spatial structure
- Performance estimates will be optimistic relative to real deployment
- Explicitly a feasibility study, not a deployment-ready model

---

## Future Question (Q2) — Spatial Generalisation

> **Can a model trained on known fields predict Cs137 exchangeability
> on new, never-measured fields?**

### Modelling implications

- **Split**: block split by `field_no` — entire fields held out as test set
- **Resampling**: group k-fold CV (`group_vfold_cv()`) by `field_no`
- **Why harder**: the model cannot rely on having seen the spatial
  context of a test field during training

---

## Future Question (Q3) — Temporal Generalisation

> **Can a model trained on earlier years predict later years,
> accounting for Cs137 fixation, weathering, and remediation?**

### Modelling implications

- **Split**: temporal split — e.g. train on 2013–2016, test on 2017–2020
- **Resampling**: time-based CV (`sliding_period()` or manual year folds)
- **Why harder**: Cs137 behaviour in soil evolves over time
  (fixation, remediation actions); a temporally naive model may
  not capture this drift

---

## Future Question (Q4) — Joint Spatial & Temporal Generalisation

> **Can the model generalise to new fields in future years?**

The most demanding and most realistic deployment scenario.
Requires both Q2 and Q3 to be solved first.