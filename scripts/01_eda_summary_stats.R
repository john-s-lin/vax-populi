library(sf)
library(leaflet)
library(ggplot2)

raw_data_dir <- file.path(getwd(), "data/raw")

# Geographic locations
ny_electoral_districts <- st_read(file.path(raw_data_dir, "nyed_24d/nyed.shp"))
ny_modzcta <- read_sf(file.path(raw_data_dir, "MODZCTA_2010_WGS1984.topo.json"))

# TODO
# Leaflet plots of electoral districts
# Leaflet plots of MODZCTA districts