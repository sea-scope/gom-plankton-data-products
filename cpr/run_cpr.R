## run_cpr.R
## Orchestrator for the CPR index (Continuous Plankton Recorder, Western Scotian
## Shelf). Open gom-plankton-data-products.Rproj before running so that
## getwd() resolves to the repo root.
##
## Needs the raw tows (not public): CPR_TOWS_FILE in settings.R.
##
##   Step 1  cpr/R/cpr_01_load.R          raw tows -> cpr/data/tows/cpr_wss_tows.csv (gitignored)
##   Step 2  cpr/R/cpr_03_annual_index.R  tows -> annual index and daily values
##                                           (cpr/data/), fit table (cpr/summaries/),
##                                           figures and diagnostics (cpr/plots/)

source("cpr/R/cpr_01_load.R")
source("cpr/R/cpr_03_annual_index.R")

cat("\nCPR index pipeline complete.\n")
