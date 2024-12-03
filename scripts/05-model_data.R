#### Preamble ####
# Purpose: use analysis data to model for relationship between variables
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: have sufficient modelling knowledge to understand which model to use, and has obtained cleaned data



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


