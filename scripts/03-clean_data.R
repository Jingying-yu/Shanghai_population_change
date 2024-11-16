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

#### Read Raw Data ####
# Define the main output directory and metadata subdirectory
output_dir <- "data/01-raw_data"
metadata_dir <- file.path(output_dir, "metadata")

# Get a list of all Parquet files in the output directory and metadata subdirectory
main_files <- list.files(output_dir, pattern = "\\.parquet$", full.names = TRUE)
metadata_files <- list.files(metadata_dir, pattern = "\\.parquet$", full.names = TRUE)

# Combine file lists
all_files <- c(main_files, metadata_files)

# Read each Parquet file and assign it to the environment with a clean name
for (file in all_files) {
  # Create a clean name for the data frame (remove directory and extension)
  data_name <- tools::file_path_sans_ext(basename(file))
  
  # Read the Parquet file and assign it to the global environment
  assign(data_name, read_parquet(file), envir = .GlobalEnv)
  
  message(paste("Loaded Parquet file:", file, "as", data_name))
}


#### Clean data ####
# Remember to remove datasheet without any observations!


cleaned_data <-
  raw_data |>
  janitor::clean_names() |>
  select(wing_width_mm, wing_length_mm, flying_time_sec_first_timer) |>
  filter(wing_width_mm != "caw") |>
  mutate(
    flying_time_sec_first_timer = if_else(flying_time_sec_first_timer == "1,35",
                                   "1.35",
                                   flying_time_sec_first_timer)
  ) |>
  mutate(wing_width_mm = if_else(wing_width_mm == "490",
                                 "49",
                                 wing_width_mm)) |>
  mutate(wing_width_mm = if_else(wing_width_mm == "6",
                                 "60",
                                 wing_width_mm)) |>
  mutate(
    wing_width_mm = as.numeric(wing_width_mm),
    wing_length_mm = as.numeric(wing_length_mm),
    flying_time_sec_first_timer = as.numeric(flying_time_sec_first_timer)
  ) |>
  rename(flying_time = flying_time_sec_first_timer,
         width = wing_width_mm,
         length = wing_length_mm
         ) |> 
  tidyr::drop_na()

#### Save data ####
write_csv(cleaned_data, "outputs/data/analysis_data.csv")
