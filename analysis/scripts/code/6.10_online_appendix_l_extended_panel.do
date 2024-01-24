version 15
disp "DateTime: $S_DATE $S_TIME"

***********
* SCRIPT: 6.xx_online_appendix_extended_panel.do
* PURPOSE: Run analysis for Appendix L - Adding additional years of data to the end of the sample
	
************

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _) drop(*)"
local booktabs_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"
local baseline_controls_int "c.percent_illit##i.race c.percent_black##i.race c.percent_other_race##i.race c.percent_urban##i.race c.retail_sales_per_capita##i.race c.chd_presence##i.race"	

// Duke treatment variable 
local treat "capp_all"

// List of Southern states 
global southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

/////////////////////////////////////////////////////////////////////////////////////
// Create extended panel data for hospitals (1922-1950)

// Panel start and end dates
local year_start 	1922
local year_end 		1950

// Restrict to extended sample years 
use "$PROJ_PATH/analysis/processed/data/hospitals/hospital-by-year_panel_data.dta" if year >= `year_start' & year <= `year_end', clear

// Drop flagged categories 
desc flag_*, f 
foreach var of varlist flag_* {
	tab `var', m
	bysort hosp_id: egen ever_`var' = max(`var')
	gunique hosp_id if capp_all > 0 & ever_`var' == 1 // Check if we're dropping Duke funded hospitals
	drop if ever_`var' == 1
}

// Create lables for types of hospitals 
tab hosp_type, m 
tab hosp_control, m 

gsort hosp_id year

gen current_general =  0
replace current_general = 1 if hosp_type == "General"
bysort hosp_id (year): egen ever_general  = max(current_general)

gen current_non_profit =  0
replace current_non_profit = 1 if hosp_control == "Non-profit"
bysort hosp_id (year): egen ever_non_profit  = max(current_non_profit)

gen current_church =  0
replace current_church = 1 if hosp_control == "Church"
bysort hosp_id (year): egen ever_church  = max(current_church)

gen current_public =  0
replace current_public = 1 if hosp_control == "Public"
bysort hosp_id (year): egen ever_public  = max(current_public)

gen current_prop =  0
replace current_prop = 1 if hosp_control == "Proprietary"
bysort hosp_id (year): egen ever_prop  = max(current_prop)

gen current_likely =  0
replace current_likely = 1 if current_public == 1 | current_church == 1 | current_non_profit == 1
bysort hosp_id (year): egen ever_likely  = max(current_likely)

gunique hosp_id if capp_all > 0 & ever_general == 0 
keep if ever_general == 1

gunique hosp_id if capp_all > 0 & ever_likely == 0 & ever_prop == 0
keep if ever_likely == 1 | ever_prop == 1

// Create a measure for total hospitals (for collapsing) and closure
gen tot_hospitals = 1
gen closure = (year == last_year)

// Create separate variables for types of beds
gen i_beds_current_likely = 0
replace i_beds_current_likely = i_tot_beds_aha if current_likely == 1

gen i_beds_current_gen = 0
replace i_beds_current_gen = i_tot_beds_aha if current_general == 1

gen i_beds_ever_likely = 0
replace i_beds_ever_likely = i_tot_beds_aha if ever_likely == 1

gen i_beds_ever_gen = 0
replace i_beds_ever_gen = i_tot_beds_aha if ever_general == 1

// Keep only what we will need
keep hosp_id year fips institution i_tot_beds_amd i_tot_beds_aha i_beds_per_pop_aha ///
i_usage ///
est_year capp_all capp_ex_nurse capp_new_hosp capp_addition capp_equipment ///
capp_purchase capp_not_stated frst_year last_year pop_total births_occ ///
current_general ever_general current_prop ever_prop current_non_profit ever_non_profit current_church ///
ever_church current_public ever_public current_likely ever_likely tot_hospitals ///
closure i_beds_current_likely i_beds_current_gen i_beds_ever_likely i_beds_ever_gen

