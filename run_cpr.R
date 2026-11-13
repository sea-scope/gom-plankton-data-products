## run_cpr.R
## Orchestrator for the CPR index (Continuous Plankton Recorder, Western Scotian
## Shelf). Open gom-plankton-data-products.Rproj before running so that
## getwd() resolves to the repo root.
##
## Needs the raw tows (not public): CPR_TOWS_FILE in settings.R.
##
##   Step 1  R/05_cpr/cpr_01_load.R          raw tows -> data/cpr/tows/cpr_wss_tows.csv (gitignored)
##   Step 2  R/05_cpr/cpr_03_annual_index.R  tows -> annual index and daily values
##                                           (data/cpr/), fit table (summaries/cpr/),
##                                           figures and diagnostics (plots/cpr/)

source("R/05_cpr/cpr_01_load.R")
source("R/05_cpr/cpr_03_annual_index.R")

cat("\nCPR index pipeline complete.\n")
