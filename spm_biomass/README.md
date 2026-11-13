# DFO *Calanus* biomass (SPM)

Modelled *Calanus finmarchicus* CIV–CVI biomass from the DFO species distribution model (Plourde et al. 2024), driven by GLORYS12v1. It is depth-integrated, then summarised by month for each CINAR polygon and EcoMon stratum.

**Published table:** `summaries/DFO_biomass_summary.csv`, monthly mean and SD per polygon, 1999–2024.

**Run:** from the repo root, `source("spm_biomass/run_spm_biomass.R")`.

| Step | Script | Does |
|---|---|---|
| 1 | `R/DFO_data_process.R` | reads the DFO `*.rds` files (from `DFO_RDS_DIR` in `settings.R`) and integrates over depth → `processed/` |
| 2 | `R/Data_layer_Polygons.R` | assigns grid points to CINAR polygons and EcoMon strata (polygons from `geography/`) → `polygons/` |
| 3 | `R/DFO_data_polygon_summary.R` | polygon statistics → `summaries/DFO_biomass_summary.csv` |
| 4a–b | `R/DFO_biomass_visualization_CINAR.R`, `_EcoMon.R` | viewer figures → `plots/` |
| 4c | `R/export_viewer_metadata.R` | `plots/stations_metadata.json` for the pages |
| 4e–f | `R/DFO_CINAR_polygon_map.R`, `R/DFO_EcoMon_strata_map.R` | polygon QC and strata maps → `figures/` |
| 4g | `../geography/R/DFO_region_map.R` | shared region maps → `geography/figures/` |

- **Intermediates:** `processed/` and `polygons/` are gitignored. Steps 1–2 are slow; steps 4a onward need only `summaries/`.
- **Web pages:** `cinar.html`, `ecomon.html`, `cpo.html`.
- **Reading the per-year figures:**
  - light grey ribbon = historical range;
  - dark grey ribbon = climatological mean ± 1 SD;
  - dashed line = climatological mean;
  - orange = the selected year, mean ± 1 SD;
  - months with fewer than 22 data points show "limited data".

**Packages:** dplyr, tidyr, ggplot2, sf, scales, leaflet, leaflet.extras, htmlwidgets, jsonlite, marmap, mapdata, viridis, RColorBrewer.

**Reference:** Plourde, S., et al. (2024). Calanus species distribution models and NARW foraging habitat in Canadian waters. DFO CSAS Research Document 2024/039.
