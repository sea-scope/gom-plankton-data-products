# Gulf of Maine plankton data products

Prepared datasets and web viewers for Gulf of Maine plankton and environmental indicators, maintained by NERACOOS. Each product has its own folder: code, prepared data, published tables, figures and web pages, plus a README.

| Folder | Product | Published tables |
|---|---|---|
| [`spm_biomass/`](spm_biomass/) | Modelled *C. finmarchicus* CIV–CVI biomass, DFO species distribution model (Plourde et al. 2024), aggregated to CINAR polygons and EcoMon strata | `spm_biomass/summaries/DFO_biomass_summary.csv` |
| [`sentinel/`](sentinel/) | WBTS and CMTS station time series: *Calanus* abundance, stage index, mesozooplankton biomass, GAM-based anomalies | `sentinel/data/prepared/`, `sentinel/summaries/` |
| [`satellite/`](satellite/) | NOAA OISST v2.1 SST and ESA OC-CCI v6 chlorophyll-a: 8-day composites and daily means over CINAR and CPO polygons and 5 km buffers around WBTS/CMTS | `satellite/summaries/` |
| [`cpr/`](cpr/) | Continuous Plankton Recorder, Western Scotian Shelf: annual *C. finmarchicus* CV–CVI and zooplankton energy (ZCEI) indices, biological year Aug–Jul | `cpr/data/` |
| [`geography/`](geography/) | Shared region polygons (CINAR, CPO/SBNMS, EcoMon strata, Bay of Fundy critical habitat) and the region maps | the polygon CSVs |

`index.html` is the landing page. Each product's pages sit in its folder.

## How the repo works

- **Working directory.** Open `gom-plankton-data-products.Rproj`; every script runs from the repo root.
- **Raw inputs.** They are not committed. `settings.R` says where they live: one data folder outside the repo, set with `SEASCOPE_DATA` in `~/.Renviron`.
- **Running.** `source("run_pipeline.R")` runs every product. A product's own run script runs just that one, e.g. `source("satellite/run_satellite.R")`.
- **Copying one product elsewhere:** take its folder, plus `settings.R`, `geography/` and the `.Rproj`.

## Raw inputs (data folder)

| Subfolder | Contents | Source |
|---|---|---|
| `dfo_bioenergy_3d/` | DFO Bioenergy_3D `*.rds` files (~8.8 GB) | DFO (Caroline Lehoux, Eve Rioux) |
| `satellite_erddap_cache/` | NetCDF cache | downloaded from ERDDAP by the satellite run script |
| `sentinel_uber/` | raw station spreadsheets (UBER and MBON Excel files) | WHOI Zooplankton Lab. Not public |
| `cpr/` | `WSS_data_per_tow.csv`, raw CPR tows | J. Pinti (NERACOOS/GMRI). Not public |

## Status (2026-11-13)

- Split out of `sea-scope/Gulf_of_Maine_Plankton_Sentinel_Indicators`, which is now an archive.
- Code, prepared data and published tables were carried over unchanged apart from paths. The next full pipeline run will re-check them.
- The DFO and satellite viewer images are not yet committed. They will be re-rendered at 150 dpi on that run, then added.

**Maintainer:** Cameron Thompson, NERACOOS
