library(dplyr)
library(ggplot2)
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
