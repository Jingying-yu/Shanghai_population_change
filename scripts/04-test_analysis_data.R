#### Preamble ####
# Purpose: Tests... [...UPDATE THIS...]
# Author: Rohan Alexander [...UPDATE THIS...]
# Date: 26 September 2024 [...UPDATE THIS...]
# Contact: rohan.alexander@utoronto.ca [...UPDATE THIS...]
# License: MIT
# Pre-requisites: [...UPDATE THIS...]
# Any other information needed? [...UPDATE THIS...]


#### Workspace setup ####
model_format <- read_parquet("data/02-analysis_data/model_format.parquet")
year_refugee_summary <- read_parquet("data/02-analysis_data/year_refugee_summary.parquet")
calibration_percent <- read_parquet("data/02-analysis_data/calibration_percent.parquet")

library(tidyverse)
library(testthat)
library(arrow)

#### Test data ####

## Basic Tests
test_that("year column contains only values from 1936 to 1942", {
  expect_true(all(model_format$year >= 1936 & model_format$year <= 1942))
})

test_that("there are no missing values in the dataset", {
  expect_true(all(complete.cases(model_format)))
})

test_that("district_type has only three unique values and each appears the same amount of times", {
  unique_districts <- unique(model_format$district_type)
  expect_length(unique_districts, 3)
  
  # Check that each district appears the same number of times
  district_counts <- table(model_format$district_type)
  expect_true(all(district_counts == district_counts[1]))
})


test_that("class type for each column is appropriate", {
  expect_type(model_format$year, "double")
  expect_type(model_format$district_type, "character")
  expect_type(model_format$population, "double")
  expect_type(model_format$cd_occupied, "double")
  expect_type(model_format$french_surrender, "double")
  expect_type(model_format$is_occupied, "double")
})



## Test that missing value in initial model_format dataset has been calibrated correctly with the help of other datasets
# Test for 1938: Chinese-administered area
test_that("1938 population for Chinese-administered area is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "Chinese-administered area") |>
    pull(population)
  
  is_refugees <- year_refugee_summary |>
    filter(year == 1938) |>
    pull(is_refugees)
  
  fc_refugees <- year_refugee_summary |>
    filter(year == 1938) |>
    pull(fc_refugees)
  
  expected_pop <- base_pop - (is_refugees + fc_refugees)
  actual_pop <- model_format |>
    filter(year == 1938, district_type == "Chinese-administered area") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})


# Test for 1938: International Settlement
test_that("1938 population for International Settlement is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "International Settlement") |>
    pull(population)
  
  is_refugees <- year_refugee_summary |>
    filter(year == 1938) |>
    pull(is_refugees)
  
  expected_pop <- base_pop + is_refugees
  actual_pop <- model_format |>
    filter(year == 1938, district_type == "International Settlement") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})

# Test for 1938: French Concession
test_that("1938 population for French Concession is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "French Concession") |>
    pull(population)
  
  fc_refugees <- year_refugee_summary |>
    filter(year == 1938) |>
    pull(fc_refugees)
  
  expected_pop <- base_pop + fc_refugees
  actual_pop <- model_format |>
    filter(year == 1938, district_type == "French Concession") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})

# Test for 1939: Chinese-administered area
test_that("1939 population for Chinese-administered area is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "Chinese-administered area") |>
    pull(population)
  
  is_refugees <- year_refugee_summary |>
    filter(year == 1939) |>
    pull(is_refugees)
  
  fc_refugees <- year_refugee_summary |>
    filter(year == 1939) |>
    pull(fc_refugees)
  
  expected_pop <- base_pop - (is_refugees + fc_refugees)
  actual_pop <- model_format |>
    filter(year == 1939, district_type == "Chinese-administered area") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})

# Test for 1939: International Settlement
test_that("1939 population for International Settlement is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "International Settlement") |>
    pull(population)
  
  is_refugees <- year_refugee_summary |>
    filter(year == 1939) |>
    pull(is_refugees)
  
  expected_pop <- base_pop + is_refugees
  actual_pop <- model_format |>
    filter(year == 1939, district_type == "International Settlement") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})

# Test for 1939: French Concession
test_that("1939 population for French Concession is correct", {
  base_pop <- model_format |>
    filter(year == 1937, district_type == "French Concession") |>
    pull(population)
  
  fc_refugees <- year_refugee_summary |>
    filter(year == 1939) |>
    pull(fc_refugees)
  
  expected_pop <- base_pop + fc_refugees
  actual_pop <- model_format |>
    filter(year == 1939, district_type == "French Concession") |>
    pull(population)
  
  expect_equal(actual_pop, expected_pop)
})

# Test for 1941 value
test_that("value in 1941 matches pop_1941 * percentage_adjusted from calibration_percent", {
  for (district in unique(model_format$district_type)) {
    pop_1941 <- calibration_percent |>
      filter(category == district) |>
      pull(pop_1941)
    
    percentage_adjusted <- calibration_percent |>
      filter(category == district) |>
      pull(percentage_adjusted)
    
    expected_value <- pop_1941 * percentage_adjusted
    actual_value <- model_format |>
      filter(year == 1941, district_type == district) |>
      pull(population)
    
    expect_true(abs(actual_value - expected_value) < 1) #allow for some rounding difference
  }
})

