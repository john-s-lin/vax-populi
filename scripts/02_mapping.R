library(dplyr)
library(sf)
library(leaflet)
library(mapview)
library(webshot2)
library(ggplot2)
library(RColorBrewer)

clean_data_dir <- file.path(getwd(), "data", "clean")
cached_covid_er_geo_2020 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2020.gpkg")
cached_covid_er_geo_2024 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2024.gpkg")
output_dir <- file.path(getwd(), "out", "maps")

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
  dataset$democrat_two_party_frac <- 1 - dataset$republican_two_party_frac
  return(dataset)
}

covid_v_er_2020 <- normalize_rates(covid_v_er_2020)
covid_v_er_2024 <- normalize_rates(covid_v_er_2024)

# Generate a leaflet map with the desired column
generate_leaflet_map <- function(dataset, column_name, palette, title) {
  # Drop rows with NA or NULL
  dataset <- dataset %>% filter(!is.na(.data[[column_name]]))
  
  generated_map <- leaflet(dataset) %>%
    addProviderTiles("CartoDB.Positron") %>%
    addPolygons(
      weight = 1,
      fillOpacity = 0.6,
      color = ~ palette(dataset[[column_name]])
    ) %>%
    addLegend(
      position = "bottomright",
      pal = palette,
      values = dataset[[column_name]],
      title = title
    )
  return(generated_map)
}

# Save the map if it doesn't exist
save_leaflet_map <- function(leaflet_map, filename) {
  if (!file.exists(filename)) {
    mapshot2(leaflet_map, file = filename)
  }
}

# Generate map-view of COVID case rates per district (should be the same for 2020, 2024, so keep 2020)
pal_case_rate_2020 <- colorNumeric(palette = "YlOrRd", domain = covid_v_er_2020$COVID_CASE_RATE)
covid_case_rate_map_2020 <- generate_leaflet_map(
  dataset = covid_v_er_2020,
  column_name = "COVID_CASE_RATE",
  palette = pal_case_rate_2020,
  title = "COVID Case Rate"
)
save_leaflet_map(
  covid_case_rate_map_2020,
  filename = file.path(output_dir, "covid_case_rate_map_leaflet.png")
)

# Generate map-view of COVID death rates per district (same as above)
pal_death_rate_2020 <- colorNumeric(palette = "RdPu", domain = covid_v_er_2020$COVID_DEATH_RATE)
covid_death_map_2020 <- generate_leaflet_map(
  dataset = covid_v_er_2020,
  column_name = "COVID_DEATH_RATE",
  palette = pal_death_rate_2020,
  title = "COVID Death Rate"
)
save_leaflet_map(covid_death_map_2020,
                 filename = file.path(output_dir, "covid_death_rate_map_leaflet.png"))

# Generate map-view of COVID vax rates per district (same as above)
pal_vax_rate_2020 <- colorNumeric(palette = "Blues", domain = c(0, max(covid_v_er_2020$PERC_FULLY)))
covid_vax_map_2020 <- generate_leaflet_map(
  dataset = covid_v_er_2020,
  column_name = "PERC_FULLY",
  palette = pal_vax_rate_2020,
  title = "COVID Fully Vaccinated Rate"
)
save_leaflet_map(covid_vax_map_2020,
                 filename = file.path(output_dir, "covid_vax_rate_map_leaflet.png"))

# Generate map-view of political alignment in this modified region for 2020
pal_pol_scale_2020 <- colorNumeric(
  palette = "RdYlBu",
  domain = covid_v_er_2020$republican_two_party_frac,
  reverse = TRUE
)
electoral_map_2020 <- generate_leaflet_map(
  dataset = covid_v_er_2020,
  column_name = "republican_two_party_frac",
  palette = pal_pol_scale_2020,
  title = "Poltical Voting Scale 2020 (Democrat vs. Republican)"
)
save_leaflet_map(electoral_map_2020,
                 filename = file.path(output_dir, "electoral_map_2020_leaflet.png"))

# Generate map-view of political alignment in this modified region for 2024
pal_pol_scale_2024 <- colorNumeric(
  palette = "RdYlBu",
  domain = covid_v_er_2024$republican_two_party_frac,
  reverse = TRUE
)
electoral_map_2024 <- generate_leaflet_map(
  dataset = covid_v_er_2024,
  column_name = "republican_two_party_frac",
  palette = pal_pol_scale_2024,
  title = "Poltical Voting Scale 2024 (Democrat vs. Republican)"
)
save_leaflet_map(electoral_map_2024,
                 filename = file.path(output_dir, "electoral_map_2024_leaflet.png"))

# Function to generate a ggplot2 map
generate_ggplot_map <- function(dataset,
                                column_name,
                                pal,
                                title,
                                with_legend = TRUE) {
  # Drop rows with NA or NULL
  dataset <- dataset %>% filter(!is.na(.data[[column_name]]))
  
  # Create the ggplot2 map
  map <- ggplot(data = dataset) +
    geom_sf(
      aes(fill = .data[[column_name]]),
      color = "white",
      size = 0.1,
      show.legend = with_legend
    ) +
    scale_fill_gradientn(colors = pal, name = title) +
    theme_light() +
    labs(title = title)
  
  return(map)
}

# Generate and save a ggplot2 map for COVID case rates
covid_case_rate_map_gg <- generate_ggplot_map(
  dataset = covid_v_er_2020,
  column_name = "COVID_CASE_RATE",
  pal = brewer.pal(n = 8, "YlOrRd"),
  title = "COVID Case Rate"
)
ggsave(file.path(output_dir, "covid_case_rate_map_gg.png"), plot = covid_case_rate_map_gg)

# Generate and save a ggplot2 map for COVID death rates
covid_death_rate_map_gg <- generate_ggplot_map(
  dataset = covid_v_er_2020,
  column_name = "COVID_DEATH_RATE",
  pal = brewer.pal(n = 8, "RdPu"),
  title = "COVID Death Rate"
)
ggsave(file.path(output_dir, "covid_death_rate_map_gg.png"), plot = covid_death_rate_map_gg)

# Generate and save a ggplot2 map for COVID vax rates
covid_vax_rate_map_gg <- generate_ggplot_map(
  dataset = covid_v_er_2020,
  column_name = "PERC_FULLY",
  pal = brewer.pal(n = 8, "Blues"),
  title = "COVID Fully Vaccinated Rate"
)
ggsave(file.path(output_dir, "covid_vax_rate_map_gg.png"), plot = covid_vax_rate_map_gg)

# Generate and save a ggplot2 map for electoral results in 2020
electoral_map_2020_gg <- generate_ggplot_map(
  dataset = covid_v_er_2020,
  column_name = "democrat_two_party_frac",
  pal = brewer.pal(n = 11, "RdYlBu"),
  title = "Poltical Voting Scale 2020 (Democrat vs. Republican)",
  with_legend = FALSE
)
ggsave(file.path(output_dir, "electoral_map_2020_gg.png"), plot = electoral_map_2020_gg)

# Generate and save a ggplot2 map for electoral results in 2024
electoral_map_2024_gg <- generate_ggplot_map(
  dataset = covid_v_er_2024,
  column_name = "democrat_two_party_frac",
  pal = brewer.pal(n = 11, "RdYlBu"),
  title = "Poltical Voting Scale 2024 (Democrat vs. Republican)",
  with_legend = FALSE
)
ggsave(file.path(output_dir, "electoral_map_2024_gg.png"), plot = electoral_map_2024_gg)
