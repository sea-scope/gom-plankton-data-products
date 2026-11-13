## plot_presentation_poster_wbts.R
## Presentation (16:9) and poster versions of the WBTS sentinel figures:
##   - CI, CSI and DW phenology (seasonal cycle), one figure each
##   - CI and DW seasonal anomaly bars, all 4 seasons in one 2x2 figure each
##     (the pipeline computes no CSI anomaly, so there is no CSI anomaly figure)
##     A season whose model fails the anomaly gate (model_pass = FALSE in
##     anomalies_long.csv) shows "Not Available" and the reason instead of bars.
##
## Run after run_sentinel.R Step 4 (run_sentinel.R sources this as Step 6).
## Nothing is refit here: the script only reads files the pipeline wrote, so
## every number matches the pipeline figures.
##   sentinel/data/prepared/WBTS_prepared.csv           observations (phenology points)
##   sentinel/data/prepared/WBTS_prepared_enriched.csv  per-tow anomalies (bar chart points)
##   sentinel/summaries/predictions_long.csv            phenology GAMs (curve + ribbon)
##   sentinel/summaries/anomalies_long.csv              seasonal anomalies (bars + error bars)
##
## Output, the same five files in each folder:
##   sentinel/plots/WBTS/presentation/   13.33 x 7.5 in (full 16:9 slide)
##   sentinel/plots/WBTS/poster/         10.7 x 5.7 in (poster slot, labels included)
##     WBTS_CI_phenology.png  WBTS_CSI_phenology.png  WBTS_DW_phenology.png
##     WBTS_CI_anomaly_seasons.png  WBTS_DW_anomaly_seasons.png
##   sentinel/plots/WBTS/slide_tiles/    pieces that sit under a slide title (section 6c),
##                                       smaller text (formats$slide_tiles)
##     WBTS_CI_phenology_anomaly_slide.png            13 x 6.5   CI phenology + summer/fall/winter anomalies
##     WBTS_{CI,CSI,DW}_phenology_square.png          6.5 x 6.5
##     WBTS_CI_anomaly_{summer,fall,winter}_wide.png  6.5 x 3.25 (w x h)
## The font sizes in section 1 are the printed sizes at those dimensions.
##
## Open gom-plankton-data-products.Rproj first so paths resolve.

library(ggplot2)
library(dplyr)
library(patchwork)

# Pipeline label text, units, palette, and year-period aesthetics
source(file.path("sentinel", "R", "theme_sentinel.R"))
source(file.path("sentinel", "R", "station_config.R"))


# ============================================================
# 1. SETTINGS
# ============================================================

station_id <- "WBTS"
cfg        <- station_config[[station_id]]
ref_years  <- seq(cfg$reference_period[1], cfg$reference_period[2])   # 2004-2010
ref_text   <- paste0(min(ref_years), "–", max(ref_years))              # "2004–2010"

# One entry per output version. width/height in inches, text sizes in pt.
# point_scale multiplies the pipeline's year-period point sizes.
formats <- list(
  presentation = list(width = 13.33, height = 7.5,
                      axis_text = 16, axis_title = 17, title = 20, panel_title = 17,
                      legend = 15, annotation = 14, caption = 13,
                      point_scale = 1.6, tow_size = 2.2, line_width = 1.0),
  poster       = list(width = 10.7, height = 5.7,
                      axis_text = 13, axis_title = 14, title = 16, panel_title = 14,
                      legend = 12, annotation = 11, caption = 11,
                      point_scale = 1.3, tow_size = 1.6, line_width = 0.8),
  # Slide tiles: built in the same pass as the others but saved only in 6c,
  # at the sizes in tile_dims below (width/height here are not used)
  slide_tiles  = list(width = NA, height = NA,
                      axis_text = 13, axis_title = 14, title = 15, panel_title = 14,
                      legend = 11, annotation = 12, caption = 11,
                      point_scale = 1.3, tow_size = 1.8, line_width = 0.9)
)

pheno_vars <- c("CI", "CSI", "DW")
anom_vars  <- c("CI", "DW")
seasons    <- names(cfg$season_boundaries)   # spring, summer, fall, winter (2x2 reading order)

