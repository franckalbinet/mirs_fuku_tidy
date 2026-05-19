# ── Constructor (user-facing) ─────────────────────────────────────────────────
step_snv <- function(
  recipe,
  ...,
  role    = NA,
  trained = FALSE,
  skip    = FALSE,
  id      = rand_id("snv")
) {
  terms <- enquos(...)
  if (is_empty(terms)) terms <- quos(all_predictors())  # <-- default
  
  add_step(
    recipe,
    step_snv_new(
      terms   = terms,
      cols    = NULL,
      role    = role,
      trained = trained,
      skip    = skip,
      id      = id
    )
  )
}

# ── Internal constructor ───────────────────────────────────────────────────────
step_snv_new <- function(terms, cols, role, trained, skip, id) {
  step(
    subclass = "snv",
    terms    = terms,
    cols     = cols,
    role     = role,
    trained  = trained,
    skip     = skip,
    id       = id
  )
}

# ── prep: resolve selectors → column names (nothing to estimate) ──────────────
prep.step_snv <- function(x, training, info = NULL, ...) {
  cols <- recipes_eval_select(x$terms, training, info)
  
  step_snv_new(
    terms   = x$terms,
    cols    = cols,
    role    = x$role,
    trained = TRUE,
    skip    = x$skip,
    id      = x$id
  )
}

# ── bake: apply SNV row-wise ───────────────────────────────────────────────────
bake.step_snv <- function(object, new_data, ...) {
  check_new_data(object$cols, object, new_data)
  
  spc     <- as.matrix(new_data[, object$cols])
  spc_snv <- prospectr::standardNormalVariate(spc)
  colnames(spc_snv) <- object$cols
  
  new_data |>
    select(-all_of(object$cols)) |>
    bind_cols(as_tibble(spc_snv))
}

# ── print ──────────────────────────────────────────────────────────────────────
print.step_snv <- function(x, width = max(20, options()$width - 35), ...) {
  print_step(
    tr_obj   = x$cols,
    untr_obj = x$terms,
    trained  = x$trained,
    title    = "Standard Normal Variate (SNV) on ",
    width    = width
  )
  invisible(x)
}

# ── tidy: one row per selected column ─────────────────────────────────────────
tidy.step_snv <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble::tibble(terms = x$cols)
  } else {
    res <- tibble::tibble(terms = recipes::sel2char(x$terms))
  }
  res$id <- x$id
  res
}


# ── Constructor (user-facing) ─────────────────────────────────────────────────
step_sg <- function(
  recipe,
  ...,
  w       = 11L,
  p       = 2L,
  m       = 1L,
  role    = NA,
  trained = FALSE,
  skip    = FALSE,
  id      = rand_id("sg")
) {
  terms <- enquos(...)
  if (is_empty(terms)) terms <- quos(all_predictors())
  
  add_step(
    recipe,
    step_sg_new(
      terms   = terms,
      w       = w,
      p       = p,
      m       = m,
      cols    = NULL,
      role    = role,
      trained = trained,
      skip    = skip,
      id      = id
    )
  )
}

# ── Internal constructor ───────────────────────────────────────────────────────
step_sg_new <- function(terms, w, p, m, cols, role, trained, skip, id) {
  step(
    subclass = "sg",
    terms    = terms,
    w        = w,
    p        = p,
    m        = m,
    cols     = cols,
    role     = role,
    trained  = trained,
    skip     = skip,
    id       = id
  )
}

# ── prep: resolve selectors → column names ────────────────────────────────────
prep.step_sg <- function(x, training, info = NULL, ...) {
  cols <- recipes_eval_select(x$terms, training, info)
  
  step_sg_new(
    terms   = x$terms,
    w       = x$w,
    p       = x$p,
    m       = x$m,
    cols    = cols,
    role    = x$role,
    trained = TRUE,
    skip    = x$skip,
    id      = x$id
  )
}

# ── bake: apply Savitzky-Golay, preserve trimmed wavenumber names ─────────────
bake.step_sg <- function(object, new_data, ...) {
  check_new_data(object$cols, object, new_data)
  
  spc    <- as.matrix(new_data[, object$cols])
  spc_sg <- prospectr::savitzkyGolay(
    spc,
    w = object$w,
    p = object$p,
    m = object$m
  )
  
  # savitzkyGolay() trims (w-1)/2 points from each end
  trim      <- (object$w - 1L) / 2L
  kept_cols <- object$cols[seq(trim + 1L, length(object$cols) - trim)]
  colnames(spc_sg) <- kept_cols
  
  new_data |>
    select(-all_of(object$cols)) |>
    bind_cols(as_tibble(spc_sg))
}

