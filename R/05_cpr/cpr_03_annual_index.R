## cpr_03_annual_index.R  (CPR index, step 2 of 2: the annual index and daily values)
##
## Moved to the data products on 2026-11-13 from the right whale analysis (WP10
## v3), where it was step 3 (cpr_02 was exploration and stays in the archive).
## References below to "05", "06-10" and Layer A are WP10 steps.
##
## Builds the CPR inputs to WP10 from the Western Scotian Shelf (WSS) tows:
##   C. fin   C. finmarchicus CV-CVI (cfin_abund), Tweedie GAM
##   energy   ZCEI (energy), Gaussian GAM on log10(energy + 1)
## Two outputs from the same two models:
##   - the annual index (cpr_cfin_WSS, cpr_energy_WSS in 06-10), fixed before
##     any CPR value was fitted against SPUE (methods log, "CPR annual index --
##     FIXED", Session 34);
##   - daily values (section 4b): each year's level x the seasonal cycle, for
##     every day of the year. 05 multiplies them by WSS connectivity on each
##     source date to build CPR accumulation (cpr_accum_cfin_WSS,
##     cpr_accum_energy_WSS) -- the same recipe as DFO accumulation (v3, CT
##     2026-11-08).
## Both are ordinary v3 indicators, screened and compared with the others.
##
## THE YEAR IS A BIOLOGICAL YEAR: Aug 1 of the year before to Jul 31 of the
## SPUE year (CT, 2026-11-05). Index year 2010 = tows from Aug 2009 to Jul 2010,
## paired with the Aug-Sep 2010 SPUE. Why:
##   - the annual analysis uses the CPR as a year-level index of the WSS
##     population, so every month counts, not just spring. (The Session 33 plan
##     used Mar-May only: 323 tows, and 5 GoM3 years on 3 tows or fewer. The
##     biological year uses all 1,179 tows; 1 GoM3 year, 2008, has 3 or fewer.)
##   - every tow comes BEFORE the SPUE window it is paired with. A calendar
##     year would pair Aug-Dec tows with SPUE they come after.
##   - the year covers the full seasonal cycle, so the cyclic seasonal smooth
##     is valid. It runs from the autumn stock going into diapause to the
##     spring-summer generation it produces.
##
## Model, the same terms for both variables (REML):
##     cfin_abund        ~ bio_year_f + s(doy, bs = "cc", k = 30) + day_night    Tweedie, log link
##     log10(energy + 1) ~ bio_year_f + s(doy, bs = "cc", k = 30) + day_night    Gaussian
##   - bio_year_f = the biological year as a FACTOR: one free level per year,
##     no smoothing across years. (A year smooth would mostly carry the
##     long-term trend, which SPUE shares -- the WP9 lesson.)
##   - s(doy, cc): one average seasonal cycle shared by all years, cyclic so
##     Dec 31 joins Jan 1. Families and k as in the exploration (cpr_02b).
##   - day_night: one night / day shift (C. fin 1.63x at night in cpr_02b).
## The index is each year's level read at day 105 (mid-April, inside the WSS
## source window) at NIGHT. The year level shifts the whole seasonal curve up
## or down, so the day and the day / night state only set the reported level:
## every year moves by the same factor, and no ranking or z-score changes.
##
## Layer A uses the index on the LOG scale (CT, 2026-11-05): the natural log of
## the C. fin prediction (the Tweedie link scale) and log10 for energy (the
## model scale). The year values span about an order of magnitude; on the log
## scale the GAM's SE is symmetric and no single high year dominates a z-score.
##
## Known limits (from the exploration):
##   - Tows from the same cruise are not independent (no cruise random effect,
##     CT's choice), so the SEs are too narrow. They are reported, not used.
##   - C. fin over-dispersion is high (12.6 in cpr_02b, from a few enormous
##     tows), so a year resting on few tows is noisy. n tows, n months and
##     flags are written beside the index.
##   - A year sampled in only a few months leans on the average seasonal shape.
##
## Reads   data/cpr/tows/cpr_wss_tows.csv   (from cpr_01_load.R; gitignored)
## Writes  data/cpr/cpr_wss_annual_index.csv   one row per biological year
##         data/cpr/cpr_wss_daily.csv          one row per biological year x day (for WP10 step 05)
##         summaries/cpr/cpr_03_index_fit.csv  fit, night / day and diagnostics
##         plots/cpr/cpr_03_annual_index.png
##         plots/cpr/diagnostics/cpr_03_<variable>_{dharma, gamcheck}.png

