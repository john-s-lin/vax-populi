library(sf)
library(leaflet)
library(dplyr)
library(mapview)
library(webshot2)
library(ggplot2)

raw_data_dir <- file.path(getwd(), "data/raw")
output_dir <- file.path(getwd(), "out", "eda")


if (!file.exists(output_dir)) {
  dir.create(output_dir, mode = "0755", recursive = TRUE)
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
ggsave(file.path(output_dir, "nyed_gg.png"), plot = nyed_gg)

modzcta_gg <- ggplot(data = ny_modzcta) +
  geom_sf(aes(fill = "MODZCTA"), alpha = 0.5, color = "red") +
  scale_fill_manual(values = "red") +
  labs(title = "NY MODZCTA") +
  theme_light() +
  theme(legend.position = "none")
ggsave(file.path(output_dir, "modzcta_gg.png"), plot = modzcta_gg)

# Join the two maps with `st_union` and see if it works!