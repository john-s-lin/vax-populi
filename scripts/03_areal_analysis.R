library(spdep)
library(sf)
library(ggplot2)
library(RColorBrewer)
library(jsonlite) # To save text results as readable JSON

# Source util functions
# - normalize_rates(dataset)
source("R/utils.R")

clean_data_dir <- file.path(getwd(), "data", "clean")
output_dir <- file.path(getwd(), "out", "areal")

if (!file.exists(output_dir)) {
  dir.create(output_dir, mode = "0755", recursive = TRUE)
}

cached_covid_v_er_2020_src <- file.path(clean_data_dir, "covid_nyer_merged_geo_2020.gpkg")
cached_covid_v_er_2024_src <- file.path(clean_data_dir, "covid_nyer_merged_geo_2024.gpkg")

covid_v_er_2020_raw <- st_read(cached_covid_v_er_2020_src)
covid_v_er_2024_raw <- st_read(cached_covid_v_er_2024_src)

covid_v_er_2020 <- normalize_rates(covid_v_er_2020_raw)
covid_v_er_2024 <- normalize_rates(covid_v_er_2024_raw)

# Histograms
generate_gg_histogram <- function(dataset,
                                  column_name,
                                  fill_color,
                                  title,
                                  x_lab) {
  # Drop rows with NA or NULL
  dataset <- dataset %>% filter(!is.na(.data[[column_name]]))
  
  hist <- ggplot(dataset, aes(x = .data[[column_name]])) +
    geom_histogram(bins = 20,
                   fill = fill_color,
                   color = "black") +
    stat_bin(
      bins = 20,
      aes(label = after_stat(count), y = after_stat(count)),
      geom = "text",
      vjust = -0.5,
      size = 3
    ) +
    theme_light() +
    labs(title = title, x = x_lab, y = "Frequency")
  return(hist)
}

# Case rates
hist_covid_case_rates <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "COVID_CASE_RATE",
  fill_color = brewer.pal(9, "YlOrRd")[7],
  title = "Distribution of COVID Case Rates",
  x_lab = "Case Rates"
)
ggsave(file.path(output_dir, "covid_case_rates_hist.png"), plot = hist_covid_case_rates)

# Case count
hist_covid_case_counts <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "COVID_CASE_COUNT",
  fill_color = brewer.pal(9, "YlOrRd")[5],
  title = "Distribution of COVID Case Count",
  x_lab = "Case Counts"
)
ggsave(file.path(output_dir, "covid_case_count_hist.png"), plot = hist_covid_case_counts)

# Deaths
hist_covid_death_rates <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "COVID_DEATH_RATE",
  fill_color = brewer.pal(9, "RdPu")[9],
  title = "Distribution of COVID Death Rates",
  x_lab = "Death Rate"
)
ggsave(file.path(output_dir, "covid_death_rates_hist.png"), plot = hist_covid_death_rates)

hist_covid_death_count <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "COVID_DEATH_COUNT",
  fill_color = brewer.pal(9, "RdPu")[7],
  title = "Distribution of COVID Death Count",
  x_lab = "Death Count"
)
ggsave(file.path(output_dir, "covid_death_count_hist.png"), plot = hist_covid_death_count)

# Vaccinations
hist_covid_vax_rates <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "PERC_FULLY",
  fill_color = brewer.pal(9, "Blues")[2],
  title = "Distribution of COVID Fully Vaccinated Rates",
  x_lab = "Fully Vaccinated Rate"
)
ggsave(file.path(output_dir, "covid_vax_rate_hist.png"), plot = hist_covid_vax_rates)

hist_covid_vax_count <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "COUNT_FULLY_CUMULATIVE",
  fill_color = brewer.pal(9, "Blues")[4],
  title = "Distribution of COVID Fully Vaccinated Count",
  x_lab = "Fully Vaccinated Rate"
)
ggsave(file.path(output_dir, "covid_vax_count_hist.png"), plot = hist_covid_vax_count)

# Voting 2020
# Republican Fraction
hist_gop_frac_2020 <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "republican_two_party_frac",
  fill_color = brewer.pal(9, "Reds")[4],
  title = "Histogram of Republican Voting Fraction 2020",
  x_lab = "Proportion of Republicans out of Total Republican + Democrat Voters"
)
ggsave(file.path(output_dir, "gop_frac_2020_hist.png"), plot = hist_gop_frac_2020)

