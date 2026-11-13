# Sentinel indicators (WBTS and CMTS)

Zooplankton time series at the Wilkinson Basin (WBTS) and Coastal Maine (CMTS) stations:
- *Calanus finmarchicus* abundance;
- the *Calanus* stage index;
- mesozooplankton biomass;
- seasonal GAMs, with anomalies relative to a baseline.

**Published tables:**
- `data/prepared/` (`*_prepared.csv`, `*_prepared_enriched.csv`)
- `summaries/` (`sentinel_dashboard.csv`, `predictions_long.csv`, `anomalies_long.csv`, `baselines.csv`, `model_diagnostics.csv`)

**Run:** from the repo root, `source("sentinel/run_sentinel.R")`.

| Step | Script | Does |
|---|---|---|
| 1 | `R/station_config.R` | station definitions |
| 2 | `R/ingest_station_data.R` | raw UBER/MBON spreadsheets (`SENTINEL_UBER_DIR`, `settings.R`) → `data/raw/` (gitignored) |
| 3 | `R/prepare_station_data.R` | cleaning → `data/prepared/` |
| 4 | `R/analyze_station_data.R` | GAMs, anomalies, figures and the dashboard. Sources `fit_sentinel_gams.R`, `compute_anomalies.R`, the `plot_*.R` scripts and `export_sentinel_metadata.R` |
| 5 | `R/plot_presentation_poster_wbts.R` | presentation and poster figures |

- **Not in the run script:**
  - `R/plot_poster_wbts.R`: a single poster figure;
  - `R/plot_station_map.R`: the station map, written to `figures/NES_bathy_CMTS_WBTS_SBNMS_map.*`.
- **Plot theme:** `R/theme_sentinel.R`.
- **Web page:** `index.html` (`?station=WBTS` or `?station=CMTS`).

**Packages:** dplyr, tidyr, tibble, ggplot2, mgcv, DHARMa, MASS, readxl, lubridate, sf, ggspatial, rnaturalearth, marmap, patchwork, gridExtra, scales, shadowtext, jsonlite.
