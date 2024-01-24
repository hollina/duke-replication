version 15
disp "DateTime: $S_DATE $S_TIME"

***********
* SCRIPT: 4_compile_data.do
* PURPOSE: processes the main dataset in preparation for analysis

************

* User switches for each section of code
local duke 				1
local hosp_first_stage	1
local amd_physicians	1
local nc_deaths 		1

// For all things Southern 
local southern_deaths	1	// DEPENDENCIES: hosp_first_stage
local numident			1	// DEPENDENCIES: southern_deaths

// For other medical professionals (Appendix C)
local ipums 			1

// Duke treatment variable 
local treat 			"capp_all"

// List of Southern states 
local southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

************
* Code begins
************
******************************************************
// Create county-by-year panel data for Duke *********
******************************************************

if `duke' {

	// Load cleaned capital appropriations data 
	use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta" if statefip == 37, clear

	// Aggregrate capital appropriations data from hospital-by-year to county-by-year
	gcollapse (sum) appropriation app_payments capp_* pay_*, by(fips year) labelformat(#sourcelabel#)

	tempfile appropriations_1927_1962
	save `appropriations_1927_1962', replace

	
	// Load complete panel of counties for NC 
	use year statefip fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta" if year >= 1925 & statefip == 37, clear

	// Merge in inflation factor
	fmerge m:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) keep(3) nogen

	// Merge in appropriations and payments 
	fmerge 1:1 fips year using `appropriations_1927_1962', assert(1 3) keep(1 3) nogen keepusing(appropriation app_payments capp_* pay_*)

	replace appropriation = 0 if missing(appropriation)
	replace app_payments = 0 if missing(app_payments)
		
	foreach z in all ex_nurse new_hosp addition equipment purchase not_stated {

		replace capp_`z' = 0 if missing(capp_`z')
		replace pay_`z' = 0 if missing(pay_`z')
		
		// Create cumulative appropriations and payments - adjust for inflation before summing. 
		gisid fips year
		gsort fips year
		
		gen capp_`z'_adj = capp_`z'*inv_inflation_factor
		bysort fips (year): gen tot_capp_`z'_adj = capp_`z'_adj if _n == 1
		bysort fips (year): replace tot_capp_`z'_adj = capp_`z'_adj + tot_capp_`z'_adj[_n-1] if _n > 1
		
		// Adjust for inflation (i.e. convert to 2017 dollars) and re-scale units to 1,000,000 dollars
		replace tot_capp_`z'_adj = tot_capp_`z'_adj/1000000
		
		gisid fips year
		gsort fips year
		
		gen pay_`z'_adj = pay_`z'*inv_inflation_factor
		bysort fips (year): gen tot_pay_`z'_adj = pay_`z'_adj if _n == 1
		bysort fips (year): replace tot_pay_`z'_adj = pay_`z'_adj + tot_pay_`z'_adj[_n-1] if _n > 1
		
		// Adjust for inflation (i.e. convert to 2017 dollars) and re-scale units to 1,000,000 dollars
		replace tot_pay_`z'_adj = tot_pay_`z'_adj/1000000
	}

	order fips year 
	gisid fips year
	gsort fips year

	desc, f
	compress		
	save "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", replace

}


********************************************************
// Generate county-level hospital first stage data *****
********************************************************