# Democrat Fraction
hist_dem_frac_2020 <- generate_gg_histogram(
  dataset = covid_v_er_2020,
  column_name = "democrat_two_party_frac",
  fill_color = brewer.pal(9, "Blues")[3],
  title = "Histogram of Democrat Voting Fraction 2020",
  x_lab = "Proportion of Democrat out of Total Republican + Democrat Voters"
)
ggsave(file.path(output_dir, "dem_frac_2020_hist.png"), plot = hist_dem_frac_2020)

# Voting 2024
# Republican Fraction
hist_gop_frac_2024 <- generate_gg_histogram(
  dataset = covid_v_er_2024,
  column_name = "republican_two_party_frac",
  fill_color = brewer.pal(9, "Reds")[4],
  title = "Histogram of Republican Voting Fraction 2024",
  x_lab = "Proportion of Republicans out of Total Republican + Democrat Voters"
)
ggsave(file.path(output_dir, "gop_frac_2024_hist.png"), plot = hist_gop_frac_2024)

# Democrat Fraction
hist_dem_frac_2024 <- generate_gg_histogram(
  dataset = covid_v_er_2024,
  column_name = "democrat_two_party_frac",
  fill_color = brewer.pal(9, "Blues")[3],
  title = "Histogram of Democrat Voting Fraction 2024",
  x_lab = "Proportion of Democrat out of Total Republican + Democrat Voters"
)
ggsave(file.path(output_dir, "dem_frac_2024_hist.png"), plot = hist_dem_frac_2024)

# Correlations
# Note: correlations for Republican fraction are just -1 * correlation_vs_democrat_fraction
# Store correlations in some sort of dataframe and save as JSON
calc_corr_test <- function(x, y, x_label, y_label) {
  result <- cor.test(x, y)
  list(
    x = x_label,
    y = y_label,
    correlation = result$estimate,
    p_value = result$p.value
  )
}

# Case rates vs. political alignment
corr_case_rate_v_dem_2020 <- calc_corr_test(
  x = covid_v_er_2020$democrat_two_party_frac,
  y = covid_v_er_2020$COVID_CASE_RATE,
  x_label = "Democrat Fraction 2020",
  y_label = "COVID Case Rate"
)
corr_case_rate_v_dem_2024 <- calc_corr_test(
  x = covid_v_er_2024$democrat_two_party_frac,
  y = covid_v_er_2024$COVID_CASE_RATE,
  x_label = "Democrat Fraction 2024",
  y_label = "COVID Case Rate"
)

# Death rates vs. political alignment
corr_death_rate_v_dem_2020 <- calc_corr_test(
  x = covid_v_er_2020$democrat_two_party_frac,
  y = covid_v_er_2020$COVID_DEATH_RATE,
  x_label = "Democrat Fraction 2020",
  y_label = "COVID Death Rate"
)
corr_death_rate_v_dem_2024 <- calc_corr_test(
  x = covid_v_er_2024$democrat_two_party_frac,
  y = covid_v_er_2024$COVID_DEATH_RATE,
  x_label = "Democrat Fraction 2024",
  y_label = "COVID Death Rate"
)

# Vax rate vs. political alignment
corr_vax_rate_v_dem_2020 <- calc_corr_test(
  x = covid_v_er_2020$democrat_two_party_frac,
  y = covid_v_er_2020$PERC_FULLY,
  x_label = "Democrat Fraction 2020",
  y_label = "COVID Percent Fully Vaccinated"
)
corr_vax_rate_v_dem_2024 <- calc_corr_test(
  x = covid_v_er_2024$democrat_two_party_frac,
  y = covid_v_er_2024$PERC_FULLY,
  x_label = "Democrat Fraction 2024",
  y_label = "COVID Percent Fully Vaccinated"
)

# Compile correlations with rbind into a dataframe, then store as JSON
correlations = list(
  corr_case_rate_v_dem_2020,
  corr_case_rate_v_dem_2024,
  corr_death_rate_v_dem_2020,
  corr_death_rate_v_dem_2024,
  corr_vax_rate_v_dem_2020,
  corr_vax_rate_v_dem_2024
)

corr_df <- do.call(rbind, lapply(correlations, as.data.frame))

output_json_path <- file.path(output_dir, "correlations.json")
write_json(corr_df, output_json_path, pretty = TRUE)