version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 5_tables.do
* PURPOSE: Run regressions for main tables and figures
************/

// Settings for figures
graph set window fontface 		"Roboto Light"
graph set ps fontface 			"Roboto Light"
graph set eps fontface 			"Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables for short-run
local baseline_controls 		"percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"

// Control variables for long-run
local int_baseline_controls 	"i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"

local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"

// Duke treatment variable 
local treat 					"capp_all"

// Panel start and end dates
local year_start 				1922
local year_end 					1942

// Long-run mortality restrictions
local age_lb 					56
local age_ub					64

**************************************************
***** Table 1: Hospitals first-stage results *****
**************************************************

// Load county-level first-stage hospitals data 
use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

// Add Duke treatment 
duketreat, treatvar(`treat') time(year) location(fips)

	// Panel A - Beds 
	
	////////////////////////////////////////////////////////////////////////
	// Count of beds 
	
	local depvar i_tot_beds_aha
	
	// Count of beds //
	
	// Column 1 - Beds - no controls - no weights
	eststo c_c_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - Beds - no controls - weights
	eststo c_c_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Beds - county-level controls - weights
	eststo c_c_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Beds per 1,000 births //

	// Column 1 - Beds per 1,000 births - no controls - no weights
	eststo c_r_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Beds per 1,000 births - no controls -  weights
	eststo c_r_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Beds per 1,000 births -  controls -  weights
	eststo c_r_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	////////////////////////////////////////////////////////////////////////
	// Count of likely beds 

	local depvar i_likely_beds_aha
	
	// Count of likely beds //
	
	// Column 1 - likely Beds - no controls - no weights
	eststo c_cl_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - likely Beds - no controls - weights
	eststo c_cl_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - likely Beds - county-level controls - weights
	eststo c_cl_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Beds per 1,000 births //

	// Column 1 - likely Beds per 1,000 births - no controls - no weights
	eststo c_rl_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - likely Beds per 1,000 births - no controls - weights
	eststo c_rl_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - likely Beds per 1,000 births - controls - weights
	eststo c_rl_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	////////////////////////////////////////////////////////////////////////
	// Count of Proprietary beds //

	local depvar i_prop_beds_aha
	
	// Count of proprietary beds //
	
	// Column 1 - likely Beds - no controls - no weights
	eststo c_cp_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - likely Beds - no controls - weights
	eststo c_cp_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - likely Beds - county-level controls - weights
	eststo c_cp_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Proprietary beds per 1,000 births //

	// Column 1 - likely Beds per 1,000 births - no controls - no weights
	eststo c_rp_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - likely Beds per 1,000 births - no controls - weights
	eststo c_rp_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 -likely Beds per 1,000 births - controls - weights
	eststo c_rp_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	////////////////////////////////////////////////////////////////////////
	// Count of hospitals 
	
	local depvar tot_hospitals
	
	// Count of hospitals //
	
	// Column 1 - Hospitals - no controls - no weights
	eststo c_ch_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - Hospitals - no controls - weights
	eststo c_ch_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Hospitals - county-level controls - weights
	eststo c_ch_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Hospitals per 1,000 births //

	// Column 1 - Hospitals per 1,000 births - no controls - no weights
	eststo c_rh_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Hospitals per 1,000 births - no controls - weights
	eststo c_rh_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Hospitals per 1,000 births - controls - weights
	eststo c_rh_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	////////////////////////////////////////////////////////////////////////
	// Count of likely beds 

	local depvar tot_hosp_likely
	
	// Count of likely hospitals //
	
	// Column 1 - likely hospitals - no controls - no weights
	eststo c_clh_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - likely hospitals - no controls - weights
	eststo c_clh_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - likely hospitals - county-level controls - weights
	eststo c_clh_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Likely hospitals per 1,000 births //

	// Column 1 - likely hospitals per 1,000 births - no controls - no weights
	eststo c_rlh_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - likely hospitals per 1,000 births - no controls - weights
	eststo c_rlh_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - likely hospitals per 1,000 births - controls - weights
	eststo c_rlh_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	////////////////////////////////////////////////////////////////////////
	// Count of Proprietary hospitals //

	local depvar tot_hosp_prop
	
	// Count of proprietary hospitals //
	
	// Column 1 - proprietary hospitals - no controls - no weights
	eststo c_cph_1 :reghdfe `depvar' b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - proprietary hospitals - no controls - weights
	eststo c_cph_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - proprietary hospitals - county-level controls - weights
	eststo c_cph_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Proprietary hospitals per 1,000 births //

	// Column 1 - proprietary hospitals per 1,000 births - no controls - no weights
	eststo c_rph_1 :reghdfe `depvar'_pc b0.treated, absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - proprietary hospitals per 1,000 births - no controls - weights
	eststo c_rph_2 :reghdfe `depvar'_pc b0.treated [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - proprietary hospitals per 1,000 births - controls - weights
	eststo c_rph_3 :reghdfe `depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)
	di "`e(cmdline)'"	

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Beds or Hospitals}$"'
local y_2 "\$Y^{R}_{ct} = \text{Beds or Hospitals per 1,000 births}$"

