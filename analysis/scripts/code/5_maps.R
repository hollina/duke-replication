#########################################################################################################
#  Clear memory
rm(list = ls())

#########################################################################################################
#  Set CRAN Mirror (place where code will be downloaded from)
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://mirror.las.iastate.edu/CRAN/"
  options(repos = r)
})

#########################################################################################################
#  Set Library paths
.libPaths('analysis/scripts/libraries/R')

###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(Cairo, extrafont, ggplot2, haven, tidyverse, remotes, sf, sjlabelled, viridis, tidyr, statar)

###################################################################################
# Settings
my_theme <- theme(
  # Background and Line themes
  axis.text = element_blank(),
  line = element_blank(), 
  rect = element_rect(fill = "white"),
  panel.background = element_rect(fill = "white"),
  panel.grid = element_blank(),
  #Text editing:
  title = element_text(face = "italic", size = 20), #Alternative: face = bold
  plot.caption = element_text(size = 5),
  # Legend themes
  legend.position = c(0.25, 0.1), # Alternative: "bottom"
  legend.direction = "horizontal",
  legend.title =  element_text(size = 10),
  legend.margin = margin(0.2, 0.2, 0, 0.2, "cm")
)

# Make custom range of colors
colfunc <- colorRampPalette(c("white", c(rgb(230, 65, 115, maxColorValue = 255))))
colfunc(6)

###################################################################################

## Grab the North Carolina shapefile that comes bundled with sf
nc_shapefile = system.file("shape/nc.shp", package = "sf")
nc = st_read(nc_shapefile)
nc = nc %>%
  mutate(fips = FIPSNO)

# Load data for maps
map_data <- read_dta(paste0("analysis/processed/data/R/input/map_input.dta")) %>%
  rename_all(tolower) %>%
  mutate(duke_cat = as.factor(duke_cat)) %>%
  mutate(fips = fips/10) %>%
  inner_join(nc, by = c("fips"))

levels(map_data$duke_cat) <- c("No Duke", "1939-42", "1934-38","1930-33","1929", "1927-28")
st_geometry(map_data) <- map_data$geometry

# Map of Duke roll out
duke_map <- ggplot() +
  geom_sf(data = nc) +
  geom_sf(data = map_data, aes(fill = duke_cat))+
  scale_fill_manual(values = colfunc(6)) + # WGS84
  coord_sf(crs = st_crs(4326)) + # WGS84
  my_theme + 
  # Box around legend
  labs(
    fill = "First Duke funding" 
  )

#ggsave(plot = duke_map, paste0("analysis/output/main/figure_1b_duke_map.png"), h = 4.5, w = 8, type = "cairo-png")
ggsave(plot = duke_map, paste0("analysis/output/main/figure_1b_duke_map.pdf"), h = 4.5, w = 8)

# Map of percent change in infant mortality rate between 1922 and 1942 (start and end years of sample)
imr_map <- ggplot() +
  geom_sf(data = nc) +
  geom_sf(data = map_data, aes(fill = pct_change_imr))+
  scale_fill_viridis_c(direction = 1, option = "magma") + 
  coord_sf(crs = st_crs(4326)) + # WGS84
  my_theme + 
  # Box around legend
  labs(
    fill = "Pct. change in infant mortality rate, 1922-42."
  )

#ggsave(plot = imr_map, paste0("analysis/output/main/figure_1d_imr_map.png"), h = 4.5, w = 8, type = "cairo-png")
ggsave(plot = imr_map, paste0("analysis/output/main/figure_1d_imr_map.pdf"), h = 4.5, w = 8)
