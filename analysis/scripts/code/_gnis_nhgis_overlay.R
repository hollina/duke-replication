###################################################################################
# Clear working directory/RAM
rm(list=ls())
###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(haven, tidyverse, sf)
###################################################################################

# Extract southern US states from NHGIS county boundary file
nhgis_1920 <- st_read(paste0("analysis/raw/nhgis/nhgis0033_shapefile_tl2000_us_county_1920/US_county_1920.shp"), quiet = FALSE) %>%
  rename_all(tolower) %>%
  mutate(
    statefip = as.numeric(str_sub(state,1,2)),
    gisjoin = as.character(gisjoin)
  ) %>%
  filter(statefip %in% c(37)) %>%
  select(statefip, countyicp = icpsrctyi, gisjoin)

# Get CRS from NHGIS data
nhgis_crs <- st_crs(nhgis_1920)

# Load GNIS data
gnis_1920 <- read_dta(paste0("analysis/processed/temp/gnis.dta")) %>%
  rename_all(tolower) %>%
  select(
    state_id = statefip, feature_id, lat_dec, long_dec
  ) %>%
  filter(
    state_id %in% c(37)
    ) %>%
  filter(lat_dec != "0" & long_dec != "0" & lat_dec != "" & long_dec != "") %>%
  st_as_sf(
    coords = c('long_dec','lat_dec'),
    crs = 4269 # GNIS uses NAD83 CRS
  ) %>%
  st_transform(crs = nhgis_crs) # Project onto NA Alberts Equal Area Conic CRS used by NHGIS

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
gnis_nhgis_xwk <- map_dfr(states, .f = st_coord2cty, data = gnis_1920, boundary = nhgis_1920)
write_dta(gnis_nhgis_xwk,paste0("analysis/processed/intermediate/gnis/gnis_nhgis_xwk.dta"), version = 14)