// Make top panel - Beds - All 
#delimit ;
esttab c_c_1 c_c_2 c_c_3  c_r_1 c_r_2 c_r_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main' \midrule") 
keep(1.treated) coeflabels(1.treated "\emph{A. Beds} &&&&&& \\ \addlinespace\hspace{.5cm} Total") ;
#delimit cr

//  Beds - Church/NP/Public 
#delimit ;
esttab c_cl_1 c_cl_2 c_cl_3  c_rl_1 c_rl_2 c_rl_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Non-profit/church/public") ;
#delimit cr

//   Beds - Proprietary
#delimit ;
esttab c_cp_1 c_cp_2 c_cp_3  c_rp_1 c_rp_2 c_rp_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Proprietary") ;
#delimit cr

//  Number of hospitals - Any 
#delimit ;
esttab c_ch_1 c_ch_2 c_ch_3  c_rh_1 c_rh_2 c_rh_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\emph{B. Hospitals} &&&&&& \\ \addlinespace\hspace{.5cm} Total") ;
#delimit cr

// Make 3rd panel - Number of hospitals - Church/NP/Public  
#delimit ;
esttab c_clh_1 c_clh_2 c_clh_3  c_rlh_1 c_rlh_2 c_rlh_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated " \addlinespace\hspace{.5cm} Non-profit/church/public") ;
#delimit cr

// Number of hospitals - Proprietary 
#delimit ;
esttab c_cph_1 c_cph_2 c_cph_3  c_rph_1 c_rph_2 c_rph_3
 using "$PROJ_PATH/analysis/output/main/table_1_county_level_hospitals.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated " \addlinespace\hspace{.5cm} Proprietary") 
stats(N, fmt(%9.0fc) labels("\addlinespace Observations") layout("\multicolumn{1}{c}{@}"))
postfoot("\midrule 
	County FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr



****************************************************************************************
***** Table 2: Doctors first-stage results pooled and by race - TWFE specification *****
****************************************************************************************

local qual "2yr"
local good_var good_`qual'
local bad_var bad_`qual'
local suffix "_`qual'_as_quality"
local depvar md

eststo clear

// Load data 
use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

////////////////////////////////////////////////////////////////////////
// All doctors //

// Column 1 - Docs - no controls - no weights
eststo c_c_1 :reghdfe `depvar' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs - no controls - weights
eststo c_c_2 :reghdfe `depvar' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs - county-level controls - weights
eststo c_c_3 :reghdfe `depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Doctors per 1,000 births //

// Column 1 - Docs per 1k births - no controls - no weights
eststo c_r_1 :reghdfe r`depvar' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs per 1k births - no controls -  weights
eststo c_r_2 :reghdfe r`depvar' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs per 1k births -  controls -  weights
eststo c_r_3 :reghdfe r`depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Good doctors //

// Column 1 - Docs - no controls - no weights
eststo c_cg_1 :reghdfe `depvar'_`good_var' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs - no controls - weights
eststo c_cg_2 :reghdfe `depvar'_`good_var' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs - county-level controls - weights
eststo c_cg_3 :reghdfe `depvar'_`good_var' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Good doctors per 1,000 births //

// Column 1 - Docs per 1k births - no controls - no weights
eststo c_rg_1 :reghdfe r`depvar'_`good_var' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs per 1k births - no controls -  weights
eststo c_rg_2 :reghdfe r`depvar'_`good_var' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs per 1k births -  controls -  weights
eststo c_rg_3 :reghdfe r`depvar'_`good_var' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Bad doctors //

// Column 1 - Docs - no controls - no weights
eststo c_cbad_1 :reghdfe `depvar'_`bad_var' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs - no controls - weights
eststo c_cbad_2 :reghdfe `depvar'_`bad_var' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs - county-level controls - weights
eststo c_cbad_3 :reghdfe `depvar'_`bad_var' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Bad doctors per 1,000 births //

// Column 1 - Docs per 1k births - no controls - no weights
eststo c_rbad_1 :reghdfe r`depvar'_`bad_var' b0.treated, absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 2 - Docs per 1k births - no controls -  weights
eststo c_rbad_2 :reghdfe r`depvar'_`bad_var' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

// Column 3 - Docs per 1k births -  controls -  weights
eststo c_rbad_3 :reghdfe r`depvar'_`bad_var' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
di "`e(cmdline)'"

egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
drop if ever_zero_births == 1

////////////////////////////////////////////////////////////////////////
// By race doctors

foreach race in black white {
	
	if "`race'" == "white" {
		local el w
		local weight births_pub_wt
	}
	if "`race'" == "black" {
		local el b
		local weight births_pub_bk
	}
		
	// All doctors //
	
	// Column 1 - Docs - no controls - no weights
	eststo c_c`el'_1 :reghdfe `depvar'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - Docs - no controls - weights
	eststo c_c`el'_2 :reghdfe `depvar'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs - county-level controls - weights
	eststo c_c`el'_3 :reghdfe `depvar'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Doctors per 1,000 births //
	
	// Column 1 - Docs per 1,000 births - no controls - no weights
	eststo c_r`el'_1 :reghdfe r`depvar'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Docs per 1,000 births - no controls -  weights
	eststo c_r`el'_2 :reghdfe r`depvar'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs per 1,000 births -  controls -  weights
	eststo c_r`el'_3 :reghdfe r`depvar'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Good doctors //
	
	// Column 1 - Docs - no controls - no weights
	eststo c_cg`el'_1 :reghdfe `depvar'_`good_var'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - Docs - no controls - weights
	eststo c_cg`el'_2 :reghdfe `depvar'_`good_var'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs - county-level controls - weights
	eststo c_cg`el'_3 :reghdfe `depvar'_`good_var'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Good doctors per 1,000 births //

	// Column 1 - Docs per 1,000 births - no controls - no weights
	eststo c_rg`el'_1 :reghdfe r`depvar'_`good_var'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Docs per 1,000 births - no controls -  weights
	eststo c_rg`el'_2 :reghdfe r`depvar'_`good_var'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs per 1,000 births -  controls -  weights
	eststo c_rg`el'_3 :reghdfe r`depvar'_`good_var'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Bad doctors //
	
	// Column 1 - Docs - no controls - no weights
	eststo c_cbad`el'_1 :reghdfe `depvar'_`bad_var'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 2 - Docs - no controls - weights
	eststo c_cbad`el'_2 :reghdfe `depvar'_`bad_var'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs - county-level controls - weights
	eststo c_cbad`el'_3 :reghdfe `depvar'_`bad_var'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Bad doctors per 1,000 births //

	// Column 1 - Docs per 1,000 births - no controls - no weights
	eststo c_rbad`el'_1 :reghdfe r`depvar'_`bad_var'_`race' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Docs per 1,000 births - no controls -  weights
		
	eststo c_rbad`el'_2 :reghdfe r`depvar'_`bad_var'_`race' b0.treated [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"
	
	// Column 3 - Docs per 1,000 births -  controls -  weights
	eststo c_rbad`el'_3 :reghdfe r`depvar'_`bad_var'_`race' b0.treated `baseline_controls' [aw = `weight'], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

}

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Doctors}$"'
local y_2 "\$Y^{R}_{ct} = \text{Doctors per 1,000 live births}$"