# ── print ─────────────────────────────────────────────────────────────────────
print.step_sg <- function(x, width = max(20, options()$width - 35), ...) {
  title <- glue::glue("Savitzky-Golay (w={x$w}, p={x$p}, m={x$m}) on ")
  print_step(
    tr_obj   = x$cols,
    untr_obj = x$terms,
    trained  = x$trained,
    title    = title,
    width    = width
  )
  invisible(x)
}

# ── tidy: one row per selected column ─────────────────────────────────────────
tidy.step_sg <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble::tibble(
      terms = x$cols,
      w     = x$w,
      p     = x$p,
      m     = x$m
    )
  } else {
    res <- tibble::tibble(
      terms = recipes::sel2char(x$terms),
      w     = x$w,
      p     = x$p,
      m     = x$m
    )
  }
  res$id <- x$id
  res
}

# ── tunable: w, p, and m are all tunable ──────────────────────────────────────
tunable.step_sg <- function(x, ...) {
  tibble::tibble(
    name      = c("w", "p", "m"),
    call_info = list(
      list(pkg = NULL, fun = "sg_window"),
      list(pkg = NULL, fun = "sg_degree"),
      list(pkg = NULL, fun = "sg_diff_order")
    ),
    source       = "recipe",
    component    = "step_sg",
    component_id = x$id
  )
}


# ── Constructor (user-facing) ─────────────────────────────────────────────────
step_resample <- function(
  recipe,
  ...,
  by      = 5,
  role    = NA,
  trained = FALSE,
  skip    = FALSE,
  id      = rand_id("resample")
) {
  terms <- enquos(...)
  if (is_empty(terms)) terms <- quos(all_predictors())
  
  add_step(
    recipe,
    step_resample_new(
      terms    = terms,
      by       = by,
      cols     = NULL,
      wns      = NULL,   # original wavenumbers, learned in prep
      new_wns  = NULL,   # target wavenumber grid, learned in prep
      role     = role,
      trained  = trained,
      skip     = skip,
      id       = id
    )
  )
}

# ── Internal constructor ───────────────────────────────────────────────────────
step_resample_new <- function(terms, by, cols, wns, new_wns, role, trained, skip, id) {
  step(
    subclass = "resample",
    terms    = terms,
    by       = by,
    cols     = cols,
    wns      = wns,
    new_wns  = new_wns,
    role     = role,
    trained  = trained,
    skip     = skip,
    id       = id
  )
}

# ── prep: resolve selectors and fix wavenumber grids ─────────────────────────
prep.step_resample <- function(x, training, info = NULL, ...) {
  cols    <- recipes_eval_select(x$terms, training, info)
  wns     <- get_wns(training)
  new_wns <- seq(min(wns), max(wns), by = x$by)
  
  # Inherit the role from the original spectral columns
  # so downstream steps can find them via all_predictors()
  col_info <- info[info$variable %in% cols, ]
  inherited_role <- unique(col_info$role)  # should be "predictor"
  
  step_resample_new(
    terms   = x$terms,
    by      = x$by,
    cols    = cols,
    wns     = wns,
    new_wns = new_wns,
    role    = inherited_role,   # <-- was NA, now "predictor"
    trained = TRUE,
    skip    = x$skip,
    id      = x$id
  )
}

# ── bake: resample onto the fixed grid learned in prep ────────────────────────
bake.step_resample <- function(object, new_data, ...) {
  check_new_data(object$cols, object, new_data)
  
  spc    <- as.matrix(new_data[, object$cols])
  spc_rs <- prospectr::resample(
    spc,
    wav      = object$wns,
    new.wav  = object$new_wns,
    interpol = "linear"
  )
  new_col_names <- paste0("X", round(object$new_wns))
  colnames(spc_rs) <- new_col_names
  
  new_data |>
    select(-all_of(object$cols)) |>
    bind_cols(as_tibble(spc_rs))
}

# ── print ─────────────────────────────────────────────────────────────────────
print.step_resample <- function(x, width = max(20, options()$width - 35), ...) {
  title <- glue::glue("Spectral resampling (by={x$by}) on ")
  print_step(
    tr_obj   = x$cols,
    untr_obj = x$terms,
    trained  = x$trained,
    title    = title,
    width    = width
  )
  invisible(x)
}

