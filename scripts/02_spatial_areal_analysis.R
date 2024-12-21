library(dplyr)
library(sf)

clean_data_dir <- file.path(getwd(), "data", "clean")
cached_covid_er_geo_2020 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2020.gpkg")
cached_covid_er_geo_2024 <- file.path(clean_data_dir, "covid_nyer_merged_geo_2024.gpkg")

covid_v_er_2020 <- st_read(cached_covid_er_geo_2020)
covid_v_er_2024 <- st_read(cached_covid_er_geo_2024)