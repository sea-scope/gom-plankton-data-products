# CPR index, Western Scotian Shelf

Continuous Plankton Recorder tows on the Western Scotian Shelf (1,179 tows, 1961–2024), compiled by NERACOOS/GMRI and prepared by Jerome Pinti. Two annual indices come from the same model:
- *C. finmarchicus* CV–CVI abundance;
- zooplankton energy (ZCEI).

**Model**
- `variable ~ year (factor) + s(day of year, cyclic) + day/night`.
- *C. fin*: Tweedie. Energy: Gaussian on log10(x + 1).
- Each year's level is read at mid-April at night.
- The year is a **biological year**: Aug 1 of the year before to Jul 31. Every tow therefore comes before the August–September window it is paired with in the right whale analysis.

**Published tables**
- `data/cpr_wss_annual_index.csv`: one row per biological year, with n tows and flags;
- `data/cpr_wss_daily.csv`: each year's level × the seasonal cycle;
- `summaries/cpr_03_index_fit.csv`: fit and diagnostics.

**Run:** from the repo root, `source("cpr/run_cpr.R")`.
- It needs the raw tows, `CPR_TOWS_FILE` in `settings.R`. These are not public.
- The tidied tows (`data/tows/`) are gitignored for the same reason.

**Limits**
- Tows from one cruise are not independent, so the standard errors are too narrow.
- A few years rest on 1–3 tows.

**Packages:** dplyr, tidyr, ggplot2, mgcv, DHARMa.
