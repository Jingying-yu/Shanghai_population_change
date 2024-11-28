#### Preamble ####
# Purpose: Downloads and saves the data from Virtual Shanghai Research Data Portal.
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: Researched the data aspects necessary for the analysis and find reliable sources
# Data credibility is cross-referenced with scanned first-hand government written records in the 1930s-1940s
# shanghai_pop_1852-1950 dataset is pulled from page 91-91 of the reference text 《旧上海人口变迁的研究》with the help of the LLM ChatGPT 4o (and manually adjusted)
# PDF version of the reference text can be found in the other/literature section of the repository


#### Workspace setup ####
library(httr)
library(readxl)
library(arrow)

#### Download data ####
# Define output directory
output_dir <- "data/01-raw_data"

# File paths for the refugee data
refugee_xls_file <- file.path(output_dir, "refugees_data.xls")  # Refugee .xls file
refugee_parquet_file <- file.path(output_dir, "refugees_data.parquet")  # Refugee Parquet file


# File paths for the 1941-42 data
data_1941_42_xlsx_file <- file.path(output_dir, "1941_42.xlsx")  # 1941-42 .xlsx file
data_1941_42_parquet_file <- file.path(output_dir, "1941_42.parquet")  # 1941-42 Parquet file

#### Download and Process Refugee Data ####
# Download the refugee data
download.file(url = "https://www.virtualshanghai.net/Asset/Source/dbData_ID-35_No-01.xls",
              destfile = refugee_xls_file,
              mode = "wb")

# Read only the first sheet ("Data") from the refugee data
refugees_data <- read_excel(refugee_xls_file, sheet = "Data")


#### Download and Process 1941-42 Data ####
# Download the 1941-42 data
download.file(url = "https://www.virtualshanghai.net/Asset/Source/dbData_ID-46_No-01.xlsx",
              destfile = data_1941_42_xlsx_file,
              mode = "wb")

# Read the second sheet ("Data") from the 1941-42 data
data_1941_42 <- read_excel(data_1941_42_xlsx_file, sheet = "Data")


#### Save data ####
write_parquet(refugees_data, sink = refugee_parquet_file)
unlink(refugee_xls_file)

population_data <- read_excel("data/01-raw_data/shanghai_population_1852_1950.xlsx")
write_parquet(population_data, "data/01-raw_data/shanghai_population_1852_1950.parquet")

write_parquet(data_1941_42, sink = data_1941_42_parquet_file)
unlink(data_1941_42_xlsx_file)  # Delete the temporary .xlsx file
