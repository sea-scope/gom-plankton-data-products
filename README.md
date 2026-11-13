# Gulf of Maine plankton data products

Prepared datasets and web viewers for Gulf of Maine plankton and environmental indicators, maintained by NERACOOS:

| Product | What it is | Code | Outputs | Web page |
|---|---|---|---|---|
| **DFO *Calanus* biomass** | Modelled *C. finmarchicus* CIV–CVI biomass from the DFO species distribution model (Plourde et al. 2024), aggregated to CINAR polygons and EcoMon strata | `R/01_spm_biomass/`, `run_spm_biomass.R` | `summaries/spm_biomass/` | `spm_biomass/cinar.html`, `ecomon.html`, `cpo.html` |
| **Sentinel indicators** | WBTS and CMTS station time series: *Calanus* abundance, stage index, mesozooplankton biomass; GAM-based anomalies | `R/02_sentinel_indicators/`, `run_sentinel.R` | `data/sentinel/prepared/`, `summaries/sentinel/` | `sentinel/index.html` |
| **Satellite SST and chlorophyll** | NOAA OISST v2.1 SST and ESA OC-CCI v6 chlorophyll-a, 8-day composites and daily means over CINAR and CPO polygons and 5 km buffers around WBTS/CMTS | `R/04_satellite_products/`, `run_satellite.R` | `summaries/satellite/` | `satellite/cinar.html`, `cpo.html` |
| **CPR index** | Continuous Plankton Recorder, Western Scotian Shelf: annual *C. finmarchicus* CV–CVI and zooplankton energy (ZCEI) indices, biological year Aug–Jul | `R/05_cpr/`, `run_cpr.R` | `data/cpr/`, `summaries/cpr/` | — |

The landing page is `index.html`. Region polygons used across the products are in `data/` (`poly_*.csv`) and `data/spm_biomass/`.

## Layout

```
gom-plankton-data-products/
  gom-plankton-data-products.Rproj   open first: every script runs from the repo root
  settings.R                         where the raw inputs live (outside the repo)
  run_pipeline.R                     runs every product in turn
  run_spm_biomass.R, run_sentinel.R, run_satellite.R, run_cpr.R
  R/01_spm_biomass/  R/02_sentinel_indicators/  R/04_satellite_products/  R/05_cpr/  R/shared/
  data/        prepared inputs and polygons (raw inputs are not committed)
  summaries/   the published tables
  plots/       viewer images and diagnostics
  figures/     maps
  index.html   landing page; one folder of pages per product (spm_biomass/, sentinel/, satellite/)
```

## Reproducing the products

1. **Raw inputs.** They are not in the repo. Put them in one data folder, and set `SEASCOPE_DATA` in `~/.Renviron` to point at it (see `settings.R`):

   | Subfolder | Contents | Source |
   |---|---|---|
   | `dfo_bioenergy_3d/` | DFO Bioenergy_3D `*.rds` files (~8.8 GB) | DFO (Caroline Lehoux, Eve Rioux) |
   | `satellite_erddap_cache/` | NetCDF cache | downloaded by `run_satellite.R` from ERDDAP |
   | `sentinel_uber/` | raw station spreadsheets (UBER and MBON Excel files) | WHOI Zooplankton Lab. Not public |
   | `cpr/` | `WSS_data_per_tow.csv`, raw CPR tows | J. Pinti (NERACOOS/GMRI). Not public |

2. **R packages.**
   - Every product: dplyr, tidyr, ggplot2, sf, scales.
   - DFO biomass: leaflet, leaflet.extras, htmlwidgets, jsonlite, marmap, mapdata, viridis, RColorBrewer.
   - Sentinel: mgcv, DHARMa, MASS, readxl, lubridate, ggspatial, rnaturalearth, patchwork, gridExtra, shadowtext, tibble.
   - Satellite: rerddap, terra, exactextractr, ncdf4, units, lubridate, readr.
   - CPR: mgcv, DHARMa.

3. **Run.** Open the `.Rproj`, then `source("run_pipeline.R")`, or the run script of a single product. Each run script lists its steps and outputs.

The DFO step that reads the `.rds` files and the satellite download step are slow. Their outputs (`summaries/`) are committed, so the plotting steps can be rerun from them alone.

## Reading the viewer plots (DFO biomass and satellite)

Each per-year figure has four layers:

| Layer | Meaning |
|---|---|
| Light grey ribbon | historical range (min–max across all years) |
| Dark grey ribbon | climatological mean ± 1 SD |
| Dashed grey line | climatological mean |
| Orange line + error bars | the selected year, mean ± 1 SD |

Months with fewer than 22 data points show a "limited data" placeholder.

## Status (2026-11-13)

- This repo was split out of `sea-scope/Gulf_of_Maine_Plankton_Sentinel_Indicators` (now an archive).
- The code, prepared data and published tables were carried over unchanged, apart from path updates. The next full pipeline run will re-check them.
- The DFO and satellite viewer images are not yet committed. They will be re-rendered at 150 dpi on that run, then added.

## References

- Plourde, S., et al. (2024). Calanus species distribution models and NARW foraging habitat in Canadian waters. DFO CSAS Research Document 2024/039.

**Maintainer:** Cameron Thompson, NERACOOS
