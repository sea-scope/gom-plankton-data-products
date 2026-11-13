## run_spm_biomass.R
## Orchestrator for the SPM Calanus biomass pipeline.
## Open gom-plankton-data-products.Rproj before running so that
## getwd() resolves to the repo root.
##
## Steps 1-4g reproduce the full DFO (SPM) biomass product, all under spm_biomass/:
##   processed/ -> polygons/ -> summaries/ -> plots/ + figures/
## processed/ and polygons/ are intermediates (gitignored). Step 4g draws the
## shared region maps into geography/figures/ (used by every product page).

source("spm_biomass/R/DFO_data_process.R")           # Step 1: RDS -> processed/
source("spm_biomass/R/Data_layer_Polygons.R")         # Step 2: processed/ -> polygons/
source("spm_biomass/R/DFO_data_polygon_summary.R")    # Step 3: polygons/ -> summaries/

source("spm_biomass/R/DFO_biomass_visualization_CINAR.R")   # Step 4a: CINAR biomass plots
source("spm_biomass/R/DFO_biomass_visualization_EcoMon.R")  # Step 4b: EcoMon biomass plots

source("spm_biomass/R/export_viewer_metadata.R")            # Step 4c: viewer metadata JSON

source("spm_biomass/R/DFO_CINAR_polygon_map.R")             # Step 4e: CINAR polygon map
source("spm_biomass/R/DFO_EcoMon_strata_map.R")             # Step 4f: EcoMon strata map
source("geography/R/DFO_region_map.R")                    # Step 4g: CINAR + SBNMS region maps

cat("\nSPM biomass pipeline complete. Output files:\n")
cat("  spm_biomass/processed/                 -- depth-integrated biomass per grid point (gitignored)\n")
cat("  spm_biomass/polygons/                  -- polygon-assigned grid points (gitignored)\n")
cat("  spm_biomass/summaries/                 -- DFO_biomass_summary.csv\n")
cat("  spm_biomass/plots/stations_metadata.json -- viewer metadata\n")
cat("  spm_biomass/plots/{cinar,ecomon}_{overview,yearly}/ -- viewer figures\n")
cat("  spm_biomass/figures/                   -- polygon QC and strata maps\n")
cat("  geography/figures/                     -- CINAR and SBNMS region maps\n")
