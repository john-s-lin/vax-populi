# Introduction

- COVID-19 affected communities across the globe with wide-reaching impacts
- However, did it effect every cohort equally?
- Why we chose New York:
    - It was a microcosm of various demographic and cultural differences
    - Well connected through public transit and other transport options
    - Distinct communities
- Recent 2024 US election shows heightened polarity on various issues
    - Including on healthcare administration and policy
- Does political affiliation stratify health outcomes as it appears in COVID-19?
    - Anti-vaccination movement - is it a political issue?
- Here we examine COVID-19 outcomes, including case rates, vaccination rates and death rates in NYC neighborhoods
    - vs. election voting ratios per district for 2020 and 2024 elections
- Hope to uncover patterns that highlight issues in public health in diverse urban populations

# Methods

## Datasets

### NYC COVID Data

- NYC COVID dataset is publicly available on GitHub
- Maintained by the NYC Department of Health.
- Uses Modified Zip Code Tabulation Areas (MODZCTA) for spatial data
- Contains cumulative data including
    - Case counts
    - Case rates per 100_000 residents
    - Death counts
    - Death rates per 100_000 residents
- We do a little post-processing to convert case rates and death rates to a floating-point number between [0, 1]. 
- This allows cases to be represented as percentages of the total population in that neighborhood

### NYC COVID Vaccination Data

- NYC COVID vaccination data is publicly available on GitHub
- Maintained by the NYC Department of Health
- Uses MODZCTA also
- Contains cumulative data of vaccination rates as percentages of the total population per neighborhood
- Contains stratified data including those vaccinated with only a first dose, those who are fully vaccinated (2 or more doses), and those with additional doses (>2 doses)
- Here we will focus on those fully vaccinated (2 or more doses) based on popular policy that a full vaccination program consists of an initial and a booster vaccination

### NYC Electoral Districts

- Electoral districts are divided to 4345 distinct regions in NY
- Shapefile with polygon geometry
- Maintained by the NYC Department of City Planning

### NYC Election Results 2020/2024

- Author: Todd W. Schneider
- Available on GitHub, matched with electoral district codes
- With 2016, 2020 and 2024 election results
- Focus on 2020 since that is COVID at its peak
- But also see if voting patterns changed or if correlations remain consistent over time

## Data transformation and cleaning

- Most computationally intensive part
- [Image] MODZCTA - 177 regions
- [Image] Electoral districts - 4345 districts
- st_join cover combined them into a polygon map with 177 regions, fitting almost exactly the MODZCTA region
- [Image] Merged map - 177 regions
- COVID data is joined by MODZCTA ID
- Election data is joined by electoral district ID
- Then election data is filtered by year
- Merged
- For certain studies, NaN rows are dropped
- Rates are normalized to floats between 0 and 1

## Visualizing distributions

- Histograms showing distributions of
    - Case rates per district
    - Death rates per district
    - Vaccination rates per district
    - Proportion democratic voters 2020/2024
    - Proportion republican voters 2020/2024

## Visualizing distributions on a map

- Mapping the distributions we can also at a glance see the density of the proportion of the population of each targeted feature
- This is especially important for electoral districts, since the overlaid polygons should accumulate results from separate electoral divisions

## Correlation statistics

- Correlations between COVID metrics and election results were plotted
    - COVID case rate vs. voting fraction (2020, 2024)
    - COVID death rate vs. voting fraction (2020, 2024)
    - COVID vax rate vs. voting fraction (2020, 2024)
    - COVID vax rate vs case rates
    - COVID vax rate vs death rates

## Areal statistics

- Moran's I calculated
    - 6NN
    - Queen
    - IDW
- Best neighbor metrics used for subsequent analysis
- Correlograms are generated to view autocorrelative effects across neighboring regions
- Getis-Ord Gi Star is calculated
    - What does Getis-Ord do?
- SAR model with spatial lag-errors on case rates vs vax and political alignment
    - What does the SAR model do?
- CAR model with case rates vs vax and political alignment.
    - What does the CAR model do?

# Results

# Conclusion