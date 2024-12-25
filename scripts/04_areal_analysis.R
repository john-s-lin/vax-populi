library(dplyr)
library(ggplot2)
library(jsonlite)
library(RColorBrewer)
library(spdep) # For Moran's I, local G
library(sf)
library(spatialreg) # For SAR/CAR

# Source util functions
# - normalize_rates(dataset)
source("R/utils.R")

clean_data_dir <- file.path(getwd(), "data", "clean")
output_dir <- file.path(getwd(), "out")
areal_dir <- file.path(output_dir, "areal")

if (!file.exists(areal_dir)) {
  dir.create(areal_dir, mode = "0755", recursive = TRUE)
}

cached_covid_v_er_2020_src <- file.path(clean_data_dir, "covid_nyer_merged_geo_2020.gpkg")
cached_covid_v_er_2024_src <- file.path(clean_data_dir, "covid_nyer_merged_geo_2024.gpkg")

covid_v_er_2020_raw <- st_read(cached_covid_v_er_2020_src)
covid_v_er_2024_raw <- st_read(cached_covid_v_er_2024_src)

covid_v_er_2020 <- normalize_rates(covid_v_er_2020_raw)
covid_v_er_2024 <- normalize_rates(covid_v_er_2024_raw)

# Convert the geometries to EPSG:2263 NAD83 for meters
NAD83 <- 2263
covid_v_er_2020_meters <- st_transform(covid_v_er_2020, crs = NAD83)
covid_v_er_2024_meters <- st_transform(covid_v_er_2024, crs = NAD83)

# Compare 6-NN to Queen Neighbors
ny_centroids <- st_centroid(covid_v_er_2020_meters)
ny_centroid_coords <- st_coordinates(ny_centroids)
knn_6_ny <- knearneigh(ny_centroid_coords, k = 6)
knn_6_ny_nb <- knn2nb(knn_6_ny)
knn_6_ny_weights <- nb2listw(knn_6_ny_nb, style = "W", zero.policy = TRUE)

# Moran's I using 6-NN
# Case rates
moran_6nn_case_rate <- moran.test(covid_v_er_2020$COVID_CASE_RATE,
                                  knn_6_ny_weights,
                                  randomisation = FALSE)

# Death rates
moran_6nn_death_rate <- moran.test(covid_v_er_2020$COVID_DEATH_RATE,
                                   knn_6_ny_weights,
                                   randomisation = FALSE)

# Vax rates
moran_6nn_vax_rate <- moran.test(covid_v_er_2020$PERC_FULLY, knn_6_ny_weights, randomisation = FALSE)

