
*****************************************************
* OVERVIEW
*	FILE: 0_run_all.do
*   This script runs the code to generate the tables and figures for the paper:
*		"The Gift of a Lifetime: The Hospital, Modern Medicine, and Mortality" 
*	AUTHORS: Alex Hollingsworth, Krzysztof Karbownik, Melissa Thomasson, and Anthony Wray
* 	VERSION: January 2024

* DESCRIPTION
* 	This script replicates the analysis in our paper and online appendix
*   All raw data are stored in /raw/
*   All code is stored in /scripts/
*   All tables and figures are outputted to /output/
* 
* SOFTWARE REQUIREMENTS
*   Analyses run on Windows using Stata version 18 and R-4.3.1
*
* TO PERFORM A CLEAN RUN, 
*	1. Be sure to have downloaded the publicly available IPUMS data that we are not
*		allowed to redistribute
* 	2. Delete the following two directories:
*   	/processed
*   	/output
*	3. Open the stata project `duke-replication.stpr` or 
*		make the working directory of Stata is the same directory `duke-replication.stpr`
*		 is located in
* 	4. Run this file, `0_run_all.do`

*****************************************************
// Clear stored objects and set preferences
clear all
matrix drop _all // Drop everything in mata
set more off
set varabbrev off

*****************************************************
// Local switches

* Install Stata packages (should not be needed, all used are in library.zip)
local install_packages 0

* Install gtools, The stata package gtools installs differently depending on your machine.
*The version in our libraries may not work for your machine. 

local machine = c(machine_type)
local processors = c(processors)
if  "`machine'" == "Mac (Apple Silicon)" &  "`processors'" == "10" {
  // Skip install
  local install_gtools 0
}  
else {
  // Force install, because the version provided will not be compatible
  local install_gtools 1
}

* Switch log on/off
local log 1

* Switches for running individual do files
local unzip_files		1 // Note this will not include some IPUMS and ICPSR data
local run_build			1 // You will need to download IPUMS and ICPSR data before this will run. Please see Read me.
local run_paper 		1
local run_appendix		1
local run_slow_code		1
local run_spec_chart 	1
local run_numbers		1

*****************************************************

// Set root directory
	local root_directory `c(pwd)'
	di "`root_directory'"
	global PROJ_PATH 	"`root_directory'"		// Project folder

// Set shell command paths. 
	global R_PATH "/usr/local/bin/R"
	global RSCRIPT_PATH "/usr/local/bin/Rscript"
	
if `unzip_files' {
	// Unzip raw data (Note this will not include some IPUMS and ICPSR data)
	*shell unzip "$PROJ_PATH/analysis/raw.zip" -d "$PROJ_PATH/analysis/"
	shell rm -r "$PROJ_PATH/analysis/__MACOSX"

// Unzip R and stata libraries 
	shell unzip "$PROJ_PATH/analysis/scripts/libraries.zip" -d "$PROJ_PATH/analysis/scripts"
	shell rm -r "$PROJ_PATH/analysis/scripts/__MACOSX"
	
	// Unzip renv (libraries for R)
	shell unzip "$PROJ_PATH/renv.zip" -d "$PROJ_PATH/"
	shell rm -r "$PROJ_PATH/__MACOSX"
}
*****************************************************
// Create project directories 

cap mkdir "$PROJ_PATH/analysis/output"
cap mkdir "$PROJ_PATH/analysis/output/appendix"
cap mkdir "$PROJ_PATH/analysis/output/main"
cap mkdir "$PROJ_PATH/analysis/processed"
cap mkdir "$PROJ_PATH/analysis/processed/data"
cap mkdir "$PROJ_PATH/analysis/processed/data/ama"
cap mkdir "$PROJ_PATH/analysis/processed/data/amd_med_schools"
cap mkdir "$PROJ_PATH/analysis/processed/data/amd_physicians"
cap mkdir "$PROJ_PATH/analysis/processed/data/chd"
cap mkdir "$PROJ_PATH/analysis/processed/data/crosswalks"
cap mkdir "$PROJ_PATH/analysis/processed/data/duke"
cap mkdir "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures"
cap mkdir "$PROJ_PATH/analysis/processed/data/gnis"
cap mkdir "$PROJ_PATH/analysis/processed/data/hospitals"
cap mkdir "$PROJ_PATH/analysis/processed/data/icpsr"
cap mkdir "$PROJ_PATH/analysis/processed/data/ipums"
cap mkdir "$PROJ_PATH/analysis/processed/data/nc_deaths"
cap mkdir "$PROJ_PATH/analysis/processed/data/nc_vital_stats"
cap mkdir "$PROJ_PATH/analysis/processed/data/nhgis"
cap mkdir "$PROJ_PATH/analysis/processed/data/numident"
cap mkdir "$PROJ_PATH/analysis/processed/data/R"
cap mkdir "$PROJ_PATH/analysis/processed/data/R/input"
cap mkdir "$PROJ_PATH/analysis/processed/data/R/output"
cap mkdir "$PROJ_PATH/analysis/processed/data/pvf"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/ama"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/amd_physicians"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/chd"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/duke"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/pvf"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/gnis"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/hospitals"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/icpsr"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nc_deaths"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nhgis"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/numident"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/numident/death"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/numident/ss5"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/seer"
cap mkdir "$PROJ_PATH/analysis/processed/temp"

*****************************************************

* Confirm that the globals for the project root directory and the R executable have been defined
assert !missing("$PROJ_PATH")
		
* Initialize log and record system parameters
cap mkdir "$PROJ_PATH/analysis/scripts/logs"
cap log close
set linesize 255 // Specify screen width for log files
local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$PROJ_PATH/analysis/scripts/logs/log_`datetime'.txt"
if `log' {
	log using "`logfile'", text
}

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"

