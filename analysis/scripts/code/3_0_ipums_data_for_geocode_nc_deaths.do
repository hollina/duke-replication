version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 3_0_ipums_data_for_geocode_nc_deaths.do
* PURPOSE: Processes IPUMS USA Full-Count datasets used as input for assigning birth county to birth place text string from North Carolina death certificates (3_geocode_nc_deaths.do)

************

local places		1

*************************************************
// Get IPUMS/NHGIS places *****
*************************************************

if `places' { 
	
	// Load IPUMS PLACENHG code list: https://usa.ipums.org/usa-action/variables/PLACENHG#codes_section
	import excel using "$PROJ_PATH/analysis/raw/ipums/ipums_placenhg_code_list.xlsx", firstrow case(lower) clear	
	tempfile ipums_placenhg_code_list
	save `ipums_placenhg_code_list', replace

	// Load 1940 complete count extract 
	use statefip countyicp city placenhg using "$PROJ_PATH/analysis/raw/ipums/usa_00087.dta", clear
	bysort statefip countyicp city placenhg: gen total_obs = _N
	gduplicates drop 

	// Merge in PLACENHG codes 
	fmerge m:1 placenhg using `ipums_placenhg_code_list', assert(2 3) keep(3) nogen
	gen fips = statefip*10000 + countyicp 
	order statefip state countyicp fips city placenhg placename

	rename placename stdcity 
	rename countyicp county 
	keep statefip state county city stdcity total_obs placenhg 

	// Drop unincorporated places 
	drop if placenhg == "9999999999"

	preserve 
		
		keep placenhg
		gduplicates drop
		tempfile placenhg_nc
		save `placenhg_nc', replace 

	restore 

	drop placenhg state
	replace stdcity = upper(stdcity)
	order statefip county city stdcity total_obs  
	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ipums_placenhg_codes_1940.dta", replace

	// Run code in R to add 1940 counties to PLACENHG locations
	shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/_placenhg_nhgis_overlay.R"
	
	// Load place points with added county 
	clear 
	forvalues y = 1910(10)1940 {
		append using "$PROJ_PATH/analysis/processed/temp/placenhg_nhgis_xwk_`y'.dta"
	}
	rename _all, lower

	// Restrict to NC
	keep if state == "North Carolina"
	fmerge m:1 placenhg using `placenhg_nc', keepusing(placenhg) 
	keep if _merge == 1
	drop _merge

	keep state county stdcity
	order state county stdcity
	rename stdcity unincorporated 
	gen obs = 1000
	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/unincorporated_placenhg_1910_1940.dta", replace
	
	forvalues y = 1910(10)1940 {
		cap rm "$PROJ_PATH/analysis/processed/temp/placenhg_nhgis_xwk_`y'.dta"
	}

}

disp "DateTime: $S_DATE $S_TIME"

* EOF