# Figure titles. "Calanus" is italic, so the titles are plotmath expressions.
title_pheno <- list(
  CI  = bquote(bold(.(station_id)) ~ bolditalic("Calanus") ~ bold("Abundance Seasonal Cycle")),
  CSI = bquote(bold(.(station_id)) ~ bolditalic("Calanus") ~ bold("Stage Index Seasonal Cycle")),
  DW  = bquote(bold(.(station_id) ~ "Zooplankton Biomass Seasonal Cycle"))
)
title_anom <- list(
  CI = bquote(bold(.(station_id)) ~ bolditalic("Calanus") ~
                bold("Abundance Anomaly (reference" ~ .(ref_text) * ")")),
  DW = bquote(bold(.(station_id) ~ "Zooplankton Biomass Anomaly (reference" ~ .(ref_text) * ")"))
)

caption_anom <- paste0(
  "Bars: GAM anomaly with 95% credible interval, colored where the interval excludes zero.\n",
  "Points: individual tows. Triangles: tows beyond the axis range, drawn at the edge."
)

# Slide tiles (section 6c): width x height in inches, text sizes in
# formats$slide_tiles. A square + two wide tiles stacked fill the same 13 x 6.5.
tile_dims    <- list(slide  = c(13, 6.5),
                     square = c(6.5, 6.5),
                     wide   = c(6.5, 3.25))
tile_seasons <- c("summer", "fall", "winter")   # CI anomaly seasons shown in the tiles

# Phenology legend inside the panel, top right, just below the season names
# (x, y as fractions of the panel)
tile_legend_xy <- c(0.99, 0.92)

# Anomaly panel y-limits follow the pipeline bar charts (plot_anomaly_bars.R):
# bar + error bar range, padded by pad_frac x that range but no further than
# the farthest tow. Tows still outside are drawn as triangles at the edge.
pad_frac <- 1.0

# Significance colors, as in the pipeline bar charts
sig_colors <- c("pos" = "cornflowerblue", "neg" = "firebrick", "ns" = "gray60")
sig_labels <- c("pos" = "Significant (+)", "neg" = "Significant (-)", "ns" = "Not significant")

# Season boundaries on the phenology x-axis (DOY 73.5, 147.5, 247.5) and the
# season name centered in each window along the top of the panel
season_lines  <- c(cfg$season_boundaries$winter[2],
                   cfg$season_boundaries$spring[2],
                   cfg$season_boundaries$summer[2]) + 0.5
season_labels <- data.frame(
  label = c("Winter", "Spring", "Summer", "Fall"),
  x     = (c(1, season_lines) + c(season_lines, 365)) / 2
)


# ============================================================
# 2. READ PIPELINE OUTPUTS
# ============================================================

prep <- read.csv(file.path("sentinel", "data", "prepared",
                           paste0(station_id, "_prepared.csv")),
                 stringsAsFactors = FALSE)

enriched <- read.csv(file.path("sentinel", "data", "prepared",
                               paste0(station_id, "_prepared_enriched.csv")),
                     stringsAsFactors = FALSE)

pred_long <- read.csv(file.path("sentinel", "summaries", "predictions_long.csv"),
                      stringsAsFactors = FALSE) %>%
  filter(station == station_id, season == "phenology")

anom_long <- read.csv(file.path("sentinel", "summaries", "anomalies_long.csv"),
                      stringsAsFactors = FALSE) %>%
  filter(station == station_id)


# ============================================================
# 3. YEAR PERIODS
# Built exactly as the pipeline does: reference years, middle years, then the
# most recent 3 years each on their own. The year range comes from the CI,
# CSI and DW data together.
# ============================================================

has_data  <- (!is.na(prep$CI) & prep$CI > 0) | !is.na(prep$CSI) |
             (!is.na(prep$DW) & prep$DW > 0)
all_years <- sort(unique(prep$year[has_data]))
aes_cfg   <- build_year_period_aesthetics(all_years, ref_years)

legend_labels <- gsub(" - ", "–", aes_cfg$levels)   # "2004 - 2010" -> "2004–2010"


# ============================================================
# 4. PHENOLOGY DATA
# Observations use the same filters as the GAMs (fit_sentinel_gams.R):
# CI and DW present and > 0, then sqrt-transformed because the models are fit
# on sqrt; CSI present, untransformed. The y-axis labels for CI and DW are
# back-transformed (pipeline breaks in theme_sentinel.R).
# Curves: predictions_long holds each phenology GAM predicted for the middle
# year of the record, the same curve the pipeline plots. fit and se_fit are on
# the model scale; ribbon = fit +/- 1.96 SE.
# ============================================================

obs <- list(
  CI  = prep %>% filter(!is.na(CI), CI > 0) %>% mutate(y = sqrt(CI)),
  CSI = prep %>% filter(!is.na(CSI))        %>% mutate(y = CSI),
  DW  = prep %>% filter(!is.na(DW), DW > 0) %>% mutate(y = sqrt(DW))
)

pheno <- list()
for (v in pheno_vars) {
  # Older periods drawn first so the recent years sit on top
  obs[[v]] <- aes_cfg$assign_fn(obs[[v]]) %>% arrange(year_period)

  pheno[[v]] <- pred_long %>%
    filter(variable == v) %>%
    mutate(fit_low  = fit - 1.96 * se_fit,
           fit_high = fit + 1.96 * se_fit)
}

cat("Phenology curve year:", unique(pred_long$year), "\n")


# ============================================================
# 5. ANOMALY DATA
# anomalies_long and the enriched reference_difference_* columns are in data
# units (CI individuals m-2, DW g m-2); divide by the pipeline divisor so the
# values match the axis label (CI in 1,000 m-2).
# Each tow's x position is jittered within its year once, here, with a fixed
# seed, so both output versions show the same layout and reruns match.
# ============================================================

anom   <- list()
tows   <- list()
y_lims <- list()

for (v in anom_vars) {
  divisor  <- sentinel_anomaly_labels[[v]]$divisor
  diff_col <- paste0("reference_difference_", v)

  # Bars: GAM anomaly per year and season, significance from the 95% interval
  anom[[v]] <- anom_long %>%
    filter(variable == v) %>%
    mutate(anomaly      = anomaly / divisor,
           anomaly_low  = anomaly_low / divisor,
           anomaly_high = anomaly_high / divisor,
           sig = case_when(anomaly_low  > 0 ~ "pos",
                           anomaly_high < 0 ~ "neg",
                           TRUE             ~ "ns"))

  # Points: each tow's difference from the reference-period prediction
  set.seed(42)
  tows_v <- enriched %>%
    filter(!is.na(.data[[diff_col]])) %>%
    transmute(year, season, value = .data[[diff_col]] / divisor) %>%
    mutate(x = year + runif(n(), -0.2, 0.2))

  # Per-season y-limits (pipeline rule, see pad_frac in section 1)
  bar_rng <- anom[[v]] %>%
    group_by(season) %>%
    summarise(bar_lo = min(anomaly, anomaly_low),
              bar_hi = max(anomaly, anomaly_high), .groups = "drop")
  tow_rng <- tows_v %>%
    group_by(season) %>%
    summarise(tow_lo = min(value), tow_hi = max(value), .groups = "drop")

  y_lims[[v]] <- bar_rng %>%
    left_join(tow_rng, by = "season") %>%
    mutate(bar_range = bar_hi - bar_lo,
           pad_lo    = pmin(pad_frac * bar_range, pmax(0, bar_lo - tow_lo, na.rm = TRUE)),
           pad_hi    = pmin(pad_frac * bar_range, pmax(0, tow_hi - bar_hi, na.rm = TRUE)),
           y_lo      = pmin(0, bar_lo) - pad_lo,
           y_hi      = pmax(0, bar_hi) + pad_hi)

  # Tows outside the limits are moved to the edge and flagged
  tows[[v]] <- tows_v %>%
    left_join(dplyr::select(y_lims[[v]], season, y_lo, y_hi), by = "season") %>%
    mutate(edge = case_when(value > y_hi ~ "above",
                            value < y_lo ~ "below",
                            TRUE         ~ "inside"),
           y    = pmin(pmax(value, y_lo), y_hi))

  cat("\n", v, "tows drawn at the axis edge, by season:\n")
  print(table(tows[[v]]$season, tows[[v]]$edge))
}

max_year <- max(anom_long$year)


# ============================================================
# 6. BUILD AND SAVE, ONE PASS PER OUTPUT VERSION
# ============================================================

for (fmt_name in names(formats)) {
  f <- formats[[fmt_name]]

  out_dir <- file.path("sentinel", "plots", station_id, fmt_name)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  cat("\n=====", fmt_name, "=====\n")

  theme_print <- theme_bw() +
    theme(
      axis.text        = element_text(size = f$axis_text, color = "black"),
      axis.title       = element_text(size = f$axis_title),
      plot.title       = element_text(size = f$title, face = "bold"),
      plot.caption     = element_text(size = f$caption, color = "grey30", hjust = 0),
      panel.grid.minor = element_blank(),
      legend.title     = element_blank(),
      legend.text      = element_text(size = f$legend),
      plot.margin      = margin(6, 10, 6, 6)
    )

  # Finished plots kept for the slide tiles in 6c
  pheno_plots <- list()
  anom_panels <- list()


  # ----------------------------------------------------------
  # 6a. PHENOLOGY: one figure per variable
  # Legend outside on the right so it never covers data or season names.
  # ----------------------------------------------------------

  for (v in pheno_vars) {
    vl <- sentinel_var_labels[[v]]

    # Legend lists only the periods with tows for this variable (e.g. the 2026
    # tows have CI and CSI but no DW yet). Colors stay tied to the period.
    keep          <- aes_cfg$levels %in% unique(obs[[v]]$year_period)
    legend_levels <- aes_cfg$levels[keep]
    legend_text   <- legend_labels[keep]

    p <- ggplot() +
      # Season boundaries, faint, with the season names along the top
      geom_vline(xintercept = season_lines, linetype = "dashed",
                 color = "black", linewidth = 0.4, alpha = 0.3) +
      geom_text(data = season_labels, aes(x = x, y = Inf, label = label),
                vjust = 1.5, size = f$annotation / .pt, color = "grey30") +
      # GAM climatology and 95% CI
      geom_ribbon(data = pheno[[v]],
                  aes(x = day_of_year, ymin = fit_low, ymax = fit_high),
                  fill = "grey", alpha = 0.4) +
      geom_line(data = pheno[[v]], aes(x = day_of_year, y = fit),
                color = "black", linewidth = f$line_width) +
      # Every tow, colored by period
      geom_point(data = obs[[v]],
                 aes(x = day_of_year, y = y, color = year_period,
                     shape = year_period, size = year_period, alpha = year_period)) +
      scale_color_manual(values = aes_cfg$colors, limits = legend_levels,
                         labels = legend_text, name = NULL) +
      scale_shape_manual(values = aes_cfg$shapes, limits = legend_levels,
                         labels = legend_text, name = NULL) +
      scale_size_manual(values = aes_cfg$sizes * f$point_scale, limits = legend_levels,
                        labels = legend_text, name = NULL) +
      scale_alpha_manual(values = aes_cfg$alphas, limits = legend_levels,
                         labels = legend_text, name = NULL) +
      scale_x_continuous(breaks = sentinel_month_breaks, labels = sentinel_month_labels,
                         limits = c(1, 365), expand = expansion(add = 2)) +
      labs(x = NULL, y = vl$y_lab, title = title_pheno[[v]]) +
      theme_print +
      theme(legend.position = "right",
            legend.key.size = unit(1.3, "lines"))

    # y-axis: 10% headroom at the top for the season names; CI and DW get the
    # back-transformed labels
    if (!is.null(vl$sqrt_breaks)) {
      p <- p + scale_y_continuous(breaks = vl$sqrt_breaks, labels = vl$sqrt_labels,
                                  expand = expansion(mult = c(0.03, 0.10)))
    } else {
      p <- p + scale_y_continuous(expand = expansion(mult = c(0.03, 0.10)))
    }
    pheno_plots[[v]] <- p
    if (fmt_name == "slide_tiles") next   # tiles are saved in 6c

    fname <- file.path(out_dir, paste0(station_id, "_", v, "_phenology.png"))
    ggsave(fname, p, width = f$width, height = f$height, dpi = 300, bg = "white")
    cat("Saved:", fname, "\n")
  }


  # ----------------------------------------------------------
  # 6b. SEASONAL ANOMALY BARS: 2x2, one figure per variable
  # Each season keeps its own y-range (as in the pipeline); the y-axis title
  # sits on the left column only. One significance legend for all four panels.
  # ----------------------------------------------------------

  for (v in anom_vars) {
    al     <- sentinel_anomaly_labels[[v]]
    panels <- list()

    for (ssn in seasons) {
      a_s <- anom[[v]]   %>% filter(season == ssn)
      t_s <- tows[[v]]   %>% filter(season == ssn)
      l_s <- y_lims[[v]] %>% filter(season == ssn)

      # Gate: the seasonal model failed (anomaly_gate in compute_anomalies.R),
      # so the panel says why instead of showing bars
      if (!isTRUE(a_s$model_pass[1])) {
        panels[[ssn]] <- ggplot() +
          annotate("text", x = 0.5, y = 0.5,
                   label = paste0("Not Available\n",
                                  sentinel_gate_labels[[a_s$gate_reason[1]]]),
                   size = f$panel_title / .pt, fontface = "bold", color = "grey30") +
          labs(title = tools::toTitleCase(ssn)) +
          theme_void() +
          theme(plot.title  = element_text(size = f$panel_title, face = "bold"),
                plot.margin = margin(6, 10, 6, 6))
        next
      }

      y_title <- if (ssn %in% seasons[c(1, 3)]) al$y_lab else NULL

      panels[[ssn]] <- ggplot() +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey40",
                   linewidth = 0.5) +
        # Bars colored by significance. show.legend = TRUE draws every key in
        # every panel, so patchwork can merge the four legends into one.
        geom_col(data = a_s, aes(x = year, y = anomaly, fill = sig),
                 width = 0.7, color = NA, show.legend = TRUE) +
        geom_errorbar(data = a_s, aes(x = year, ymin = anomaly_low, ymax = anomaly_high),
                      width = 0.3, linewidth = 0.5, color = "grey30") +
        # Individual tows; triangles for tows clamped to the top or bottom edge
        geom_point(data = filter(t_s, edge == "inside"), aes(x = x, y = y),
                   size = f$tow_size, alpha = 0.6, color = "grey20", shape = 16) +
        geom_point(data = filter(t_s, edge == "above"), aes(x = x, y = y),
                   size = f$tow_size * 1.3, color = "grey20", shape = 17) +
        geom_point(data = filter(t_s, edge == "below"), aes(x = x, y = y),
                   size = f$tow_size * 1.3, color = "grey20", fill = "grey20", shape = 25) +
        scale_fill_manual(values = sig_colors, labels = sig_labels,
                          limits = c("ns", "pos", "neg"), name = NULL) +
        # Year labels counted back from the latest year so it is always labelled
        scale_x_continuous(breaks = seq(max_year, cfg$year_start, by = -4)) +
        coord_cartesian(xlim = c(cfg$year_start - 0.5, max_year + 0.5),
                        ylim = c(l_s$y_lo, l_s$y_hi)) +
        labs(x = NULL, y = y_title, title = tools::toTitleCase(ssn)) +
        theme_print +
        theme(plot.title = element_text(size = f$panel_title, face = "bold"))
    }
    anom_panels[[v]] <- panels
    if (fmt_name == "slide_tiles") next   # tiles are saved in 6c

    p_all <- wrap_plots(panels, ncol = 2) +
      plot_layout(guides = "collect") +
      plot_annotation(
        title   = title_anom[[v]],
        caption = caption_anom,
        theme   = theme(plot.title   = element_text(size = f$title, face = "bold"),
                        plot.caption = element_text(size = f$caption, color = "grey30",
                                                    hjust = 0))
      ) &
      theme(legend.position = "bottom")

    fname <- file.path(out_dir, paste0(station_id, "_", v, "_anomaly_seasons.png"))
    ggsave(fname, p_all, width = f$width, height = f$height, dpi = 300, bg = "white")
    cat("Saved:", fname, "\n")
  }


  # ----------------------------------------------------------
  # 6c. SLIDE TILES (slide_tiles pass only)
  # Built from the 6a/6b plots of this pass (text sizes in
  # formats$slide_tiles); only titles, legends and axis labels change here.
  # Figure sizes in tile_dims (section 1). No anomaly legend or caption:
  # the tiles are explained on the slide.
  # ----------------------------------------------------------

  if (fmt_name == "slide_tiles") {
    al_ci <- sentinel_anomaly_labels$CI

    # Phenology legend inside the panel, top right (tile_legend_xy), on a
    # light background so points underneath stay visible
    legend_inside <- theme(
      legend.position             = "inside",
      legend.position.inside      = tile_legend_xy,
      legend.justification.inside = c(1, 1),
      legend.background           = element_rect(fill = alpha("white", 0.8), color = NA),
      legend.key.size             = unit(0.9, "lines"),
      legend.text                 = element_text(size = f$legend)
    )

    # Which tile seasons passed the anomaly gate. Gated seasons keep their
    # "Not Available" panel and get no axis or legend changes.
    ci_pass   <- anom$CI %>%
      filter(season %in% tile_seasons) %>%
      group_by(season) %>%
      summarise(pass = isTRUE(model_pass[1]), .groups = "drop")
    tile_pass <- setNames(ci_pass$pass, ci_pass$season)[tile_seasons]
    last_pass <- tail(tile_seasons[tile_pass], 1)   # bottom-most panel that has bars


    # --- Phenology, 6.5 x 6.5: CI, CSI, DW ---
    # Legend inside the panel keeps it square; title starts at the left edge
    # of the figure.
    pheno_tiles <- list()
    for (v in pheno_vars) {
      pheno_tiles[[v]] <- pheno_plots[[v]] +
        legend_inside +
        theme(plot.title.position = "plot")

      fname <- file.path(out_dir, paste0(station_id, "_", v, "_phenology_square.png"))
      ggsave(fname, pheno_tiles[[v]],
             width = tile_dims$square[1], height = tile_dims$square[2],
             dpi = 300, bg = "white")
      cat("Saved:", fname, "\n")
    }


    # --- CI anomaly, one season per tile, 6.5 wide x 3.25 tall ---
    for (ssn in tile_seasons) {
      p <- anom_panels$CI[[ssn]] +
        labs(title = paste(tools::toTitleCase(ssn), "Anomaly"))

      if (tile_pass[[ssn]]) {
        p <- p +
          labs(y = al_ci$y_lab) +
          theme(legend.position     = "none",
                plot.title.position = "plot")
      }

      fname <- file.path(out_dir, paste0(station_id, "_CI_anomaly_", ssn, "_wide.png"))
      ggsave(fname, p, width = tile_dims$wide[1], height = tile_dims$wide[2],
             dpi = 300, bg = "white")
      cat("Saved:", fname, "\n")
    }


    # --- CI phenology (left) + summer/fall/winter anomalies stacked (right), 13 x 6.5 ---
    # No overall title: the slide title goes in the space above.
    # The stack shares one x-axis (year labels on the bottom panel only) and
    # one y-axis title (middle panel).
    stack <- list()
    for (ssn in tile_seasons) {
      p <- anom_panels$CI[[ssn]] +
        labs(title = paste(tools::toTitleCase(ssn), "Anomaly"))

      if (tile_pass[[ssn]]) {
        p <- p +
          labs(y = if (ssn == "fall") al_ci$y_lab else NULL) +
          theme(legend.position = "none")
        if (ssn != last_pass) {
          p <- p + theme(axis.text.x = element_blank())
        }
      }
      stack[[ssn]] <- p
    }

    # Layout: A = phenology spanning all three rows, B/C/D = the stacked seasons.
    # Plots fill the areas in letter order. Each column gets half the width.
    p_slide <- wrap_plots(list(pheno_tiles$CI, stack$summer, stack$fall, stack$winter),
                          design = "AB\nAC\nAD")

    fname <- file.path(out_dir, paste0(station_id, "_CI_phenology_anomaly_slide.png"))
    ggsave(fname, p_slide, width = tile_dims$slide[1], height = tile_dims$slide[2],
           dpi = 300, bg = "white")
    cat("Saved:", fname, "\n")
  }
}