*****************************************************
* Make sure libraries are set up correctly
*****************************************************

	* Disable locally installed Stata programs
	cap adopath - PERSONAL
	cap adopath - PLUS
	cap adopath - SITE
	cap adopath - OLDPLACE
	cap adopath - "$PROJ_PATH/analysis/scripts/libraries/stata-18"
	
	* Create and define a local installation directory for the packages
	net set ado "$PROJ_PATH/analysis/scripts/libraries/stata-18"
	
	adopath ++ "$PROJ_PATH/analysis/scripts/libraries/stata-18"
	adopath ++ "$PROJ_PATH/analysis/scripts/programs" // Stata programs and R scripts are stored in /scripts/programs

if `install_packages' {
	// Stata
	do "$PROJ_PATH/analysis/scripts/code/_install_stata_packages.do"
	// R
	shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/_install_R_packages.R"	
}
if `install_gtools' {
	shell rm -r "$PROJ_PATH/analysis/scripts/libraries/stata-18/g"
	ssc install gtools
	gtools, upgrade
}
// Build new list of libraries to be searched
mata: mata mlib index

cd "$PROJ_PATH"

**********************************************************************************************************
* Run project analysis ***********************************************************************************
**********************************************************************************************************

local t1 = clock(c(current_time), "hms")
di "Starting build: `t1'"
// Takes ~52 min to run
if `run_build' {
	// You will need to download IPUMS and ICPSR data before this will run. Please see Read me.
	
	do "$PROJ_PATH/analysis/scripts/code/1_process_raw_data.do" // 248 seconds
	do "$PROJ_PATH/analysis/scripts/code/1_1_process_ipums_data.do" // 175 seconds
	
	do "$PROJ_PATH/analysis/scripts/code/2_clean_data.do" // 2,068 seconds	
		
	do "$PROJ_PATH/analysis/scripts/code/3_0_ipums_data_for_geocode_nc_deaths.do"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths.do" // 830 seconds
	
	do "$PROJ_PATH/analysis/scripts/code/4_compile_data.do" // 61 seconds
	do "$PROJ_PATH/analysis/scripts/code/4_1_compile_ipums_data.do"
	
}
local t2 = clock(c(current_time), "hms")
di "Ending build and starting analysis: `t2'"

////////////////////////////////////////////////////////////////////////////
// Main tables and figures (~2 minutes to run)
////////////////////////////////////////////////////////////////////////////

