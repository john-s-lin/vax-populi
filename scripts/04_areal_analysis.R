library(dplyr)
library(ggplot2)
library(jsonlite)
library(RColorBrewer)
library(spdep)
library(sf)

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
