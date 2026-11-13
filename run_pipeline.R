## run_pipeline.R
## Master orchestrator — runs all data product pipelines in sequence.
## Open gom-plankton-data-products.Rproj before running so that
## getwd() resolves to the repo root.

source("run_spm_biomass.R")
source("run_sentinel.R")
source("run_satellite.R")
source("run_cpr.R")

cat("\nAll pipelines complete.\n")
