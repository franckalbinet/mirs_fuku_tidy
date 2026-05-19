#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: libraries

library(tidyverse)
library(tidymodels)
library(prospectr)
library(resemble)
library(here)
library(plsmod)
library(rules)
library(Cubist)
library(hexbin)
library(vip)

source(here("R", "utils.R"))
source(here("R", "load.R"))
source(here("R", "steps.R"))
source(here("R", "split.R"))

library(doParallel)
registerDoParallel(cores = parallel::detectCores() - 1L)
#
#
#
#| label: configuration

# --- Data -------------------------------------------------------------------
WET_PATH     <- here("data-raw", "WetData_2013_2023.csv")
SPECTRA_PATH <- here("data-raw", "1320_Jumpei_spectra_outlier_full.rds")
BY_WET       <- "ID"
BY_SPECTRA   <- "sample_id"

# --- Target property --------------------------------------------------------
TARGET <- "soil_ex_K2O"

# --- Filtering --------------------------------------------------------------
EXCLUDE_YEARS <- c(2021, 2022, 2023)

# --- Preprocessing ----------------------------------------------------------
RESAMPLE_BY <- 5L
SG_W        <- 15L   # tuned in tune_sg.qmd
SG_P        <- 3L    # tuned in tune_sg.qmd
SG_M        <- 1L    # first derivative — confirmed in tune_sg.qmd

# --- Splitting --------------------------------------------------------------
SEED            <- 123L
TRAIN_PROP      <- 0.75
CALIB_PROP      <- 0.65
KS_MAX_EXPL_VAR <- 0.99

# --- Model ------------------------------------------------------------------
MAX_NCOMP <- 50L
GRID_SIZE <- 20L

set.seed(SEED)
#
#
#
#
#
#| label: load

raw <- load_raw_data(
  wet_path     = WET_PATH,
  spectra_path = SPECTRA_PATH,
  by_wet       = BY_WET,
  by_spectra   = BY_SPECTRA
)

glimpse(raw)
#
#
#
#
#
#| label: prepare

prepared <- raw |>
  filter(
    !year %in% EXCLUDE_YEARS,
    !is.na(.data[[TARGET]]),
    .data[[TARGET]] > 0
  )
nrow(prepared)
#
#
#
#
#
#
#
#| label: split

split <- ks_split(prepared, train_prop = TRAIN_PROP, calib_prop = CALIB_PROP)
#
#
#
#
#
#| label: recipe

spc_cols  <- grep("^X\\d+", names(training(split)), value = TRUE)
meta_cols <- setdiff(names(training(split)), c(TARGET, spc_cols))

rec <- recipe(training(split)) |>
  update_role(all_of(TARGET),    new_role = "outcome")   |>
  update_role(all_of(spc_cols),  new_role = "predictor") |>
  update_role(all_of(meta_cols), new_role = "metadata")  |>
  step_log(all_outcomes(), base = 10)      |>
  step_resample(by = RESAMPLE_BY)          |>
  step_snv()                               |>
  step_sg(w = SG_W, p = SG_P, m = SG_M)
#
#
#
#| label: plot-spectra-fn

plot_spectra <- function(data, title = NULL, ylim = NULL) {
  wns <- get_wns(data)
  spc <- as.matrix(data[, get_wn_cols(data)])

  matplot(
    x    = wns,
    y    = t(spc),
    xlab = expression("Wavenumber /" * cm^-1),
    ylab = "Absorbance",
    xlim = c(max(wns), min(wns)),
    ylim = ylim,
    main = title,
    type = "l", lty = 1,
    col  = rgb(0.5, 0.5, 0.5, 0.3)
  )
}
#
#
#
#
#
#| label: fig-spectra-check

rec_prepped <- prep(rec)
train_baked <- bake(rec_prepped, new_data = NULL)

par(mfrow = c(1, 2))
plot_spectra(training(split), title = "Raw")
plot_spectra(train_baked,     title = "Preprocessed")
par(mfrow = c(1, 1))
#
#
#
#
#
#
#
#| label: pls-spec

pls_spec <- pls(num_comp = tune()) |>
  set_engine("mixOmics") |>
  set_mode("regression")

pls_spec
#
#
#
#| label: pls-workflow

