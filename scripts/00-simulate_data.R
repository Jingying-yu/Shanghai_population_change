#### Preamble ####
# Purpose: Simulates a dataset to fit into DiD model that evaluates the population between within districts in Shanghai between 1936-1942
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: The `tidyverse`, `dplyr`, and `arrow` packages must be installed
# Any other information needed? Make sure you are in the `starter_folder` rproj


#### Workspace setup ####
library(tidyverse)
library(dplyr)
library(arrow)


#### Simulate data ####
set.seed(21)

# Define years and districts
years <- 1936:1942
districts <- c("Chinese District", "International Settlement", "French Concession")

# Create a data frame for all combinations of year and district
simulated_data <- expand.grid(year = years, District = districts)

# Assign base population for 1936
simulated_data <- simulated_data |>
  mutate(
    Base_Population = case_when(
      District == "Chinese District" ~ 3000000,  # Base for CD
      District == "International Settlement" ~ 1500000,  # Base for IS
      District == "French Concession" ~ 600000  # Base for FC (~1/3 of IS)
    )
  )

# Add the effects of events with corrected is_occupied
simulated_data <- simulated_data |>
  mutate(
    cd_occupied = ifelse(year >= 1937, 1, 0),  # Event 1: 1937 Japanese occupation of CD
    french_surrender = ifelse(year >= 1940, 1, 0),  # Event 2: 1940 rejection of refugees in FC
    is_occupied = ifelse(year >= 1942, 1, 0),   # Event 3: 1942 Japanese occupation of IS
    Population_Change = case_when(
      District == "Chinese District" & cd_occupied == 1 ~ -500000 * (year - 1936), # CD population declines after 1937
      District == "International Settlement" & cd_occupied == 1 ~ 200000 * (year - 1936), # IS increases due to refugees
      District == "French Concession" & cd_occupied == 1 & french_surrender == 0 ~ 100000 * (year - 1936), # FC increases until 1940
      District == "French Concession" & french_surrender == 1 ~ -50000 * (year - 1939), # FC declines after 1940
      TRUE ~ 0 # No change otherwise
    ),
    Population = Base_Population + Population_Change # Total population
  ) |>
  mutate(District = as.character(District))

# Add dummy variables for district types
simulated_data <- simulated_data |>
  mutate(
    District_IS = ifelse(District == "International Settlement", 1, 0),
    District_FC = ifelse(District == "French Concession", 1, 0)
  )


#### Save data ####
write_parquet(simulated_data, "data/00-simulated_data/simulated_data.parquet")
