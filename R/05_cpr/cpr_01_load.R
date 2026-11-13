## cpr_01_load.R  (CPR index, step 1 of 2)
##
## Continuous Plankton Recorder tows on the Western Scotian Shelf (WSS), from
## Jerome Pinti (2026-10-14). Built for the right whale analysis (WP10) as an
## upstream Calanus record longer than the DFO biomass product (CPR from 1961,
## DFO from 1999); moved to the data products on 2026-11-13.
##
## Source: CPR_TOWS_FILE (settings.R; sea-scope-data/cpr/WSS_data_per_tow.csv,
## not public) -- one row per CPR sample (tow
## segment) in the WSS, 1,179 tows. Jerome's notes:
##   - energy         J / 100 m3, the Zooplankton Community Energy Index (ZCEI):
##                    abundance x energy per individual x a catchability
##                    correction factor that differs day vs night (Olin et al.
##                    2022 factors, from British time series), summed over the
##                    30 most frequent taxa.
##   - calanus_abund  ind / 100 m3, all Calanus: C. finmarchicus CV-CVI plus
##                    unidentified copepodites and adults of other species
##                    (mostly C. glacialis, few). NO catchability correction.
##   - cfin_abund     ind / 100 m3, C. finmarchicus CV-CVI only. Uncorrected.
##   - day_night      "day" or "night"; twilight tows were dropped by Jerome
##                    because the diel bias cannot be corrected there.
## Time of day is exact from 1977 on; before that tows carry 5 am / 5 pm UTC
## stamps, assumed night / day (Jerome's methods).
##
## Writes  data/cpr/tows/cpr_wss_tows.csv   one row per tow, tidied. Gitignored:
##         it is the raw tow data, which is not public.

library(dplyr)

if (!file.exists("gom-plankton-data-products.Rproj")) {
  stop("Working directory is ", getwd(), " -- open gom-plankton-data-products.Rproj ",
       "(or setwd to the repo root) and re-run.")
}

source("settings.R")      # CPR_TOWS_FILE: the raw tows, outside the repo
in_tows <- CPR_TOWS_FILE
out_dir <- "data/cpr/tows"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)


## ===========================================================================
## 1. Read and tidy
## ===========================================================================

raw <- read.csv(in_tows, stringsAsFactors = FALSE)

tows <- raw %>%
  mutate(date      = as.Date(date),
         year      = as.integer(format(date, "%Y")),
         month     = as.integer(format(date, "%m")),
         doy       = as.integer(format(date, "%j")),
         day_night = factor(day_night, levels = c("day", "night"))) %>%
  transmute(id = ID, cruise, transect = transect_number, date, year, month, doy,
            hour = hourofday, day_night, lat = latitude, lon = longitude,
            energy, calanus_abund, cfin_abund) %>%
  arrange(date, id)


## ===========================================================================
## 2. Look at what we have
## ===========================================================================

cat("tows:", nrow(tows), "|", min(tows$year), "-", max(tows$year),
    "| years with tows:", n_distinct(tows$year), "\n")
cat("day / night:\n"); print(table(tows$day_night, useNA = "ifany"))
cat("\nmissing years:", paste(setdiff(min(tows$year):max(tows$year), unique(tows$year)), collapse = ", "), "\n")

cat("\nzeros: energy", sum(tows$energy == 0), "| calanus_abund", sum(tows$calanus_abund == 0),
    "| cfin_abund", sum(tows$cfin_abund == 0), "\n")
cat("\nvalue ranges (quantiles):\n")
print(signif(sapply(tows[, c("energy", "calanus_abund", "cfin_abund")],
                    quantile, probs = c(0, 0.1, 0.5, 0.9, 1)), 3))

cat("\ntows per month (all years), by day / night:\n")
print(table(tows$month, tows$day_night))

cat("\nlocation range: lat", paste(range(tows$lat), collapse = " - "),
    "| lon", paste(range(tows$lon), collapse = " - "), "\n")


## ===========================================================================
## 3. Write
## ===========================================================================

write.csv(tows, file.path(out_dir, "cpr_wss_tows.csv"), row.names = FALSE)
cat("\nwrote", file.path(out_dir, "cpr_wss_tows.csv"), "\n")
