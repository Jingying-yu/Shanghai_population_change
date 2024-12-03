#### Preamble ####
# Purpose: Cleans the raw Shanghai population data
# Author: Sandy Yu
# Date: 16 November 2024
# Contact: jingying.yu@mail.utoronto.ca
# License: MIT
# Pre-requisites: obtained raw data and created simulated plan of data


#### Workspace setup ####
library(tidyverse)
library(arrow)
library(dplyr)

#### Read Raw Data ####
pop_1852_1950 <- read_parquet(file.path("data/01-raw_data", "shanghai_population_1852_1950.parquet"))
refugees_data <- read_parquet(file.path("data/01-raw_data", "refugees_data.parquet"))
pop_1941_42 <- read_parquet(file.path("data/01-raw_data", "1941_42.parquet"))


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



# Get a year end summary for refugges within each district
# Ensure 'date' column is in Date format
year_refugees_data <- cleaned_refugees_data |>
  mutate(date = as.Date(date))

# Manually select rows for 'is_refugees' and 'fc_refugees'


manual_is_refugees <- year_refugees_data %>%
  filter(date %in% as.Date(c("1937-12-14", "1938-12-29", "1939-10-04", 
                             "1940-12-18", "1941-08-15", "1942-10-01"))) %>%
  mutate(year = format(date, "%Y")) %>%
  select(date, year, is_refugees)

manual_fc_refugees <- year_refugees_data %>%
  filter(date %in% as.Date(c("1937-12-14", "1938-10-23", "1939-06-20", 
                             "1940-12-18", "1941-08-15", "1942-10-01"))) %>%
  mutate(year = format(date, "%Y")) %>%
  select(date, year, fc_refugees)


# Combine the manually selected data
year_refugee_summary <- manual_is_refugees |>
  left_join(manual_fc_refugees, by = "year")

# Keep only year, is_refugees, and fc_refugees
year_refugee_summary <- year_refugee_summary |>
  select(year, is_refugees, fc_refugees)



#### Clean the Population 1852-1950 Data ####
pop_36_42 <- pop_1852_1950[1:29,] |>
  janitor::clean_names() |>
  mutate(year = as.numeric(year)) |>
  filter(year >= 1936 & year <= 1942)



#### Clean pop_1941_42 Data ####
pop_1941_42 <- pop_1941_42 |>
  mutate(
    category = case_when(
      District %in% c("Baoshan", "Beiqiao", "Chongming", "Chuansha", "Fengxian", 
                      "Jiading", "Minhang", "Nanhui", "Pudong", "Yangsi", "Yimiao", "Yulin") ~ "Chinese-administered area",
      District %in% c("Zhabei", "Shizhongxin", "Hubei", "Huxi", "Zhonghua") ~ "International Settlement",
      District %in% c("Xuhui", "Xieqiao", "Yulin", "Gaoqiao") ~ "French Concession",
      TRUE ~ "Unknown"  # For districts not listed in the above categories
    )
  )

cleaned_pop_1941_42 <- pop_1941_42 |>
  janitor::clean_names() |>
  select(2, 5, 10, category) |>  # Select columns 2, 5, and 10
  slice(-1, -2) |>
  rename(pop_1941 = x1941, pop_1942 = x1942_10) |>
  tidyr::drop_na() |> #Beiqiao District in Chinese District does not have any data, will adjust the pop value using pop_36_42 dataset
  mutate(pop_1941 = as.numeric(pop_1941), pop_1942 = as.numeric(pop_1942))

summary_41_42 <- cleaned_pop_1941_42 |>
  group_by(category) |>
  summarise(pop_1941 = sum(pop_1941),
            pop_1942 = sum(pop_1942))




#### Combined Data ####

### Use data from year_refugee_summary to get more accurate estimation of missing data in 1938 & 1939
# Create new rows for 1938 and 1939
year38_39 <- data.frame(
  year = c(1938, 1939),
  chinese_population = rep(pop_36_42$chinese_population[pop_36_42$year == 1937], 2),
  public_settlement_population = rep(pop_36_42$public_settlement_population[pop_36_42$year == 1937], 2),
  french_concession_population = rep(pop_36_42$french_concession_population[pop_36_42$year == 1937], 2),
  total_population = rep(pop_36_42$total_population[pop_36_42$year == 1937], 2)
)

# Combine the new rows with the original dataset
combined_data <- rbind(
  pop_36_42[1:2, ],  # Keep rows before 1938
  year38_39,          # Add the new rows
  pop_36_42[3:nrow(pop_36_42), ]  # Keep rows after 1939
) |>
  rename(chn_admin_pop = chinese_population, is_pop = public_settlement_population, fc_pop = french_concession_population) |>
  select(year, chn_admin_pop, is_pop, fc_pop)

