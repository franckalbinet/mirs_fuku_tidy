# load.R — Data ingestion for MIR soil spectroscopy
# Wavenumber columns are normalised to X{integer} at ingestion (e.g. X4000)


# Rename numeric column names (integer or float) to X{integer} format
normalise_wn_cols <- function(data) {
  nms     <- names(data)
  is_wn   <- grepl("^[0-9]+\\.?[0-9]*$", nms)
  new_nms <- ifelse(is_wn, paste0("X", round(as.numeric(nms))), nms)
  setNames(data, new_nms)
}


# Load raw MIR spectra from RDS; normalise wavenumber column names
load_spectra <- function(path) {
  readRDS(path) |>
    mutate(sample_id = as.integer(sample_id)) |>
    normalise_wn_cols()
}


# Load wet chemistry data from CSV
load_wet_data <- function(path, header = TRUE, sep = ";", dec = ",") {
  read.csv(path, header = header, sep = sep, dec = dec) |>
    mutate(year = as.integer(year))
}

# Inner-join wet chemistry and spectra; surviving ID column is named by_wet
join_wet_spectra <- function(wet, spectra, by_wet, by_spectra) {
  stopifnot(by_wet %in% names(wet), by_spectra %in% names(spectra))
  inner_join(wet, spectra, by = setNames(by_spectra, by_wet))
}


# Load and join wet chemistry and MIR spectra into one tibble
load_raw_data <- function(wet_path, spectra_path, by_wet, by_spectra,
                          header = TRUE, sep = ";", dec = ",") {
  wet     <- load_wet_data(wet_path, header = header, sep = sep, dec = dec)
  spectra <- load_spectra(spectra_path)
  raw <- join_wet_spectra(wet, spectra, by_wet, by_spectra)
  raw |> select(-spc, -specSnvC, -spcAtSg, -X2022_soil_total_Cs137, -X2022_soil_ex_Cs137)
}