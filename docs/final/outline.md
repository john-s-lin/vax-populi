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

## Distributions and Maps of COVID Case Rates, Death Rates and Vaccinations

### Case rates

- Average case rate per district is approximately 0.4, so on average in NYC, every 2 out of 5 people would have had COVID at some point.
- Case counts did not exceed 50_000 cases per 100000 people so at the maximum, the case rate was 0.5.
- Looking at the map for case rate distribution, we see hot spots mainly located in Staten Island, as well as a hot spot in Midtown Manhattan, known to be highly dense due to tourist attractions and the like. Additionally, we see hot spots in Rockaway Beach at the southern border of Queens.
- [Image] COVID Case rate map gg 
- [Image] COVID case rate hist

### Death rates

- Death rate was very low, as evidenced by the fact that the average death rate is .5%
- Death rate is also relatively evenly spread across all districts, with the exception of isolated districts in southern Brooklyn and Queens
- [Image] Covid death rate hist
- [Image] COVID death rate map

### Vaccination rates

- Percentage of fully vaccinated rates in each district was very high, with many districts having greater than 2 doses that represent full vaccination.
- The average of fully vaccinated districts was 0.9. Many districts had above 1 for percentage fully vaccinated, which in this context represents those that exceeded 2 doses, which implies booster vaccinations.
- [Image] COVID vax hist
- [Image] COVID vax map

## Distributions of election results

### 2020

- For the most part, NYC is mostly left-leaning, with many districts with a higher democrat-republican voting ratio
- However, in staten island and southern brooklyn, there were more communities voting significantly to the right.
- [Image] Voting districts map

### 2024

- NYC shifted more towards the right in 2024, with more districts in norther Queens becoming conservative
- Additionally, the ratio of dem-reps decreased, with more voters voting republican
- Staten Island and South and central brooklyn became more conservative
- Likewise, Manhattan, Queens and the Bronx had a shift towards more conservative, while still having a higher Democrat voting ratio
- [Image] Voting districts map

## Correlations

### Political Alignment vs Case rate

- Democrats voters and case rate was negatively correlated with a correlation of -0.37, and a p-value of 1.13E-7 suggesting statistical significance.
- Republican voters were the inverse and showed positive correlation with case rates
- [Image] Correlation plot case rate 2020 vs dem frac
- In 2024, the correlation saw a slight decrease to -0.33 but still statistically significant
- [Image] Corr plot case rate vs dem frac 2024

### Political alignment vs Death rate

- Democrat voting fraction and death rate was also negatively correlated in 2020, with a p-value of 0.04, which is also statistically significant.
- [Image] corr plot death rate vs dem frac 2020
- In 2024, the correlation became stronger at -0.2395, with a p-value of 1.6e-3
- [Image] corr plot death rate vs dem frac 2024

### Political alignment vs Vaccinations

- There was no correlation between vaccination rate and election voting patterns as for both years, 2020 and 2024, the correlation was near 0.
- Suggests that regardless of voting tendencies, both cohorts had equal behaviour in vaccination
- [Image] corr plot vax rate vs dem frac 2020
- [Image] corr plot vax rate vs dem frac 2024

### Case rates vs Fully vaccinated

- There was a positive correlation between case rates and fully vaccinated cohorts at 0.33 with a p-value of 6.2e-06
- This does not mean that those that are fully vaccinated are more likely to contract COVID, but rather that the act of vaccination may play a role with putting oneself in riskier positions to contract COVID due to the protection that a vaccination may afford
- Additionally, the alternative is more likely, that case rates may affect the number of subsequent vaccinations in order to prevent future
- [Image] corr plot vax rates v case rate

### Case rates vs Death rate

- On the other hand, there was a negative correlation of death rate and fully vaccinated cohorts, with a correlation of -0.195 and a p-value of 0.0093.
- This is in-line with studies that show that vaccinations reduce severe symptoms ref: {ref}
- [Image] corr plot vax rates vs death rate

## Areal Analysis

### Moran's I

- [Table] Moran's I results Queen vs 6-NN vs IDW
    - Vax rate
    - Case rate
    - Death rate
    - Voting ratio 2020
    - Voting ratio 2024
- Observed that 6-NN is the best, followed by IDW
- Queen neighbors performed the worst, since some districts are spatially separated by water boundaries such as the Hudson and East Rivers

### Correlogram/Lag Structures for Moran's I with 6NN

- [Multifigure] - Lag plots
    - Case rates - up to lag 2
    - Death rates - up to lag 6
    - Vax rates - up to lag 2
    - Voting fraction 2020 - up to lag 3
    - Voting fraction 2024 - up to lag 3
- We see that there are neighbor effects for case rates up to lag 2
- Death rates, because the rate was so low, showed lag distance of 6 neighbors away, while case rates and vax rates were more autocorrelated within 1-2 lag distances away
- Lag distances for voting patterns were autocorrelated to 3 neighbors away

### Getis-Ord G-star

- [Image] Case rates show clustering of hot spots in midtown manhattan and staten island
- [Image] Death rates show clustering in southern Queens
- [Image] Vax rates also show hot spots in midtown Manhattan
- [Image] Political alignment for 2020 and 2024 show lots of clustering of republicans in southern Staten Island, Brooklyn and Queens, which migrate north in 2024

### SAR Lag-Error Model

- [Table] SAR Lag error model 
- Shows that case rate and vaccination rate capture most of the spatial behaviour but not voting behavior. P-value is not significant
- Taking a moran test of the residuals show no statistical significance, suggesting that case rates autoregressive effect has largely been captured
- AIC = 368

### CAR model

- [Table] CAR model
- Shows that vaccination rate and voting fractions do capture the behaviour of autoregression in COVID case rates
- The CAR model is substantially better than the SAR model with an AIC of -1681.7
- Well suited for irregular spatial layouts as seen in NY

# Conclusion

- We did not see that vaccination behaviour was affected by voting preferences
- However we did see that case rates and vaccination rates were affected by voting preferences
- There was an spatial component to this behaviour when it comes to case rates and vaccination rates, and especially voting behaviour
- This is just exploratory work and more work is needed to explore other demographic factors such as education level, wealth disparity, even gender differences on a municipal scale for COVID 19 metrics in the city of NY
- Ending on a high note