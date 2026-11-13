## plot_station_map.R
## Northeast shelf context map: bathymetry, CMTS + WBTS time-series stations,
## and the Stellwagen Bank National Marine Sanctuary (SBNMS) boundary.
##
## Aesthetic copied from GOMRAN/GOMRAN_MAP/GOMRAN_fig1_region_map.R (variant v_a):
##   - hybrid bathymetry raster, colour capped at 500 m
##   - minor isobaths every 50 m, 100 + 200 m isobaths emphasized
##   - rnaturalearth land in light gray drawn on top
##   - shadowtext feature labels, scale bar, north arrow
## EPU polygons and the Hague Line from the GOMRAN figure are dropped.
##
## Station coordinates and SBNMS boundary from geography/R/DFO_region_map.R
## and geography/SBNMS.csv.
##
## Run from the SPM_calanus_biomass .Rproj root. Output -> figures/

library(marmap)
library(sf)
library(dplyr)
library(rnaturalearth)
library(ggplot2)
library(ggspatial)
library(shadowtext)

sf_use_s2(FALSE)

## ---- paths ------------------------------------------------------------------
work_dir <- getwd()
fig_dir  <- file.path(work_dir, "sentinel", "figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

bathy_cache <- file.path(work_dir, "sentinel", "cache", "gom_bathy.rda")   # loads 'gom' (-77 to -58, 39 to 48, 1 arc-min)
sbnms_csv   <- file.path(work_dir, "geography", "SBNMS.csv")

## ---- spatial domain ---------------------------------------------------------
## Tighter than the GOMRAN regional figure (-72.5 to -62, 39.5 to 46).
## Edit here to zoom in/out; the cached bathymetry covers -77 to -58 W, 39 to 48 N.
x_lim <- c(-71.5, -63.0)
y_lim <- c( 40.0,  45.5)

bbox_poly <- st_as_sfc(st_bbox(c(xmin = x_lim[1], xmax = x_lim[2],
                                 ymin = y_lim[1], ymax = y_lim[2]),
                               crs = 4326))

## ---- land polygon -----------------------------------------------------------
## 'large' (1:10m) coastline if rnaturalearthhires is installed; else 'medium'.
coast_scale <- if (requireNamespace("rnaturalearthhires", quietly = TRUE)) "large" else "medium"
message("Using coastline scale: ", coast_scale)

land <- rnaturalearth::ne_countries(scale = coast_scale, returnclass = "sf") |>
  st_make_valid() |>
  st_crop(st_bbox(bbox_poly))

## ---- bathymetry -------------------------------------------------------------
## Use the project's cached NOAA ETOPO pull rather than re-downloading.
## Crop to the plot extent + 0.5 deg so contours run cleanly off the panel edge.
load(bathy_cache)   # -> gom

bathy_df <- fortify.bathy(gom) |>
  rename(lon = x, lat = y, depth = z) |>
  filter(depth <= 0,
         lon >= x_lim[1] - 0.5, lon <= x_lim[2] + 0.5,
         lat >= y_lim[1] - 0.5, lat <= y_lim[2] + 0.5)

## Depth palette, breaks and isobaths: GOMRAN variant v_a
cap_m           <- -500
palette_colours <- c("#0B3D66","#3478AB","#6FA4CB","#A8C9E3","#DCEAF5","#F4F8FC")
palette_breaks  <- c(-500, -300, -200, -100, -50, 0)
bold_iso        <- c(-100, -200)
minor_step      <- 50

## ---- SBNMS boundary ---------------------------------------------------------
## SBNMS.csv: no header, lon/lat, single ring. Close the ring if the last
## vertex does not repeat the first, then build an sf polygon.
sbnms_xy <- read.csv(sbnms_csv, header = FALSE, col.names = c("lon", "lat"))
if (!all(sbnms_xy[1, ] == sbnms_xy[nrow(sbnms_xy), ])) {
  sbnms_xy <- rbind(sbnms_xy, sbnms_xy[1, ])
}
sbnms <- st_sf(name = "Stellwagen Bank NMS",
               geometry = st_sfc(st_polygon(list(as.matrix(sbnms_xy))), crs = 4326))

sbnms_color <- "#D55E00"   # vermillion — separates from the blue ramp and gold stations

## ---- time-series stations ---------------------------------------------------
## Coordinates as used in DFO_region_map.R
stations <- tibble::tribble(
  ~name,  ~lon,       ~lat,
  "CMTS", -69.50383,  43.7495,
  "WBTS", -69.8616,   42.8627
)

## ---- Boston -----------------------------------------------------------------
boston <- tibble::tibble(name = "Boston", lon = -71.0589, lat = 42.3601)

## ---- feature labels ---------------------------------------------------------
## GOMRAN set, minus the Hague Line, GULF OF MAINE and ATLANTIC OCEAN labels.
## Scotian Shelf moved west from -63.5 so it is not clipped by the new east edge.
features <- tibble::tribble(
  ~label,                   ~lon,    ~lat,
  "Wilkinson\nBasin",       -69.55,  42.45,
  "Jordan\nBasin",          -67.85,  43.70,
  "Georges\nBasin",         -66.85,  42.40,
  "Northeast\nChannel",     -65.85,  42.05,
  "Great South\nChannel",   -69.20,  40.85,
  "Georges Bank",           -67.50,  41.20,
  "Scotian Shelf",          -64.00,  43.30,
  "Bay of\nFundy",          -65.80,  44.95
)

## ---- build map --------------------------------------------------------------
p <- ggplot() +

  # Bathymetry raster
  geom_raster(data = bathy_df, aes(x = lon, y = lat, fill = depth)) +

  # Minor isobaths (every 50 m down to the 500 m cap)
  geom_contour(data = bathy_df, aes(x = lon, y = lat, z = depth),
               breaks = seq(cap_m, -minor_step, by = minor_step),
               color = "grey55", linewidth = 0.12) +

  # Emphasized isobaths (100, 200 m)
  geom_contour(data = bathy_df, aes(x = lon, y = lat, z = depth),
               breaks = bold_iso,
               color = "grey10", linewidth = 0.5) +

  scale_fill_gradientn(
    colours  = palette_colours,
    values   = scales::rescale(palette_breaks),
    limits   = c(cap_m, 0),
    oob      = scales::squish,
    breaks   = palette_breaks,
    labels   = c(paste0("> ", abs(palette_breaks[1])),
                 as.character(abs(palette_breaks[-1]))),
    name     = "Depth (m)",
    guide    = guide_colorbar(
      barheight = unit(4.5, "cm"),
      barwidth  = unit(0.35, "cm"),
      position  = "inside",
      theme     = theme(
        legend.position.inside      = c(0.985, 0.05),
        legend.justification.inside = c(1, 0)
      )
    )
  ) +

  # SBNMS boundary — light fill + solid outline. Mapped to colour so it gets
  # a legend entry.
  geom_sf(data = sbnms, aes(color = name),
          fill = scales::alpha(sbnms_color, 0.20), linewidth = 0.8) +
  scale_color_manual(values = c("Stellwagen Bank NMS" = sbnms_color),
                     name = NULL,
                     guide = guide_legend(
                       order    = 1,
                       position = "inside",
                       theme    = theme(
                         legend.position.inside      = c(0.015, 0.92),
                         legend.justification.inside = c(0, 1)
                       )
                     )) +

  # Land on top
  geom_sf(data = land, fill = "lightgray", color = "gray30", linewidth = 0.3) +

  # Feature labels (GOMRAN styling, larger)
  geom_shadowtext(data = features,
                  aes(x = lon, y = lat, label = label),
                  color = "black", bg.color = "white", bg.r = 0.15,
                  size = 4.2, fontface = "bold", lineheight = 0.85) +

  # Boston — small black dot, label above (west of the point runs off the panel)
  geom_point(data = boston, aes(x = lon, y = lat),
             shape = 21, fill = "black", color = "white", size = 2.6, stroke = 0.6) +
  geom_shadowtext(data = boston, aes(x = lon, y = lat + 0.09, label = name),
                  vjust = 0, color = "black", bg.color = "white", bg.r = 0.15,
                  size = 4.3) +

  # Panel title, inside top edge, left-justified 25% of the way across the panel
  annotate("text", x = x_lim[1] + 0.20 * diff(x_lim), y = y_lim[2] - 0.10,
           label = "Gulf of Maine", hjust = 0, vjust = 1,
           size = 7, fontface = "bold") +

  # Time-series stations — gold circles. Shape mapped so they get a legend entry.
  geom_point(data = stations, aes(x = lon, y = lat, shape = "Time-series stations"),
             fill = "gold", color = "black", size = 3.2, stroke = 0.7) +
  scale_shape_manual(values = c("Time-series stations" = 21),
                     name = NULL,
                     guide = guide_legend(
                       order        = 2,
                       override.aes = list(fill = "gold", size = 3.2),
                       position     = "inside",
                       theme        = theme(
                         legend.position.inside      = c(0.015, 0.92),
                         legend.justification.inside = c(0, 1)
                       )
                     )) +

  # Station name labels, placed east of each point
  geom_shadowtext(data = stations, aes(x = lon + 0.12, y = lat, label = name),
                  hjust = 0, color = "black", bg.color = "white", bg.r = 0.15,
                  size = 4.5, fontface = "bold") +

  coord_sf(xlim = x_lim, ylim = y_lim, expand = FALSE) +
  annotation_scale(location = "br", width_hint = 0.2, style = "ticks") +
  annotation_north_arrow(location = "tr", which_north = "true",
                         height = unit(0.7, "cm"),
                         width  = unit(0.7, "cm"),
                         style  = north_arrow_minimal()) +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = 14) +
  theme(panel.grid.major  = element_line(color = "grey92", linewidth = 0.3),
        panel.grid.minor  = element_blank(),
        panel.background  = element_rect(fill = "white"),
        # No border on each legend so the SBNMS + station legends, stacked
        # top-left, read as a single box
        legend.background = element_rect(fill = scales::alpha("white", 0.85),
                                         color = NA),
        legend.key        = element_rect(fill = NA, color = NA),
        legend.spacing.y  = unit(0, "pt"),
        legend.box.just   = "left",
        legend.text       = element_text(size = 12))

## ---- save --------------------------------------------------------------------
ggsave(file.path(fig_dir, "NES_bathy_CMTS_WBTS_SBNMS_map.pdf"),
       p, width = 8.3, height = 7)
ggsave(file.path(fig_dir, "NES_bathy_CMTS_WBTS_SBNMS_map.png"),
       p, width = 8.3, height = 7, dpi = 400)

cat("\nSaved to ", fig_dir, ":\n",
    "  NES_bathy_CMTS_WBTS_SBNMS_map.pdf\n",
    "  NES_bathy_CMTS_WBTS_SBNMS_map.png\n", sep = "")
