# utils.R — Helpers for navigating wide MIR spectral tibbles
# Wavenumber columns are always named X{integer} (e.g. X4000, X3995)

# All non-wavenumber column names (metadata, target, etc.)
get_non_spc_names <- function(data) {
  grep("^X\\d+", names(data), value = TRUE, invert = TRUE)
}

# Wavenumber column names as character vector
get_wn_cols <- function(data) {
  grep("^X\\d+$", colnames(data), value = TRUE)
}

# Wavenumber values as numeric vector
get_wns <- function(data) {
  as.numeric(sub("^X", "", get_wn_cols(data)))
}
