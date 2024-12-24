library(dplyr)

normalize_rates <- function(dataset) {
  # Convert case rates from rate/100_000 people to fraction between [0, 1]
  dataset <- dataset %>%
    mutate(across(
      c(
        "COVID_CONFIRMED_CASE_RATE",
        "COVID_CASE_RATE",
        "COVID_DEATH_RATE"
      ),
      ~ . / 100000
    )) %>%
    # Convert percentage vaccinated into fraction between [0, 1]
    mutate(across(
      c(
        "PERC_PARTIALLY",
        "PERC_FULLY",
        "PERC_1PLUS",
        "PERC_ADDITIONAL",
        "PERC_BIVALENT_ADDITIONAL"
      ),
      ~ . / 100
    )) %>%
    # Calculate fractions for two-party voting
    mutate(
      two_party_total = republican + democratic,
      republican_two_party_frac = republican / two_party_total,
      democrat_two_party_frac = 1 - republican_two_party_frac
    ) %>%
    # Replace NaN values with 0
    mutate(across(
      c(republican_two_party_frac, democrat_two_party_frac),
      ~ if_else(is.nan(.), 0, .)
    ))
  
  return(dataset)
}