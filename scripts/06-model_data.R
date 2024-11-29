#### Preamble ####
# Purpose: Models... [...UPDATE THIS...]
# Author: Rohan Alexander [...UPDATE THIS...]
# Date: 11 February 2023 [...UPDATE THIS...]
# Contact: rohan.alexander@utoronto.ca [...UPDATE THIS...]
# License: MIT
# Pre-requisites: [...UPDATE THIS...]
# Any other information needed? [...UPDATE THIS...]


#### Workspace setup ####
library(tidyverse)
library(rstanarm)
library(arrow)

#### Read data ####
model_format <- read_parquet("data/02-analysis_data/model_format.parquet")

### Model data ####

did_model <- stan_glm(
  population ~ cd_occupied * district_type + 
    french_surrender * district_type + 
    is_occupied * district_type,
  data = model_format,
  family = gaussian(),  # Continuous dependent variable
  prior = normal(0, 10),  # Weakly informative prior
  prior_intercept = normal(0, 10),
  chains = 4, iter = 2000, seed = 123
)


#### Save model ####
saveRDS(
  did_model,
  file = "models/did_model.rds"
)


