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
  population ~ year + district_is + district_fc + cd_occupied * district_is + 
    cd_occupied * district_fc +
    french_surrender * district_is + 
    french_surrender * district_fc +
    is_occupied * district_is + 
    is_occupied * district_fc,
  data = model_format,
  family = gaussian(),  # Continuous dependent variable
  prior = normal(location = 0, scale = 2.5, autoscale = TRUE),
  prior_intercept = normal(0, 2.5, autoscale = TRUE),
  prior_aux = exponential(rate = 1, autoscale = TRUE),
  seed = 853
)







#### Save model ####
saveRDS(
  did_model,
  file = "models/did_model.rds"
)