pls_wf <- workflow() |>
  add_recipe(rec) |>
  add_model(pls_spec)
#
#
#
#| label: pls-grid

pls_grid <- tibble(num_comp = seq_len(MAX_NCOMP))
#
#
#
#| label: pls-tune

pls_tuned <- tune_grid(
  pls_wf,
  resamples = validation_set(split),
  grid      = pls_grid,
  metrics   = metric_set(rmse, rsq)
)
#
#
#
#| label: fig-pls-tuning

autoplot(pls_tuned)
#
#
#
#| label: pls-final

pls_final <- pls_wf |>
  finalize_workflow(select_best(pls_tuned, metric = "rmse")) |>
  last_fit(split)

collect_metrics(pls_final)
#
#
#
#| label: fig-pls-obs-pred

pls_preds <- collect_predictions(pls_final)

pls_preds |>
  ggplot(aes(x = .pred, y = .data[[TARGET]])) +
  geom_point(alpha = 0.4) +
  geom_abline(colour = "red", linetype = "dashed") +
  coord_obs_pred() +
  labs(
    x     = "Predicted log10(soil_ex_K2O)",
    y     = "Observed log10(soil_ex_K2O)",
    title = glue::glue(
      "PLSR test set  |  RMSE = {round(collect_metrics(pls_final) |> filter(.metric == 'rmse') |> pull(.estimate), 3)},",
      "  R² = {round(collect_metrics(pls_final) |> filter(.metric == 'rsq') |> pull(.estimate), 3)}"
    )
  )

pls_preds |>
  mutate(
    pred_orig = 10^.pred,
    obs_orig  = 10^.data[[TARGET]]
  ) |>
  metrics(truth = obs_orig, estimate = pred_orig)
#
#
#
#
#
#| label: cubist-spec

cubist_spec <- cubist_rules(
  committees = tune(),
  neighbors  = tune()
) |>
  set_engine("Cubist") |>
  set_mode("regression")

cubist_wf <- workflow() |>
  add_recipe(rec) |>
  add_model(cubist_spec)
#
#
#
#| label: cubist-tune

cubist_grid <- grid_regular(
  committees(),
  neighbors(),
  levels = c(committees = 20, neighbors = 10)
)

cubist_tuned <- tune_grid(
  cubist_wf,
  resamples = validation_set(split),
  grid      = cubist_grid,
  metrics   = metric_set(rmse, rsq)
)
#
#
#
#| label: fig-cubist-tuning

autoplot(cubist_tuned)
select_best(cubist_tuned, metric = "rmse")
#
#
#
#| label: cubist-final

cubist_final <- cubist_wf |>
  finalize_workflow(select_best(cubist_tuned, metric = "rmse")) |>
  last_fit(split)

collect_metrics(cubist_final)
#
#
#
#| label: fig-cubist-obs-pred

collect_predictions(cubist_final) |>
  ggplot(aes(x = .pred, y = .data[[TARGET]])) +
  geom_point(alpha = 0.4) +
  geom_abline(colour = "red", linetype = "dashed") +
  coord_obs_pred() +
  labs(
    x     = "Predicted log10(soil_ex_K2O)",
    y     = "Observed log10(soil_ex_K2O)",
    title = glue::glue(
      "Cubist test set  |  RMSE = {round(collect_metrics(cubist_final) |> filter(.metric == 'rmse') |> pull(.estimate), 3)},",
      "  R² = {round(collect_metrics(cubist_final) |> filter(.metric == 'rsq') |> pull(.estimate), 3)}"
    )
  )

collect_predictions(cubist_final) |>
  mutate(
    pred_orig = 10^.pred,
    obs_orig  = 10^.data[[TARGET]]
  ) |>
  metrics(truth = obs_orig, estimate = pred_orig)
#
#
#
#| label: fig-cubist-vip

vi(extract_fit_parsnip(cubist_final)) |>
  mutate(wn = as.numeric(str_remove(Variable, "^X"))) |>
  filter(!is.na(wn)) |>
  ggplot(aes(x = wn, y = Importance)) +
  geom_line() +
  scale_x_reverse() +
  labs(
    x = expression("Wavenumber /" * cm^-1),
    y = "Variable importance"
  )
#
#
#
#
