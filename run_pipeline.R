## run_pipeline.R
## Runs every data product in turn. Open gom-plankton-data-products.Rproj
## before running so that getwd() resolves to the repo root. Each product can
## also be run on its own with its run script.

source("spm_biomass/run_spm_biomass.R")   # DFO Calanus biomass (+ the shared region maps in geography/)
source("sentinel/run_sentinel.R")         # WBTS / CMTS sentinel indicators
source("satellite/run_satellite.R")       # satellite SST and chlorophyll
source("cpr/run_cpr.R")                   # CPR index, Western Scotian Shelf

cat("\nAll pipelines complete.\n")