foreach t in likely general prop {
	foreach h in amd aha {
		gen i_`t'_beds_`h' = 0
		replace i_`t'_beds_`h' = i_tot_beds_`h' if current_`t' == 1
	}
}
foreach t in likely general prop {
		gen tot_hosp_`t' = 0
		gen closure_`t' = 0
		replace tot_hosp_`t' = 1 if tot_hospitals == 1 & current_`t' == 1
		replace closure_`t' = 1 if closure == 1 & current_`t' == 1
	
}

// Collapse to the county level. 
collapse (sum) ///
i_tot_beds_amd i_tot_beds_aha  ///
i_likely_* i_prop_* i_general_* ///
tot_hosp* closure* ///
i_usage ///
capp_all capp_ex_nurse capp_new_hosp capp_addition capp_equipment ///
capp_purchase capp_not_stated ///
, by(year fips)

tempfile county_level_hospitals
save `county_level_hospitals', replace


// Use NHGIS data for controls/weights
use statefip fips year percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita using ///
	"$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", clear

keep if statefip == 37 & year >= `year_start' & year <= `year_end'

xtset fips year

// Merge in CHD presence
fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", assert(2 3) keep(3) nogen keepusing(chd_presence)

// Merge with published birth cohort size by race 
fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_cohorts_by_year.dta", keep(1 3) nogen keepusing(births_pub*)
sort fips year 
bysort fips: carryforward births_pub* if year > 1948 & year <= 1950, replace
// Merge in hospitals 
fmerge 1:1 fips year using `county_level_hospitals', assert(1 3) nogen 

recode tot_* i_* closure* capp* births_pub* (mis = 0)
gisid fips year
gsort fips year
order fips year 
xtset fips year

// Generate "per 1,000" measures of beds and usage 
gen i_tot_beds_amd_pc =  (i_tot_beds_amd/births_pub)*1000
label var i_tot_beds_amd_pc "Total beds per 1,000 live births in county, AMD"
label var i_tot_beds_amd "Total beds, AMD"

gen i_tot_beds_aha_pc =  (i_tot_beds_aha/births_pub)*1000
label var i_tot_beds_aha_pc "Total beds per 1,000 live births in county, AHA"
label var i_tot_beds_aha "Total beds, AHA"

gen i_likely_beds_amd_pc =  (i_likely_beds_amd/births_pub)*1000
label var i_likely_beds_amd_pc "Total non-profit/church/public beds per 1,000 live births in county, AMD"
label var i_likely_beds_amd "Total non-profit/church/public beds, AMD"

gen i_likely_beds_aha_pc =  (i_likely_beds_aha/births_pub)*1000
label var i_likely_beds_aha_pc "Total non-profit/church/public beds per 1,000 live births in county, AHA"
label var i_likely_beds_aha "Total non-profit/church/public beds, AHA"

gen i_prop_beds_amd_pc =  (i_prop_beds_amd/births_pub)*1000
label var i_prop_beds_amd_pc "Total proprietary beds per 1,000 live births in county, AMD"
label var i_prop_beds_amd "Total proprietary beds, AMD"

gen i_prop_beds_aha_pc =  (i_prop_beds_aha/births_pub)*1000
label var i_prop_beds_aha_pc "Total proprietary beds per 1,000 live births in county, AHA"
label var i_prop_beds_aha "Total proprietary beds, AHA"

gen tot_hosp_likely_pc =  (tot_hosp_likely/births_pub)*1000
label var tot_hosp_likely_pc "Total  non-profit/church/public hospitals per 1,000 live births in county"
label var tot_hosp_likely "Total non-profit/church/public hospitals"

gen tot_hosp_prop_pc =  (tot_hosp_prop/births_pub)*1000
label var tot_hosp_prop_pc "Total  proprietary hospitals per 1,000 live births in county"
label var tot_hosp_prop "Total proprietary hospitals in county"

gen tot_hospitals_pc =  (tot_hospitals/births_pub)*1000
label var tot_hospitals_pc "Total hospitals per 1,000 live births in county"
label var tot_hospitals "Total hospitals in county"

gen share_likely = i_likely_beds_aha/i_tot_beds_aha
gen share_prop = i_prop_beds_aha/i_tot_beds_aha

tempfile hospitals_1922_1950
save `hospitals_1922_1950', replace


// Run additional analysis
local stackMin		-6
local stackMax		15
local weightvar  	births_pub

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
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main' \midrule") 
keep(1.treated) coeflabels(1.treated "\emph{A. Beds} &&&&&& \\ \addlinespace\hspace{.5cm} Total") ;
#delimit cr

// Beds - Church/ NP/ Public 
#delimit ;
esttab c_cl_1 c_cl_2 c_cl_3  c_rl_1 c_rl_2 c_rl_3
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Non-profit/church/public") ;
#delimit cr

// Beds - Proprietary
#delimit ;
esttab c_cp_1 c_cp_2 c_cp_3  c_rp_1 c_rp_2 c_rp_3
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' append 
keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Proprietary") ;
#delimit cr

// Number of hospitals - Any 
#delimit ;
esttab c_ch_1 c_ch_2 c_ch_3  c_rh_1 c_rh_2 c_rh_3
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' append 
keep(1.treated) coeflabels(1.treated "\emph{B. Hospitals} &&&&&& \\ \addlinespace\hspace{.5cm} Total") ;
#delimit cr

// Make 3rd panel - Number of hospitals - Church/ NP/ Public  
#delimit ;
esttab c_clh_1 c_clh_2 c_clh_3  c_rlh_1 c_rlh_2 c_rlh_3
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' append 
keep(1.treated) coeflabels(1.treated " \addlinespace\hspace{.5cm} Non-profit/church/public") ;
#delimit cr

// Number of hospitals - Proprietary 
#delimit ;
esttab c_cph_1 c_cph_2 c_cph_3  c_rph_1 c_rph_2 c_rph_3
 using "$PROJ_PATH/analysis/output/appendix/table_l1_county_level_hospitals_1922_1950.tex", `booktabs_options' append 
keep(1.treated) coeflabels(1.treated " \addlinespace\hspace{.5cm} Proprietary") 
stats(N, fmt(%9.0fc) labels("\addlinespace Observations") layout("\multicolumn{1}{c}{@}"))
postfoot("\midrule 
	County FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr	


///////////////////////////////////////
// Event studies

local z = 1
local weightvar  births_pub

foreach depvar in i_tot_beds_aha i_likely_beds_aha i_prop_beds_aha { 
							
	// Load county-level first-stage hospitals data 
	use `hospitals_1922_1950', clear 

	local lbl: var label `depvar'
	di "`lbl'"
	
	// Add Duke treatment 
	duketreat, treatvar(`treat') time(year) location(fips)

	// Create separate version of treatment for Callaway-Sant'Anna with untreated coded to 0
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
		
	
	// TWFE OLS estimation
	
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
	mat list event_time_names
					
	local unique_event_times = r(r)
	di `unique_event_times'
	
	// Find out which event time in the pre-period is closest to -1
	capture drop event_time_names1
	svmat event_time_names
	preserve 
		drop if event_time_names1 >= 0
		egen ref_event_time = max(event_time_names1)
		sum ref_event_time
		local ref_event_time = r(mean)
	restore
	di `ref_event_time'
	capture drop event_time_names1
		
	recode event_time_bacon (.=`ref_event_time')
	*ensure that "xi" omits -1
	char event_time_bacon[omit] `ref_event_time'

	xi i.event_time_bacon, pref(_T)
	
	reghdfe `depvar' ///
				_T* ///
				[aw = `weightvar'] ///
				, absorb(fips year) vce(cluster fips)	
				
	mat b = e(b)'
	mat list b 
	mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
	mat list b

	mata st_matrix("ll", (st_matrix("e(b)"))'- invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
	mat list ll
	mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
	mat list ll
	
	mata st_matrix("ul", (st_matrix("e(b)"))'+ invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
	mat list ul
	mata st_matrix("ul",select(st_matrix("ul"),st_matrix("ul")[.,1]:!=0))
	mat list ul		
	
	levelsof(event_time_bacon) if event_time_bacon != `ref_event_time' & !missing(`depvar') , matrow(event_time_names_without_ref) 
	
	// Find out max order
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order
		local max_pos = r(max)
	restore
	di `max_pos'
	capture drop event_time_names_without_ref1		
				
	// Combine event time, coef, lower ci, and upper ci into one matrix
	mat twfe_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list twfe_results
								
	// Find out order of event time in the pre-period is right before reference event-time
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		drop if event_time_names_without_ref1 >= 0
		egen time_b4_ref_event_time = max(event_time_names_without_ref1)
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order if time_b4_ref_event_time == event_time_names_without_ref1
		local time_b4_ref_event_time = r(mean)
	restore
	capture drop event_time_names_wo_ref_capped1
	
	// Find out order of event time in the post-period is right after reference event-time
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		egen time_after_ref_event_time = min(event_time_names_without_ref1) if event_time_names_without_ref1 >= 0
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order if time_after_ref_event_time == event_time_names_without_ref1
		local time_after_ref_event_time = r(mean)
		
		sum temp_order
		local max_pos = r(max)
	restore
	capture drop event_time_names_wo_ref_capped1		
		
	// Add row where reference group should be
	mat twfe_results = twfe_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ twfe_results[`time_after_ref_event_time'..`max_pos',.]
	mat list twfe_results
							
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1
				
	// csdid of Callaway and Sant'Anna

	*Estimation
	csdid `depvar' [iw = `weightvar'], ivar(fips) time(year) gvar(time_treated_2) agg(event)
	
	*Aggregation
	csdid_estat event
	
	* Store event-study info
	local evlist = subinstr("`:colname r(table)'","T","",.)
	local evlist = subinstr("`evlist'","m","-",.)
	local evlist = subinstr("`evlist'","p","+",.)
	 
	matrix mm = r(table)'
	matrix mm=mm[3...,....]
	
	tsvmat mm, name(cs_b cs_se cs_z cs_p cs_ll cs_ul)
	qui:gen cs_order =.
	local k = 0
	foreach i of local evlist {
		if !inlist("`i'","Pre_avg","Post_avg")  {
			local k = `k'+1
			qui:replace cs_order =`i' in `k'
		} 	
	}
	mkmat cs_order cs_b cs_se cs_z cs_p cs_ll cs_ul, matrix(cs_results) nomissing

	mat list cs_results

	
	////////////////////////////////////////////////////////////////////////////////

	clear
	tempfile twfe_results
	svmat twfe_results
	rename twfe_results1 order
	rename twfe_results2 b
	rename twfe_results3 ll
	rename twfe_results4 ul
	gen method = "twfe"

	save "`twfe_results'"

	clear
	tempfile cs_results
	svmat cs_results, names(col)
	rename cs_b b
	rename cs_ll ll
	rename cs_ul ul
	gen method = "cs"
	rename cs_order order

	save "`cs_results'"


	append using "`twfe_results'"

	replace b = 0 if missing(b) & order == -1

	////////////////////////////////////////////////////////////////////////////////
	// Figure 
	
	gen new_id = 0 
	replace new_id = 1 if method == "twfe"
	replace new_id = 2 if method == "cs"

	// generate code that will take order and shift new_id value 1 to the left by .25 and new_id value 2 to the right by .25
	// 
	gen modified_event_time = order + (new_id - 2)/4 + 1/8

	keep if order >= -6
	keep if order <= 15
	sort modified_event_time
	order modified_event_time

	local gphMin -6
	local gphMax 15
	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'



	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	di "`high_event_cap_graph'"

	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

	// File settings
	if "`depvar'" == "i_tot_beds_aha" {
		local panel "a"
		local title "total_beds"
	} 
	if "`depvar'" == "i_likely_beds_aha" {
		local panel "b"
		local title "likely_beds"
	} 
	if "`depvar'" == "i_prop_beds_aha" {
		local panel "c"
		local title "private_beds"
		
	}
	
	// Plot estimates
	twoway ///
		|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
		|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
		|| rcap ll ul modified_event_time if  new_id == 2, fcol("sea") lcol("sea") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 2,  col(white) msize(3) msymbol(c)  /// highlighting
		|| scatter b modified_event_time if  new_id == 2,  col("sea") msize(2) msymbol(c)  /// connect estimates
		|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(`low_label_cap_graph'(1)`high_label_cap_graph'  ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%3.2f)) ///		
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(order(3 "TWFE" ///
						6 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/appendix/figure_l1`panel'_`title'_first_stage_1922_1950.png", replace
		graph export "$PROJ_PATH/analysis/output/appendix/figure_l1`panel'_`title'_first_stage_1922_1950.pdf", replace 
	
}


/////////////////////////////////////////////////////////////////////////////////////
// Create extended panel data for infant mortality (1922-1962)

// Panel start and end dates
local year_start 	1922
local year_end 		1940

/////////////////////////////////////////////////////////////////////////////////
// Open NC imr data, keep county identifiers, then merge in extended series of infant deaths
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 , clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

bysort fips: keep if _n == 1
keep fips ever_treated
tempfile duke_fips
save `duke_fips', replace

/////////////////////////////////////////////////////////////////////////////////
// Open birth data from pvf, keep county identifiers, then merge in extended series of infant deaths
use "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta", clear
bysort fips: keep if _n == 1
keep fips
tempfile pvf_fips
save `pvf_fips', replace

/////////////////////////////////////////////////////////////////////////////////
// Open extended series of infant deaths
use "$PROJ_PATH/analysis/raw/icpsr/36603-0001-Data.dta", clear

// Keep pooled (for now)
keep if RACE == 0 

// Gen fips for merge 
gen fips = STATEFIP*10000 + V_H_COUNTYCODE
rename YEAR year
keep fips year IM_OCC IM_RES BIRTHS_OCC BIRTHS_RES IM_OCC_FIXED IM_RES_FIXED ATTHOSPITAL_OCC ATTHOSPITAL_RES BWLESSEQ2500G_OCC BWLESSEQ2500G_RES DRADATE BRADATE
merge m:1 fips using  `pvf_fips', nogen keep(3) 

// Generate a series of infant mortality rates. 
gen infant_deaths = IM_OCC
replace infant_deaths = IM_RES if missing(IM_OCC)

gen infant_births = BIRTHS_OCC
replace infant_births = BIRTHS_RES if missing(BIRTHS_OCC)

// Collapse the IMR for whole series 
rename infant_deaths mort_bailey
rename infant_births births_bailey

keep fips year mort_bailey births_bailey
tempfile imr_bailey_full_non_NC
save `imr_bailey_full_non_NC', replace

collapse (sum) mort_bailey births_bailey, by(year)

gen imr_bailey = (mort_bailey/births_bailey)*1000


tempfile imr_bailey
save `imr_bailey', replace

/////////////////////////////////////////////////////////////////////////////////
// Open extended series of infant births for NC
use "$PROJ_PATH/analysis/raw/icpsr/36603-0001-Data.dta", clear

// Keep pooled (for now)
keep if RACE == 0 

// Gen fips for merge 
gen fips = STATEFIP*10000 + V_H_COUNTYCODE
rename YEAR year
keep fips year BIRTHS_OCC
merge m:1 fips using  `duke_fips', nogen keep(3) 
rename BIRTHS_OCC births_bailey

tempfile imr_bailey_full_NC
save `imr_bailey_full_NC', replace
rename births_bailey births_bailey_
collapse (sum) births_bailey_ ,  by(year ever_treated)

reshape wide births_bailey_, i(year) j(ever_treated)
rename *_1 *_NC_treated
rename *_0 *_NC_untreated

tempfile births_bailey
save `births_bailey', replace


/////////////////////////////////////////////////////////////////////////////////
// Open pvf imr data
use "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta", clear
collapse (sum) mort births_pub, by(year)
gen imr_pvf = (mort/births_pub)*1000
rename mort mort_pvf
rename births_pub births_pvf

tempfile imr_pvf
save `imr_pvf', replace

/////////////////////////////////////////////////////////////////////////////////
// Open NC imr data
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 , clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

keep mort births_pub year ever_treated
collapse (sum) mort births_pub, by(year ever_treated)
gen imr_pub_ = (mort/births_pub)*1000
rename mort mort_pub_
rename births_pub births_pub_
reshape wide imr_pub_ mort_pub_ births_pub_, i(year) j(ever_treated)
rename *_1 *_NC_treated
rename *_0 *_NC_untreated

// Merge in other data 
merge 1:1 year using `imr_bailey', nogen
merge 1:1 year using `imr_pvf', nogen
merge 1:1 year using  `births_bailey', nogen

gen imr_bailey_NC_treated = (mort_pub_NC_treated/births_bailey_NC_treated)*1000
gen imr_bailey_NC_untreated = (mort_pub_NC_untreated/births_bailey_NC_untreated)*1000

twoway ///
    || connected imr_bailey year if year > 1924 & year < 1962, lcolor(black) lpattern(dash) lwidth(medthick)  msymbol(none) ///
    || connected imr_bailey_NC_treated year if year > 1924 & year < 1962, lcolor("230 65 115") lpattern("l") lwidth(thick)  msymbol(none) ///
    legend(off) ///
		xtitle("Year", size(5) height(7)) ///
		ytitle("", size(5)) ///
		subtitle("Pooled infant mortality rate, treated NC vs non-NC", size(5) pos(11)) ///
		xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		xlab(1925(5)1960, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xtitle("Year", size(5) height(7)) ///
				title("{bf:Pooled infant mortality by year comparing ever-treated NC}" "{bf:   to Duke-ineligible other southern counties}", size(6) pos(11)) ///
								subtitle("Infant deaths per 1,000 live births", size(5) pos(11)) ///
				text(43 1936 "Ever-treated (in NC)", size(large)) ///
				text(90 1940 "Other southern counties", size(large)) ///
				text(82 1940 "ineligible for Duke funding", size(large)) 

graph export "$PROJ_PATH/analysis/output/appendix/figure_l2a_imr_bailey_treated_vs_bailey_south_1962.pdf", replace


/////////////////////////////////////////////////////////////////////////////////
// Event-study
local graphMin -6 
local graphMax 15

// Open Bailey data
use `imr_bailey_full_NC', clear 
append using `imr_bailey_full_non_NC'
merge 1:1 fips year using  "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta"

keep if year >= `year_start'
keep if year <= 1962
replace capp_all = 0 if missing(capp_all)
drop ever_treated
duketreat, treatvar(`treat') time(year) location(fips)

gen mort_combined = mort 
replace mort_combined = mort_bailey if missing(mort)

gen births_combined = births_pub
replace births_combined = births_bailey if missing(births_pub)

gen imr_combined = (mort_combined/births_combined)*1000

local depvar imr_combined
local weightvar births_combined

	//  Make indicator for "control" counties in N.C.
	gen drop = 0 
	replace drop = 1 if statefip == 37 & ever_treated == 0


// Create separate version of treatment for Callaway-Sant'Anna with untreated coded to 0
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
	ppmlhdfe `depvar' b0.treated  [pw = `weightvar']    , ///
		absorb(fips year) vce(cluster fips)  	
	ppmlhdfe `depvar' b0.treated  [pw = `weightvar']  if drop == 0  , ///
		absorb(fips year) vce(cluster fips)  
	

	* gen event-time (adoption_date = treatment adoption date)
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
	replace event_time_bacon = `graphMax' + 1 if event_time_bacon > `graphMax'
	replace event_time_bacon = `graphMin' - 1 if event_time_bacon < `graphMin'
	mat list event_time_names
					
	local unique_event_times = r(r)
	di `unique_event_times'
	
	// Find out which event time in the pre-period is closest to -1
	capture drop event_time_names1
	svmat event_time_names
	preserve 
		drop if event_time_names1 >= 0
		egen ref_event_time = max(event_time_names1)
		sum ref_event_time
		local ref_event_time = r(mean)
	restore
	di `ref_event_time'
	capture drop event_time_names1
		
	recode event_time_bacon (.=`ref_event_time')
	*ensure that "xi" omits -1
	char event_time_bacon[omit] `ref_event_time'

	xi i.event_time_bacon, pref(_T)
	
	ppmlhdfe `depvar' ///
				_T* ///
				[pw = `weightvar']  if drop == 0 ///
				, absorb(fips year) cluster(fips) 	
	
	levelsof(event_time_bacon) if  !missing(`y_var') , local(event_time_names_with_ref)
	local wnum = 0
	forval j = 1/`=wordcount("`event_time_names_with_ref'")' {
		if word("`event_time_names_with_ref'", `j') == "`ref_event_time'" local wnum = `j'
	}
	local reference_year_pos = `wnum'
	local max_numb_event_tim = `=wordcount("`event_time_names_with_ref'")'

	local nlcom_list "(100*(exp(_b[_Tevent_tim_1])-1))"
	forvalues z = 2(1)`max_numb_event_tim' {
		if `z' != `reference_year_pos' {
			local nlcom_list "`nlcom_list' (100*(exp(_b[_Tevent_tim_`z'])-1))"
		}
	}
	di "`nlcom_list'"
	nlcom `nlcom_list'

	// List of coefficients, 95% CI, and event time
	mat b = r(b)'
	mat list b 
	mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
	mat list b
	mata st_matrix("ll", (st_matrix("r(b)"))'- invt(st_numscalar("e(df)"), 0.975)*sqrt(diagonal(st_matrix("r(V)"))))
	mat list ll
	mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
	mat list ll
	mata st_matrix("ul", (st_matrix("r(b)"))'+ invt(st_numscalar("e(df)"), 0.975)*sqrt(diagonal(st_matrix("r(V)"))))
	mat list ul
	mata st_matrix("ul",select(st_matrix("ul"),st_matrix("ul")[.,1]:!=0))
	mat list ul		
	
	levelsof(event_time_bacon) if event_time_bacon != `ref_event_time' & !missing(`depvar') , matrow(event_time_names_without_ref) 
	
	// Find out max order
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order
		local max_pos = r(max)
	restore
	di `max_pos'
	capture drop event_time_names_without_ref1		
				
	// Combine event time, coef, lower ci, and upper ci into one matrix
	mat ppml_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list ppml_results
								
	// Find out order of event time in the pre-period is right before reference event-time
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		drop if event_time_names_without_ref1 >= 0
		egen time_b4_ref_event_time = max(event_time_names_without_ref1)
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order if time_b4_ref_event_time == event_time_names_without_ref1
		local time_b4_ref_event_time = r(mean)
	restore
	capture drop event_time_names_wo_ref_capped1
	
	// Find out order of event time in the post-period is right after reference event-time
	capture drop event_time_names_without_ref1
	svmat event_time_names_without_ref
	preserve 
		egen time_after_ref_event_time = min(event_time_names_without_ref1) if event_time_names_without_ref1 >= 0
		gen temp_order = _n if !missing(event_time_names_without_ref1)
		sum temp_order if time_after_ref_event_time == event_time_names_without_ref1
		local time_after_ref_event_time = r(mean)
		
		sum temp_order
		local max_pos = r(max)
	restore
	capture drop event_time_names_wo_ref_capped1		
		
	// Add row where reference group should be
	mat ppml_results = ppml_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ ppml_results[`time_after_ref_event_time'..`max_pos',.]
	mat list ppml_results
							
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1


	clear
	tempfile ppml_results
	svmat ppml_results
	rename ppml_results1 order
	rename ppml_results2 b
	rename ppml_results3 ll
	rename ppml_results4 ul
	gen method = "poisson"

	save "`ppml_results'"

	replace b = 0 if missing(b) & order == -1

	////////////////////////////////////////////////////////////////////////////////
	// Figure 
	gen new_id = 0 
	replace new_id = 1 if method == "poisson"

	gen modified_event_time = order
	 
	keep if order >= `graphMin'
	keep if order <= `graphMax'
	sort modified_event_time
	order modified_event_time

	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	di "`high_event_cap_graph'"
	
	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'
	di "here"

	// Scale CS coefficients by 100
	replace ll = ll*100 if method == "cs"
	replace ul = ul*100 if method == "cs"
	replace b = b*100 if method == "cs"
	
	// Plot estimates
	twoway ///
		|| rarea ll ul modified_event_time if  new_id == 1,  fcol(gs14) lcol(white) msize(3) /// estimates
		|| connected b modified_event_time if  new_id == 1,  lw(1.1) col(white) msize(7) msymbol(s) lp(solid) /// highlighting
		|| connected b modified_event_time if  new_id == 1,  lw(0.6) col("230 65 115") msize(5) msymbol(s) lp(solid) /// connect estimates
		|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(-5(5)15 ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%3.2f)) ///		
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(off) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/appendix/figure_l2b_pooled_other_southern_states_event_study_bailey.png", replace
		graph export "$PROJ_PATH/analysis/output/appendix/figure_l2b_pooled_other_southern_states_event_study_bailey.pdf", replace 


***************************************************************************************
// Table L2 - Effects on infant mortality: Non-Carolina controls extended to 1962 *****
***************************************************************************************

////////////////////////////////////////////////////////////////
// Fishback
////////////////////////////////////////////////////////////////

// Short-run: Set up infant mortality analysis 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

// Append southern states 
append using "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta"

// Restrict to IV years 
keep if year >= `year_start' & year <= 1940

//  Make indicator for "control" counties in N.C.
gen drop = 0 
replace drop = 1 if statefip == 37 & ever_treated == 0

gen drop_inculde_no_np = 0 
replace drop_inculde_no_np = 1 if drop == 1
replace drop_inculde_no_np = 1 if statefip != 37  & ever_non_profit == 0


// Column 1 - Poisson IMR 
eststo fish_1: ppmlhdfe imr_pub b0.treated [pw = births_pub], absorb(fips year) vce(cluster fips)
		di "`e(cmdline)'"

	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 
// Column 2 - Poisson IMR - drop NC 
eststo fish_2: ppmlhdfe imr_pub b0.treated [pw = births_pub] if drop == 0, absorb(fips year) vce(cluster fips)
		di "`e(cmdline)'"
	lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 

	
	
////////////////////////////////////////////////////////////////
// Bailey
////////////////////////////////////////////////////////////////

// Open Bailey data
use `imr_bailey_full_NC', clear 
append using `imr_bailey_full_non_NC'
merge 1:1 fips year using  "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta"
keep if year >= `year_start'
keep if year <= 1962
replace capp_all = 0 if missing(capp_all)
drop ever_treated
duketreat, treatvar(`treat') time(year) location(fips)

gen mort_combined = mort 
replace mort_combined = mort_bailey if missing(mort)

gen births_combined = births_pub
replace births_combined = births_bailey if missing(births_pub)

gen imr_combined = (mort_combined/births_combined)*1000

local depvar imr_combined
local weightvar births_combined

//  Make indicator for "control" counties in N.C.
gen drop = 0 
replace drop = 1 if statefip == 37 & ever_treated == 0

// Restrict to fishback years       
    
	// Column 3 - Poisson IMR 
    eststo bail_3: ppmlhdfe imr_combined b0.treated [pw = births_combined] if year <= 1940 & year >= 1922, absorb(fips year) vce(cluster fips)
            di "`e(cmdline)'"

        lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 
    
	// Column 4 - Poisson IMR - drop NC 
    eststo bail_4: ppmlhdfe imr_combined b0.treated [pw = births_combined] if drop == 0 & year <= 1940 & year >= 1922, absorb(fips year) vce(cluster fips)
            di "`e(cmdline)'"
        lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 
		
// Extend sample out to 1962       

    // Column 3 - Poisson IMR 
    eststo bail_5: ppmlhdfe imr_combined b0.treated [pw = births_combined] if year <= 1962 & year >= 1922, absorb(fips year) vce(cluster fips)
            di "`e(cmdline)'"

        lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 
		
    // Column 4 - Poisson IMR - drop NC 
    eststo bail_6: ppmlhdfe imr_combined b0.treated [pw = births_combined] if drop == 0 & year <= 1962 & year >= 1922, absorb(fips year) vce(cluster fips)
            di "`e(cmdline)'"
        lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
		
// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 "Fishback data"
local y_2 "Bailey data"

local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"
local year_labels "&\multicolumn{4}{c}{1922-1940}          &\multicolumn{2}{c}{1922-1962}                                                        \\\cmidrule(lr){2-5}\cmidrule(lr){6-7}"

// Make top panel - Pooled
#delimit ;
esttab fish_1 fish_2 bail_3 bail_4 bail_5 bail_6 
using "$PROJ_PATH/analysis/output/appendix/table_l2_combined_mortality_poisson_clean_controls_1962.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`year_labels' `numbers_main' ")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule 
County of birth FE 						 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
Year of birth FE 			 			 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\   
Weights 								 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
Controls								 & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} \\
Exclude untreated NC 					 & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} \\");
#delimit cr

 

disp "DateTime: $S_DATE $S_TIME"

* EOF