# ── tidy: one row per selected column ─────────────────────────────────────────
tidy.step_resample <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble::tibble(
      terms   = x$cols,
      by      = x$by,
      wns     = x$wns,
      new_wns = x$new_wns
    )
  } else {
    res <- tibble::tibble(
      terms   = recipes::sel2char(x$terms),
      by      = x$by,
      wns     = NA_real_,
      new_wns = NA_real_
    )
  }
  res$id <- x$id
  res
}

# ── tunable ───────────────────────────────────────────────────────────────────
tunable.step_resample <- function(x, ...) {
  tibble::tibble(
    name = "by",
    call_info = list(
      list(pkg = "your_pkg", fun = "resample_by")
    ),
    source       = "recipe",
    component    = "step_resample",
    component_id = x$id
  )
}

sg_window <- function(range = c(5L, 21L), trans = NULL) {
  dials::new_quant_param(
    type      = "integer",
    range     = range,
    inclusive = c(TRUE, TRUE),
    trans     = trans,
    label     = c(sg_window = "SG Window Size")
  )
}

sg_degree <- function(range = c(1L, 3L), trans = NULL) {
  dials::new_quant_param(
    type      = "integer",
    range     = range,
    inclusive = c(TRUE, TRUE),
    trans     = trans,
    label     = c(sg_degree = "SG Polynomial Degree")
  )
}

sg_diff_order <- function(range = c(0L, 2L), trans = NULL) {
  dials::new_quant_param(
    type      = "integer",
    range     = range,
    inclusive = c(TRUE, TRUE),
    trans     = trans,
    label     = c(sg_diff_order = "SG Derivative Order")
  )
}

resample_by <- function(range = c(1, 20), trans = NULL) {
  dials::new_quant_param(
    type      = "double",
    range     = range,
    inclusive = c(TRUE, TRUE),
    trans     = trans,
    label     = c(resample_by = "Resampling Interval")
  )
}


# ── Constructor (user-facing) ─────────────────────────────────────────────────
step_rm_co2 <- function(
  recipe,
  ...,
  min_wn  = 2269,
  max_wn  = 2389,
  role    = NA,
  trained = FALSE,
  skip    = FALSE,
  id      = rand_id("rm_co2")
) {
  terms <- enquos(...)
  if (is_empty(terms)) terms <- quos(all_predictors())

  add_step(
    recipe,
    step_rm_co2_new(
      terms   = terms,
      min_wn  = min_wn,
      max_wn  = max_wn,
      cols    = NULL,
      role    = role,
      trained = trained,
      skip    = skip,
      id      = id
    )
  )
}

# ── Internal constructor ───────────────────────────────────────────────────────
step_rm_co2_new <- function(terms, min_wn, max_wn, cols, role, trained, skip, id) {
  step(
    subclass = "rm_co2",
    terms    = terms,
    min_wn   = min_wn,
    max_wn   = max_wn,
    cols     = cols,
    role     = role,
    trained  = trained,
    skip     = skip,
    id       = id
  )
}

# ── prep: identify wavenumber columns within the CO2 band ─────────────────────
prep.step_rm_co2 <- function(x, training, info = NULL, ...) {
  all_cols <- recipes_eval_select(x$terms, training, info)
  wns      <- as.numeric(sub("^X", "", all_cols))
  cols     <- all_cols[!is.na(wns) & wns >= x$min_wn & wns <= x$max_wn]

  step_rm_co2_new(
    terms   = x$terms,
    min_wn  = x$min_wn,
    max_wn  = x$max_wn,
    cols    = cols,
    role    = x$role,
    trained = TRUE,
    skip    = x$skip,
    id      = x$id
  )
}

# ── bake: drop the CO2 band columns ───────────────────────────────────────────
bake.step_rm_co2 <- function(object, new_data, ...) {
  check_new_data(object$cols, object, new_data)
  new_data |> select(-all_of(object$cols))
}

# ── print ──────────────────────────────────────────────────────────────────────
print.step_rm_co2 <- function(x, width = max(20, options()$width - 35), ...) {
  title <- glue::glue("CO2 band removal ({x$min_wn}–{x$max_wn} cm⁻¹) on ")
  print_step(
    tr_obj   = x$cols,
    untr_obj = x$terms,
    trained  = x$trained,
    title    = title,
    width    = width
  )
  invisible(x)
}

# ── tidy: one row per removed column ──────────────────────────────────────────
tidy.step_rm_co2 <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble::tibble(terms = x$cols)
  } else {
    res <- tibble::tibble(terms = recipes::sel2char(x$terms))
  }
  res$id <- x$id
  res
}
