# Satellite SST and chlorophyll

NOAA OISST v2.1 sea surface temperature (daily, 0.25°, 1982 on) and ESA OC-CCI v6 chlorophyll-a (8-day, ~4 km, 1998 on). Both are extracted over:
- the CINAR polygons;
- the CPO polygons;
- 5 km buffers around the WBTS and CMTS stations.

They are then summarised as 8-day composites and as daily polygon means.

**Published tables:**
- `summaries/satellite_summary.csv`: 8-day composites;
- `summaries/satellite_daily.csv`: daily polygon means, used by the downstream analyses.

**Run:** from the repo root, `source("satellite/run_satellite.R")`. Downloads go to `SATELLITE_CACHE_DIR` (`settings.R`).

| Script | Does |
|---|---|
| `R/satellite_config.R` | datasets, ERDDAP servers, geography sets, minimum counts, output paths |
| `R/load_geography_sets.R` | polygons from `geography/` and the EcoMon strata |
| `R/satellite_ingest.R` | ERDDAP download into the cache |
| `R/satellite_extract.R`, `R/satellite_composite.R`, `R/satellite_summary.R` | polygon extraction, 8-day composites, the two summary tables |
| `R/plot_satellite_climatology.R` | per-year and overview figures → `plots/{cinar,cpo,stations}/` |

- **Web pages:** `cinar.html`, `cpo.html`.
- **Per-year figures** read like the DFO biomass ones: range, mean ± SD, and the selected year.

**Packages:** dplyr, ggplot2, sf, terra, exactextractr, ncdf4, rerddap, units, lubridate, readr, scales, viridis.
