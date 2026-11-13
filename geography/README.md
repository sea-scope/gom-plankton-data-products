# Geography: shared region polygons

Polygon CSVs used by the products here and by the analysis repos. Each is lon/lat in WGS84. Most have no header (lon, lat columns).

| File | Region |
|---|---|
| `poly_GMB_150.csv`, `poly_GMB_200.csv` | Grand Manan Basin, 150 m and 200 m isobaths |
| `poly_BOF_latlon.csv` | Bay of Fundy |
| `poly_BoF_CritHab.csv` | Bay of Fundy right whale critical habitat |
| `poly_JB_250.csv`, `poly_JB_deep.csv` | Jordan Basin |
| `poly_WSS_broad.csv` | Western Scotian Shelf |
| `poly_GeorgesNEC.csv` | Georges Basin / Northeast Channel |
| `poly_EGOM_broad.csv` | eastern Gulf of Maine |
| `poly_Browns_line.csv`, `poly_Halifax_line.csv` | Browns Bank and Halifax lines |
| `SBNMS.csv`, `SBNMS_40m_latlon.csv` | Stellwagen Bank National Marine Sanctuary, and its 40 m contour |
| `EMstrata_v4_coords.csv` | EcoMon strata (exported from `EMstrata_v4.mat`) |

- **Origin:** the particle-tracking workflow (`sea-scope/gom-particle-tracking`, `data/`) holds the polygon files the particle-tracking runs used. Those are the canonical versions. A check that these copies match them is pending.
- **Region maps:** `R/DFO_region_map.R` draws `figures/DFO_region_map_CINAR.png` and `_SBNMS.png`. It runs as step 4g of `spm_biomass/run_spm_biomass.R`.
