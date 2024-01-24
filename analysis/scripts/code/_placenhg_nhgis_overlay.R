###################################################################################
# Clear working directory/RAM
rm(list=ls())
#########################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(haven, tidyverse, sf)

###################################################################################

# Extract southern US states from NHGIS county boundary file
nhgis_1940 <- st_read(paste0(
                      "analysis/raw/nhgis/",
                      "nhgis0033_shapefile_tl2000_us_county_1940/",
                      "US_county_1940.shp"),
                      quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    statefip = as.numeric(str_sub(state, 1, 2)),
    gisjoin = as.character(gisjoin)
  ) %>%
  filter(statefip %in% c(37)) %>%
  select(statefip, countyicp = icpsrctyi, county = nhgisnam, gisjoin)

nhgis_1930 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0033_shapefile_tl2000_us_county_1930/",
  "US_county_1930.shp"),
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    statefip = as.numeric(str_sub(state, 1, 2)),
    gisjoin = as.character(gisjoin)
  ) %>%
  filter(statefip %in% c(37)) %>%
  select(statefip, countyicp = icpsrctyi, county = nhgisnam, gisjoin)

nhgis_1920 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0033_shapefile_tl2000_us_county_1920/",
  "US_county_1920.shp"),
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    statefip = as.numeric(str_sub(state, 1, 2)),
    gisjoin = as.character(gisjoin)
  ) %>%
  filter(statefip %in% c(37)) %>%
  select(statefip, countyicp = icpsrctyi, county = nhgisnam, gisjoin)

nhgis_1910 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0033_shapefile_tl2000_us_county_1910/",
  "US_county_1910.shp"),
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    statefip = as.numeric(str_sub(state, 1, 2)),
    gisjoin = as.character(gisjoin)
  ) %>%
  filter(statefip %in% c(37)) %>%
  select(statefip, countyicp = icpsrctyi, county = nhgisnam, gisjoin)

# Load place points data with placenhg variable
# https://www.nhgis.org/documentation/gis-data/place-points
placenhg_1940 <- st_read(paste0(
                        "analysis/raw/nhgis/",
                        "nhgis0034_shapefile_tlgnis_us_place_point_1940/",
                        "US_place_point_1940.shp"), 
                        quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    state_id = as.numeric(str_sub(nhgisst, 1, 2)),
  ) %>%
  filter(state_id %in% c(37)) %>%
  select(state, state_id, stdcity = name, placenhg = nhgisplace)

placenhg_1930 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0035_shapefile_tlgnis_us_place_point_1930/",
  "US_place_point_1930.shp"), 
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    state_id = as.numeric(str_sub(nhgisst, 1, 2)),
  ) %>%
  filter(state_id %in% c(37)) %>%
  select(state, state_id, stdcity = name, placenhg = nhgisplace)

placenhg_1920 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0035_shapefile_tlgnis_us_place_point_1920/",
  "US_place_point_1920.shp"), 
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    state_id = as.numeric(str_sub(nhgisst, 1, 2)),
  ) %>%
  filter(state_id %in% c(37)) %>%
  select(state, state_id, stdcity = name, placenhg = nhgisplace)

placenhg_1910 <- st_read(paste0(
  "analysis/raw/nhgis/",
  "nhgis0036_shapefile_tlgnis_us_place_point_1910/",
  "US_place_point_1910.shp"), 
  quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    state_id = as.numeric(str_sub(nhgisst, 1, 2)),
  ) %>%
  filter(state_id %in% c(37)) %>%
  select(state, state_id, stdcity = name, placenhg = nhgisplace)

# Get list of unique state FIPS codes
states <- c(37)

# Function that extract IDs from coordinate and boundary data corresponding to closest county for each coordinate
create_xwk <- function(i, data, boundary, xwk){
  bind_cols(
    st_drop_geometry(data[i,]), 
    st_drop_geometry(boundary[xwk[i],])
  )
}

# Function that finds nearest county for each coordinate from state i in input data
st_coord2cty <- function(i, data, boundary){
  # Subset data to states
  st_data <- data %>% filter(state_id == i)
  st_boundary <- boundary %>% filter(statefip == i)
  # Find nearest county
  closest_cty <- st_nearest_feature(st_data, st_boundary)
  
  coord_nhgis_xwk <- map_dfr(seq_len(nrow(st_data)), .f = create_xwk, data = st_data, boundary = st_boundary, xwk = closest_cty) %>%
    mutate(fips = statefip*10000 + countyicp) %>%
    distinct() %>%
    filter(statefip == state_id) %>%
    select(!state_id)

}

# Save counties assigned to GNIS coordinates
placenhg_nhgis_xwk_1940 <- map_dfr(states, .f = st_coord2cty, data = placenhg_1940, boundary = nhgis_1940)
write_dta(placenhg_nhgis_xwk_1940,paste0("analysis/processed/temp/placenhg_nhgis_xwk_1940.dta"), version = 15)

placenhg_nhgis_xwk_1930 <- map_dfr(states, .f = st_coord2cty, data = placenhg_1930, boundary = nhgis_1930)
write_dta(placenhg_nhgis_xwk_1930,paste0("analysis/processed/temp/placenhg_nhgis_xwk_1930.dta"), version = 15)

placenhg_nhgis_xwk_1920 <- map_dfr(states, .f = st_coord2cty, data = placenhg_1920, boundary = nhgis_1920)
write_dta(placenhg_nhgis_xwk_1920,paste0("analysis/processed/temp/placenhg_nhgis_xwk_1920.dta"), version = 15)

placenhg_nhgis_xwk_1910 <- map_dfr(states, .f = st_coord2cty, data = placenhg_1910, boundary = nhgis_1910)
write_dta(placenhg_nhgis_xwk_1910,paste0("analysis/processed/temp/placenhg_nhgis_xwk_1910.dta"), version = 15)
