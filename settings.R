## settings.R -- where the large and restricted inputs live (outside the repo)
##
## The repo holds the code, the prepared data and the outputs. Raw inputs that
## are large (the DFO model files, the satellite download cache) or not ours to
## publish (raw CPR tows, raw station spreadsheets) live in one data folder
## outside the repo. Every script that needs one of them sources this file.
##
## To point at the data folder, set SEASCOPE_DATA in ~/.Renviron, e.g.
##   SEASCOPE_DATA="C:/Users/camer/NERACOOS Dropbox/Cameron Thompson/sea-scope-data"
## On Windows the line below falls back to that folder; on any other system
## SEASCOPE_DATA must be set.
##
## Data folder layout (subfolders used by this repo):
##   dfo_bioenergy_3d/        DFO Bioenergy_3D *.rds files (download from DFO)
##   satellite_erddap_cache/  ERDDAP NetCDF cache, rebuilt by the satellite ingest step
##   sentinel_uber/           raw station spreadsheets (if not read from the WHOI OneDrive)
##   cpr/                     WSS_data_per_tow.csv, raw CPR tows (not public)

if (.Platform$OS.type == "windows") {
  DATA_DIR <- Sys.getenv("SEASCOPE_DATA",
                         unset = "C:/Users/camer/NERACOOS Dropbox/Cameron Thompson/sea-scope-data")
} else {
  DATA_DIR <- Sys.getenv("SEASCOPE_DATA")
  if (DATA_DIR == "") stop("Set SEASCOPE_DATA in ~/.Renviron to the sea-scope-data folder (see settings.R).")
}

## DFO Calanus model files (step 1 of run_spm_biomass.R)
DFO_RDS_DIR <- file.path(DATA_DIR, "dfo_bioenergy_3d")

## Satellite download cache (run_satellite.R, ingest step)
SATELLITE_CACHE_DIR <- file.path(DATA_DIR, "satellite_erddap_cache")

## Raw sentinel station spreadsheets (run_sentinel.R). Read from the WHOI
## OneDrive on CT's Windows machine; anywhere else set SEASCOPE_UBER, or copy
## the files to sea-scope-data/sentinel_uber.
if (.Platform$OS.type == "windows") {
  SENTINEL_UBER_DIR <- Sys.getenv("SEASCOPE_UBER",
                                  unset = "C:/Users/camer/OneDrive - Woods Hole Oceanographic Institution/Data/Zoo Lab Data")
} else {
  SENTINEL_UBER_DIR <- Sys.getenv("SEASCOPE_UBER", unset = file.path(DATA_DIR, "sentinel_uber"))
}

## Raw CPR tows, Western Scotian Shelf (R/05_cpr/cpr_01_load.R). Not public.
CPR_TOWS_FILE <- file.path(DATA_DIR, "cpr", "WSS_data_per_tow.csv")