// Make top panel - Doctors - All
#delimit ;
esttab c_c_1 c_c_2 c_c_3  c_r_1 c_r_2 c_r_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main' \midrule") 
keep(1.treated) coeflabels(1.treated "\emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} All") ;
#delimit cr

//  - Doctors - Good
#delimit ;
esttab c_cg_1 c_cg_2 c_cg_3  c_rg_1 c_rg_2 c_rg_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} High quality") ;
#delimit cr

//  - Doctors - Bad 
#delimit ;
esttab c_cbad_1 c_cbad_2 c_cbad_3  c_rbad_1 c_rbad_2 c_rbad_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Low quality") 
stats(N, fmt(%9.0fc) labels("\addlinespace\hspace{.5cm} Observations") layout("\multicolumn{1}{c}{@}"));
#delimit cr

//  - Black Doctors - All
#delimit ;
esttab c_cb_1 c_cb_2 c_cb_3  c_rb_1 c_rb_2 c_rb_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\emph{B. Black} &&&&&& \\ \addlinespace\hspace{.5cm} All") ;
#delimit cr

//  - Black Doctors - Good
#delimit ;
esttab c_cgb_1 c_cgb_2 c_cgb_3  c_rgb_1 c_rgb_2 c_rgb_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} High quality") ;
#delimit cr

//  - Black Doctors - Bad 
#delimit ;
esttab c_cbadb_1 c_cbadb_2 c_cbadb_3  c_rbadb_1 c_rbadb_2 c_rbadb_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Low quality") 
stats(N, fmt(%9.0fc) labels("\addlinespace\hspace{.5cm} Observations") layout("\multicolumn{1}{c}{@}"));
#delimit cr

//  - White Doctors - All
#delimit ;
esttab c_cw_1 c_cw_2 c_cw_3  c_rw_1 c_rw_2 c_rw_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\emph{C. White} &&&&&& \\ \addlinespace\hspace{.5cm} All") ;
#delimit cr

//  - White Doctors - Good
#delimit ;
esttab c_cgw_1 c_cgw_2 c_cgw_3  c_rgw_1 c_rgw_2 c_rgw_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} High quality") ;
#delimit cr

