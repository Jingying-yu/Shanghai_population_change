#### Preamble ####
# Purpose: Tests the structure and validity of the simulated simulated_data
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: 
  # - The `tidyverse` package must be installed and loaded
  # - 00-simulate_data.R must have been run


#### Workspace setup ####
library(tidyverse)
library(arrow)

simulated_data <- read_parquet("data/00-simulated_data/simulated_data.parquet")

# Test if the data was successfully loaded
if (exists("simulated_data")) {
  message("Test Passed: The simulated_data was successfully loaded.")
} else {
  stop("Test Failed: The simulated_data could not be loaded.")
}


#### Test data ####
# Test 1: Check if the simulated_data has the correct number of rows
expected_rows <- length(years) * length(districts)
if (nrow(simulated_data) == expected_rows) {
  message("Test Passed: The simulated_data has the correct number of rows.")
} else {
  stop("Test Failed: The simulated_data does not have the correct number of rows.")
}

# Test 2: Check if the simulated_data has the correct number of columns
expected_columns <- 10  # Adjust based on the simulated_data structure
if (ncol(simulated_data) == expected_columns) {
  message("Test Passed: The simulated_data has the correct number of columns.")
} else {
  stop("Test Failed: The simulated_data does not have the correct number of columns.")
}

# Test 3: Check for missing values in any column
if (all(complete.cases(simulated_data))) {
  message("Test Passed: There are no missing values in the simulated_data.")
} else {
  stop("Test Failed: There are missing values in the simulated_data.")
}

# Test 4: Verify the year range
expected_years <- 1936:1942
if (all(simulated_data$Year %in% expected_years)) {
  message("Test Passed: The year range is correct.")
} else {
  stop("Test Failed: The year range is not correct.")
}

# Test 5: Check the data types of specific columns
if (is.numeric(simulated_data$Year)) {
  message("Test Passed: 'Year' is numeric.")
} else {
  stop("Test Failed: 'Year' is not numeric.")
}

if (is.character(simulated_data$District)) {
  message("Test Passed: 'District' is character.")
} else {
  stop("Test Failed: 'District' is not character.")
}

if (is.numeric(simulated_data$Population)) {
  message("Test Passed: 'Population' is numeric.")
} else {
  stop("Test Failed: 'Population' is not numeric.")
}

# Test 6: Verify the values in the 'District' column
expected_districts <- c("Chinese District", "International Settlement", "French Concession")
if (all(simulated_data$District %in% expected_districts)) {
  message("Test Passed: The 'District' column has valid values.")
} else {
  stop("Test Failed: The 'District' column has invalid values.")
}

# Test 7: Check if 'cd_occupied', 'french_surrender', and 'is_occupied' are binary
binary_columns <- c("cd_occupied", "french_surrender", "is_occupied")
for (col in binary_columns) {
  if (all(simulated_data[[col]] %in% c(0, 1))) {
    message(paste("Test Passed:", col, "is binary."))
  } else {
    stop(paste("Test Failed:", col, "is not binary."))
  }
}

# Test 8: Verify no negative values in 'Population'
if (all(simulated_data$Population >= 0)) {
  message("Test Passed: 'Population' has no negative values.")
} else {
  stop("Test Failed: 'Population' contains negative values.")
}


# Test 9: Verify that population change is zero for 1936
if (all(simulated_data$Population_Change[simulated_data$Year == 1936] == 0)) {
  message("Test Passed: 'Population_Change' is zero for 1936.")
} else {
  stop("Test Failed: 'Population_Change' is not zero for 1936.")
}
