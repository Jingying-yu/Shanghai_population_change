#### Preamble ####
# Purpose: Downloads and saves the data from Virtual Shanghai Research Data Portal.
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: Researched the data aspects necessary for the analysis and find relable sources
# Data credibility is cross-referenced with scanned first-hand government written records in the 1930s-1940s


#### Workspace setup ####
library(httr)
library(readxl)
library(arrow)
library(fs)

#### Download data ####

# Define URLs and corresponding file names
urls <- c(
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-103_No-01.xlsx",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-101_No-01.xlsx",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-35_No-01.xls",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-94_No-01.xlsx",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-77_No-01.xlsx",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-153_No-01.xlsx",
  "https://www.virtualshanghai.net/Asset/Source/dbData_ID-46_No-01.xlsx"
)

file_names <- c(
  "1936_pop_density",
  "1936_chn_pop",
  "1937-44_settlements",
  "1942_foreign_origin",
  "1942_chn_origin",
  "1942_pop_count_int",
  "1941-43_pop"
)

# Define the output directory for Parquet files
output_dir <- "data/01-raw_data"
metadata_dir <- file.path(output_dir, "metadata")
dir_create(metadata_dir)  # Create the metadata directory

# Process each URL
for (i in seq_along(urls)) {
  # Download the file to a temporary location
  temp_file <- tempfile(fileext = ifelse(grepl("\\.xls$", urls[i]), ".xls", ".xlsx"))
  download.file(urls[i], destfile = temp_file, mode = "wb")
  message(paste("Downloaded to temporary file:", temp_file))
  
  # Get the list of sheet names
  sheet_names <- excel_sheets(temp_file)
  
  # Iterate through each sheet and save as a separate Parquet file
  for (sheet in sheet_names) {
    # Read the data from the sheet
    data <- read_excel(temp_file, sheet = sheet)
    
    # Create the Parquet file name with the sheet name as a lowercase prefix
    sheet_prefix <- tolower(sheet)
    parquet_file <- file.path(output_dir, paste0("raw_", sheet_prefix, "_", file_names[i], ".parquet"))
    
    # Write to Parquet
    write_parquet(data, sink = parquet_file)
    message(paste("Saved sheet", sheet, "to Parquet file:", parquet_file))
  }
  
  # Remove the temporary file
  unlink(temp_file)
}



#### Move Metadata into new folder ####
# Get a list of all files in the main directory
all_files <- list.files(output_dir, pattern = "\\.parquet$", full.names = TRUE)

# Filter files containing "metadata" in their names
metadata_files <- all_files[grepl("metadata", basename(all_files), "metadata")]

# Move the metadata files to the metadata directory
for (file in metadata_files) {
  new_location <- file.path(metadata_dir, basename(file))
  file_move(file, new_location)
  message(paste("Moved:", basename(file), "to", new_location))
}