//  - White Doctors - Bad 
#delimit ;
esttab c_cbadw_1 c_cbadw_2 c_cbadw_3  c_rbadw_1 c_rbadw_2 c_rbadw_3
using "$PROJ_PATH/analysis/output/main/table_2_county_level_doctors`suffix'.tex", `booktabs_default_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Low quality") 
stats(N, fmt(%9.0fc) labels("\addlinespace\hspace{.5cm} Observations") layout("\multicolumn{1}{c}{@}"))
postfoot("\midrule 
County FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
AMD Wave FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr



*********************************************************************************************
***** Table 3: Main infant mortality results pooled and by race - Poisson specification *****
*********************************************************************************************
	
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

// Panel A - Pooled

// Column 1 - Poisson deaths - no controls - no weights
imppml, y_stub(mort) suffix(pub) t(treated) a(fips year) column(1) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ncontrols, Nweights")

// Column 2 - Poisson deaths - no controls - weights
imppml, y_stub(mort) suffix(pub) t(treated) wgt(births) a(fips year) column(2) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ncontrols, Yweights")

// Column 3 - Poisson deaths - controls - weights
imppml, y_stub(mort) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(3) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ycontrols, Yweights")

// Column 4 - Poisson IMR - no controls - no weights
imppml, y_stub(imr_) suffix(pub) t(treated) a(fips year) column(4) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ncontrols, Nweights")

// Column 5 - Poisson IMR - no controls - weights
imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births) a(fips year) column(5) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ncontrols, Yweights")

// Column 6 - Poisson IMR - controls - weights
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(6) pooled  ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")

// Panels B to D - By Race and Fully Interacted

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

// Column 1 - Poisson deaths - no controls - no weights - drop counties ever with zero births
imppml, y_stub(mort) suffix(pub) t(treated) restrict("ever_zero_births == 0") a(fips year) column(1)   ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ncontrols, Nweights")

// Column 2 - Poisson deaths - no controls - weights - drop counties ever with zero births
imppml, y_stub(mort) suffix(pub) t(treated) wgt(births) restrict("ever_zero_births == 0") a(fips year) column(2)   ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ncontrols, Yweights")

// Column 3 - Poisson deaths - no controls - weights - drop counties ever with zero births
imppml, y_stub(mort) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(3)   ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_count, Ycounty, Yyear, Ycontrols, Yweights")

// Column 4 - Poisson IMR - no controls - no weights - drop counties ever with zero births
imppml, y_stub(imr_) suffix(pub) t(treated) restrict("ever_zero_births == 0") a(fips year) column(4)   ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ncontrols, Nweights")

// Column 5 - Poisson IMR - no controls - weights - drop counties ever with zero births
imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births) restrict("ever_zero_births == 0") a(fips year) column(5)    ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ncontrols, Yweights")

// Column 6 - Poisson IMR - controls - weights - drop counties ever with zero births
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(6)   ///
	store ///
	store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
	store_options("sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Infant deaths}$"'
local y_2 "\$Y^{R}_{ct} = \text{Infant mortality rate}$"

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c4 p1_c5 p1_c6
 using "$PROJ_PATH/analysis/output/main/table_3_infant_mortality_poisson_extensive.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
drop(*) stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled infant deaths or infant mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c4 p2_c5 p2_c6
 using "$PROJ_PATH/analysis/output/main/table_3_infant_mortality_poisson_extensive.tex", `booktabs_default_options' append
drop(*) stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black infant deaths or infant mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 p3_c4 p3_c5 p3_c6
 using "$PROJ_PATH/analysis/output/main/table_3_infant_mortality_poisson_extensive.tex", `booktabs_default_options' append
drop(*) stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White infant deaths or infant mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 p4_c4 p4_c5 p4_c6
 using "$PROJ_PATH/analysis/output/main/table_3_infant_mortality_poisson_extensive.tex", `booktabs_default_options' append
drop(*) stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr



**************************************************************************************
***** Table 4: Intensive margin. Infant mortality results. Poisson specification *****
**************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

replace tot_pay_all_adj = 0 if missing(tot_pay_all_adj)
replace tot_capp_all_adj = 0 if missing(tot_capp_all_adj)

///////////////////////////////////////////////////////////////////
// Pooled

// Appropriations
eststo pl_c1: ppmlhdfe imr_pub tot_capp_all_adj  `baseline_controls' [pw = births_pub], ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_capp_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// Payments
eststo pl_c2: ppmlhdfe imr_pub tot_pay_all_adj  `baseline_controls' [pw = births_pub], ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_pay_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// First stage
eststo pl_c3: reghdfe tot_pay_all_adj tot_capp_all_adj `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips)
lincomestadd2a _b[tot_capp_all_adj], comtype("nlcom") statname("first_stage_")

///////////////////////////////////////////////////////////////////////////////
// Make Table of Main Poisson Results

local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\ "
local titles_main "& \multicolumn{1}{c}{IMR} & \multicolumn{1}{c}{IMR} & \multicolumn{1}{c}{Payments} \\"
local titles_main2 "& \multicolumn{1}{c}{Appropriations} & \multicolumn{1}{c}{Payments} & \multicolumn{1}{c}{Appropriations} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Infant mortality rate}$"'
local y_2 "\$Y^{R}_{ct} = \text{Cumulative payments}$"

// Make top panel 
esttab pl_c1 pl_c2 pl_c3    ///
  using "$PROJ_PATH/analysis/output/main/table_4_infant_mortality_poisson_intensive.tex", `booktabs_default_options' replace ///
  mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
  posthead("`titles_main2' `numbers_main'") ///
  drop(*) stats(pct_efct_b pct_efct_se first_stage_b first_stage_se  N, fmt(0 0 0 0 %9.0fc) labels("\midrule \emph{A. Pooled infant mortality rate} && \\ \addlinespace\hspace{.5cm}  Percent effect from \\$1 million of Duke support" "~" "\addlinespace\hspace{.5cm} Cumulative appropriations" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ @ @ "\multicolumn{1}{c}{@}"))