# add refugee values for 1938 & 1939 on top of 1937 pop value in International Settlement & French Concession
# International (Public) Settlement
combined_data[combined_data$year == 1938, "is_pop"] <- 
  (combined_data[combined_data$year == 1937, "is_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1938, "is_refugees"])

combined_data[combined_data$year == 1939, "is_pop"] <- 
  (combined_data[combined_data$year == 1937, "is_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1939, "is_refugees"])

combined_data[combined_data$year == 1940, "is_pop"] <- 
  (combined_data[combined_data$year == 1937, "is_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1940, "is_refugees"])


# French Concession
combined_data[combined_data$year == 1938, "fc_pop"] <- 
  (combined_data[combined_data$year == 1937, "fc_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1938, "fc_refugees"])


combined_data[combined_data$year == 1939, "fc_pop"] <- 
  (combined_data[combined_data$year == 1937, "fc_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1939, "fc_refugees"])

combined_data[combined_data$year == 1940, "fc_pop"] <- 
  (combined_data[combined_data$year == 1937, "fc_pop"] + 
     year_refugee_summary[year_refugee_summary$year == 1940, "fc_refugees"])

#Chinese District
# pop value for Chinese district in 1938 & 1939 will just be  1937 - total # of refugees in IS & FC since there is no data record
combined_data[combined_data$year == 1938, "chn_admin_pop"] <- 
  (combined_data[combined_data$year == 1937, "chn_admin_pop"] - 
     year_refugee_summary[year_refugee_summary$year == 1938, "is_refugees"] -
     year_refugee_summary[year_refugee_summary$year == 1938, "fc_refugees"])

combined_data[combined_data$year == 1939, "chn_admin_pop"] <- 
  (combined_data[combined_data$year == 1937, "chn_admin_pop"] - 
     year_refugee_summary[year_refugee_summary$year == 1939, "is_refugees"] -
     year_refugee_summary[year_refugee_summary$year == 1939, "fc_refugees"])


### Use summary_41_42 to estimate 1941 values
# use 1942 value in the existing combined_data dataset to calibrate the 1941 values
calibration_percent <- summary_41_42 |>
  mutate(percentage_adjusted = c(as.numeric(combined_data[combined_data$year == 1942, "chn_admin_pop"]/summary_41_42[1, "pop_1942"]),
                                 as.numeric(combined_data[combined_data$year == 1942, "fc_pop"]/summary_41_42[2, "pop_1942"]),
                                 as.numeric(combined_data[combined_data$year == 1942, "is_pop"]/summary_41_42[3, "pop_1942"])))
  

adjusted_summary_41 <- calibration_percent |>
  mutate(percentage_adjusted = as.numeric(percentage_adjusted)) |>
  mutate(pop_1941 = pop_1941 * percentage_adjusted) |>
  select(category, pop_1941)

year41 <- data.frame(
  year = 1941,
  chn_admin_pop = adjusted_summary_41[adjusted_summary_41$category == "Chinese-administered area", "pop_1941"],
  is_pop = adjusted_summary_41[adjusted_summary_41$category == "International Settlement", "pop_1941"],
  fc_pop = adjusted_summary_41[adjusted_summary_41$category == "French Concession", "pop_1941"]) |>
  rename(chn_admin_pop = pop_1941,
         is_pop = pop_1941.1,
         fc_pop = pop_1941.2) |>
  mutate(chn_admin_pop = as.integer(chn_admin_pop), is_pop = as.integer(is_pop), fc_pop = as.integer(fc_pop))

combined_data <- rbind(
  combined_data[1:5, ],  # Keep rows before 1938
  year41,          # Add the new rows
  combined_data[6, ]  # Keep rows after 1939
)


# Reshape the final combined_data into model-friendly format
model_format <- combined_data |>
  pivot_longer(
    cols = c(chn_admin_pop, is_pop, fc_pop),
    names_to = "district_type",
    values_to = "population"
  ) |>
  mutate(
    # Create a categorical variable for district type
    district_type = case_when(
      district_type == "chn_admin_pop" ~ "Chinese-administered area",
      district_type == "is_pop" ~ "International Settlement",
      district_type == "fc_pop" ~ "French Concession")) |> 
  mutate(cd_occupied = ifelse(year >= 1937, 1, 0),  # Event 1: Japanese occupation of CD
         french_surrender = ifelse(year >= 1940, 1, 0),  # Event 2: Rejection of refugees in FC
         is_occupied = ifelse(year >= 1942, 1, 0)) |> # Event 3: Japanese occupation of IS
  mutate(district_is = ifelse(district_type == "International Settlement", 1, 0),  # Dummy for IS
         district_fc = ifelse(district_type == "French Concession", 1, 0)) |>         # Dummy for FC
  mutate(district_type = as.factor(district_type))  # Ensure District is a factor


#### Save data ####
write_parquet(pop_1852_1950, "data/02-analysis_data/pop_analysis_data.parquet")
write_parquet(year_refugee_summary, "data/02-analysis_data/year_refugee_summary.parquet")
write_parquet(calibration_percent, "data/02-analysis_data/calibration_percent.parquet")
write_parquet(model_format, "data/02-analysis_data/model_format.parquet")

