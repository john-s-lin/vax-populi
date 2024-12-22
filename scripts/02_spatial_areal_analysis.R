library(dplyr)
library(sf)
library(leaflet)
library(mapview)
library(webshot2)
library(ggplot2)

clean_data_dir <- file.path(getwd(), "data", "clean")
cached_covid_er_geo_2020 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2020.gpkg")
cached_covid_er_geo_2024 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2024.gpkg")
output_dir <- file.path(getwd(), "out", "areal")

if (!file.exists(output_dir)) {
  dir.create(output_dir, mode = "0755", recursive = TRUE)
}

covid_v_er_2020 <- st_read(cached_covid_er_geo_2020)
covid_v_er_2024 <- st_read(cached_covid_er_geo_2024)

normalize_rates <- function(dataset) {
  # Convert case rates from rate/100_000 people to fraction between [0, 1] 
  dataset <- mutate(dataset, across(
    c(
      "COVID_CONFIRMED_CASE_RATE",
      "COVID_CASE_RATE",
      "COVID_DEATH_RATE"
    ),
    ~ . / 100000
  ))
  # Convert percentage vaccinated into fraction between [0, 1]
  dataset <- mutate(dataset, across(
    c(
      "PERC_PARTIALLY",
      "PERC_FULLY",
      "PERC_1PLUS",
      "PERC_ADDITIONAL",
      "PERC_BIVALENT_ADDITIONAL"
    ),
    ~ . / 100
  ))
  # Store ratio of republican voters over sum of Dem + Rep parties, ignore Green and Libertarian
  dataset$two_party_total <- dataset$republican + dataset$democratic
  dataset$republican_two_party_frac <- dataset$republican / dataset$two_party_total
  return(dataset)
}

covid_v_er_2020 <- normalize_rates(covid_v_er_2020)
covid_v_er_2024 <- normalize_rates(covid_v_er_2024)

# Generate map-view of COVID case rates per district (should be the same for 2020, 2024, so keep 2020)
pal_case_rate_2020 <- colorNumeric(palette = "YlOrRd", domain = covid_v_er_2020$COVID_CASE_RATE)

covid_case_rate_map_2020 <- leaflet(covid_v_er_2020) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    weight = 1,
    fillOpacity = 0.6,
    color = ~ pal_case_rate_2020(COVID_CASE_RATE),
    label = ~ paste0(NEIGHBORHOOD_NAME, ": ", COVID_CASE_RATE)
  ) %>%
  addLegend(
    position = "bottomright",
    pal = pal_case_rate_2020,
    values = ~ COVID_CASE_RATE,
    title = "COVID Case Rate"
  )

covid_case_rate_map_file <- file.path(output_dir, "covid_case_rate_map_leaflet.png")
if (!file.exists(covid_case_rate_map_file)) {
  mapshot2(covid_case_rate_map_2020, file = covid_case_rate_map_file)
}

# Generate map-view of COVID death rates per district (same as above)
pal_death_rate_2020 <- colorNumeric(palette = "RdPu", domain = covid_v_er_2020$COVID_DEATH_RATE)

covid_death_map_2020 <- leaflet(covid_v_er_2020) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    weight = 1,
    fillOpacity = 0.6,
    color = ~ pal_death_rate_2020(COVID_DEATH_RATE),
    label = ~ paste0(NEIGHBORHOOD_NAME, ": ", COVID_DEATH_RATE)
  ) %>%
  addLegend(
    position = "bottomright",
    pal = pal_death_rate_2020,
    values = ~ COVID_DEATH_RATE,
    title = "COVID Death Rate"
  )
covid_death_map_file <- file.path(output_dir, "covid_death_rate_map_leaflet.png")
if (!file.exists(covid_death_map_file)) {
  mapshot2(covid_death_map_2020, file = covid_death_map_file)
}

# Generate map-view of COVID vax rates per district (same as above)
pal_vax_rate_2020 <- colorNumeric(palette = "Blues", domain = c(0, max(covid_v_er_2020$PERC_FULLY)))

covid_vax_map_2020 <- leaflet(covid_v_er_2020) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    weight = 1,
    fillOpacity = 0.6,
    color = ~ pal_vax_rate_2020(PERC_FULLY),
    label = ~ paste0(NEIGHBORHOOD_NAME, ": ", PERC_FULLY)
  ) %>%
  addLegend(
    position = "bottomright",
    pal = pal_vax_rate_2020,
    values = ~ PERC_FULLY,
    title = "COVID Fully Vaccinated Rate"
  )
covid_vax_map_file <- file.path(output_dir, "covid_vax_rate_map_leaflet.png")
if (!file.exists(covid_vax_map_file)) {
  mapshot2(covid_vax_map_2020, file = covid_vax_map_file)
}