# Political alignment 2020
moran_6nn_pa_2020 <- moran.test(
  covid_v_er_2020$democrat_two_party_frac,
  knn_6_ny_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Political alignment 2024
moran_6nn_pa_2024 <- moran.test(
  covid_v_er_2024$democrat_two_party_frac,
  knn_6_ny_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Queen Neighbors
ny_queen_nb <- poly2nb(covid_v_er_2020_meters, queen = TRUE)
ny_queen_weights <- nb2listw(ny_queen_nb, style = "W", zero.policy = TRUE)

# Moran's I using Queen contiguity
# Case rates
moran_queen_case_rate <- moran.test(covid_v_er_2020$COVID_CASE_RATE,
                                    ny_queen_weights,
                                    randomisation = FALSE)

# Death rates
moran_queen_death_rate <- moran.test(covid_v_er_2020$COVID_DEATH_RATE,
                                     ny_queen_weights,
                                     randomisation = FALSE)

# Vax rates
moran_queen_vax_rate <- moran.test(covid_v_er_2020$PERC_FULLY, ny_queen_weights, randomisation = FALSE)

# Political alignment 2020
moran_queen_pa_2020 <- moran.test(
  covid_v_er_2020$democrat_two_party_frac,
  ny_queen_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Political alignment 2024
moran_queen_pa_2024 <- moran.test(
  covid_v_er_2024$democrat_two_party_frac,
  ny_queen_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Use Inverse-Distance Weighting, set distance to 5km
knn_1_nb <- knn2nb(knearneigh(ny_centroid_coords, k = 1))
dists <- nbdists(knn_1_nb, ny_centroid_coords)
ndist <- unlist(dists)
max_dist <- max(ndist)

ny_inverse_distance_nb <- dnearneigh(ny_centroid_coords, d1 = 0, d2 = max_dist)
ny_inverse_distance_weights <- nb2listw(ny_inverse_distance_nb,
                                        style = "W",
                                        zero.policy = TRUE)

# Moran's I using inverse distance weighting
# Case rates
moran_idw_case_rate <- moran.test(covid_v_er_2020$COVID_CASE_RATE,
                                  ny_inverse_distance_weights,
                                  randomisation = FALSE)

# Death rates
moran_idw_death_rate <- moran.test(covid_v_er_2020$COVID_DEATH_RATE,
                                   ny_inverse_distance_weights,
                                   randomisation = FALSE)

# Vax rates
moran_idw_vax_rate <- moran.test(covid_v_er_2020$PERC_FULLY,
                                 ny_inverse_distance_weights,
                                 randomisation = FALSE)

# Political alignment 2020
moran_idw_pa_2020 <- moran.test(
  covid_v_er_2020$democrat_two_party_frac,
  ny_inverse_distance_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Political alignment 2024
moran_idw_pa_2024 <- moran.test(
  covid_v_er_2024$democrat_two_party_frac,
  ny_inverse_distance_weights,
  randomisation = FALSE,
  na.action = na.omit
)

# Compile into a single df and save to JSON
# Function to extract Moran's I test results into a named list
extract_moran_results <- function(test, method_name, metric) {
  list(
    method = method_name,
    metric = metric,
    statistic = as.numeric(test$statistic),
    p_value = as.numeric(test$p.value),
    estimate = as.numeric(test$estimate["Moran I statistic"]),
    expectation = as.numeric(test$estimate["Expectation"]),
    variance = as.numeric(test$estimate["Variance"])
  )
}

# Collect all Moran's I results into a list
moran_results <- list(
  knn_6_case_rate = extract_moran_results(moran_6nn_case_rate, "6-NN", "COVID_CASE_RATE"),
  knn_6_death_rate = extract_moran_results(moran_6nn_death_rate, "6-NN", "COVID_DEATH_RATE"),
  knn_6_vax_rate = extract_moran_results(moran_6nn_vax_rate, "6-NN", "PERC_FULLY"),
  knn_6_pa_2020 = extract_moran_results(moran_6nn_pa_2020, "6-NN", "democrat_two_party_frac_2020"),
  knn_6_pa_2024 = extract_moran_results(moran_6nn_pa_2024, "6-NN", "democrat_two_party_frac_2024"),
  queen_case_rate = extract_moran_results(moran_queen_case_rate, "Queen", "COVID_CASE_RATE"),
  queen_death_rate = extract_moran_results(moran_queen_death_rate, "Queen", "COVID_DEATH_RATE"),
  queen_vax_rate = extract_moran_results(moran_queen_vax_rate, "Queen", "PERC_FULLY"),
  queen_pa_2020 = extract_moran_results(moran_queen_pa_2020, "Queen", "democrat_two_party_frac_2020"),
  queen_pa_2024 = extract_moran_results(moran_queen_pa_2024, "Queen", "democrat_two_party_frac_2024"),
  idw_case_rate = extract_moran_results(moran_idw_case_rate, "IDW", "COVID_CASE_RATE"),
  idw_death_rate = extract_moran_results(moran_idw_death_rate, "IDW", "COVID_DEATH_RATE"),
  idw_vax_rate = extract_moran_results(moran_idw_vax_rate, "IDW", "PERC_FULLY"),
  idw_pa_2020 = extract_moran_results(moran_idw_pa_2020, "IDW", "democrat_two_party_frac_2020"),
  idw_pa_2024 = extract_moran_results(moran_idw_pa_2024, "IDW", "democrat_two_party_frac_2024")
)

# Convert the results list to a dataframe for tabular view
moran_df <- do.call(rbind, lapply(names(moran_results), function(name) {
  cbind(data.frame(name = name), as.data.frame(t(unlist(moran_results[[name]]))))
}))

# Write results to JSON
write_json(
  moran_results,
  path = file.path(areal_dir, "moran_results.json"),
  pretty = TRUE
)

# KNN should be better, but IDW comes as a close second
# Correlograms and lag structures
generate_correlogram <- function(neighbors,
                                 dataset,
                                 column_name,
                                 order,
                                 year = 2020) {
  dataset <- dataset %>% filter(!is.na(.data[[column_name]]))
  
  # Recalculate neighbors if there are different lengths
  # Specific to voting patterns since there are some that are NaN
  if (length(neighbors) != length(dataset[[column_name]])) {
    neighbors = st_centroid(dataset) %>%
      st_coordinates() %>%
      knearneigh(k = 6) %>%
      knn2nb()
  }
  
  # Generate the correlogram
  cg <- sp.correlogram(
    neighbors,
    var = dataset[[column_name]],
    order = order,
    method = "I",
    style = "W",
    randomisation = FALSE,
    zero.policy = TRUE
  )
  
  # Extract results
  correlogram_data <- data.frame(
    lag = seq_along(cg$res[, 1]),
    moran_i = cg$res[, 1],
    # Moran's I
    expectation = cg$res[, 2],
    # Expectation
    variance = cg$res[, 3]      # Variance
  )
  
  # Calculate z-scores and p-values
  correlogram_data <- correlogram_data %>%
    mutate(
      z_score = (moran_i - expectation) / sqrt(variance),
      p_value = 2 * pnorm(-abs(z_score)) # Two-tailed p-value
    )
  
  # Write to JSON
  output_file <- file.path(areal_dir,
                           paste0("correlogram_", column_name, "_", year, ".json"))
  write_json(as.list(correlogram_data),
             path = output_file,
             pretty = TRUE)
  
  # Return the correlogram object
  return(cg)
}

# Case rates
cg_case_rates <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2020_meters,
  column_name = "COVID_CASE_RATE",
  order = 7
)

# Death rates
cg_death_rates <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2020_meters,
  column_name = "COVID_DEATH_RATE",
  order = 7
)

# Vax rates
cg_vax_rates <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2020_meters,
  column_name = "PERC_FULLY",
  order = 7
)

# 2020 DEM rates
cg_dem_2020 <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2020_meters,
  column_name = "democrat_two_party_frac",
  order = 7
)

# 2024 DEM rates
cg_dem_2024 <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2024_meters,
  column_name = "democrat_two_party_frac",
  order = 7,
  year = 2024
)

