# Potential Datasets

COVID Vaccination rate vs. Political Alignment
COVID Deaths vs. Political Alignment

## Datasets

- [NYC COVID Vaccinations](https://github.com/nychealth/covid-vaccine-data)
    - COVID Vaccine data
    - MODZCTA areal data
    - Age groups (18+/children)
    - Percentage 1-dose, fully immunized
    - Neighbourhoods
    - Absolute dosages
    - Contains Citywide Immunization Registry and Reporting data
- [NYC Political Districts](https://www.nyc.gov/site/planning/data-maps/open-data/districts-download-metadata.page)
    - Contains border boundaries for electoral districts
- [NYC Presidential Election Map 2020](https://toddwschneider.com/maps/nyc-presidential-election-results/#10.19/40.7053/-73.975), [Code and Data](https://github.com/toddwschneider/nyc-presidential-election-map)
    - Political boundaries
    - What each electoral division voted (Dem vs GOP)
    - Data from 2020 (during the COVID pandemic) as well as from 2024 (most recent)
    - topojson geographical polygons
    - electoral district numbers
- [NYC COVID Data (w/deaths)](https://github.com/nychealth/coronavirus-data)
    - Neighbourhoods
    - COVID confirmed case count
    - COVID confirmed case rate
    - COVID death count
    - COVID death rate
    - COVID probable case count
    - MODZCTA areal data

## Proposed Methods

### Correlation Analysis
To understand the relationship between political alignment and COVID-19 metrics, we will perform a correlation analysis. This involves:
- **Data Collection**: Gathering data from the NYC COVID Vaccinations, NYC COVID Data (w/deaths), and NYC Presidential Election Map 2020 datasets.
- **Data Cleaning**: Ensuring the datasets are clean and consistent, including handling missing values and normalizing data formats.
- **Data Integration**: Merging the datasets based on common geographic identifiers such as neighborhoods or electoral districts.
- **Statistical Analysis**: Using statistical methods to calculate correlation coefficients between political alignment (percentage of votes for Democratic vs. Republican candidates) and COVID-19 metrics (vaccination rates, infection rates, death rates).

### Conversion Between MODZCTA and Electoral Districts
To facilitate the analysis, we need to convert data organized by MODZCTA to electoral districts. This involves:
- **Mapping MODZCTA to Electoral Districts**: Creating a mapping between MODZCTA areas and electoral districts using geographic information system (GIS) tools.
- **Data Transformation**: Aggregating or disaggregating data as necessary to align with the new geographic boundaries.
- **Validation**: Ensuring the accuracy of the conversion by cross-referencing with official boundary definitions and sample data points.

### Autocorrelation Modelling
To account for spatial dependencies in the data, we will use autocorrelation modelling. This involves:
- **Spatial Autocorrelation Analysis**: Measuring the degree to which COVID-19 metrics in one area are similar to those in nearby areas using metrics such as Moran's I.
- **Model Development**: Developing spatial regression models that incorporate autocorrelation to better understand the influence of political alignment on COVID-19 outcomes.
- **Model Validation**: Validating the models using techniques such as cross-validation and assessing their predictive performance.

### Additional Analyses
Depending on the initial findings, we may conduct additional analyses, such as:
- **Time Series Analysis**: Examining how the relationships between political alignment and COVID-19 metrics evolve over time.
- **Demographic Analysis**: Investigating how demographic factors (e.g., age, income, race) interact with political alignment and COVID-19 metrics.
- **Policy Impact Analysis**: Assessing the impact of public health policies on the observed relationships.

By employing these methods, we aim to uncover meaningful insights into how political alignment may influence or be influenced by COVID-19 vaccination rates, infection rates, and death rates across New York City.