# Data Sources
covid_vax_adults_src <- "https://raw.githubusercontent.com/nychealth/covid-vaccine-data/refs/heads/main/people/coverage-by-modzcta-adults.csv"
covid_total_modzcta_src <- "https://raw.githubusercontent.com/nychealth/coronavirus-data/refs/heads/master/totals/data-by-modzcta.csv"
nyc_election_districts_src <- "https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/nyed_24d.zip"
nyc_election_results_by_year <- "https://raw.githubusercontent.com/toddwschneider/nyc-presidential-election-map/refs/heads/main/nyc_election_results_by_district.csv"

data_dir <- paste0(getwd(), "/data")
raw_data_dir <- paste0(data_dir, "/raw")

if (!file.exists(data_dir)) {
  dir.create(data_dir, mode = "0755")
}

if (!file.exists(raw_data_dir)) {
  dir.create(raw_data_dir, mode = "0755")
}

download_data <- function(url, destination) {
  name = basename(url)
  dest = file.path(destination, name)
  download.file(url, dest, method = "curl")
  
  # If the file is a zip file, unzip it
  if (endsWith(dest, ".zip")) {
    unzip(dest, exdir = raw_data_dir)
    file.remove(dest)
  }
}

download_data(covid_vax_adults_src, raw_data_dir)
download_data(covid_total_modzcta_src, raw_data_dir)
download_data(nyc_election_districts_src, raw_data_dir)
download_data(nyc_election_results_by_year, raw_data_dir)