# 2020 GOP rates
cg_rep_2020 <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2020_meters,
  column_name = "republican_two_party_frac",
  order = 7
)

# 2024 GOP rates
cg_rep_2024 <- generate_correlogram(
  neighbors = knn_6_ny_nb,
  dataset = covid_v_er_2024_meters,
  column_name = "republican_two_party_frac",
  order = 7,
  year = 2024
)

# Generate correlogram plots with ggplot
save_lag_plot <- function(correlogram, title, output_path) {
  png(output_path, width = 800, height = 600)
  plot(correlogram, main = title)
  dev.off()
}

save_lag_plot(
  correlogram = cg_case_rates,
  title = "KNN-6 Lags for COVID Case Rates",
  output_path = file.path(areal_dir, "case_rates_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_death_rates,
  title = "KNN-6 Lags for COVID Death Rates",
  output_path = file.path(areal_dir, "death_rates_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_vax_rates,
  title = "KNN-6 Lags for COVID Vaccination Rates",
  output_path = file.path(areal_dir, "vax_rates_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_dem_2020,
  title = "KNN-6 Lags for Democrat Two Party Fraction, 2020",
  output_path = file.path(areal_dir, "dem_2020_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_dem_2024,
  title = "KNN-6 Lags for Democrat Two Party Fraction, 2024",
  output_path = file.path(areal_dir, "dem_2024_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_rep_2020,
  title = "KNN-6 Lags for Republican Two Party Fraction, 2020",
  output_path = file.path(areal_dir, "rep_2020_lag_plot.png")
)
save_lag_plot(
  correlogram = cg_rep_2024,
  title = "KNN-6 Lags for Republic Two Party Fraction, 2024",
  output_path = file.path(areal_dir, "rep_2024_lag_plot.png")
)

# Getis-Ord G*
# Reset to use WGS84 coordinates
ny_centroids_coords_84 <- st_centroid(covid_v_er_2020) %>% st_coordinates()
knn_1_nb_84 <- knearneigh(ny_centroids_coords_84, k = 1) %>% knn2nb()
knn_1_weights_84 <- nb2listw(knn_1_nb_84, style = "B")

# Case rates
gi_star_case_rates <- localG(covid_v_er_2020$COVID_CASE_RATE, knn_1_weights_84)

# Death rates
gi_star_death_rates <- localG(covid_v_er_2020$COVID_DEATH_RATE, knn_1_weights_84)

# Vax rates
gi_star_vax_rates <- localG(covid_v_er_2020$PERC_FULLY, knn_1_weights_84)

# PA 2020 rates
gi_star_dem_2020 <- localG(covid_v_er_2020$democrat_two_party_frac, knn_1_weights_84)

# PA 2024 rates
gi_star_dem_2024 <- localG(covid_v_er_2024$democrat_two_party_frac, knn_1_weights_84)

# Add G* scores to the dataset
covid_v_er_2020$G_STAR_CASE_RATE <- as.numeric(gi_star_case_rates)
covid_v_er_2020$G_STAR_DEATH_RATE <- as.numeric(gi_star_death_rates)
covid_v_er_2020$G_STAR_VAX_RATE <- as.numeric(gi_star_vax_rates)
covid_v_er_2020$G_STAR_DEM_2020 <- as.numeric(gi_star_dem_2020)
covid_v_er_2020$G_STAR_DEM_2024 <- as.numeric(gi_star_dem_2024)

# Define a function to plot and save the G* score maps
save_getis_ord_map <- function(dataset, column_name, title, output_path) {
  map <- ggplot(data = dataset) +
    geom_sf(aes_string(fill = column_name)) +
    scale_fill_gradient2(
      name = "G* Score",
      low = "blue",
      mid = "white",
      high = "red",
      midpoint = 0
    ) +
    labs(title = title) +
    theme_light()
  
  # Save the map as a PNG file
  ggsave(
    filename = output_path,
    plot = map,
    width = 8,
    height = 6
  )
}

# Save maps for G* scores
save_getis_ord_map(
  dataset = covid_v_er_2020,
  column_name = "G_STAR_CASE_RATE",
  title = "Getis-Ord G* for COVID Case Rates (2020)",
  output_path = file.path(areal_dir, "g_star_case_rate_2020.png")
)

save_getis_ord_map(
  dataset = covid_v_er_2020,
  column_name = "G_STAR_DEATH_RATE",
  title = "Getis-Ord G* for COVID Death Rates (2020)",
  output_path = file.path(areal_dir, "g_star_death_rate_2020.png")
)

save_getis_ord_map(
  dataset = covid_v_er_2020,
  column_name = "G_STAR_VAX_RATE",
  title = "Getis-Ord G* for Vaccination Rates (2020)",
  output_path = file.path(areal_dir, "g_star_vax_rate_2020.png")
)

save_getis_ord_map(
  dataset = covid_v_er_2020,
  column_name = "G_STAR_DEM_2020",
  title = "Getis-Ord G* for Democrat Two Party Fraction (2020)",
  output_path = file.path(areal_dir, "g_star_dem_2020.png")
)

save_getis_ord_map(
  dataset = covid_v_er_2020,
  column_name = "G_STAR_DEM_2024",
  title = "Getis-Ord G* for Democrat Two Party Fraction (2024)",
  output_path = file.path(areal_dir, "g_star_dem_2024.png")
)

# SAR spatial lag-error
sar_lag_error_case_rate <- sacsarlm(
  formula = scale(COVID_CASE_RATE) ~ democrat_two_party_frac + PERC_FULLY,
  data = covid_v_er_2020,
  listw = knn_6_ny_weights
)
sar_lag_error_residuals <- residuals(sar_lag_error_case_rate)
sar_lag_error_moran_residuals <- moran.test(sar_lag_error_residuals, listw = knn_6_ny_weights)

# Capture and save the summary output
summary_output <- capture.output(summary(sar_lag_error_case_rate))
writeLines(summary_output, con = file.path(areal_dir, "sar_model_summary.txt"))

# Save Moran's test results (optional, for diagnostics)
moran_output <- capture.output(sar_lag_error_moran_residuals)
writeLines(moran_output, con = file.path(areal_dir, "sar_model_moran_test.txt"))

# CAR model
car_case_rate <- spautolm(
  formula = scale(COVID_CASE_RATE) ~ democrat_two_party_frac + PERC_FULLY,
  data = covid_v_er_2020,
  listw = knn_6_ny_weights,
  zero.policy = TRUE,
  family = "CAR"
)
car_residuals <- residuals(car_case_rate)
car_moran_residuals <- moran.test(car_residuals, listw = knn_6_ny_weights)

# Capture and save the summary output
summary_output_car <- capture.output(summary(car_case_rate))
writeLines(summary_output_car, con = file.path(areal_dir, "car_model_summary.txt"))

# Save Moran's test results (optional, for diagnostics)
moran_output_car <- capture.output(car_moran_residuals)
writeLines(moran_output_car,
           con = file.path(areal_dir, "car_model_moran_test.txt"))