if `run_paper' {

	// Create file to store various specifications
	file open sr_output_vary_spec using "$PROJ_PATH/analysis/output/sr_output_vary_spec.txt", write replace

	file write sr_output_vary_spec ///
					"notes" _tab ///
					"group" _tab ///
					"b" _tab ///
					"se" _tab ///
					"p_value" _tab ///
					"N" ///
					_n
	file close sr_output_vary_spec			
			
	// Create file to store various subsamples
	file open sr_output_vary_samp using "$PROJ_PATH/analysis/output/sr_output_vary_samp.txt", write replace

	file write sr_output_vary_samp ///
					"notes" _tab ///
					"group" _tab ///
					"b" _tab ///
					"se" _tab ///
					"p_value" _tab ///
					"N" ///
					_n
	file close sr_output_vary_samp			
			
	// Run analysis for main paper
	do "$PROJ_PATH/analysis/scripts/code/5_tables.do" // 34 seconds
	do "$PROJ_PATH/analysis/scripts/code/5_figures.do" // 110 seconds

}
local t3 = clock(c(current_time), "hms")
di "Ending main analysis and starting appendix: `t3'"

////////////////////////////////////////////////////////////////////////////
// Appendix tables and figures (~27 minutes, 11 minutes of which is spent on randomization inference)
////////////////////////////////////////////////////////////////////////////

if `run_appendix' {

	do "$PROJ_PATH/analysis/scripts/code/6.01_online_appendix_b_hospitals.do" // 131 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.02_online_appendix_c_doctors.do" // 73 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do" // 92 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do" // 4 seconds
	
	// Must run before 6.06_online_appendix_j_non_nc.do
	do "$PROJ_PATH/analysis/scripts/code/6.05_online_appendix_g_other_results.do" // 30 seconds
		
	//Must run after 6.05_online_appendix_g_other_results.do, and before 6.07_online_appendix_f_long_run.do	
	do "$PROJ_PATH/analysis/scripts/code/6.06_online_appendix_j_non_nc.do" // 10 seconds 
		
	// Must run after 6.06_online_appendix_j_non_nc.do
	do "$PROJ_PATH/analysis/scripts/code/6.07_online_appendix_f_long_run.do"	// ~600 seconds
		
	do "$PROJ_PATH/analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do" // 23 seconds
	local t3a = clock(c(current_time), "hms")

	if `run_slow_code' {
		do "$PROJ_PATH/analysis/scripts/code/6.09_online_appendix_k_ri.do"
	}
	local t3b = clock(c(current_time), "hms")

	do "$PROJ_PATH/analysis/scripts/code/6.10_online_appendix_l_extended_panel.do" // 120 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.11_online_appendix_m_psm.do" // 15 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.12_online_appendix_n_summary_stats.do" // 2 seconds
	do "$PROJ_PATH/analysis/scripts/code/6.13_online_appendix_j_iv.do"
	
}


if `run_spec_chart' {
	
	// Make robustness checks figure
	shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/7_sample_chart.R"	// 2 seconds
	shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/7_combined_spec_chart.R" // 2 seconds

	cap rm "$PROJ_PATH/Rplots.pdf"

}
local t4 = clock(c(current_time), "hms")
di "Ending appendix: `t4'"

if `run_numbers' {
	// <1 min to run
	do "$PROJ_PATH/analysis/scripts/code/8_intext_stats.do"
	
}
*****************************************************
	
local t5 = clock(c(current_time), "hms")
di "Ending in-text-stats: `t5'"

*****************************************************
// Log of times per section

// Build
local time = clockdiff_frac(`t1', `t2', "minute")
di "Time to build raw data: `time' minutes"

// Main analysis
local time = clockdiff_frac(`t2', `t3', "minute")
di "Time to do main analysis: `time' minutes"

// Appendix + Spec/Sample charts
local time = clockdiff_frac(`t3', `t4', "minute")
di "Total time to run appendix: `time' minutes"
local time2 = clockdiff_frac(`t3a', `t3b', "minute")
di "Time spent of the `time' minutes  on RI: `time2' minutes"

// In-text citations
local time = clockdiff_frac(`t4', `t5', "minute")
di "Time to run in-text numbers: `time' minutes"

*****************************************************
// End log

di "End date and time: $S_DATE $S_TIME"

if `log' {
	log close
}

*****************************************************

** EOF