library(dplyr)
library(tidyr)
library(ggplot2)
library(mgcv)
library(DHARMa)

if (!file.exists("gom-plankton-data-products.Rproj")) {
  stop("Working directory is ", getwd(), " -- open gom-plankton-data-products.Rproj ",
       "(or setwd to the repo root) and re-run.")
}

in_tows   <- "data/cpr/tows/cpr_wss_tows.csv"
out_prep  <- "data/cpr"
out_summ  <- "summaries/cpr"
out_plots <- "plots/cpr"
diag_dir  <- file.path(out_plots, "diagnostics")
for (d in c(out_prep, out_summ, diag_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

read_doy <- 105L     # mid-April: where each year's level is read (sets the level only)

theme_c <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#e1e0d9", linewidth = 0.3),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.subtitle = element_text(colour = "#52514e"),
        legend.position = "bottom",
        plot.background = element_rect(fill = "white", colour = NA))


## ===========================================================================
## 1. Read, and assign each tow to its biological year
## ===========================================================================
## Aug-Dec tows count toward the NEXT year's SPUE; Jan-Jul tows toward the same
## year's. The record (Jul 1961 - Dec 2024) therefore gives biological years
## 1961 (Jul 1961 only) to 2025 (Aug-Dec 2024 only); both ends are half-years.

tows <- read.csv(in_tows, stringsAsFactors = FALSE) %>%
  mutate(date       = as.Date(date),
         day_night  = factor(day_night, levels = c("day", "night")),
         bio_year   = as.integer(ifelse(month >= 8, year + 1L, year)),
         bio_year_f = factor(bio_year))

## Coverage per biological year: how many tows, day / night, how many of the
## 12 months, and the first and last tow.
coverage <- tows %>%
  group_by(bio_year) %>%
  summarise(n_tows    = n(),
            n_day     = sum(day_night == "day"),
            n_night   = sum(day_night == "night"),
            n_months  = n_distinct(month),
            first_tow = min(date),
            last_tow  = max(date), .groups = "drop")

cat("tows:", nrow(tows), "| biological years with tows:", nrow(coverage),
    "(", min(coverage$bio_year), "-", max(coverage$bio_year), ")\n")
cat("biological years with NO tows:",
    paste(setdiff(min(tows$bio_year):max(tows$bio_year), coverage$bio_year), collapse = ", "), "\n")
cat("\ncoverage, GoM3 years (1987-2016):\n")
print(as.data.frame(coverage %>% filter(bio_year >= 1987, bio_year <= 2016)))


## ===========================================================================
## 2. Fit the two GAMs
## ===========================================================================
## knots = c(0.5, 366.5) puts the cyclic join at the turn of the year, as in
## the exploration. Each model has one coefficient per biological year (about
## 60), so summary() prints a long table; only the parts that matter are
## printed below.

## C. fin: Tweedie, log link, raw ind / 100 m3 (zeros allowed).
fit_cfin <- gam(cfin_abund ~ bio_year_f + s(doy, bs = "cc", k = 30) + day_night,
                family = tw(), data = tows, method = "REML",
                knots = list(doy = c(0.5, 366.5)))

## Energy: Gaussian on log10(energy + 1).
tows$log_energy <- log10(tows$energy + 1)
fit_energy <- gam(log_energy ~ bio_year_f + s(doy, bs = "cc", k = 30) + day_night,
                  data = tows, method = "REML",
                  knots = list(doy = c(0.5, 366.5)))

fits <- list(cfin_abund = fit_cfin, energy = fit_energy)

for (v in names(fits)) {
  s <- summary(fits[[v]])
  cat("\n==================", v, "==================\n")
  cat("n =", nrow(fits[[v]]$model), "| biological-year levels:", nlevels(tows$bio_year_f),
      "| deviance explained:", round(100 * s$dev.expl, 1), "%\n")
  print(s$s.table)
  cat("\nk check (s(doy)):\n"); print(k.check(fits[[v]]))
}
tw_power <- fit_cfin$family$getTheta(TRUE)
cat("\nC. fin Tweedie power p =", round(tw_power, 3), "(cpr_02b: 1.744)\n")

## Night / day multiplier from the day_night coefficient b:
##   C. fin (log link)        exp(b) = multiplier on mean abundance
##   energy (log10 scale)     10^b   = multiplier on (energy + 1)
## Compared with the exploration fits (year smooth instead of year factor).
b_c <- summary(fit_cfin)$p.table["day_nightnight", ]
b_e <- summary(fit_energy)$p.table["day_nightnight", ]
night_day <- data.frame(
  variable       = c("cfin_abund", "energy"),
  night_over_day = c(exp(b_c[1]),                 10^b_e[1]),
  lo             = c(exp(b_c[1] - 1.96 * b_c[2]), 10^(b_e[1] - 1.96 * b_e[2])),
  hi             = c(exp(b_c[1] + 1.96 * b_c[2]), 10^(b_e[1] + 1.96 * b_e[2])),
  p              = c(b_c[4],                      b_e[4]),
  exploration    = c(1.63, 0.66),                 # cpr_02b / cpr_02
  row.names = NULL)
cat("\n---- Night / day multiplier ----\n"); print(night_day, digits = 3)


## ===========================================================================
## 3. Diagnostics
## ===========================================================================
## As in cpr_02b: DHARMa simulated residuals, 1,000 draws. Energy is simulated
## by DHARMa from the Gaussian fit. C. fin is simulated by hand with mgcv's
## rTweedie() (DHARMa does not support mgcv's Tweedie) and wrapped with
## createDHARMa(). With n = 1,179 the tests are high-powered -- judge from the
## plots. Over-dispersion is expected for C. fin (12.6 in cpr_02b): the year
## factor fits each year's level freely, but the few enormous tows remain.

mu_c  <- fitted(fit_cfin)
phi_c <- summary(fit_cfin)$scale
set.seed(20261105)
sims_c <- replicate(1000, rTweedie(mu_c, p = tw_power, phi = phi_c))
cat("\nC. fin zeros: observed", sum(tows$cfin_abund == 0),
    "| simulated, mean", round(mean(colSums(sims_c == 0)), 1), "\n")

res_list <- list(
  cfin_abund = createDHARMa(simulatedResponse       = sims_c,
                            observedResponse        = tows$cfin_abund,
                            fittedPredictedResponse = mu_c,
                            integerResponse         = FALSE),
  energy     = simulateResiduals(fittedModel = fit_energy, n = 1000)
)

diag_rows <- list()
for (v in names(fits)) {
  fit <- fits[[v]]
  res <- res_list[[v]]
  s   <- summary(fit)

  diag_rows[[v]] <- data.frame(
    variable         = v,
    family           = if (v == "cfin_abund") "Tweedie, log link" else "Gaussian on log10(x + 1)",
    n_tows           = nrow(fit$model),
    n_bio_years      = nlevels(tows$bio_year_f),
    dev_expl         = round(100 * s$dev.expl, 1),
    doy_edf          = round(s$s.table["s(doy)", "edf"], 2),
    tweedie_p        = if (v == "cfin_abund") round(tw_power, 3) else NA,
    uniformity_p     = signif(testUniformity(res, plot = FALSE)$p.value, 3),
    outliers_p       = signif(testOutliers(res,   plot = FALSE)$p.value, 3),
    dispersion_p     = signif(testDispersion(res, plot = FALSE)$p.value, 3),
    dispersion_ratio = signif(testDispersion(res, plot = FALSE)$statistic, 3),
    zeroinfl_p       = if (v == "cfin_abund") signif(testZeroInflation(res, plot = FALSE)$p.value, 3) else NA,
    obs_zeros        = sum(fit$y == 0),
    row.names = NULL)

  ## DHARMa: QQ of scaled residuals (left), residuals vs predicted (right).
  png(file.path(diag_dir, paste0("cpr_03_", v, "_dharma.png")), width = 1200, height = 600, res = 150)
  plot(res, main = paste("WSS CPR, biological-year model --", v))
  dev.off()

  ## gam.check's four panels on one page.
  png(file.path(diag_dir, paste0("cpr_03_", v, "_gamcheck.png")), width = 1200, height = 1000, res = 150)
  par(mfrow = c(2, 2))
  gam.check(fit)
  dev.off()
}

fit_tab <- bind_rows(diag_rows) %>%
  left_join(night_day, by = "variable")
cat("\n---- Fit and diagnostics (plots in", diag_dir, ") ----\n")
print(fit_tab)


## ===========================================================================
## 4. The index: each biological year's level at day 105, at night
## ===========================================================================
## One prediction per year level, with its SE, on the model scale:
##   C. fin   link scale = ln(mean ind / 100 m3)       -> cfin_gam_night_log
##   energy   log10(J / 100 m3 + 1)                     -> energy_gam_night_log10
## These two log-scale columns are what Layer A uses. The back-transformed
## levels (cfin_gam_night in ind / 100 m3, energy_gam_night in J / 100 m3) are
## for reading only.

grid <- data.frame(bio_year_f = factor(levels(tows$bio_year_f), levels = levels(tows$bio_year_f)),
                   doy        = read_doy,
                   day_night  = factor("night", levels = c("day", "night")))

pr_c <- predict(fit_cfin,   newdata = grid, se.fit = TRUE)
pr_e <- predict(fit_energy, newdata = grid, se.fit = TRUE)

pred <- data.frame(
  bio_year               = as.integer(as.character(grid$bio_year_f)),
  cfin_gam_night_log     = as.numeric(pr_c$fit),
  cfin_gam_night_se      = as.numeric(pr_c$se.fit),
  energy_gam_night_log10 = as.numeric(pr_e$fit),
  energy_gam_night_se    = as.numeric(pr_e$se.fit)) %>%
  mutate(cfin_gam_night   = exp(cfin_gam_night_log),
         energy_gam_night = 10^energy_gam_night_log10 - 1)


## ===========================================================================
## 4b. Daily values for CPR accumulation (05)
## ===========================================================================
## The same two models predicted for every day of the year (doy 1-366) in every
## biological year with tows, at night. Back-transformed, because accumulation
## is biomass x connectivity on the linear scale, as for DFO accumulation:
##   cfin_day    ind / 100 m3            exp(link-scale prediction)
##   energy_day  J / 100 m3              10^(log10 prediction) - 1
## The model has one seasonal shape for all years, so within a year these
## values follow the average seasonal cycle, scaled by that year's level. 05
## reads them on each WSS source date (release minus 20 days, ~Mar 12 - May 11):
## the biological year of a source date is its calendar year when the month is
## before August, the next year otherwise (none of the WSS source dates are).

daily_grid <- expand.grid(bio_year_f = factor(levels(tows$bio_year_f), levels = levels(tows$bio_year_f)),
                          doy        = 1:366) %>%
  mutate(day_night = factor("night", levels = c("day", "night")))

daily <- daily_grid %>%
  mutate(bio_year   = as.integer(as.character(bio_year_f)),
         cfin_day   = exp(as.numeric(predict(fit_cfin,   newdata = daily_grid))),
         energy_day = 10^as.numeric(predict(fit_energy, newdata = daily_grid)) - 1) %>%
  select(bio_year, doy, cfin_day, energy_day) %>%
  arrange(bio_year, doy)

cat("\ndaily values:", nrow(daily), "rows (", n_distinct(daily$bio_year), "biological years x 366 days )\n")
cat("seasonal multiplier over the WSS source dates (day 71-131, ~Mar 12 - May 11), max / min within a year:",
    "C. fin", round(with(daily %>% filter(bio_year == bio_year[1], doy %in% 71:131), max(cfin_day) / min(cfin_day)), 1),
    "| energy", round(with(daily %>% filter(bio_year == bio_year[1], doy %in% 71:131), max(energy_day) / min(energy_day)), 1), "\n")


## ===========================================================================
## 5. Assemble the index table, with coverage and flags
## ===========================================================================
## Every biological year in the record gets a row; years with no tows are NA
## (1975-76 and 2018-20).
##   few_tows       1-3 tows in the year (GoM3: 2008, one tow)
##   partial_year   the two half-years at the ends of the record (1961, 2025)
## Flagged years are KEPT in Layer A (Session 34 decision); the drop-one-year
## rule (rule 4) shows whether any one of them drives a result.

index <- data.frame(bio_year = min(tows$bio_year):max(tows$bio_year)) %>%
  left_join(coverage, by = "bio_year") %>%
  left_join(pred,     by = "bio_year") %>%
  mutate(across(c(n_tows, n_day, n_night, n_months), ~ coalesce(as.integer(.x), 0L)),
         tow_window   = paste0("Aug ", bio_year - 1L, " - Jul ", bio_year),
         few_tows     = n_tows >= 1 & n_tows <= 3,
         partial_year = bio_year %in% c(min(bio_year), max(bio_year))) %>%
  select(bio_year, tow_window, n_tows, n_day, n_night, n_months, first_tow, last_tow,
         cfin_gam_night_log, cfin_gam_night_se, cfin_gam_night,
         energy_gam_night_log10, energy_gam_night_se, energy_gam_night,
         few_tows, partial_year)

g3 <- index %>% filter(bio_year >= 1987, bio_year <= 2016)
cat("\n---- Index, GoM3 years (log scale = what Layer A uses) ----\n")
print(as.data.frame(g3 %>% select(bio_year, n_tows, n_months, cfin_gam_night_log, cfin_gam_night_se,
                                  energy_gam_night_log10, energy_gam_night_se, few_tows)), digits = 3)
cat("\nflagged years (all):\n")
print(as.data.frame(index %>% filter(few_tows | partial_year) %>%
                      select(bio_year, tow_window, n_tows, n_months, few_tows, partial_year)))
cat("\nGoM3 years: range of each index (max / min, back-transformed): C. fin",
    round(max(g3$cfin_gam_night) / min(g3$cfin_gam_night), 1), "x | energy",
    round(max(g3$energy_gam_night) / min(g3$energy_gam_night), 1), "x\n")
cat("GoM3 years: Spearman correlation, C. fin index vs energy index:",
    round(cor(g3$cfin_gam_night_log, g3$energy_gam_night_log10, method = "spearman"), 2), "\n")


## ===========================================================================
## 6. Figure: the index over the years
## ===========================================================================
## Back-transformed levels on a log axis, 95% CI (too narrow -- see header).
## Open points = flagged years. Dashed lines bracket the GoM3 fitting years
## (1987-2016); grey band = the 2008-2012 regime-shift window (literature).

fig_d <- bind_rows(
  index %>% transmute(bio_year, variable = "C. finmarchicus CV-CVI, ind / 100 m3",
                      fit = cfin_gam_night,
                      lo  = exp(cfin_gam_night_log - 1.96 * cfin_gam_night_se),
                      hi  = exp(cfin_gam_night_log + 1.96 * cfin_gam_night_se),
                      flagged = few_tows | partial_year),
  index %>% transmute(bio_year, variable = "Energy (ZCEI), J / 100 m3",
                      fit = energy_gam_night,
                      lo  = 10^(energy_gam_night_log10 - 1.96 * energy_gam_night_se) - 1,
                      hi  = 10^(energy_gam_night_log10 + 1.96 * energy_gam_night_se) - 1,
                      flagged = few_tows | partial_year)
) %>%
  filter(!is.na(fit)) %>%
  mutate(flagged = ifelse(flagged, "1-3 tows or half-year", "4+ tows"))

p_idx <- ggplot(fig_d, aes(bio_year, fit)) +
  annotate("rect", xmin = 2008, xmax = 2012, ymin = 0, ymax = Inf, fill = "grey92") +
  geom_vline(xintercept = c(1986.5, 2016.5), linetype = "dashed", colour = "grey55") +
  geom_linerange(aes(ymin = lo, ymax = hi), colour = "#2a78d6", alpha = 0.5) +
  geom_point(aes(shape = flagged), colour = "#2a78d6", size = 2) +
  scale_shape_manual(values = c("4+ tows" = 16, "1-3 tows or half-year" = 1), name = NULL) +
  scale_y_log10() +
  facet_wrap(~ variable, ncol = 1, scales = "free_y") +
  labs(title = "Western Scotian Shelf CPR: annual index",
       subtitle = paste0("Biological year (Aug of the year before - Jul), level read at day ", read_doy,
                         " at night, 95% CI. Year as a factor + seasonal cycle + day/night.\n",
                         "Dashed: GoM3 fitting years 1987-2016. Grey band: 2008-2012 regime-shift window (literature)."),
       x = "biological year (= the SPUE year it is paired with)", y = NULL) +
  theme_c
ggsave(file.path(out_plots, "cpr_03_annual_index.png"), p_idx, width = 10, height = 7.5, dpi = 150)


## ===========================================================================
## 7. Write
## ===========================================================================

write.csv(index,   file.path(out_prep, "cpr_wss_annual_index.csv"), row.names = FALSE)
write.csv(daily,   file.path(out_prep, "cpr_wss_daily.csv"),        row.names = FALSE)
write.csv(fit_tab, file.path(out_summ, "cpr_03_index_fit.csv"),     row.names = FALSE)
cat("\nwrote", file.path(out_prep, "cpr_wss_annual_index.csv"), "|", file.path(out_prep, "cpr_wss_daily.csv"), "|",
    file.path(out_summ, "cpr_03_index_fit.csv"), "|", file.path(out_plots, "cpr_03_annual_index.png"), "\n")
