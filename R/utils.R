library(dplyr)

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