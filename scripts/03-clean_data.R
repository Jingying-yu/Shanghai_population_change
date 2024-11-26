#### Preamble ####
# Purpose: Cleans the raw plane data recorded by two observers..... [...UPDATE THIS...]
# Author: Rohan Alexander [...UPDATE THIS...]
# Date: 6 April 2023 [...UPDATE THIS...]
# Contact: rohan.alexander@utoronto.ca [...UPDATE THIS...]
# License: MIT
# Pre-requisites: [...UPDATE THIS...]
# Any other information needed? [...UPDATE THIS...]

#### Workspace setup ####
library(tidyverse)
library(arrow)
library(dplyr)

#### Read Raw Data ####
pop_1852_1950 <- read_parquet(file.path("data/01-raw_data", "shanghai_population_1852_1950.parquet"))
refugees_data <- read_parquet(file.path("data/01-raw_data", "refugees_data.parquet"))


#### Clean data ####

#### Clean the Refugees Data ####
cleaned_refugees_data <- refugees_data |>
  as.data.frame() |>
  (\(df) df[, 1:6])() |>  # Keep only the first 6 columns
  (\(df) df[, -c(2, 4)])() |>  # Remove columns 2 and 4
  slice(-c(1:3)) |>  # Remove rows 1 to 3
  setNames(c("date", "is_refugees", "fc_refugees", "total")) |>  # Rename columns
  mutate(
    date = as.Date(as.numeric(date), origin = "1899-12-30"),  # Convert Excel serial numbers
  is_refugees = as.numeric(is_refugees), fc_refugees = as.numeric(fc_refugees)) |>
  mutate(
    across(c(is_refugees, fc_refugees, total), ~ replace_na(as.numeric(.), 0)) # treat NAs as 0
  )


#year_refugee_summary <- cleaned_refugees_data |>
#  group_by(date = as.numeric(format(date, "%Y"))) |>  # Group by year extracted from the `date` column
#  summarize(
#    total_is_refugees = sum(is_refugees, na.rm = TRUE),   # Summing `is_refugees`
#    total_fc_refugees = sum(fc_refugees, na.rm = TRUE)    # Summing `fc_refugees`
#  ) |>
#  mutate(
#    total_sum = total_is_refugees + total_fc_refugees     # Calculate the total column
#  ) |>
#  ungroup()

#### Clean the Population 1852-1950 Data ####





#### Save data ####
write_parquet(cleaned_pop_1852_1950, "data/02-analysis_data/pop_analysis_data.parquet")
