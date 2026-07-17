# split.R — Two-stage Kennard-Stone split wrapped into rsample objects
# Requires: utils.R (get_wn_cols), resemble, prospectr, rsample
#
# Split proportions (all relative to full dataset):
#   train      : calib_prop                    (e.g. 0.65)
#   validation : train_prop - calib_prop       (e.g. 0.10)
#   test       : 1 - train_prop                (e.g. 0.25)


# PCA on spectral matrix — used by KS to compute Mahalanobis distance
pca_scores <- function(data, max_expl_var, use_snv = TRUE) {
  wn_matrix <- as.matrix(data[, get_wn_cols(data)])

  xr <- if (use_snv) prospectr::standardNormalVariate(wn_matrix) else wn_matrix

  resemble::ortho_projection(
    Xr     = xr,
    ncomp  = resemble::ncomp_by_cumvar(max_expl_var),
    center = TRUE,
    scale  = FALSE
  )$scores
}


ks_split <- function(data,
                     train_prop   = 0.75,
                     calib_prop   = 0.65,
                     max_expl_var = 0.99,
                     seed         = 123L) {

  stopifnot(calib_prop < train_prop, train_prop < 1)
  n <- nrow(data)

  # Stage 1: train pool vs test
  set.seed(seed)
  ks_1 <- prospectr::kenStone(
    X = pca_scores(data, max_expl_var),
    k = floor(n * train_prop), metric = "mahal",
    .center = TRUE, .scale = FALSE
  )
  train_pool_idx <- sort(ks_1$model)

  # Stage 2: train vs validation within train pool
  set.seed(seed)
  ks_2 <- prospectr::kenStone(
    X = pca_scores(data[train_pool_idx, ], max_expl_var),
    k = floor(n * calib_prop), metric = "mahal",
    .center = TRUE, .scale = FALSE
  )
  train_idx <- sort(train_pool_idx[ks_2$model])
  val_idx   <- sort(train_pool_idx[ks_2$test])

  message(glue::glue(
    "Split: {length(train_idx)} train | ",
    "{length(val_idx)} val | ",
    "{n - length(train_idx) - length(val_idx)} test"
  ))

  # ---- Emit an initial_validation_split object ----
  res <- list(
    data     = data,
    train_id = train_idx,
    val_id   = val_idx,
    test_id  = NA,        # rsample convention: test = complement
    id       = "split"
  )
  class(res) <- c("initial_validation_split", "three_way_split")
  res
}


# Kennard-Stone split into a train pool (for CV-based tuning) and a fixed test set.
# Stage 1 only — same seed/pool_prop as ks_split(), so the test set is
# identical to ks_split()'s test set (directly comparable metrics).
# Returns a two-way rsplit — training(split) is the pool, testing(split) is the test set.
ks_pool_split <- function(data,
                           pool_prop    = 0.75,
                           max_expl_var = 0.99,
                           seed         = 123L) {
  n <- nrow(data)

  set.seed(seed)
  ks_pool <- prospectr::kenStone(
    X = pca_scores(data, max_expl_var),
    k = floor(n * pool_prop), metric = "mahal",
    .center = TRUE, .scale = FALSE
  )
  pool_idx <- as.integer(sort(ks_pool$model))
  test_idx <- as.integer(sort(ks_pool$test))

  message(glue::glue(
    "KS pool split: {length(pool_idx)} pool | {length(test_idx)} test"
  ))

  rsample::make_splits(
    x    = list(analysis = pool_idx, assessment = test_idx),
    data = data
  )
}