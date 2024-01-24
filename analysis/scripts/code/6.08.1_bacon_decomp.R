###################################################################################
# Clear working directory/RAM
rm(list=ls())
###################################################################################
# Load arguments

args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  start_year <- args[1]
  end_year <- args[2]
  yvar <- args[3]
  if (length(args) > 3) stop('Too many arguments.')
  
} else stop('Arguments required.')

rootpath <- paste0("analysis/processed/data/R/")

###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  data.table, lubridate, tidyverse, tidylog, fixest, did, kableExtra, bacondecomp, magrittr, haven
)
options(tigris_use_cache = TRUE)
options("tidylog.display" = NULL)

###################################################################################
# Load data
death_data <- haven::read_dta(paste0(rootpath,"input/bacon_input.dta")) %>% 
  as_tibble() %>%
  filter(statefip == 37 & year >= start_year & year <= end_year) %>%
  mutate(time_treated = replace_na(time_treated, 0))

###################################################################################
# Bacon decomposition

# Summarize Bacon decomposition
bacon_decomp <- function(data, depvar) {
  
  bacon_formula <- as.formula(paste0(depvar, " ~ treated"))
  
  # Calculate the Bacon decomposition without covariates
  bacon_out <- bacon(bacon_formula,
                     data = data,
                     id_var = "fips",
                     time_var = "year")
  
  # Save data to dta
  write_dta(bacon_out, paste0(rootpath,"output/bacon_out.dta"), version = 14, label = attr(data, "label"))
  
 # Goodman-Bacon decomposition table
  bacon_out %>% 
    group_by(type) %>% 
    summarize(Avg_Estimate = mean(estimate),
             Number_Comparisons = n(),
              Total_Weight = sum(weight))
  
}

# Function to save Bacon decomposition estimates and write to dta 
bacon_to_stata <- function(data, depvar){
  bacon_table <- bacon_decomp(data, depvar)
  write_dta(bacon_table, paste0(rootpath, "output/bacon_table.dta"), version = 14, label = attr(data, "label"))
}

# Export Bacon decomposition 
bacon_to_stata(death_data, yvar)