///////////////////////////////////////////////////////////////////
// Reshape
///////////////////////////////////////////////////////////////////

// Reshape dataset to do analysis by race
keep mort_* births_pub_* imr_* `baseline_controls' tot_pay_all_adj tot_capp_all_adj fips year treated // ln_imr_* 
reshape long mort_@ births_pub_@ imr_pub_@, i(fips year) j(race) string // ln_imr_pub_@  ln_imr_p1_pub_@ 
replace mort_ = . if births_pub_ == 0

rename race race_str
gen race = . 
replace race = 1 if race_str == "wt"
replace race = 2 if race_str == "bk"

gen related_to_bk = regexm(race_str, "bk")
gen related_to_wt = regexm(race_str, "wt")

gen race_related_to = 0
replace race_related_to = 1 if related_to_wt == 1
replace race_related_to = 2 if related_to_bk == 1

// Expand weight for each race fips year group. 
bysort fips year race_related_to: egen weight = max(births_pub_)

///////////////////////////////////////////////////////////////////
// Drop ever zero births 
///////////////////////////////////////////////////////////////////

// Flag counties with black or white births ever equal to zero
gegen ever_zero_births = max(births_pub_ == 0), by(fips)

// Drop counties that ever have zero births
keep if ever_zero_births == 0

///////////////////////////////////////////////////////////////////
// Black
///////////////////////////////////////////////////////////////////

// Appropriations
eststo bk_c1: ppmlhdfe imr_pub_ tot_capp_all_adj  `baseline_controls' [pw = births_pub_] if race == 2, ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_capp_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// Payments
eststo bk_c2: ppmlhdfe imr_pub_ tot_pay_all_adj  `baseline_controls' [pw = births_pub_] if race == 2, ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_pay_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// First stage
eststo bk_c3: reghdfe tot_pay_all_adj tot_capp_all_adj `baseline_controls' [pw = births_pub_]  if race == 2, absorb(fips year) vce(cluster fips)
lincomestadd2a _b[tot_capp_all_adj], comtype("nlcom") statname("first_stage_")

// Make middle panel 
esttab bk_c1 bk_c2 bk_c3    ///
 using "$PROJ_PATH/analysis/output/main/table_4_infant_mortality_poisson_intensive.tex", `booktabs_default_options' append ///
 drop(*) stats(pct_efct_b pct_efct_se first_stage_b first_stage_se N, fmt(0 0 0 0 %9.0fc) labels("\emph{B. Black infant mortality rate} && \\ \addlinespace\hspace{.5cm}  Percent effect from \\$1 million of Duke support" "~" "\addlinespace\hspace{.5cm} Cumulative appropriations" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ @ @ "\multicolumn{1}{c}{@}"))

///////////////////////////////////////////////////////////////////
// White
///////////////////////////////////////////////////////////////////

// Appropriations
eststo wt_c1: ppmlhdfe imr_pub_ tot_capp_all_adj  `baseline_controls' [pw = births_pub_] if race == 1, ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_capp_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// Payments
eststo wt_c2: ppmlhdfe imr_pub_ tot_pay_all_adj  `baseline_controls' [pw = births_pub_] if race == 1, ///
	absorb(fips year ) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[tot_pay_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")

// First stage
eststo wt_c3: reghdfe tot_pay_all_adj tot_capp_all_adj `baseline_controls' [pw = births_pub_] if race == 1, absorb(fips year) vce(cluster fips)
lincomestadd2a _b[tot_capp_all_adj], comtype("nlcom") statname("first_stage_")

