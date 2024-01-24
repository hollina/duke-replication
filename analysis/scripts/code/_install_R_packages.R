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

#########################################################################################################
#  Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(renv, lazyeval)

#########################################################################################################
#  For this R-Session, change location of R-packages to be custom directory `r_packages`  
renv::restore()



