prelim_data_dir <- paste(getwd(), "/prelim_data", sep = "")

vaccine_data <- read.csv(paste0(prelim_data_dir, "/coverage-by-modzcta-adults.csv"))
covid_data <- read.csv(paste0(prelim_data_dir, "/data-by-modzcta.csv"))