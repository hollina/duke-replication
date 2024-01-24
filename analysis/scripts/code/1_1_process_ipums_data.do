version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 1_1_process_ipums_data.do
* PURPOSE: processes the main dataset in preparation for analysis

************

*********************************************************
// Create uniform measure of infant/child mortality *****
*********************************************************

	//////////////////////////////////////////////////////////////////////////////
	// Get set of HIKs that appear in both 1920 and 1930 census. 

	// Open linked census data
	use "$PROJ_PATH/analysis/raw/ipums/us/usa_00004.dta", clear

	// Keep only married-couple family household
	keep if hhtype == 1

	// Keep only Southern states 
	keep if inlist(statefip,1,5,10,11,12,13,21,22,24,28,37,40,45,47,48,51,54)

	// Keep only what we need
	keep year hik histid histid_head
	compress

	// Which hiks are in both
	bysort hik: gen count = _N
	keep if count == 2
	drop count 
	keep if year == 1920

	// Create identifier variables
	gen in_both_1920_1930 = 1

	// Save this list 
	compress
	gisid year histid 
	gsort year histid 
	
	save "$PROJ_PATH/analysis/processed/temp/hik_in_1920_and_1930.dta", replace 

	//////////////////////////////////////////////////////////////////////////////
	// Open full count. 
	use "$PROJ_PATH/analysis/raw/ipums/us/usa_00005.dta", clear

	// Keep only  1920
	keep if year == 1920

	// Keep only  married-couple family household
	keep if hhtype == 1

	// Keep only Southern states 
	keep if inlist(statefip,1,5,10,11,12,13,21,22,24,28,37,40,45,47,48,51,54)

	merge 1:1 year histid using "$PROJ_PATH/analysis/processed/temp/hik_in_1920_and_1930.dta", assert(1 3) nogen
	gisid serial pernum
	gsort serial pernum

	// Create identifiers
	gen head = 0
	replace head = 1 if relate == 1

	gen child_under_one = 0
	replace child_under_one = 1 if relate == 3 & age < 1 | relate == 4 & age < 1

	gen child_one_to_five = 0
	replace child_one_to_five = 1 if relate == 3 & age >= 1  & age <= 5 | relate == 4 & age >= 1  & age <= 5 

	gen child_five_under = 0
	replace child_five_under = 1 if relate == 3 & age <= 5 | relate == 4 & age <= 5

	// Fix missing values in in_both_1920_1930
	replace in_both_1920_1930 = 0 if missing(in_both_1920_1930)

	// Identify household heads to keep since they are in both 1920 and 1930
	gen hhh_to_keep = 0
	replace hhh_to_keep = 1 if head == 1 & in_both_1920_1930 == 1

	// Keep only if household head is matched. 
	bysort serial: egen keep_hhh = max(hhh_to_keep)
	drop hhh_to_keep

	// Identify households with children in 1920 under the age of zero or five
	bysort serial: egen keep_hh_child_und_1 = max(child_under_one)
	bysort serial: egen keep_hh_child_1_5 = max(child_one_to_five)

	keep if keep_hhh == 1 & keep_hh_child_und_1 == 1 | keep_hhh == 1 & keep_hh_child_1_5 == 1

	// Keep only chidren in 1920
	gen keep_child = 0
	replace keep_child = 1 if child_under_one == 1
	replace keep_child = 1 if child_one_to_five == 1

	keep if keep_child == 1

	// Generate present in 1930, total and by age
	gen not_in_1930_under_one = 0
	replace not_in_1930_under_one = 1 if in_both_1920_1930 == 0 & child_under_one == 1

	gen not_in_1930_one_to_five = 0
	replace not_in_1930_one_to_five = 1 if in_both_1920_1930 == 0 & child_one_to_five == 1

	gen not_in_1930_under_five = 0
	replace not_in_1930_under_five = 1 if in_both_1920_1930 == 0 

	// Now create proxy mortality rates and counts of kids for pooled. 
	preserve

		collapse ///
			(mean) pct_not_in_1930_u_1 = not_in_1930_under_one ///
				pct_not_in_1930_1_5 = not_in_1930_one_to_five ///
				pct_not_in_1930_u_5 = not_in_1930_under_five ///
			(sum) n_1920_u_1 = child_under_one ///
				n_1920_1_5 =  child_one_to_five ///
				n_1920_5_u = child_five_under, ///
				by(stateicp statefip countyicp)
		tempfile pooled
		save `pooled'		
	restore

	// White
	preserve
	keep if race == 1
		collapse ///
			(mean) pct_not_in_1930_u_1_w = not_in_1930_under_one ///
				pct_not_in_1930_1_5_w = not_in_1930_one_to_five ///
				pct_not_in_1930_u_5_w = not_in_1930_under_five ///
			(sum) n_1920_u_1_w = child_under_one ///
				n_1920_1_5_w =  child_one_to_five ///
				n_1920_5_u_w = child_five_under, ///
				by(stateicp statefip countyicp)
		tempfile white
		save `white'		
	restore

	// Black
	keep if race == 2
		collapse ///
			(mean) pct_not_in_1930_u_1_b = not_in_1930_under_one ///
				pct_not_in_1930_1_5_b = not_in_1930_one_to_five ///
				pct_not_in_1930_u_5_b = not_in_1930_under_five ///
			(sum) n_1920_u_1_b = child_under_one ///
				n_1920_1_5_b =  child_one_to_five ///
				n_1920_5_u_b = child_five_under, ///
				by(stateicp statefip countyicp)

	merge 1:1 stateicp statefip countyicp using `white', nogen
	merge 1:1 stateicp statefip countyicp using `pooled', nogen

	// Add fips 
	gen fips = statefip*10000 + countyicp 

	compress
	save "$PROJ_PATH/analysis/processed/data/ipums/childhood_survival.dta", replace
	
	// Clean up
	rm "$PROJ_PATH/analysis/processed/temp/hik_in_1920_and_1930.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF