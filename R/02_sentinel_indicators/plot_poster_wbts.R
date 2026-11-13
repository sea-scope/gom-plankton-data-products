## plot_poster_wbts.R
## Poster version of the WBTS Calanus figures: CI phenology (left) and the
## winter CI anomaly bar chart (right), side by side in one PNG at the
## printed size.
##
## Run after run_sentinel.R (Step 4). Nothing is refit here: the script only
## reads files the pipeline wrote, so every number matches the pipeline figures.
##   data/sentinel/prepared/WBTS_prepared.csv           observations (phenology points)
##   data/sentinel/prepared/WBTS_prepared_enriched.csv  per-tow anomalies (bar chart points)
##   summaries/sentinel/predictions_long.csv            phenology GAM (curve + ribbon)
##   summaries/sentinel/anomalies_long.csv              winter anomaly (bars + error bars)
##
## Left panel  = WBTS_CI_phenology.png, restyled for print.
## Right panel = WBTS_CI_anomaly_bar_winter.png, restyled for print.
##
## Output: plots/sentinel/WBTS/poster/WBTS_CI_poster.png
## Saved at 10.7 x 5.7 in (the poster slot, labels included), so the font
## sizes below are the printed sizes.
##
## Open gom-plankton-data-products.Rproj first so paths resolve.

library(ggplot2)
library(dplyr)
library(patchwork)

# Pipeline label text, palette, and year-period aesthetics
source(file.path("R", "shared", "theme_sentinel.R"))
source(file.path("R", "02_sentinel_indicators", "station_config.R"))


# ============================================================
# 1. SETTINGS
# ============================================================

station_id <- "WBTS"
cfg        <- station_config[[station_id]]
ref_years  <- seq(cfg$reference_period[1], cfg$reference_period[2])   # 2004-2010

# Printed size of the poster slot (inches)
fig_width  <- 10.7
fig_height <- 5.7

# Panel titles. "Calanus" is italic, so the left title is a plotmath expression.
title_left     <- expression(bold("WBTS") ~ bolditalic("Calanus") ~ bold("Abundance Seasonal Cycle"))
title_right    <- paste0("Winter Anomaly (reference ", min(ref_years), "–", max(ref_years), ")")
subtitle_right <- NULL

# Printed font sizes (pt)
size_axis_text  <- 13
size_axis_title <- 14
size_title      <- 16
size_subtitle   <- 13
size_legend     <- 12
size_annotation <- 11

# Point sizes are the pipeline's, scaled up for print
point_scale <- 1.3

# Extra room above the highest bar/point in the anomaly panel so the
# legend sits clear of the data (fraction of the y range)
legend_headroom <- 0.14

out_dir <- file.path("plots", "sentinel", station_id, "poster")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


# ============================================================
# 2. OBSERVATIONS (phenology points)
# Same filter the GAMs use (CI present and > 0). The phenology model is fit
# on sqrt(CI), so points go on the sqrt scale and the y-axis labels are
# back-transformed (pipeline breaks: 100..500 -> 10..250 thousand m-2).
# ============================================================

prep <- read.csv(file.path("data", "sentinel", "prepared",
                           paste0(station_id, "_prepared.csv")),
                 stringsAsFactors = FALSE)

# Year periods exactly as the pipeline builds them: reference years,
# middle years, then the most recent 3 years each on their own.
# The pipeline takes the year range from the CI, CSI and DW data together.
has_data <- (!is.na(prep$CI) & prep$CI > 0) | !is.na(prep$CSI) |
            (!is.na(prep$DW) & prep$DW > 0)
all_years <- sort(unique(prep$year[has_data]))
aes_cfg   <- build_year_period_aesthetics(all_years, ref_years)

obs <- prep %>%
  filter(!is.na(CI), CI > 0) %>%
  mutate(CI_sqrt = sqrt(CI))
obs <- aes_cfg$assign_fn(obs)

# Draw older periods first so the recent years sit on top
obs <- obs %>% arrange(year_period)


# ============================================================
# 3. PHENOLOGY CURVE
# predictions_long holds the phenology GAM predicted for the middle year
# of the record (2015 for 2004-2026), the same curve the pipeline plots.
# fit and se_fit are on the sqrt scale; ribbon = fit +/- 1.96 SE.
# ============================================================

pheno <- read.csv(file.path("summaries", "sentinel", "predictions_long.csv"),
                  stringsAsFactors = FALSE) %>%
  filter(station == station_id, variable == "CI", season == "phenology") %>%
  mutate(fit_low  = fit - 1.96 * se_fit,
         fit_high = fit + 1.96 * se_fit)

cat("Phenology curve year:", unique(pheno$year), "\n")


# ============================================================
# 4. WINTER ANOMALY (bars) AND PER-TOW ANOMALIES (points)
# Both files are in individuals m-2; divide by 1000 to match the
# "1,000 m-2" axis label.
# Bar colour follows the pipeline: significant when the 95% interval
# excludes zero.
# ============================================================

anom <- read.csv(file.path("summaries", "sentinel", "anomalies_long.csv"),
                 stringsAsFactors = FALSE) %>%
  filter(station == station_id, variable == "CI", season == "winter") %>%
  mutate(anomaly      = anomaly / 1000,
         anomaly_low  = anomaly_low / 1000,
         anomaly_high = anomaly_high / 1000,
         sig = case_when(anomaly_low  > 0 ~ "pos",
                         anomaly_high < 0 ~ "neg",
                         TRUE             ~ "ns"))

# Each winter tow's difference from the reference-period prediction
# (reference_difference_CI, written by the pipeline's enrich step)
tows <- read.csv(file.path("data", "sentinel", "prepared",
                           paste0(station_id, "_prepared_enriched.csv")),
                 stringsAsFactors = FALSE) %>%
  filter(season == "winter", !is.na(reference_difference_CI)) %>%
  mutate(value = reference_difference_CI / 1000)

cat("Winter tows per year:\n")
print(table(tows$year))

year_start <- cfg$year_start
max_year   <- max(anom$year)

# y limits: cover every bar, error bar and tow (the pipeline clamps
# far-out tows to the axis edge; here none are hidden), plus headroom
# at the top for the legend
y_lo    <- min(0, anom$anomaly_low, tows$value)
y_hi    <- max(0, anom$anomaly_high, tows$value)
y_range <- y_hi - y_lo
y_lims  <- c(y_lo - 0.03 * y_range, y_hi + legend_headroom * y_range)


# ============================================================
# 5. SHARED THEME
# ============================================================

legend_box <- element_rect(fill = "white", color = "grey40", linewidth = 0.4)

theme_poster <- theme_bw() +
  theme(
    axis.text        = element_text(size = size_axis_text, color = "black"),
    axis.title       = element_text(size = size_axis_title),
    plot.title       = element_text(size = size_title, face = "bold"),
    plot.subtitle    = element_text(size = size_subtitle, color = "grey30"),
    panel.grid.minor = element_blank(),
    legend.title     = element_blank(),
    legend.text      = element_text(size = size_legend),
    legend.background = legend_box,
    legend.margin    = margin(3, 6, 3, 4),
    plot.margin      = margin(4, 8, 4, 4)
  )


# ============================================================
# 6. LEFT PANEL: CI PHENOLOGY
# Legend inside the top-right corner (Oct-Dec, above the fall data).
# ============================================================

legend_labels <- gsub(" - ", "–", aes_cfg$levels)   # "2004 - 2010" -> "2004–2010"
winter_end    <- cfg$season_boundaries$winter[2] + 0.5   # DOY 73.5

p_pheno <- ggplot() +
  # Winter window, shaded to tie this panel to the anomaly panel
  # annotate("rect", xmin = 1, xmax = winter_end, ymin = -Inf, ymax = Inf,
  #          fill = "grey85", alpha = 0.6) +
  annotate("text", x = (1 + winter_end) / 2, y = Inf, label = "Winter",
           vjust = 1.5, size = size_annotation / .pt) +
  # Season boundaries, faint (same positions as the pipeline figure,
  # including winter/spring at DOY 73.5)
  geom_vline(xintercept = sentinel_season_lines, linetype = "dashed",
             color = "black", linewidth = 0.4, alpha = 0.3) +
  # GAM climatology and 95% CI
  geom_ribbon(data = pheno, aes(x = day_of_year, ymin = fit_low, ymax = fit_high),
              fill = "grey", alpha = 0.4) +
  geom_line(data = pheno, aes(x = day_of_year, y = fit), color = "black",
            linewidth = 0.8) +
  # Every tow, coloured by period
  geom_point(data = obs,
             aes(x = day_of_year, y = CI_sqrt, color = year_period,
                 shape = year_period, size = year_period, alpha = year_period)) +
  scale_color_manual(values = aes_cfg$colors, limits = aes_cfg$levels,
                     labels = legend_labels, name = NULL) +
  scale_shape_manual(values = aes_cfg$shapes, limits = aes_cfg$levels,
                     labels = legend_labels, name = NULL) +
  scale_size_manual(values = aes_cfg$sizes * point_scale, limits = aes_cfg$levels,
                    labels = legend_labels, name = NULL) +
  scale_alpha_manual(values = aes_cfg$alphas, limits = aes_cfg$levels,
                     labels = legend_labels, name = NULL) +
  scale_x_continuous(breaks = sentinel_month_breaks, labels = sentinel_month_labels,
                     limits = c(1, 365), expand = expansion(add = 2)) +
  scale_y_continuous(breaks = sentinel_var_labels$CI$sqrt_breaks,
                     labels = sentinel_var_labels$CI$sqrt_labels) +
  labs(x = NULL, y = sentinel_var_labels$CI$y_lab, title = title_left) +
  theme_poster +
  theme(
    legend.position        = "inside",
    legend.position.inside = c(0.99, 0.99),
    legend.justification   = c(1, 1),
    legend.key.size        = unit(0.9, "lines")
  )


# ============================================================
# 7. RIGHT PANEL: WINTER CI ANOMALY BAR CHART
# Bars = GAM anomaly with 95% interval; points = individual winter tows.
# Legend inside along the top, horizontal, in the headroom above the data.
# ============================================================

p_anom <- ggplot() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40",
             linewidth = 0.5) +
  # Bars coloured by significance
  geom_col(data = anom, aes(x = year, y = anomaly, fill = sig),
           width = 0.7, color = NA) +
  scale_fill_manual(
    values = c("pos" = "cornflowerblue", "neg" = "firebrick", "ns" = "gray60"),
    labels = c("pos" = "Significant (+)", "neg" = "Significant (-)",
               "ns" = "Not significant"),
    breaks = c("ns", "pos", "neg"),
    name = NULL
  ) +
  # Error bars (95% interval)
  geom_errorbar(data = anom, aes(x = year, ymin = anomaly_low, ymax = anomaly_high),
                width = 0.3, linewidth = 0.5, color = "grey30") +
  # Individual tows, jittered within the year (fixed seed so reruns match)
  geom_point(data = tows, aes(x = year, y = value),
             position = position_jitter(width = 0.2, height = 0, seed = 42),
             size = 1.6, alpha = 0.6, color = "grey20", shape = 16) +
  # Year labels counted back from the latest year so it is always labelled
  scale_x_continuous(breaks = seq(max_year, year_start, by = -4)) +
  coord_cartesian(xlim = c(year_start - 0.6, max_year + 0.6),
                  ylim = y_lims, expand = FALSE) +
  labs(x = NULL, y = sentinel_anomaly_labels$CI$y_lab,
       title = title_right, subtitle = subtitle_right) +
  theme_poster +
  theme(
    legend.position        = "inside",
    legend.position.inside = c(0.99, 0.99),
    legend.justification   = c(1, 1),
    legend.direction       = "horizontal",
    legend.key.size        = unit(0.9, "lines")
  )


# ============================================================
# 8. COMBINE AND SAVE
# ============================================================

p_poster <- p_pheno + p_anom + plot_layout(widths = c(1, 1))

fname <- file.path(out_dir, paste0(station_id, "_CI_poster.png"))
ggsave(fname, p_poster, width = fig_width, height = fig_height,
       dpi = 300, bg = "white")
cat("Saved:", fname, "\n")