// Make middle panel 
esttab wt_c1 wt_c2 wt_c3    ///
 using "$PROJ_PATH/analysis/output/main/table_4_infant_mortality_poisson_intensive.tex", `booktabs_default_options' append ///
 drop(*) stats( pct_efct_b pct_efct_se first_stage_b first_stage_se N, fmt(0 0 0 0 %9.0fc) labels("\emph{C. White infant mortality rate} && \\ \addlinespace\hspace{.5cm}  Percent effect from \\$1 million of Duke support" "~" "\addlinespace\hspace{.5cm} Cumulative appropriations" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ @ @ "\multicolumn{1}{c}{@}"))

///////////////////////////////////////////////////////////////////
// Fully interacted
///////////////////////////////////////////////////////////////////

// Appropriations 
eststo int_c1: ppmlhdfe imr_pub_ c.tot_capp_all_adj##i.race [pw = births_pub_], ///
	absorb(fips##i.race year##i.race `baseline_controls_int') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[c.tot_capp_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[c.tot_capp_all_adj#2.race])-1), comtype("nlcom_pois") statname("int_pct_efct_")	
	testnl exp(_b[c.tot_capp_all_adj#2.race])-1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
	
// Payments 
eststo int_c2: ppmlhdfe imr_pub_ c.tot_pay_all_adj##i.race  [pw = births_pub_], ///
	absorb(fips##i.race year##i.race `baseline_controls_int') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[c.tot_pay_all_adj])-1), comtype("nlcom_pois") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[c.tot_pay_all_adj#2.race])-1), comtype("nlcom_pois") statname("int_pct_efct_")	
testnl exp(_b[c.tot_pay_all_adj#2.race])-1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 

// First stage
eststo int_c3: reghdfe tot_pay_all_adj c.tot_capp_all_adj##i.race  [pw = births_pub_] , ///
	absorb(fips##i.race year##i.race `baseline_controls_int') vce(cluster fips)  

lincomestadd2a _b[c.tot_capp_all_adj], comtype("nlcom") statname("first_stage_")
lincomestadd2a _b[c.tot_capp_all_adj#2.race], comtype("nlcom") statname("int_first_stage_")
testnl exp(_b[c.tot_capp_all_adj#2.race])-1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
		
///////////////////////////////////////////////////////////////////////////////
// Append Table of Main Poisson Results

// Make bottom panel 
esttab int_c1 int_c2 int_c3 ///
  using "$PROJ_PATH/analysis/output/main/table_4_infant_mortality_poisson_intensive.tex", `booktabs_default_options' append ///
  eqlabels(none) ///
  drop(*) stats(int_p_value, fmt(%09.2f) labels("\hspace{.5cm} P-value for difference by race") layout(@)) ///
postfoot("\midrule County of birth FE & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\ Year of birth FE & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}    \\ Controls & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}    \\  Weights & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}   \\ ") 



***************************************************************
***** Table 5: Sulfa shift-share DD x Duke DD interaction *****
***************************************************************

// Generate upper and lower quartile values of baseline pneumonia

use "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", clear

sum base_pneumonia_22to26, d

local pneumonia_p75 = r(p75)
local pneumonia_p25 = r(p25)
local pneumonia_iqr = `pneumonia_p75' - `pneumonia_p25'

di "IQR: `pneumonia_iqr'"
	

// Short-run infant mortality outcomes
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)

// Generate sulfa x Duke treated x post shift share interaction terms
gen post_sulfa = (year >= 1937)
gen post_sulfa_shift_share = post_sulfa*base_pneumonia_22to26

gen treated_post_sulfa = treated*post_sulfa
gen treated_shift_share = treated*base_pneumonia_22to26
gen treated_post_shift_share = treated*post_sulfa*base_pneumonia_22to26

la var post_sulfa "=1 if sulfa (1937 onward)"
la var treated "$\text{Duke}_{ct}\;\;(\delta_0)$"
la var treated_post_sulfa "$\text{Duke}_{ct}\times\text{Sulfa}_{t}\;\;(\delta_1)$"
la var treated_shift_share "$\text{Duke}_{ct}\times\text{Pre-pneumonia}_{c}\;\;(\delta_2)$"
la var post_sulfa_shift_share "$\text{Sulfa}_{t}\times\text{Pre-pneumonia}_{c}\;\;(\delta_3)$"
la var treated_post_shift_share "$\text{Duke}_{ct}\times\text{Sulfa}_t\times\text{Pre-pneumonia}_c\;\;(\delta_4)$"

***** Main table with continuous Sulfa x Duke interaction *****

// Pooled IMR - Poisson with controls and weights
ppmlhdfe imr_pub ///
	treated_post_shift_share ///
	treated ///
	treated_post_sulfa treated_shift_share post_sulfa_shift_share  ///
	`baseline_controls' [pw = births_pub], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(_b[treated_post_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")


	* Panel A: DDD
	
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_post_shift_share])-1),  comtype("nlcom_pois") statname(ddd_)

	* Panel B: Difference - Duke vs. no Duke
	
	* Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_high_)
	* Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_low_)
	* Pre-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p75'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_high_)
	* Pre-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p25'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_low_)
	
	* Panel C: Difference-in-differences
	
	* Pre- vs. Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_high_)
	* Pre- vs. Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_low_)
	* High vs. low pneumonia, Post-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(high_low_post_)
	* High vs. low pneumonia, Pre-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(high_low_pre_)

eststo p1c1



* Black IMR

// Flag counties with black births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0), by(fips)

ppmlhdfe imr_pub_bk ///
	treated_post_shift_share ///
	treated ///
	treated_post_sulfa treated_shift_share post_sulfa_shift_share  ///
	`baseline_controls' if ever_zero_births == 0 [pw = births_pub_bk], ///
	absorb(fips year ) vce(cluster fips)  
	
lincomestadd2a 100*(exp(_b[treated_post_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")
	
	* Panel A: DDD
	
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_post_shift_share])-1),  comtype("nlcom_pois") statname(ddd_)
	
	* Panel B: Difference - Duke vs. no Duke
	
	* Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_high_)
	* Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_low_)
	* Pre-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p75'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_high_)
	* Pre-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p25'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_low_)
	
	* Panel C: Difference-in-differences
	
	* Pre- vs. Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_high_)
	* Pre- vs. Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_low_)
	* High vs. low pneumonia, Post-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(high_low_post_)
	* High vs. low pneumonia, Pre-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(high_low_pre_)

eststo p1c2



* White IMR
ppmlhdfe imr_pub_wt ///
	treated_post_shift_share ///
	treated ///
	treated_post_sulfa treated_shift_share post_sulfa_shift_share  ///
	`baseline_controls' [pw = births_pub_wt], ///
	absorb(fips year ) vce(cluster fips)  
	
lincomestadd2a 100*(exp(_b[treated_post_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")
	
	
	* Panel A: DDD
	
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_post_shift_share])-1),  comtype("nlcom_pois") statname(ddd_)
	
	* Panel B: Difference - Duke vs. no Duke
	
	* Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_high_)
	* Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + _b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(post_low_)
	* Pre-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p75'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_high_)
	* Pre-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated] + `pneumonia_p25'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(pre_low_)
	
	* Panel C: Difference-in-differences
	
	* Pre- vs. Post-Sulfa, high pneumonia (p75)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p75'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_high_)
	* Pre- vs. Post-Sulfa, low pneumonia (p25)
	lincomestadd2a 100*(exp(_b[treated_post_sulfa] + `pneumonia_p25'*(_b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(pre_post_low_)
	* High vs. low pneumonia, Post-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*(_b[treated_shift_share] + _b[treated_post_shift_share]))-1), comtype("nlcom_pois")  statname(high_low_post_)
	* High vs. low pneumonia, Pre-Sulfa
	lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[treated_shift_share])-1), comtype("nlcom_pois")  statname(high_low_pre_)
	
eststo p1c3

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
	
esttab p1c1 p1c2 p1c3 using "$PROJ_PATH/analysis/output/main/table_5_continuous_sulfa_interaction.tex", `booktabs_default_options' replace ///
mgroups("Pooled" "Black" "White", pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
posthead("`numbers_main'") nomtitles ///
prehead("&\multicolumn{3}{c}{\$Y^{R}_{ct} = \text{Infant mortality rate}$}\\\cmidrule(lr){2-4}\\") ///
prefoot("\midrule \multicolumn{4}{l}{\emph{A. Interaction of Duke rollout $\times$ sulfa shift-share DiD}} \\") ///
drop(*) ///
stats(	ddd_b ddd_se ///
		post_high_b post_high_se post_low_b post_low_se pre_high_b pre_high_se pre_low_b pre_low_se ///
		pre_post_high_b pre_post_high_se pre_post_low_b pre_post_low_se high_low_post_b high_low_post_se high_low_pre_b high_low_pre_se ///
		N, fmt(%9.0fc) ///
	labels(		`"\addlinespace\hspace{.5cm} Post-pre sulfa $\text{Pneumonia}_{.75}$ --"' ///
					`"\hspace{.5cm} $\quad$ Post-pre sulfa $\text{Pneumonia}_{.25}$ ($\gamma_5$)"' ///
			`"\addlinespace \emph{B. Duke vs. no Duke} &&& \\ \addlinespace\hspace{.5cm} Post-Sulfa, $\text{Pneumonia}_{.75}$"' ///
					`"\hspace{.5cm} $\quad\gamma_1 + \gamma_2 + \eta_{.75}\times$ ($\gamma_3 + \gamma_5$)"' ///
				`"\addlinespace\hspace{.5cm} Post-Sulfa, $\text{Pneumonia}_{.25}$"' ///
					`"\hspace{.5cm} $\quad\gamma_1 + \gamma_2 + \eta_{.25}\times$ ($\gamma_3 + \gamma_5$)"' ///
				`"\addlinespace\hspace{.5cm} Pre-Sulfa, $\text{Pneumonia}_{.75}$"' ///
					`"\hspace{.5cm} $\quad\gamma_1 + \eta_{.75}\times\gamma_3$"' ///
				`"\addlinespace\hspace{.5cm} Pre-Sulfa, $\text{Pneumonia}_{.25}$"' ///
					`"\hspace{.5cm} $\quad\gamma_1 + \eta_{.25}\times\gamma_3$"' ///
			`"\addlinespace \multicolumn{4}{l}{\emph{C. (Duke vs. no Duke) $\times$ (Pre vs. post sulfa) or (Duke vs. no Duke) $\times$ (Pneumonia IQR)}} \\ \addlinespace\hspace{.5cm} $\text{Pneumonia}_{.75}$, Post-pre Sulfa"' ///
					`"\hspace{.5cm} $\quad\gamma_2 + \eta_{.75}\times\gamma_5$"' ///
				`"\addlinespace\hspace{.5cm} $\text{Pneumonia}_{.25}$, Post-pre Sulfa"' ///
					`"\hspace{.5cm} $\quad\gamma_2 + \eta_{.25}\times\gamma_5$"' ///
				`"\addlinespace\hspace{.5cm} Post-Sulfa, $\text{Pneumonia}_{IQR}$"' ///
					`"\hspace{.5cm} $\quad$ ($\eta_{.75}$ -- $\eta_{.25}$) $\times$ ($\gamma_3 + \gamma_5$)"' ///
				`"\addlinespace\hspace{.5cm} Pre-Sulfa, $\text{Pneumonia}_{IQR}$"' ///
					`"\hspace{.5cm} $\quad$ ($\eta_{.75}$ -- $\eta_{.25}$) $\times\gamma_3$"' ///
				`"\addlinespace\hspace{.5cm} Observations"')) postfoot("")
			

			
***************************************/
***** Table 6: Long-run mortality *****
***************************************

// Pooled and by race - with age interactions - Poisson specification

// Panel start and end dates
local year_start 	1932
local year_end 		1941

// Fixed effects 
local fixed_effects "i.age##i.fips i.age##i.year"
local race_int_fixed_effects "i.age##i.fips##i.race i.age##i.year##i.race"


// Pooled 
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear

* Binary treatment 
	// Column 1 - Poisson deaths - no controls - no weights
	eststo p1_c1: ppmlhdfe deaths b0.treated, absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 2 - Poisson deaths - no controls -  weights
	eststo p1_c2: ppmlhdfe deaths b0.treated [pw = births_pub], absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 3 - Poisson deaths - controls -  weights
	eststo p1_c3: ppmlhdfe deaths b0.treated [pw = births_pub], absorb("`fixed_effects'   `int_baseline_controls'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	
// By race
		
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta", clear

// Flag counties with births or population ever equal to zero
egen ever_zero_births = max(births_pub == 0), by(fips)
egen ever_zero_pop = max(population == 0), by(fips)


* Black Binary treatment 
	// Column 1 - Poisson deaths - no controls - no weights
	eststo p2_c1: ppmlhdfe deaths b0.treated if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 2 - Poisson deaths - no controls -  weights
	eststo p2_c2: ppmlhdfe deaths b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 3 - Poisson deaths - controls -  weights
	eststo p2_c3: ppmlhdfe deaths b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'  `int_baseline_controls' ") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")


* White Binary treatment 
	// Column 1 - Poisson deaths - no controls - no weights
	eststo p3_c1: ppmlhdfe deaths b0.treated if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 2 - Poisson deaths - no controls -  weights
	eststo p3_c2: ppmlhdfe deaths b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

	// Column 3 - Poisson deaths - controls -  weights
	eststo p3_c3: ppmlhdfe deaths b0.treated  [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'  `int_baseline_controls' ") vce(cluster fips)
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")


* Fully interacted Binary treatment 
	// Column 1 - Poisson deaths - no controls - no weights
	eststo p4_c1: ppmlhdfe deaths b0.treated##i.race if ever_zero_births == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	test _b[1.treated#2.race] = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value' 
	
	// Column 2 - Poisson deaths - no controls -  weights
	eststo p4_c2: ppmlhdfe deaths b0.treated##i.race  [pw = births_pub] if ever_zero_births == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	test _b[1.treated#2.race] = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value' 
		
	// Column 3 - Poisson deaths - controls -  weights
	eststo p4_c3: ppmlhdfe deaths b0.treated##i.race  `race_int_baseline_controls' [pw = births_pub] if ever_zero_births == 0, absorb("`race_int_fixed_effects'  ") vce(cluster fips)
	test _b[1.treated#2.race] = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value' 

////////////////////////////////////////////////////////////////////////////////

// Prepare table
local numbers_main 	"& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
local y_1 			`"\$Y^{R}_{ct} = \text{Long-run deaths}$"'

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3
 using "$PROJ_PATH/analysis/output/main/table_6_long_run_mortality_poisson.tex", `booktabs_default_options' drop(*) replace 
 mgroups("`macval(y_1)'", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 
 using "$PROJ_PATH/analysis/output/main/table_6_long_run_mortality_poisson.tex", `booktabs_default_options' drop(*) append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 
 using "$PROJ_PATH/analysis/output/main/table_6_long_run_mortality_poisson.tex", `booktabs_default_options' drop(*) append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 
 using "$PROJ_PATH/analysis/output/main/table_6_long_run_mortality_poisson.tex", `booktabs_default_options' drop(*) append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth X Age FE 		& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth X Age FE 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\   
	Weights 						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\
	Controls						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr



disp "DateTime: $S_DATE $S_TIME"

* EOF