library(sf)
library(leaflet)
library(dplyr)
library(mapview)
library(webshot2)
library(ggplot2)

raw_data_dir <- file.path(getwd(), "data", "raw")
output_dir <- file.path(getwd(), "out", "eda")
clean_data_dir <- file.path(getwd(), "data", "clean")
cached_covid_election_src <- file.path(clean_data_dir, "covid_nyer_merged_geo.gpkg")

if (!file.exists(output_dir)) {
  dir.create(output_dir, mode = "0755", recursive = TRUE)
}

if (!file.exists(clean_data_dir)) {
  dir.create(clean_data_dir, mode = "0755", recursive = TRUE)
}

if (file.exists(cached_covid_election_src)) {
  stop("Merged SF data already cached. No need to run this file.")
}

# Transform to lat-lon for visualization
WGS84 <- 4326

# Geographic locations
ny_electoral_districts <- st_read(file.path(raw_data_dir, "nyed_24d/nyed.shp")) %>% st_transform(crs = WGS84)
ny_modzcta <- read_sf(file.path(raw_data_dir, "MODZCTA_2010_WGS1984.topo.json"),
                      crs = WGS84)

# Leaflet plots of electoral districts
nyed_map <- leaflet(data = ny_electoral_districts) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    weight = 1,
    opacity = 0.5,
    color = "blue",
    label = ~ ElectDist
  )

# Only store the leaflet files if they don't exist, since they take a long time to run
nyed_map_file <- file.path(output_dir, "ny_election_districts.png")
if (!file.exists(nyed_map_file)) {
  mapshot2(nyed_map, file = nyed_map_file)
}


# Leaflet plots of MODZCTA districts
modzcta <- leaflet(data = ny_modzcta) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    weight = 1,
    opacity = 0.5,
    color = "red",
    label = ~ MODZCTA
  )
ny_modzcta_map_file <- file.path(output_dir, "ny_modzcta.png")
if (!file.exists(ny_modzcta_map_file)) {
  mapshot2(nyed_map, file = ny_modzcta_map_file)
}

## We can save as plots using ggplot as well
nyed_gg <- ggplot(data = ny_electoral_districts) +
  geom_sf(aes(fill = "Electoral Districts"),
          alpha = 0.5,
          color = "blue") +
  scale_fill_manual(values = "blue") +
  labs(title = "NY Electoral Districts") +
  theme_light() +
  theme(legend.position = "none")
nyed_gg_map <- file.path(output_dir, "nyed_gg.png")
if (!file.exists(nyed_gg_map)) {
  ggsave(nyed_gg_map, plot = nyed_gg)
}

modzcta_gg <- ggplot(data = ny_modzcta) +
  geom_sf(aes(fill = "MODZCTA"), alpha = 0.5, color = "red") +
  scale_fill_manual(values = "red") +
  labs(title = "NY MODZCTA") +
  theme_light() +
  theme(legend.position = "none")
mz_gg_map <- file.path(output_dir, "modzcta_gg.png")
if (!file.exists(mz_gg_map)) {
  ggsave(mz_gg_map, plot = modzcta_gg)
}

# First check if geometries are valid, if not, then make valid
if (!all(st_is_valid(ny_electoral_districts))) {
  ny_electoral_districts <- ny_electoral_districts %>%
    st_make_valid() %>%
    st_buffer(0) %>%  # Remove self-intersections
    st_make_valid()   # Clean up again after buffering
  print("Made valid ny_electoral_districts")
}

if (!all(st_is_valid(ny_modzcta))) {
  ny_modzcta <- ny_modzcta %>%
    st_make_valid() %>%
    st_buffer(0) %>%
    st_make_valid()
  print("Made valid ny_modzcta")
}

# Join the two maps with `st_join` and see if it works!
# This takes a long time, so only do this if the merged_map is not created yet
merged_map <- file.path(output_dir, "merged_gg.png")
if (!file.exists(merged_map)) {
  merged_geo <- st_join(
    ny_modzcta,
    ny_electoral_districts,
    join = st_covers,
    left = TRUE,
    largest = TRUE
  )
  merged_gg <- ggplot(data = merged_geo) +
    geom_sf(aes(fill = "Merged"),
            alpha = 0.5,
            color = "darkgreen") +
    scale_fill_manual(values = "green") +
    theme_light() +
    theme(legend.position = "none")
  ggsave(filename = merged_map, plot = merged_gg)
}

# Looks like they can be merged!
# Let's join the modzcta tables with the modzcta geometry, cache it.
# Then join the electoral results with the electoral districts geometry, cache that.
# Then join them into a large table and cache that as well, since it takes a long
# time to compute, and we only want to do this once.

# Join the COVID data first by MODZCTA
covid_vax_data <- read.csv(file.path(raw_data_dir, "coverage-by-modzcta-adults.csv"),
                           header = TRUE)
covid_data <- read.csv(file.path(raw_data_dir, "data-by-modzcta.csv"), header = TRUE)
covid_data_merged <- merge(x = covid_vax_data,
                           y = covid_data,
                           by.x = "MODZCTA",
                           by.y = "MODIFIED_ZCTA")
# Drop duplicate columns and rename _.x
covid_data_merged = select(
  covid_data_merged,-c("NEIGHBORHOOD_NAME.y", "BOROUGH_GROUP", "label", "lat", "lon")
)
names(covid_data_merged)[names(covid_data_merged) == "NEIGHBORHOOD_NAME.x"] <- "NEIGHBORHOOD_NAME"
write.csv(
  covid_data_merged,
  file = file.path(clean_data_dir, "covid_data_merged_no_geo.csv"),
  row.names = FALSE
)

# Merge by MODZCTA with the geometry, then cache as a shapefile
covid_merged_geo <- merge(covid_data_merged, ny_modzcta, by = "MODZCTA") %>%
  select(-c("id", "label"))
cached_covid_merged_geo <- file.path(clean_data_dir, "covid_data_merged_geo.gpkg")
if (!file.exists(cached_covid_merged_geo)) {
  st_write(covid_merged_geo, dsn = cached_covid_merged_geo, driver = "GPKG")
}

# Same thing with electoral data, merge by electoral district
ny_electoral_results <- read.csv(file.path(raw_data_dir, "nyc_election_results_by_district.csv"),
                                 header = TRUE)
nyed_geo <- merge(ny_electoral_results,
                  ny_electoral_districts,
                  by.x = "elect_dist",
                  by.y = "ElectDist") %>%
  select(-c("Shape_Leng", "Shape_Area"))
cached_nyed_geo <- file.path(clean_data_dir, "ny_election_results_by_year_geo.gpkg")
if (!file.exists(cached_nyed_geo)) {
  st_write(nyed_geo, dsn = cached_nyed_geo, driver = "GPKG")
}

# Finally merge the NY election_results with the COVID data and cache that
# Use the cached versions
covid_data_sf <- st_read(cached_covid_merged_geo)
nyed_sf <- st_read(cached_nyed_geo)
if (!file.exists(cached_covid_election_src)) {
  covid_election_geo_merged <- st_join(
    covid_data_sf,
    nyed_sf,
    join = st_covers,
    left = TRUE,
    largest = TRUE,
  )
  st_write(covid_election_geo_merged,
           dsn = cached_covid_election_src,
           driver = "GPKG")
} 