if `hosp_first_stage' {
	
	// Panel start and end dates
	local year_start 	1922
	local year_end 		1942

	// Restrict to main sample years 
	use "$PROJ_PATH/analysis/processed/data/hospitals/hospital-by-year_panel_data.dta" if year >= `year_start' & year <= `year_end', clear
	
	// Drop flagged categories 
	desc flag_*, f 
	foreach var of varlist flag_* {
		tab `var', m
		bysort hosp_id: egen ever_`var' = max(`var')
		gunique hosp_id if capp_all > 0 & ever_`var' == 1
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

	gunique hosp_id if capp_all > 0 & ever_general == 0 // Here we drop two Duke-funded sanatorium since our analysis focuses on general hospitals
	keep if ever_general == 1
	
	gunique hosp_id if capp_all > 0 & ever_likely == 0 & ever_prop == 0
	keep if ever_likely == 1 | ever_prop == 1
	
	// Create a measure for total hospitals (for collapsing) and closure
	gen tot_hospitals = 1
	gen closure = (year == last_year)
	
	// Create separate variables for types of beds. 
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
	
	save "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", replace

}


******************************************************************
// Set up AMD physicians - doctor quality county-level panel *****
******************************************************************

if `amd_physicians' {
	
	// Set first and last year of AMD
	local first_year	1921
	local last_year		1942 
	
	// Set Duke treatment variable 
	local treated "capp_all" // capp_ex_nurse

	// Impute 1921 births using 1922 values 
	use fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_cohorts_by_year.dta", clear
	gduplicates drop 
	gen year = 1921
	tempfile births_1921
	save `births_1921', replace 
	
	// Published births by race - Collapse by AMD waves
	use fips year births_pub births_pub_wt births_pub_bk using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_cohorts_by_year.dta" if year <= `last_year', clear
	append using `births_1921'
	gsort fips year 

	bysort fips: egen birth_pub_22 = max(births_pub*(year == 1922))
	bysort fips: egen birth_pub_wt_22 = max(births_pub_wt*(year == 1922))
	bysort fips: egen birth_pub_bk_22 = max(births_pub_bk*(year == 1922))
	 
	replace births_pub = birth_pub_22 if missing(births_pub) & year == 1921
	replace births_pub_wt = birth_pub_wt_22 if missing(births_pub_wt) & year == 1921
	replace births_pub_bk = birth_pub_bk_22 if missing(births_pub_bk) & year == 1921
	drop birth_pub_22 birth_pub_wt_22 birth_pub_bk_22

	gen temp_year = . 
	replace temp_year = 1 if year > 1919 & year <= 1921
	replace temp_year = 2 if year > 1921 & year <= 1923
	replace temp_year = 3 if year > 1923 & year <= 1925
	replace temp_year = 4 if year > 1925 & year <= 1927
	replace temp_year = 5 if year > 1927 & year <= 1929
	replace temp_year = 6 if year > 1929 & year <= 1931
	replace temp_year = 7 if year > 1931 & year <= 1934
	replace temp_year = 8 if year > 1934 & year <= 1936
	replace temp_year = 9 if year > 1936 & year <= 1938
	replace temp_year = 10 if year > 1938 & year <= 1940
	replace temp_year = 11 if year > 1940 & year <= 1942

	drop year
	rename temp_year amd_wave
	assert !missing(amd_wave)
	collapse (mean) births_pub births_pub_wt births_pub_bk, by(fips amd_wave)

	tempfile births_amd_wave
	save "`births_amd_wave'", replace

	
	// NHGIS 
	use "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", clear
	keep fips year pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita 
			
	gen temp_year = . 
	replace temp_year = 1 if year > 1919 & year <= 1921
	replace temp_year = 2 if year > 1921 & year <= 1923
	replace temp_year = 3 if year > 1923 & year <= 1925
	replace temp_year = 4 if year > 1925 & year <= 1927
	replace temp_year = 5 if year > 1927 & year <= 1929
	replace temp_year = 6 if year > 1929 & year <= 1931
	replace temp_year = 7 if year > 1931 & year <= 1934
	replace temp_year = 8 if year > 1934 & year <= 1936
	replace temp_year = 9 if year > 1936 & year <= 1938
	replace temp_year = 10 if year > 1938 & year <= 1940
	replace temp_year = 11 if year > 1940 & year <= 1942

	drop year
	rename temp_year amd_wave
	collapse (mean) percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita, by(fips amd_wave)
	drop if missing(amd_wave)

	tempfile cntrls_amd_wave
	save "`cntrls_amd_wave'", replace


	// CHD 
	use "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_by_county.dta", clear
	keep fips start_year_* end_year_*
			
	foreach var in start_year_1 start_year_2 end_year_1 end_year_2 {
		gen amd_w_`var' = . 
		replace amd_w_`var' = 1 if `var' > 1919 & `var' <= 1921 & !missing(`var')
		replace amd_w_`var' = 2 if `var' > 1921 & `var' <= 1923 & !missing(`var')
		replace amd_w_`var' = 3 if `var' > 1923 & `var' <= 1925 & !missing(`var')
		replace amd_w_`var' = 4 if `var' > 1925 & `var' <= 1927 & !missing(`var')
		replace amd_w_`var' = 5 if `var' > 1927 & `var' <= 1929 & !missing(`var')
		replace amd_w_`var' = 6 if `var' > 1929 & `var' <= 1931 & !missing(`var')
		replace amd_w_`var' = 7 if `var' > 1931 & `var' <= 1934 & !missing(`var')
		replace amd_w_`var' = 8 if `var' > 1934 & `var' <= 1936 & !missing(`var')
		replace amd_w_`var' = 9 if `var' > 1936 & `var' <= 1938 & !missing(`var')
		replace amd_w_`var' = 10 if `var' > 1938 & `var' <= 1940 & !missing(`var')
		replace amd_w_`var' = 11 if `var' > 1940 & `var' <= 1942 & !missing(`var')
		
		drop `var'
		rename amd_w_`var' `var'
		
	}

	tempfile chd_amd_wave
	save "`chd_amd_wave'", replace
		
	// Create county-by-year data of number of doctors
	use "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta" if statefip == 37 & year >= `first_year' & year <= `last_year', clear

	// Make first exposure year variable
	capture drop exp_year
	gen exp_year = year if `treated' != 0 & !missing(`treated')
	gegen first_exp_year = min(exp_year), by(fips)

	keep fips first_exp_year
	gduplicates drop

	// Create two-year binned first exposure year 
	*gen time_treated = .
	*replace time_treated = floor((first_exp_year - `first_year')/2) + 1
	gen time_treated = . 
	replace time_treated = 1 if first_exp_year > 1919 & first_exp_year <= 1921
	replace time_treated = 2 if first_exp_year > 1921 & first_exp_year <= 1923
	replace time_treated = 3 if first_exp_year > 1923 & first_exp_year <= 1925
	replace time_treated = 4 if first_exp_year > 1925 & first_exp_year <= 1927
	replace time_treated = 5 if first_exp_year > 1927 & first_exp_year <= 1929
	replace time_treated = 6 if first_exp_year > 1929 & first_exp_year <= 1931
	replace time_treated = 7 if first_exp_year > 1931 & first_exp_year <= 1934
	replace time_treated = 8 if first_exp_year > 1934 & first_exp_year <= 1936
	replace time_treated = 9 if first_exp_year > 1936 & first_exp_year <= 1938
	replace time_treated = 10 if first_exp_year > 1938 & first_exp_year <= 1940
	replace time_treated = 11 if first_exp_year > 1940 & first_exp_year <= 1942

	tab first_exp_year time_treated, m 
	 
	// Sort and organize data
	keep fips time_treated
	order fips time_treated
	rename time_treated first_exp_year
	gsort fips first_exp_year

	tempfile first_duke_exposure_year
	save `first_duke_exposure_year', replace

	// Load cleaned AMD physician data with med school quality 
	use "$PROJ_PATH/analysis/processed/data/amd_physicians/amd_physicians_with_med_school_quality.dta" if year >= `first_year' & year <= `last_year', clear

	gen amd_wave = . 
	replace amd_wave = 1 if year > 1919 & year <= 1921
	replace amd_wave = 2 if year > 1921 & year <= 1923
	replace amd_wave = 3 if year > 1923 & year <= 1925
	replace amd_wave = 4 if year > 1925 & year <= 1927
	replace amd_wave = 5 if year > 1927 & year <= 1929
	replace amd_wave = 6 if year > 1929 & year <= 1931
	replace amd_wave = 7 if year > 1931 & year <= 1934
	replace amd_wave = 8 if year > 1934 & year <= 1936
	replace amd_wave = 9 if year > 1936 & year <= 1938
	replace amd_wave = 10 if year > 1938 & year <= 1940
	replace amd_wave = 11 if year > 1940 & year <= 1942

	gen md = 1
	collapse (sum) md*, by(statefip countyicp fips state county_nhgis gisjoin amd_wave year)

	la var year "Year of AMD records"
	la var md "Number of doctors"
	la var md_black "Black doctors"
	la var md_white "White doctors"

	la var md_good_1yr "Graduates from medical school with one- or two-year requirement"
	la var md_bad_1yr "Graduates from medical school without one- or two-year requirement"

	la var md_good_2yr "Graduates from medical school with two-year requirement"
	la var md_bad_2yr "Graduates from medical school without two-year requirement"

	la var md_good_ama "Graduates from medical school ever with A/A+ AMA rating"
	la var md_bad_ama "Graduates from medical school without A/A+ AMA rating"

	la var md_good_close "Graduates from medical school that remains open"
	la var md_bad_close "Graduates from medical school that closed"

	la var md_good_approve "Graduates from medical school that exists and is approved in 1942"
	la var md_bad_approve "Did not graduate from medical school that exists and is approved in 1942"

	la var md_good_approve_42 "Graduates from medical school that merged into a medical school that exists and is approved in 1942"
	la var md_bad_approve_42 "Did not graduate from medical school that merged into a medical school that exists and is approved in 1942"

	la var md_good_extinct "Graduates from medical school that is extinct in 1942"
	la var md_bad_extinct "Did not graduate from medical school that is extinct in 1942"

	la var md_good_extinct_42 "Graduates from medical school that merged into a medical school that is extinct in 1942"
	la var md_bad_extinct_42 "Did not graduate from medical school that merged into a medical school that is extinct in 1942"

	la var md_good_young "Doctor under 45 years of age"
	la var md_bad_young "Doctor 45 years old and up"

	la var md_good_recent "Doctors with academic age <= 10"
	la var md_bad_recent "Doctors with academic age > 10"

	la var md_good_all "High quality doctors"
	la var md_bad_all "Low quality doctors"

	// Label variables by race 
	foreach type in ama 1yr 2yr approve extinct approve_42 extinct_42 close recent young all {
		la var md_good_`type'_black "Black `: var label md_good_`type''"
		la var md_bad_`type'_black "Black `: var label md_bad_`type''"
		la var md_good_`type'_white "White `: var label md_good_`type''"
		la var md_bad_`type'_white "White `: var label md_bad_`type''"
	}

	// Create share variables 
	foreach type in ama 1yr 2yr approve extinct approve_42 extinct_42 close recent young all {
		gen shr_md_bad_`type' = md_bad_`type'/(md_bad_`type' + md_good_`type')
		la var shr_md_bad_`type' "Share `: var label md_bad_`type''"
		
		gen shr_md_bad_`type'_white = md_bad_`type'_white/(md_bad_`type'_white + md_good_`type'_white)
		la var shr_md_bad_`type'_white "Share `: var label md_bad_`type'_white'"
		
		gen shr_md_bad_`type'_black = md_bad_`type'_black/(md_bad_`type'_black + md_good_`type'_black)
		la var shr_md_bad_`type'_black "Share `: var label md_bad_`type'_black'"
		
	}

	// Use NHGIS data for controls/weights instead
	fmerge 1:1 fips amd_wave using "`cntrls_amd_wave'", assert(2 3) keep(3) nogen keepusing(percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita) 
	 
	// Create doctors per 1,000 births 
	// Add births
	merge 1:1 fips amd_wave using  "`births_amd_wave'", keep(3) keepusing(births_pub births_pub_wt births_pub_bk) nogen
	
	* Get variable names that start with "md_".
	ds md_*
	local mdvars = r(varlist)

	* Exclude variable names that end with "_white" or "_black".
	ds *_white *_black, not
	local mdvars_notwhiteblack = r(varlist)

	* Intersect the two lists to get the final list of variable names.
	local pooled_vars : list mdvars & mdvars_notwhiteblack
	di "`pooled_vars'"

	foreach var of local pooled_vars { 

		gen r`var' = (`var'/births_pub)*1000
		la var r`var' "`: var label `var'' per 1,000 births"

	}
		gen rmd = (md/births_pub)*1000
		la var rmd "Doctors per 1,000 births "

	ds md_*white, 
	local white_vars  `r(varlist)'

	foreach var of local white_vars { 
		
		gen r`var' = (`var'/births_pub_wt)*1000
		la var r`var' "`: var label `var'' per 1,000 births"

	}
	ds md_*black, 
	local black_vars `r(varlist)'

	foreach var of local black_vars { 
		
		gen r`var' = (`var'/births_pub_bk)*1000
		la var r`var' "`: var label `var'' per 1,000 births"

	}
		
	// Merge doctor counts with first Duke exposure year
	merge m:1 fips using `first_duke_exposure_year', assert(3) nogen
	sort fips year

	// Merge in CHD presence (NOTE: CHD presence data includes SC but AMD only includes NC)
	fmerge m:1 fips using "`chd_amd_wave'", assert(2 3) keep(3) nogen keepusing(start_year_* end_year_*)

	gen chd_presence = .

	replace chd_presence = 0 if missing(start_year_1)
	replace chd_presence = 1 if amd_wave >= start_year_1 & amd_wave <= end_year_1 & !missing(end_year_1)
	replace chd_presence = 1 if amd_wave >= start_year_1 & missing(end_year_1)
	replace chd_presence = 1 if amd_wave >= start_year_2 & amd_wave <= end_year_2 & !missing(start_year_2) & !missing(end_year_2)
	replace chd_presence = 1 if amd_wave >= start_year_2 & !missing(start_year_2) & missing(end_year_2)

	recode chd_presence (mis = 0)
	drop start_year_* end_year_*

	// Convert years to sequence of integers
	rename year calendar_year 
	gen year = amd_wave

	tab year calendar_year, m 
	tab first_exp_year, m

	// Generate ever treated
	gen ever_treated = 0 
	replace ever_treated = 1 if !missing(first_exp_year)

	// Generate post 
	gen post = 0 
	replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

	// Generate treated 
	gen treated = 0 
	replace treated = 1 if post == 1 & ever_treated == 1

	// Rename first year of exposure for event study
	rename first_exp_year time_treated
			
	// Set id and time
	xtset fips amd_wave
	desc, f

	save "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", replace
	
}


**************************************************************************
// NC Deaths: By county of birth - event study input *********************
**************************************************************************

if `nc_deaths' {
	
	use "$PROJ_PATH/analysis/processed/data/nc_deaths/nc_death_certificates_cleaned.dta" if bstate == 37 & byear >= 1915 & byear <= 1962 & dyear >= 1915 & dyear <= 1963, clear

	gen bdate = mdy(bmonth,bday,byear)
	gen ddate = mdy(dmonth,dday,dyear)
	format bdate ddate %td
	
	gen byrmon = ym(byear,bmonth)
	gen dyrmon = ym(dyear,dmonth)
	format byrmon dyrmon %tm
	
	// Flag same day deaths
	gen same_day_death = (byear == dyear & bmonth == dmonth & bday == dday & byear != . & dyear != . & bmonth != . & dmonth != . & bday != . & dday != .)
	tab same_day_death

	// Restrict to infant deaths 
	keep if age == 0

	// Main definition of mortality - exclude stillborn and unnamed infants who died on day 0
	replace no_name = 0 if same_day_death == 0
	gen mort = (stillborn == 0)*(no_name == 0)
	
	// Sub-period infant mortality outcomes
	tab same_day_death
	gen mort_day_0 = (same_day_death == 1)*(mort == 1)
	gen mort_day_1to365 = (mort_day_0 == 0)*(mort == 1)
	
// 	gen mort_day_1 = (ddate - bdate <= 1)*(mort == 1)
// 	gen mort_day_2to365 = (mort_day_1 == 0)*(mort == 1)
	
	gen mort_week_1 = (ddate - bdate <= 7)*(mort == 1)
	gen mort_week_2to52 = (mort_week_1 == 0)*(mort == 1)
	
		gen m1_cond1 = (ddate - bdate <= 30)
		gen m1_cond2 = (byrmon == dyrmon & byrmon != .)
		
	gen mort_month_1 = (m1_cond1 == 1 | m1_cond2 == 1)*(mort == 1)
	gen mort_month_2to12 = (mort_month_1 == 0)*(mort == 1)
	
		drop m1_cond1 m1_cond2
	
// 	gen mort_week_2to4 = (mort_month_1 - mort_week_1)*(mort == 1)
	
	// Add back excluded deaths for robustness
	
	gen mort_all = 1
	gen mort_excl_still = (stillborn == 0)
	gen mort_excl_nonam = (no_name == 0)
	
	gcollapse (sum) mort* stillborn no_name, by(bstate bctyfips byear age race)
	
	// Expand to include cells with no deaths
	
	glevelsof bctyfips, local(fips_list)
	glevelsof byear, local(byr_list)

	gen tempcount = 1
	count

	qui {
		foreach f of local fips_list {
			forvalues r = 1/2 {
				foreach y of local byr_list {
					sum tempcount if bctyfips == `f' & race == `r' & byear == `y'
						
					if ( r(N) == 0 ) {
					
						set obs `=_N+1'
						replace bctyfips = `f' in `=_N'
						replace race = `r' in `=_N'
						replace byear = `y' in `=_N'
						replace age = 0 if `=_N'
						replace mort = 0 in `=_N'
						replace stillborn = 0 in `=_N'
						replace no_name = 0 in `=_N'
					}
				}
			}
		}
	}

	foreach var of varlist mort_day_0 mort_day_1to365 mort_week_1 mort_week_2to52 mort_month_1 mort_month_2to12 mort_all mort_excl_still mort_excl_nonam {
		* mort_day_1 mort_day_2to365 mort_week_2to4
		recode `var' (mis = 0)
	}

	replace bstate = floor(bctyfips/10000) if bstate == .
	drop if bctyfips == .
	
	gisid bstate bctyfips race byear age
	gsort bstate bctyfips race byear age
	count
	
	drop tempcount
	

	// Scale up deaths with missing birth county

// 	preserve
//		
// 		keep if bctyfips == .
// 		keep bstate byear age race mort
// 		rename mort mort_na
// 		tempfile deaths_na
// 		save `deaths_na', replace
//		
// 	restore
//
// 	drop if bctyfips == .
//
//	
// 	egen tot_deaths = total(mort), by(bstate byear age race)
//
// 	fmerge m:1 bstate byear age race using `deaths_na', keep(1 3) nogen
// 	recode mort_na (mis = 0)
//
// 	gen mort_no_bcty = round(mort*(1+(mort_na/tot_deaths)))
// 	drop tot_deaths mort_na
//		
	order bstate bctyfips byear race age
	gisid bstate bctyfips byear race age
	gsort bstate bctyfips byear race age
	
	gen mort_wt = mort*(race == 1)
	gen mort_bk = mort*(race == 2)
	
	gen still_wt = stillborn*(race == 1)
	gen still_bk = stillborn*(race == 2)
	rename stillborn still
	
	gen no_name_wt = no_name*(race == 1)
	gen no_name_bk = no_name*(race == 2)
	
	foreach var of varlist mort_day_0 mort_day_1to365 mort_week_1 mort_week_2to52 mort_month_1 mort_month_2to12 mort_all mort_excl_still mort_excl_nonam  {
	
	* mort_day_1 mort_day_2to365 mort_week_2to4 mort_no_bcty
	
		gen `var'_wt = `var'*(race == 1)
		gen `var'_bk = `var'*(race == 2)
		
	}
	
	gcollapse (sum) mort* still* no_name*, by(bstate bctyfips byear age)
	
	order mort* still* no_name*, last
	
// 	gen still_shr = still/(mort_all)
// 	gen still_no_name_shr = (mort_all - mort)/mort_all
	
	// If there are no deaths, mortality variables are missing - impute zero
	recode mort* still* no_name* (mis = 0)
	
	rename byear year
	rename bstate statefip
	rename bctyfips fips

	// Merge with NHGIS county information
	fmerge m:1 statefip fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", assert(2 3) keep(3) nogen
	
	// Use NHGIS data for controls/weights
	fmerge 1:1 fips year ///
		using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", ///
		keepusing(pop_total pop_black pop_other_race pop_fem* percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita) ///
		keep(3) nogen 
	
	gen pop_white = pop_total - pop_black - pop_other_race
	assert pop_white >= 0
	
	// Merge with ICPSR county births
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_year_births.dta", keep(1 3) nogen keepusing(births_occ)
	
	// Merge in CHD presence
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	
	// Merge with published birth cohort size by race 
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_cohorts_by_year.dta", assert(1 3) nogen keepusing(births_pub*)

	// Merge in base pneumonia for shift share
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", assert(3) nogen
	
	// Merge in maternal mortality
 	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/imr_mmr_1922_1942.dta", keep(1 3) nogen keepusing(*mmr* maternal_deaths*)
	
	* There are 13 observations for which the number of infant deaths of blacks exceeds
	*	the number of births of blacks. Here we replace the birth count with the mortality
	*	count and assume death rate of 1. 11 such observations are in our main sample.
	
	tab year if missing(births_pub)
	
	tab year if mort > births_pub
	tab year if mort_bk > births_pub_bk
	tab year if mort_wt > births_pub_wt

	count if mort > births_pub & year >= 1922 & year <= 1942
	count if mort_bk > births_pub_bk & year >= 1922 & year <= 1942
	count if mort_wt > births_pub_wt & year >= 1922 & year <= 1942
	
	gunique fips if mort_bk > births_pub_bk & year >= 1922 & year <= 1942
	
	* Number of observations with zero deaths (and non-zero births): 64 pooled, 
	count if mort == 0 & births_pub > 0 & year >= 1922 & year <= 1942
	count if mort_bk == 0 & births_pub_bk > 0 & year >= 1922 & year <= 1942
	count if mort_wt == 0 & births_pub_wt > 0 & year >= 1922 & year <= 1942
	
	gunique fips if mort_bk == 0 & births_pub_bk > 0 & year >= 1922 & year <= 1942
	gunique fips if mort_wt == 0 & births_pub_wt > 0 & year >= 1922 & year <= 1942
	
	// Generate variables in logs
		* To deal with observations with zero deaths we calculate the log of the infant
		* mortality rate as ln(imr) = (deaths + 1)*1000/births
		
		* To deal with 21 (18 in main sample) observations with zero black births and deaths, we assume
		* the infant mortality rate is 1 per 1000 births and the log of the infant
		* mortality rate is 0.
		
	count if births_pub == 0 & year >= 1922 & year <= 1942
	count if births_pub_bk == 0 & year >= 1922 & year <= 1942
	count if births_pub_wt == 0 & year >= 1922 & year <= 1942

	gunique fips if births_pub_bk == 0 & year >= 1922 & year <= 1942
		
	// Merge with Duke treatment variables
	merge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", keep(1 3) nogen keepusing(appropriation app_payments capp_* pay_* tot_capp_* tot_pay_* ) 
	recode tot_capp_all_adj (mis = 0)
	recode tot_capp_ex_nurse_adj (mis = 0)
	recode tot_pay_all_adj (mis = 0)
	recode tot_pay_ex_nurse_adj (mis = 0)
	
	// Label treatment variables
	la var capp_all "First capital appropriation - any purpose"
	la var capp_ex_nurse "First capital appropriation - any purpose"
	la var capp_new_hosp "First capital appropriation - new hospital"
	la var capp_addition "First capital appropriation - addition to hospital"
	la var capp_equipment "First capital appropriation - equipment"
	la var capp_purchase "First capital appropriation - purchases"

	// Label outcome variables
	la var mort "Infant mortality"
	la var mort_bk "Infant mortality, blacks"
	la var mort_wt "Infant mortality, whites"
	
	// Set id and time

	xtset fips year

	save "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta", replace

}


************************
// Southern deaths *****
************************
	
if `southern_deaths' {

	// Open data from Price V. Fishback
	use "$PROJ_PATH/analysis/processed/intermediate/pvf/bdct2140.dta", clear

	/*
	// Variables we need from this

	CBIR	City Births
	CBIRB	City births for nonwhites
	CBIRW	City births for whites

	CINDTH	City infant Deaths.
	CINDTHB	City infant Deaths of whites
	CINDTHW	City infant Deaths of nonwhites

	STFIPS	state FIPS code
	cofips	County FIPS Code
	YEAR year
	*/

	rename cbir births_pub
	rename cbirb births_pub_bk
	rename cbirw births_pub_wt

	rename cindth mort
	rename cindthb mort_bk
	rename cindthw mort_wt

	// Keep only what we need
	keep mort* births* *fips year stname county counname 

	// Drop if missing county
	drop if missing(counname)
	drop if missing(stfips) 
	drop if missing(year)

	// Fix case of county name 
	replace counname = upper(counname)
	
	// Drop possible Duke affected counties
	drop if stfips == 45 // South Carolina
	drop if stfips == 37 // North Carolina

	// Restrict to other Southern states 
	rename stfips statefip 
	keep if `southern_states' 
	
	// Merge with county identifiers 
	gen state = upper(stname)
	gen county_nhgis = upper(counname)
	drop stname counname statefip
	
	// Clean state names
	replace state = "DISTRICT OF COLUMBIA" if state == "WASHINGTON, D.C."
	
	// Clean county names 
	replace county_nhgis = "MCLENNAN" if county_nhgis == "MC LENNAN" & state == "TEXAS"
	replace county_nhgis = "DISTRICT OF COLUMBIA" if county_nhgis == "WASHINGTON, D.C." & state == "DISTRICT OF COLUMBIA"
	replace county_nhgis = "POTTOWATOMIE" if county_nhgis == "POTTAWATOMIE" & state == "OKLAHOMA"
	replace county_nhgis = "MCCRACKEN" if county_nhgis == "MC CRACKEN" & state == "KENTUCKY"
	replace county_nhgis = "DEKALB" if county_nhgis == "DE KALB" & state == "GEORGIA"
	replace county_nhgis = "WILLIAMSBURG CITY" if county_nhgis == "INDEPENDENT CITY CARVED FROM JAMES CITY AND YORK COUNTIES"
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose keep(1 3) keepusing(statefip countyicp fips)
	
	assert county_nhgis == "DEKALB AND FULTON COUNTIES" | county_nhgis == "LEE AND RUSSELL COUNTIES" if _merge == 1
	drop _merge state county_nhgis 
	
	// Drop cities that straddle multiple counties 
	drop if missing(countyicp)
	
	// Create copy of each variable
	qui ds mort* births*
	foreach x in `r(varlist)' {
		gen count_`x' = `x'
	}

	// Create true zero indicator
	foreach x in `r(varlist)' {
		gen true_z_`x' = 0
		replace true_z_`x' = 1 if `x' == 0
	}

	// Collapse to the county-year level 
	collapse (sum) mort* births* true_z_* (count) count_*, by(statefip countyicp fips year) 
	gisid fips year 

	// Make sure missing values are correct
	qui ds births* mort*
	foreach x in `r(varlist)' {
		replace `x' = . if count_`x' == 0
	}

	// Make sure true zeros are correct
	foreach x in `r(varlist)' {
		replace `x' = 0 if true_z_`x' > 0
	}

	// Clean up
	drop true_z* count_*

	// Gen deaths per 100k
	gen imr_pub = (mort/births_pub)*1000
	gen imr_pub_bk = (mort_bk/births_pub_bk)*1000
	gen imr_pub_wt = (mort_wt/births_pub_wt)*1000

	// Gen log of deaths 
	gen ln_imr_pub = log(imr_pub)
	gen ln_imr_pub_bk = log(imr_pub_bk)
	gen ln_imr_pub_wt = log(imr_pub_wt)
	
	// Save as temp file
	compress
	save "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes.dta", replace

	
	// Open AMA data
	use "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta", clear

	// Restrict to other Southern states 
	rename StateFIPS statefip 
	keep if `southern_states'
	
	// Drop Carolinas
	drop if statefip == 37 | statefip == 45
	drop statefip 
	
	// Add county identifiers 
	gen state = upper(statename)
	gen county_nhgis = upper(countyname)
	
	// Clean county name 
	replace county_nhgis = subinstr(county_nhgis,".","",.)
	replace county_nhgis = subinstr(county_nhgis,"'","",.)
	replace county_nhgis = "DISTRICT OF COLUMBIA" if state == "DISTRICT OF COLUMBIA"
	replace county_nhgis = "DEKALB" if county_nhgis == "DE KALB"
	replace county_nhgis = "ST MARTIN" if county_nhgis == "SAINT MARTIN"
	replace county_nhgis = "POTTOWATOMIE" if county_nhgis == "POTTAWATOMIE"
	replace county_nhgis = "CASS" if county_nhgis == "CASS/DAVIS"
	replace county_nhgis = "DE WITT" if county_nhgis == "DEWITT" & state == "TEXAS"
	replace county_nhgis = "FORT BEND" if county_nhgis == "FT BEND"
	replace county_nhgis = "LE FLORE" if county_nhgis == "LEFLORE" & state == "OKLAHOMA"
	replace county_nhgis = "HOT SPRING" if county_nhgis == "HOT SPRINGS" & state == "ARKANSAS"
	replace county_nhgis = "HARFORD" if county_nhgis == "HARTFORD" & state == "MARYLAND"
	replace county_nhgis = "ST JOHNS" if county_nhgis == "ST JOHN" & state == "FLORIDA"
	replace county_nhgis = "FORREST" if county_nhgis == "FOREST" & state == "MISSISSIPPI"
	replace county_nhgis = "HAYS" if county_nhgis == "HAYES" & state == "TEXAS"
	replace county_nhgis = "TOOMBS" if county_nhgis == "TOMBS" & state == "GEORGIA"
	replace county_nhgis = "ELIZABETH CITY" if county_nhgis == "ELIZABETH" & state == "VIRGINIA"
	replace county_nhgis = "LUNENBURG" if county_nhgis == "LUNNENBURG" & state == "VIRGINIA"
	replace county_nhgis = "ALLEGHANY" if county_nhgis == "ALLEGHENY" & state == "VIRGINIA"
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose assert(2 3) keep(3) keepusing(fips)
	
	// Create an inidicator for each hospital with non-zero beds  
	gen has_beds = 0 
	replace has_beds = 1 if beds > 0 & !missing(beds)

	// Collapse to create # of hospitals in each county-year (including non non-profit count)
	collapse (sum) has_beds proprietary, by(fips year)

	// Make indicator for any non-profit bed in county year
	gen any_non_profit = 0
	replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds

	// Merge with births data
	compress
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes.dta"

	// Create an "ever have hospital" indicator (since these are counties with big cities, most will have them)
	bysort fips: egen ever_non_profit = max(any_non_profit)
	bysort fips: egen ever_hosp = max(has_beds)
	replace ever_hosp = 1 if ever_hosp > 1 & !missing(ever_hosp)

	// Add treatment variable 
	gen treated = 0

	// Keep data with births
	drop if _merge == 1
	drop _merge 
	compress
	
	// Use NHGIS data for controls/weights
	fmerge 1:1 fips year ///
		using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", ///
		keepusing(pop_total pop_black pop_other_race pop_fem* percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)	///
		assert(2 3) keep(3) nogen 
		
	gen pop_white = pop_total - pop_black - pop_other_race
	assert pop_white >= 0
		
	// Merge in CHD presence
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", assert(2 3) keep(3) nogen keepusing(chd_presence)

	gisid fips year 
	gsort fips year 
	
	compress
	save "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta", replace

	rm "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes.dta"

}


**********************
// NARA Numident *****
**********************

if `numident' {
	
	//////////////////////////////////////////////////////////////////////////
	// Just NC
	//////////////////////////////////////////////////////////////////////////

	// Set first year for numident 
	local first_year_numident 	1988
	
	// Set first birth cohort
	local year_start 			1922

	// Import Numident data
	use "$PROJ_PATH/analysis/processed/data/numident/numident_carolina_indiv_1920-1942.dta", clear
	rename state_numeric statefip
		
	// Keep only North Carolina
	keep if statefip == 37
	
	// Restrict to blacks and whites
	keep if race == 1 | race == 2
	
	// Drop years that are not well populated  
	drop if yodssn < `first_year_numident'
	
	// Single age population data is capped at age 85 - anyone born before 1922 will be older than 85 in 2005
	drop if yobssn < `year_start' 
	
	// Generate fips variable
	gen fips  = statefip*10000 + county_numeric*10
	
	// Generate age at death
	gen age = yodssn - yobssn
	drop if missing(age)
	
	// Keep year-of-birth, year-of-death, county-of-birth, race, and age at death
	keep yobssn yodssn age fips race sex
	
	// Create a variable indicating the number of deaths in each cell
	gen deaths_ = 1

	// Total the number of deaths in each age, county-of-birth, year-of-death bin
	collapse (sum) deaths_, by(age yobssn fips yodssn race) 

	// Sort and order the data
	order fips yobssn yodssn age
	gsort fips yobssn yodssn age
	
	// Add zeros where applicable
	* For some county-year-of-birth-yodssn combinations, there are no observed deaths when there could be. 
	* We need to identify these pairs and add zeros, being careful not to add zeros to cells that could not have
	* been observed. 

	// First reshape wide
	reshape wide deaths_@ , i(fips yobssn yodssn race) j(age)  

	// Balance on yobssn 
	egen fips_yod = group(fips yodssn race)

	tset fips_yod yobssn 

	gsort fips_yod yobssn 

	tsfill, full

	gsort fips_yod yobssn
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace


	gsort fips_yod -yobssn
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace

	gsort fips yobssn yodssn race


	drop fips_yod

	// Balance on yodssn 
	egen fips_yob = group(fips yobssn race)

	tset fips_yob yodssn 

	gsort fips_yob yodssn 

	tsfill, full

	gsort  fips_yob yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort  fips_yob -yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort fips yobssn yodssn race

	drop fips_yob

	// Now fill in zeros where appropriate
	forvalues birth_year = 1922/1942 {
		forvalues death_year = `first_year_numident'/2007 {
			local age_at_death = `death_year' - `birth_year'
			qui replace deaths_`age_at_death' = 0 if missing(deaths_`age_at_death') & yobssn == `birth_year' & yodssn == `death_year'
		}
	}

	// Now reshape back to long
	reshape long deaths_@ , i(fips yobssn yodssn race) j(age)  
	rename deaths_ deaths 

	drop if missing(deaths)

	// Sort and order
	order fips yobssn age yodssn race
	gsort fips yobssn age yodssn race

	// Merge with single age population data
	gen year = yodssn
	fmerge 1:1 fips race year age using "$PROJ_PATH/analysis/processed/intermediate/seer/nc_population_single_ages_by_year_race.dta", assert(2 3) keep(3) nogen
	drop year
	
	// Merge with estimated and published birth cohort size by race
	gen byr = yobssn
	fmerge m:1 fips race byr using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_by_race_1922_1948.dta", assert(2 3) keep(3) nogen keepusing(births_pub)
	drop byr
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta",  keep(1 3) nogen keepusing(capp_all pay_all capp_all_adj tot_capp_all_adj pay_all_adj tot_pay_all_adj)

	// Merge with NHGIS county information
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", assert(2 3) keep(3) nogen keepusing(statefip countyicp)

	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year
	
	// Merge in base pneumonia for shift share
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", assert(3) nogen
	
	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population & !missing(deaths)
// Ensure birth cohorts restricted to main sample birth cohorts
	gen year = yobssn
	drop if yodssn > 2005
	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"
	// Generate rate 
	gen lldr = (deaths/population)*100000
	
	// Create share of cohort dead
	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_full.dta", replace
	
	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	// Create share of cohort dead
	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta", replace

	// Create pooled data
	use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_full.dta", clear
	
	collapse (sum) population  deaths births_pub, by(fips yobssn yodssn age)
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", keep(1 3) nogen keepusing(capp_all pay_all capp_all_adj tot_capp_all_adj pay_all_adj tot_pay_all_adj)

	// Merge with NHGIS county information
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", assert(2 3) keep(3) nogen keepusing(statefip countyicp)

	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year
	
	// Merge in base pneumonia for shift share
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", assert(3) nogen

	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population

	drop if yodssn > 2005

	// Ensure birth cohorts restricted to main sample birth cohorts
	gen year = yobssn

	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"

	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	// Generate rate 
	gen lldr = (deaths/population)*100000
	
	order fips yobssn yodssn
	sort  fips yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", replace
	
	////////////////////////////////////////////////////////////////////////////
	// Southern cities as controls
	////////////////////////////////////////////////////////////////////////////
	
	// Create births pub for this sample
	use "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta", clear
	keep fips year births_pub_bk births_pub_wt
	rename births_pub_bk births_pub_2
	rename births_pub_wt births_pub_1
	
	reshape long births_pub_@, i(fips year) j(race)
	rename *_ *
	rename year byr
	save "$PROJ_PATH/analysis/processed/temp/birth_data_for_long_run_clean_controls.dta", replace 

	// Set first year for numident 
	local first_year_numident 	1988
	
	// Set first birth cohort
	local year_start 			1930

	// Import Numident data
	use "$PROJ_PATH/analysis/processed/data/numident/numident_south_indiv_1920-1942.dta", clear
	rename state_numeric statefip
	
	
	// Restrict to blacks and whites
	keep if race == 1 | race == 2
	
	// Drop years that are not well populated  
	drop if yodssn < `first_year_numident'
	
	// Single age population data is capped at age 85 - anyone born before 1922 will be older than 85 in 2007
	drop if yobssn < `year_start' 
	
	// Generate fips variable
	gen fips  = statefip*10000 + county_numeric*10
	
	// Generate age at death
	gen age = yodssn - yobssn
	drop if missing(age)
	
	// Keep year-of-birth, year-of-death, county-of-birth, race, and age at death
	keep yobssn yodssn age fips race sex
	
	// Create a variable indicating the number of deaths in each cell
	gen deaths_ = 1

	
	// Total the number of deaths in each age, county-of-birth, year-of-death bin
	collapse (sum) deaths_ , by(age yobssn fips yodssn race) 

	// Sort and order the data
	order fips yobssn yodssn age
	gsort fips yobssn yodssn age
	
	// Add zeros where applicable
	* For some county-year-of-birth-yodssn combinations, there are no observed deaths when there could be. 
	* We need to identify these pairs and add zeros, being careful not to add zeros to cells that could not have
	* been observed. 

	// First reshape wide
	reshape wide deaths_@ , i(fips yobssn yodssn race) j(age)  

	// Balance on yobssn 
	egen fips_yod = group(fips yodssn race)

	tset fips_yod yobssn 

	gsort fips_yod yobssn 

	tsfill, full

	gsort fips_yod yobssn // Changed yodssn to yobssn (otherwise this performs a non-unique sort)
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace


	gsort fips_yod -yobssn
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace

	gsort fips yobssn yodssn race


	drop fips_yod

	// Balance on yodssn 
	egen fips_yob = group(fips yobssn race)

	tset fips_yob yodssn 

	gsort fips_yob yodssn 

	tsfill, full

	gsort  fips_yob yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort  fips_yob -yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort fips yobssn yodssn race

	drop fips_yob

	// Now fill in zeros where appropriate
	forvalues birth_year = 1930/1942 {
		forvalues death_year = `first_year_numident'/2007 {
			local age_at_death = `death_year' - `birth_year'
			qui replace deaths_`age_at_death' = 0 if missing(deaths_`age_at_death') & yobssn == `birth_year' & yodssn == `death_year'
		}
	}

	// Now reshape back to long
	reshape long deaths_@ , i(fips yobssn yodssn race) j(age)  
	rename deaths_ deaths 

	
	drop if missing(deaths)

	// Sort and order
	order fips yobssn age yodssn race
	gsort fips yobssn age yodssn race

	// Merge with single age population data
	gen year = yodssn
	fmerge 1:1 fips race year age using "$PROJ_PATH/analysis/processed/intermediate/seer/south_population_single_ages_by_year_race.dta", keep(3) nogen
	drop year
	
	// Merge with estimated and published birth cohort size by race
	gen byr = yobssn
	fmerge m:1 fips race byr using "$PROJ_PATH/analysis/processed/temp/birth_data_for_long_run_clean_controls.dta", keep(3) nogen keepusing(births_pub)
	drop byr
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", keep(1 3) nogen keepusing(capp_all pay_all capp_all_adj tot_capp_all_adj pay_all_adj tot_pay_all_adj capp_ex_nurse pay_ex_nurse tot_capp_ex_nurse_adj tot_pay_ex_nurse_adj)
	
	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta",  keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year
	
	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population & !missing(deaths)
	gen year = yobssn
	drop if yodssn > 2005
	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"
	// Generate rate 
	gen lldr = (deaths/population)*100000
	
	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race_full.dta", replace
	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race.dta", replace
	
	// Create pooled data
	use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race_full.dta", clear
	
	collapse (sum) population deaths births_pub, by(fips yobssn yodssn age)
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", keep(1 3) nogen keepusing(capp_all pay_all capp_all_adj tot_capp_all_adj pay_all_adj tot_pay_all_adj capp_ex_nurse pay_ex_nurse tot_capp_ex_nurse_adj tot_pay_ex_nurse_adj)
	
	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta",  keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year
	
	
	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population
	gen year = yobssn
	drop if yodssn > 2005
	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"

	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	// Generate rate 
	gen lldr = (deaths/population)*100000
	order fips yobssn yodssn
	sort  fips yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_pooled.dta", replace
	
	///////// Add ever-non-profit ///////////
	
	// Open AMA data
	use  "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta", clear

	// Create an inidicator for each hospital with non-zero beds  
	gen has_beds = 0 
	replace has_beds = 1 if beds > 0 & !missing(beds)

	// Collapse to create # of hospitals in each county-year (including non non-profit count)
	rename CountyFIPS fips
	collapse (sum) has_beds proprietary, by(fips year)

	// Make indicator for any non-profit bed in county year
	gen any_non_profit = 0
	replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds

	// Merge with births data
	compress
	rename year yobssn
	replace fips = fips*10
	save "$PROJ_PATH/analysis/processed/temp/ever_non_profit.dta", replace 
	
	/////////////////////////////////////////
	
	use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race.dta"
	merge m:1 fips yobssn using "$PROJ_PATH/analysis/processed/temp/ever_non_profit.dta", nogen
	
	// Create an "ever have hospital" indicator (since these are counties with big cities, most will have them)
	bysort fips: egen ever_non_profit = max(any_non_profit)
	bysort fips: egen ever_hosp = max(has_beds)
	replace ever_hosp = 1 if ever_hosp > 1 & !missing(ever_hosp)

	save "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race.dta", replace

	use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_pooled.dta"
	merge m:1 fips yobssn using "$PROJ_PATH/analysis/processed/temp/ever_non_profit.dta", nogen
	
	// Create an "ever have hospital" indicator (since these are counties with big cities, most will have them)
	bysort fips: egen ever_non_profit = max(any_non_profit)
	bysort fips: egen ever_hosp = max(has_beds)
	replace ever_hosp = 1 if ever_hosp > 1 & !missing(ever_hosp)
	
	save "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_pooled.dta", replace
	
	
	// Clean up 
	erase "$PROJ_PATH/analysis/processed/temp/birth_data_for_long_run_clean_controls.dta"
	erase "$PROJ_PATH/analysis/processed/temp/ever_non_profit.dta"

// Create south carolina treatment 
	// Create SC treatment status. 

use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta", clear
gen COUNTY = proper(county_nhgis)
gen StateFIPS = statefip
gen CountyFIPS = .
	replace CountyFIPS=001 if COUNTY=="Alamance" & StateFIPS ==37
	replace CountyFIPS=003 if COUNTY=="Alexander" & StateFIPS ==37
	replace CountyFIPS=005 if COUNTY=="Alleghany" & StateFIPS ==37
	replace CountyFIPS=007 if COUNTY=="Anson" & StateFIPS ==37
	replace CountyFIPS=009 if COUNTY=="Ashe" & StateFIPS ==37
	replace CountyFIPS=011 if COUNTY=="Avery" & StateFIPS ==37
	replace CountyFIPS=013 if COUNTY=="Beaufort" & StateFIPS ==37
	replace CountyFIPS=015 if COUNTY=="Bertie" & StateFIPS ==37
	replace CountyFIPS=017 if COUNTY=="Bladen" & StateFIPS ==37
	replace CountyFIPS=019 if COUNTY=="Brunswick" & StateFIPS ==37
	replace CountyFIPS=019 if COUNTY=="BRUNSWICK" & StateFIPS ==37
	replace CountyFIPS=021 if COUNTY=="Buncombe" & StateFIPS ==37
	replace CountyFIPS=023 if COUNTY=="Burke" & StateFIPS ==37
	replace CountyFIPS=025 if COUNTY=="Cabarrus" & StateFIPS ==37
	replace CountyFIPS=027 if COUNTY=="Caldwell" & StateFIPS ==37
	replace CountyFIPS=029 if COUNTY=="Camden" & StateFIPS ==37
	replace CountyFIPS=031 if COUNTY=="Carteret" & StateFIPS ==37
	replace CountyFIPS=033 if COUNTY=="Caswell" & StateFIPS ==37
	replace CountyFIPS=035 if COUNTY=="Catawba" & StateFIPS ==37
	replace CountyFIPS=037 if COUNTY=="Chatham" & StateFIPS ==37
	replace CountyFIPS=039 if COUNTY=="Cherokee" & StateFIPS ==37
	replace CountyFIPS=041 if COUNTY=="Chowan" & StateFIPS ==37
	replace CountyFIPS=043 if COUNTY=="Clay" & StateFIPS ==37
	replace CountyFIPS=045 if COUNTY=="Cleveland" & StateFIPS ==37
	replace CountyFIPS=047 if COUNTY=="Columbus" & StateFIPS ==37
	replace CountyFIPS=049 if COUNTY=="Craven" & StateFIPS ==37
	replace CountyFIPS=051 if COUNTY=="Cumberland" & StateFIPS ==37
	replace CountyFIPS=053 if COUNTY=="Currituck" & StateFIPS ==37
	replace CountyFIPS=055 if COUNTY=="Dare" & StateFIPS ==37
	replace CountyFIPS=057 if COUNTY=="Davidson" & StateFIPS ==37
	replace CountyFIPS=059 if COUNTY=="Davie" & StateFIPS ==37
	replace CountyFIPS=061 if COUNTY=="Duplin" & StateFIPS ==37
	replace CountyFIPS=063 if COUNTY=="Durham" & StateFIPS ==37
	replace CountyFIPS=065 if COUNTY=="Edgecombe" & StateFIPS ==37
	replace CountyFIPS=067 if COUNTY=="Forsyth" & StateFIPS ==37
	replace CountyFIPS=069 if COUNTY=="Franklin" & StateFIPS ==37
	replace CountyFIPS=071 if COUNTY=="Gaston" & StateFIPS ==37
	replace CountyFIPS=073 if COUNTY=="Gates" & StateFIPS ==37
	replace CountyFIPS=075 if COUNTY=="Graham" & StateFIPS ==37
	replace CountyFIPS=077 if COUNTY=="Granville" & StateFIPS ==37
	replace CountyFIPS=079 if COUNTY=="Greene" & StateFIPS ==37
	replace CountyFIPS=081 if COUNTY=="Guilford" & StateFIPS ==37
	replace CountyFIPS=083 if COUNTY=="Halifax" & StateFIPS ==37
	replace CountyFIPS=085 if COUNTY=="Harnett" & StateFIPS ==37
	replace CountyFIPS=087 if COUNTY=="Haywood" & StateFIPS ==37
	replace CountyFIPS=089 if COUNTY=="Henderson" & StateFIPS ==37
	replace CountyFIPS=091 if COUNTY=="Hertford" & StateFIPS ==37
	replace CountyFIPS=093 if COUNTY=="Hoke" & StateFIPS ==37
	replace CountyFIPS=095 if COUNTY=="Hyde" & StateFIPS ==37
	replace CountyFIPS=097 if COUNTY=="Iredell" & StateFIPS ==37
	replace CountyFIPS=099 if COUNTY=="Jackson" & StateFIPS ==37
	replace CountyFIPS=101 if COUNTY=="Johnston" & StateFIPS ==37
	replace CountyFIPS=103 if COUNTY=="Jones" & StateFIPS ==37
	replace CountyFIPS=105 if COUNTY=="Lee" & StateFIPS ==37
	replace CountyFIPS=107 if COUNTY=="Lenoir" & StateFIPS ==37
	replace CountyFIPS=109 if COUNTY=="Lincoln" & StateFIPS ==37
	replace CountyFIPS=111 if COUNTY=="McDowell" & StateFIPS ==37
	replace CountyFIPS=111 if COUNTY=="Mcdowell" & StateFIPS ==37
	
	replace CountyFIPS=113 if COUNTY=="Macon" & StateFIPS ==37
	replace CountyFIPS=115 if COUNTY=="Madison" & StateFIPS ==37
	replace CountyFIPS=117 if COUNTY=="Martin" & StateFIPS ==37
	replace CountyFIPS=119 if COUNTY=="Mecklenburg" & StateFIPS ==37
	replace CountyFIPS=121 if COUNTY=="Mitchell" & StateFIPS ==37
	replace CountyFIPS=123 if COUNTY=="Montgomery" & StateFIPS ==37
	replace CountyFIPS=125 if COUNTY=="Moore" & StateFIPS ==37
	replace CountyFIPS=127 if COUNTY=="Nash" & StateFIPS ==37
	replace CountyFIPS=129 if COUNTY=="New Hanover" & StateFIPS ==37
	replace CountyFIPS=131 if COUNTY=="Northampton" & StateFIPS ==37
	replace CountyFIPS=133 if COUNTY=="Onslow" & StateFIPS ==37
	replace CountyFIPS=135 if COUNTY=="Orange" & StateFIPS ==37
	replace CountyFIPS=137 if COUNTY=="Pamlico" & StateFIPS ==37
	replace CountyFIPS=139 if COUNTY=="Pasquotank" & StateFIPS ==37
	replace CountyFIPS=141 if COUNTY=="Pender" & StateFIPS ==37
	replace CountyFIPS=143 if COUNTY=="Perquimans" & StateFIPS ==37
	replace CountyFIPS=145 if COUNTY=="Person" & StateFIPS ==37
	replace CountyFIPS=145 if COUNTY=="PERSON" & StateFIPS ==37
	replace CountyFIPS=147 if COUNTY=="Pitt" & StateFIPS ==37
	replace CountyFIPS=149 if COUNTY=="Polk" & StateFIPS ==37
	replace CountyFIPS=151 if COUNTY=="Randolph" & StateFIPS ==37
	replace CountyFIPS=153 if COUNTY=="Richmond" & StateFIPS ==37
	replace CountyFIPS=155 if COUNTY=="Robeson" & StateFIPS ==37
	replace CountyFIPS=157 if COUNTY=="Rockingham" & StateFIPS ==37
	replace CountyFIPS=159 if COUNTY=="Rowan" & StateFIPS ==37
	replace CountyFIPS=161 if COUNTY=="Rutherford" & StateFIPS ==37
	replace CountyFIPS=163 if COUNTY=="Sampson" & StateFIPS ==37
	replace CountyFIPS=165 if COUNTY=="Scotland" & StateFIPS ==37
	replace CountyFIPS=167 if COUNTY=="Stanly" & StateFIPS ==37
	replace CountyFIPS=169 if COUNTY=="Stokes" & StateFIPS ==37
	replace CountyFIPS=171 if COUNTY=="Surry" & StateFIPS ==37
	replace CountyFIPS=173 if COUNTY=="Swain" & StateFIPS ==37
	replace CountyFIPS=175 if COUNTY=="Transylvania" & StateFIPS ==37
	replace CountyFIPS=177 if COUNTY=="Tyrrell" & StateFIPS ==37
	replace CountyFIPS=179 if COUNTY=="Union" & StateFIPS ==37
	replace CountyFIPS=181 if COUNTY=="Vance" & StateFIPS ==37
	replace CountyFIPS=183 if COUNTY=="Wake" & StateFIPS ==37
	replace CountyFIPS=185 if COUNTY=="Warren" & StateFIPS ==37
	replace CountyFIPS=187 if COUNTY=="Washington" & StateFIPS ==37
	replace CountyFIPS=189 if COUNTY=="Watauga" & StateFIPS ==37
	replace CountyFIPS=191 if COUNTY=="Wayne" & StateFIPS ==37
	replace CountyFIPS=193 if COUNTY=="Wilkes" & StateFIPS ==37
	replace CountyFIPS=195 if COUNTY=="Wilson" & StateFIPS ==37
	replace CountyFIPS=197 if COUNTY=="Yadkin" & StateFIPS ==37
	replace CountyFIPS=199 if COUNTY=="Yancey" & StateFIPS ==37
	replace CountyFIPS=003 if COUNTY=="Aiken" & StateFIPS ==45
	
	replace CountyFIPS=001 if COUNTY=="Abbeville" & StateFIPS ==45
	
	replace CountyFIPS=005 if COUNTY=="Allendale" & StateFIPS ==45
	replace CountyFIPS=007 if COUNTY=="Anderson" & StateFIPS ==45
	replace CountyFIPS=009 if COUNTY=="Bamberg" & StateFIPS ==45
	replace CountyFIPS=011 if COUNTY=="Barnwell" & StateFIPS ==45
	replace CountyFIPS=013 if COUNTY=="Beaufort" & StateFIPS ==45
	replace CountyFIPS=015 if COUNTY=="Berkeley" & StateFIPS ==45
	replace CountyFIPS=017 if COUNTY=="Calhoun" & StateFIPS ==45
	replace CountyFIPS=019 if COUNTY=="Charleston" & StateFIPS ==45
	replace CountyFIPS=021 if COUNTY=="Cherokee" & StateFIPS ==45
	replace CountyFIPS=023 if COUNTY=="Chester" & StateFIPS ==45
	replace CountyFIPS=025 if COUNTY=="Chesterfield" & StateFIPS ==45
	replace CountyFIPS=027 if COUNTY=="Clarendon" & StateFIPS ==45
	replace CountyFIPS=029 if COUNTY=="Colleton" & StateFIPS ==45
	replace CountyFIPS=031 if COUNTY=="Darlington" & StateFIPS ==45
	replace CountyFIPS=033 if COUNTY=="Dillon" & StateFIPS ==45
	replace CountyFIPS=035 if COUNTY=="Dorchester" & StateFIPS ==45
	replace CountyFIPS=037 if COUNTY=="Edgefield" & StateFIPS ==45
	replace CountyFIPS=039 if COUNTY=="Fairfield" & StateFIPS ==45
	replace CountyFIPS=041 if COUNTY=="Florence" & StateFIPS ==45
	replace CountyFIPS=043 if COUNTY=="Georgetown" & StateFIPS ==45
	replace CountyFIPS=045 if COUNTY=="Greenville" & StateFIPS ==45
	replace CountyFIPS=047 if COUNTY=="Greenwood" & StateFIPS ==45
	replace CountyFIPS=049 if COUNTY=="Hampton" & StateFIPS ==45
	replace CountyFIPS=051 if COUNTY=="Horry" & StateFIPS ==45
	replace CountyFIPS=053 if COUNTY=="Jasper" & StateFIPS ==45
	replace CountyFIPS=055 if COUNTY=="Kershaw" & StateFIPS ==45
	replace CountyFIPS=057 if COUNTY=="Lancaster" & StateFIPS ==45
	replace CountyFIPS=059 if COUNTY=="Laurens" & StateFIPS ==45
	replace CountyFIPS=061 if COUNTY=="Lee" & StateFIPS ==45
	replace CountyFIPS=063 if COUNTY=="Lexington" & StateFIPS ==45
	replace CountyFIPS=065 if COUNTY=="McCormick" & StateFIPS ==45
	replace CountyFIPS=067 if COUNTY=="Marion" & StateFIPS ==45
	replace CountyFIPS=069 if COUNTY=="Marlboro" & StateFIPS ==45
	replace CountyFIPS=071 if COUNTY=="Newberry" & StateFIPS ==45
	replace CountyFIPS=073 if COUNTY=="Oconee" & StateFIPS ==45
	replace CountyFIPS=075 if COUNTY=="Orangeburg" & StateFIPS ==45
	replace CountyFIPS=077 if COUNTY=="Pickens" & StateFIPS ==45
	replace CountyFIPS=079 if COUNTY=="Richland" & StateFIPS ==45
	replace CountyFIPS=081 if COUNTY=="Saluda" & StateFIPS ==45
	replace CountyFIPS=083 if COUNTY=="Spartanburg" & StateFIPS ==45
	replace CountyFIPS=085 if COUNTY=="Sumter" & StateFIPS ==45
	replace CountyFIPS=087 if COUNTY=="Union" & StateFIPS ==45
	replace CountyFIPS=089 if COUNTY=="Williamsburg" & StateFIPS ==45
	replace CountyFIPS=091 if COUNTY=="York" & StateFIPS ==45
	
	drop fips 
	gen str_cty_fips = string(CountyFIPS, "%03.0f")
	gen str_st_fips = string(StateFIPS, "%02.0f")
	gen str_fips = str_st_fips + str_cty_fips
	destring str_fips, gen(fips)
	replace fips = fips*10
	
	collapse (sum) capp_all, by(fips CountyFIPS StateFIPS year)
	rename capp_all capp_all_with_sc



compress 
tempfile include_sc
save `include_sc', replace
	//////////////////////////////////////////////////////////////////////////
	// Both NC and SC
	//////////////////////////////////////////////////////////////////////////

	// Set first year for numident 
	local first_year_numident 	1988
	
	// Set first birth cohort
	local year_start 			1922

	// Import Numident data
	use "$PROJ_PATH/analysis/processed/data/numident/numident_carolina_indiv_1920-1942.dta", clear
	rename state_numeric statefip
		
	// Keep only North Carolina
	*keep if statefip == 37
	
	// Restrict to blacks and whites
	keep if race == 1 | race == 2
	
	// Drop years that are not well populated  
	drop if yodssn < `first_year_numident'
	
	// Single age population data is capped at age 85 - anyone born before 1922 will be older than 85 in 2005
	drop if yobssn < `year_start' 
	
	// Generate fips variable
	gen fips  = statefip*10000 + county_numeric*10
	
	// Generate age at death
	gen age = yodssn - yobssn
	drop if missing(age)
	
	// Keep year-of-birth, year-of-death, county-of-birth, race, and age at death
	keep yobssn yodssn age fips race sex
	
	// Create a variable indicating the number of deaths in each cell
	gen deaths_ = 1

	// Total the number of deaths in each age, county-of-birth, year-of-death bin
	collapse (sum) deaths_, by(age yobssn fips yodssn race) 

	// Sort and order the data
	order fips yobssn yodssn age
	gsort fips yobssn yodssn age
	
	// Add zeros where applicable
	* For some county-year-of-birth-yodssn combinations, there are no observed deaths when there could be. 
	* We need to identify these pairs and add zeros, being careful not to add zeros to cells that could not have
	* been observed. 

	// First reshape wide
	reshape wide deaths_@ , i(fips yobssn yodssn race) j(age)  

	// Balance on yobssn 
	egen fips_yod = group(fips yodssn race)

	tset fips_yod yobssn 

	gsort fips_yod yobssn 

	tsfill, full

	gsort fips_yod yobssn // Changed yodssn to yobssn (otherwise this performs a non-unique sort)
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace


	gsort fips_yod -yobssn
	bysort fips_yod: carryforward yodssn, replace
	bysort fips_yod: carryforward fips, replace
	bysort fips_yod: carryforward race, replace

	gsort fips yobssn yodssn race


	drop fips_yod

	// Balance on yodssn 
	egen fips_yob = group(fips yobssn race)

	tset fips_yob yodssn 

	gsort fips_yob yodssn 

	tsfill, full

	gsort  fips_yob yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort  fips_yob -yodssn 
	bysort fips_yob: carryforward yobssn, replace
	bysort fips_yob: carryforward fips, replace
	bysort fips_yob: carryforward race, replace

	gsort fips yobssn yodssn race

	drop fips_yob

	// Now fill in zeros where appropriate
	forvalues birth_year = 1922/1942 {
		forvalues death_year = `first_year_numident'/2007 {
			local age_at_death = `death_year' - `birth_year'
			qui replace deaths_`age_at_death' = 0 if missing(deaths_`age_at_death') & yobssn == `birth_year' & yodssn == `death_year'
		}
	}

	// Now reshape back to long
	reshape long deaths_@ , i(fips yobssn yodssn race) j(age)  
	rename deaths_ deaths 

	drop if missing(deaths)

	// Sort and order
	order fips yobssn age yodssn race
	gsort fips yobssn age yodssn race

	// Merge with single age population data
	gen year = yodssn
	fmerge 1:1 fips race year age using "$PROJ_PATH/analysis/processed/intermediate/seer/south_population_single_ages_by_year_race.dta", assert(2 3) keep(3) nogen
	drop year
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using `include_sc',  keep(1 3) nogen keepusing(capp_all_with_sc)
	rename capp_all_with_sc capp_all
	
	// Merge with NHGIS county information
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", assert(2 3) keep(3) nogen keepusing(statefip countyicp)

	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year

	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population & !missing(deaths)

	// Create share of cohort dead

	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_nc_sc_full.dta", replace
	gen year = yobssn
	drop if yodssn > 2005

	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"

	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	// Generate rate 
	gen lldr = (deaths/population)*100000
	order fips race yobssn yodssn
	sort  fips race yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_nc_sc.dta", replace
	// Create pooled data
	use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_nc_sc_full.dta", clear
	
	*collapse (sum) population  deaths births_pub, by(fips yobssn yodssn age)
	collapse (sum) population  deaths , by(fips yobssn yodssn age)
	
	// Merge with Duke treatment variables
	gen year = yobssn
	merge m:1 fips year using `include_sc',  keep(1 3) nogen keepusing(capp_all_with_sc)
	rename capp_all_with_sc capp_all

	// Merge with NHGIS county information
	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", assert(2 3) keep(3) nogen keepusing(statefip countyicp)

	// Use NHGIS data for controls/weights
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total pop_black pop_other_race percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)
	gen pop_white = pop_total - pop_black - pop_other_race

	// Merge in CHD presence
	fmerge m:1 fips year using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", keep(1 3) nogen keepusing(chd_presence)
	drop year
	
	// Merge in base pneumonia for shift share
	*fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", assert(3) nogen
	*fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_32to36.dta", assert(3) nogen	

	// If deaths > population --> let population = deaths
	replace population = deaths if deaths > population
	gen year = yobssn
	drop if yodssn > 2005

	replace capp_all = 0 if missing(capp_all)

	// Assign treatment		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = year if capp_all != 0 & !missing(capp_all)
				
		egen first_exp_year = min(`exp_year'), by(fips)
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if year >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated
		
		la var treated "\hspace{.5cm}=1 if Duke exposure"

	// Pooled 
	keep if year >= 1932 & year <= 1941

	// Cohort restrictions
	keep if age >= 56 & age <= 64

	// Generate rate 
	gen lldr = (deaths/population)*100000
	
	order fips yobssn yodssn
	sort  fips yobssn yodssn

	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled_nc_sc.dta", replace

	// Clean up long-run
	erase "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_full.dta"
	erase "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race_full.dta"
	erase "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_nc_sc_full.dta"
		
}


disp "DateTime: $S_DATE $S_TIME"
	
** EOF
