version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 2_clean_data.do
* PURPOSE: processes the main dataset in preparation for analysis
* NOTE: 1909_1923 AMD file received in pre-processed state with no documentation
* NOTE: Code for cleaning Duke data is old and should be checked over
* NOTE: Add to pipeline: "$PROJ_PATH/analysis/processed/data/crosswalks/stateabb.dta"

************

************
* Code begins
************

// User switches for each section of code
local icpsr_cty 		1	// DEPENDENCIES: none
local nhgis 			1 	// DEPENDENCIES: icpsr_cty 
local icpsr 			1   // DEPENDENCIES: none
local hosp_xwk			1	// DEPENDENCIES: none
local duke 				1	// DEPENDENCIES: nhgis, hosp_xwk
local chd				1	// DEPENDENCIES: nhgis
local vital_stats		1 	// DEPENDENCIES: nhgis

// For first stage 
local ama 				1	// DEPENDENCIES: hosp_xwk, nhgis
local hosp_name			1	// DEPENDENCIES: hosp_xwk, duke, ama
local first_stage		1	// DEPENDENCIES: hosp_xwk, duke, ama, hosp_name, icpsr  

// For doctors 
local amd_physicians	1 	// DEPENDENCIES: none 
local amd_med_schools	1 	// DEPENDENCIES: none 
local amd_quality		1 	// DEPENDENCIES: none 

// For 3_geocode_nc_deaths.do 
local geoxwk 			1	// DEPENDENCIES: nhgis, icpsr_cty
local gnis				1 	// DEPENDENCIES: nhgis and REQUIRES R

// For long-run Numident 
local numident			1	// DEPENDENCIES: nhgis 

// Save archived version of intermediate files 
local update			0	// Archive previous version of output files

// List of Southern states 
local southern_states 	"inlist(statefip,1,5,10,11,12,13,21,22,24,28,37,40,45,47,48,51,54)"


***********************************
// Process ICPSR county codes *****
***********************************

if `icpsr_cty' {
	
	use "$PROJ_PATH/analysis/processed/intermediate/icpsr/icpsr_county_codes_uncleaned.dta", clear

	rename statefips statefip
	rename countycod countyicp
	rename county county_icpsr

	drop if state == "Other"
	drop if countyicp == .
	
	replace county_icpsr = "Lanai/Molakai/Niihau/Oahu" if statefip == 15 & countyicp == 9997
	gduplicates drop

	replace county_icpsr = upper(county_icpsr)
	replace state = upper(state)
		
	la var state "State"
	la var stateicp "State (ICPSR code)"
	la var statefip "State (FIPS code)"
	la var countyicp "County (ICPSR code)"
	la var county_icpsr "County (ICPSR name)"

	gisid statefip countyicp
	gsort statefip countyicp
	save "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_codes_1850-1930.dta", replace
	
}


**********************************************************
// Process raw NHGIS boundary files and tabular data *****
**********************************************************

if `nhgis' {
	
	forvalues y = 1900(10)1960 {
		
		use "$PROJ_PATH/analysis/processed/intermediate/nhgis/nhgis_`y'_db.dta", clear

		rename _all, lower
		keep nhgisst nhgiscty nhgisnam statenam gisjoin icpsrctyi
		
		gen statefip = nhgisst
		gen str_nhgiscty = nhgiscty 
		
		rename nhgisst str_nhgisst
		rename nhgisnam county_nhgis
		rename statenam state
		rename icpsrctyi countyicp

		destring statefip nhgiscty, replace
		
		replace statefip = floor(statefip/10)
		replace state = upper(state)
		replace county_nhgis = upper(county_nhgis)

		gen fips = statefip*10000 + countyicp
		
		la var state "State"
		la var statefip "State (FIPS code)"
		la var county_nhgis "County (NHGIS name)"
		la var countyicp "County (ICPSR code)"
		la var nhgiscty "County (NHGIS code)"
		la var str_nhgisst "State (NHGIS code, string)"
		la var str_nhgiscty "County (NHGIS code, string)"
		la var gisjoin "GISJOIN"
		la var fips "=FIPS*10000+ICPSR (County FE)"
		
		gisid statefip countyicp gisjoin
		gsort statefip countyicp gisjoin
				
		order state statefip str_nhgisst county_nhgis countyicp fips str_nhgiscty nhgiscty gisjoin
		compress
		save "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_`y'_counties.dta", replace
		
	}
	
	// Get list of unique codes in NHGIS 
	clear 
	forvalues y = 1900(10)1960 {
		append using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_`y'_counties.dta"
	}
	
	// Clean county name 
	replace county_nhgis = regexr(county_nhgis," \(NEW\)$","")
	
	// Restrict to Southern states 
	keep if `southern_states'
	
	gduplicates drop 
		
	// Prioritize entries with countyicp code
	egen tot_countyicp = max(countyicp != 0), by(gisjoin)
	drop if countyicp == 0 & tot_countyicp == 1
	drop tot_countyicp 
	
	// Merge in ICPSR county names and state codes 
	merge m:1 statefip countyicp using "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_codes_1850-1930.dta", keepusing(stateicp county_icpsr) keep(1 3) nogen 
	
	replace stateicp = 53 if statefip == 40 & stateicp == .
	replace stateicp = 40 if statefip == 51 & stateicp == .
	assert !missing(stateicp)
	replace county_icpsr = county_nhgis if county_icpsr == ""
	
	gisid str_nhgisst str_nhgiscty
	gsort str_nhgisst str_nhgiscty
	
	save "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", replace 

	
	// Restrict to Carolinas 
	use "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", clear
	keep if statefip == 37 | statefip == 45 
	gisid statefip county_nhgis
	save "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties_carolinas.dta", replace 
	
	
	// Load NHGIS tabular data by census year, 1900 to 1960 
	
	// 1900
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds31_1900_county.dta", clear

	gen pop_total = aym001 
	gen pop_urban = ayt001 
	gen pop_other_race = az3001 + az3002
	gen pop_black = az3003 + az3004
	gen pop_illit = ays001 + ays002 + ays003 + ays004 + ays005

	keep year statea countya pop_* 
	
	tempfile nhgis_1900
	save `nhgis_1900', replace	
	
	// 1910
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds37_1910_county.dta", clear

	gen pop_total = a3y001
	gen pop_urban = a36001 
	gen pop_black = a30003 + a30004
	gen pop_other_race = a3y001 - (a30001 + a30002 + a30003 + a30004)
	gen pop_illit = a38001

	gen pop_fem_bk = a30004
	gen pop_fem_wt = a30002
	
	keep year statea countya pop_*
	
	tempfile nhgis_1910
	save `nhgis_1910', replace	
	
	// 1920
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds43_1920_county.dta", clear

	gen pop_total = a7l001
	gen pop_urban = a7t001 
	gen pop_black = a8l005 + a8l006
	gen pop_other_race = a7l001 - (a8l001 + a8l002 + a8l003 + a8l004 + a8l005 + a8l006)
	gen pop_illit = a7u001

	gen pop_fem_bk = a8l006
	gen pop_fem_wt = a8l002 + a8l004
	
	keep year statea countya pop_*

	tempfile nhgis_1920
	save `nhgis_1920', replace
	
	// 1930
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds54_1930_county.dta", clear

	gen pop_total = bdp001
	gen pop_urban = bdx001 
	gen pop_black = bep005 + bep006
	gen pop_other_race = bdp001 - (bep001 + bep002 + bep003 + bep004 + bep005 + bep006)
	gen pop_illit = bdv001
	gen sales_retail = bet001

	gen pop_fem_bk = bep006
	gen pop_fem_wt = bep002 + bep004
	
	keep year statea countya pop_* sales_*

	tempfile nhgis_1930
	save `nhgis_1930', replace

	// 1940 	
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds78_1940_county.dta", clear

	gen pop_total = bv7001
	gen pop_urban = bw1001 
	gen pop_black = bya003
	gen pop_other_race = bya004
	gen sales_retail = bxh001
	
	gen pop_fem_bk = bxn002*(pop_black/pop_total)
	gen pop_fem_wt = bxn002*((pop_total-pop_black-pop_other_race)/pop_total)
	
	keep year statea countya pop_* sales_* 
	
	tempfile nhgis_1940
	save `nhgis_1940', replace
	
	// 1950 
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds84_1950_county.dta", clear
	
	gen pop_total = b18001
	gen pop_urban = b2j001 
	gen pop_black = b3p003 + b3p007
	gen pop_other_race = b3p004 + b3p008

	gen pop_fem_bk = b3p007
	gen pop_fem_wt = b3p005 + b3p006	

	keep year statea countya pop_* 

	tempfile nhgis_1950
	save `nhgis_1950', replace
	
	// 1960		
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds91_1960_county.dta", clear
		
	gen pop_total = b5o001
	gen pop_black = b5s002 + b5s009
	gen pop_other_race = pop_total - (pop_black + b5s001 + b5s008)

	keep year statea countya pop_* 
	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds91_1960_county.dta", clear
	
	gen pop_total = b5o001
	gen pop_black = b5s002 + b5s009
	gen pop_other_race = pop_total - (pop_black + b5s001 + b5s008)

	keep year statea countya pop_* 	

	tempfile nhgis_1960
	save `nhgis_1960', replace
	
	clear
	forvalues y = 1900(10)1960 {
		cap append using `nhgis_`y''
	}
	
	destring year, replace
		
	// Merge in NHGIS counties and keep only Southern states 
	gen str_nhgisst = statea 
	gen str_nhgiscty = countya 
	
	merge m:1 str_nhgisst str_nhgiscty using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", assert(1 3) 
	
	// Drop if missing population 
	drop if missing(pop_total)
	
	// Make sure states that merge always merge
	egen state_ever_merge = max(_merge == 3), by(str_nhgisst)
	assert _merge == 3 if state_ever_merge == 1
	keep if _merge == 3
	drop _merge state_ever_merge 
	
	// Get first and last census 
	egen first_census = min(year), by(fips)
	egen last_census = max(year), by(fips)
	
	// Makes sure identifiers are unique 
	gsort str_nhgisst str_nhgiscty year 
	gisid str_nhgisst str_nhgiscty year 
	gisid fips year 
	
	save "$PROJ_PATH/analysis/processed/temp/nhgis_tables.dta", replace 
	
	
	
	// Make copies for previous and next censuses for units that drop out 
	use "$PROJ_PATH/analysis/processed/temp/nhgis_tables.dta" if first_census != 1900, clear
	drop pop_* sales* year 
	gduplicates drop 
	gen year = first_census - 10
	tempfile previous_census
	save `previous_census', replace
	
	use "$PROJ_PATH/analysis/processed/temp/nhgis_tables.dta" if last_census != 1960, clear
	drop pop_* sales* year 
	gduplicates drop 
	gen year = last_census + 10
	tempfile next_census
	save `next_census', replace
	
	use "$PROJ_PATH/analysis/processed/temp/nhgis_tables.dta", clear
	append using `previous_census'
	append using `next_census'
	gisid fips year 
	gsort fips year 
	tempfile expanded_nhgis_tables 
	save `expanded_nhgis_tables', replace 
	
	drop pop_* sales* 
	
	expand 10, gen(dup)
	gsort fips year dup 
	replace year = . if dup == 1
	by fips: replace year = year[_n-1] + 1 if missing(year) & dup == 1 
	drop if year > 1962 
	drop dup 
	
	merge 1:1 fips year using `expanded_nhgis_tables', assert(1 3) nogen 
	
	gisid fips year
	gsort fips year
	
	foreach var of varlist pop_* sales_* { 
		by fips: ipolate `var' year, gen(i_`var') epolate
		drop `var'
		rename i_`var' `var'
		replace `var' = 0 if `var' < 0
		replace `var' = floor(`var')
	}
	recode pop_* sales_* (mis = 0)
	
	// Drop years we know county didn't exist
	drop if year >= last_census + 10
	drop if year <= first_census - 10	
	drop first_census last_census
	
	// If total population is zero, everything else is zero 
	foreach var of varlist pop_urban pop_other_race pop_black pop_illit pop_fem_bk pop_fem_wt sales_retail {
		replace `var' = 0 if pop_total == 0
	}
	
	gen pop_fem = pop_fem_wt + pop_fem_bk
	
	sum pop* sales* 
	
	gen double percent_black = pop_black*100/pop_total
	gen double percent_other_race = pop_other_race*100/pop_total
	gen double percent_urban = pop_urban*100/pop_total
	gen double percent_illit = pop_illit*100/pop_total

	gen double percent_fem_bk = pop_fem_bk*100/pop_total
	gen double percent_fem_wt = pop_fem_wt*100/pop_total
	
	gen double retail_sales_per_capita = sales_retail/pop_total
	drop sales_retail

	recode percent_* (mis = 0)

	// Percent variables can't be greater than 100
	foreach var of varlist percent_* {
		replace `var' = 100 if `var' > 100
	}
	
	sum percent*
	
	la var pop_total "Total population"
	la var pop_black "Non-white Population, black"
	la var pop_other_race "Non-white Population, other race"
	la var pop_urban "Population urban"
	la var pop_illit "Illiterate population 10 years of age and over"

	la var percent_black "% population black"
	la var percent_other_race "% population other race"
	la var percent_urban "% population urban"
	la var percent_illit "% population illiterate"
	la var retail_sales_per_capita "Sales, retail stores per capita"

	la var pop_fem_wt "White Female Population"
	la var pop_fem_bk "Black Female Population"
	la var pop_fem "Female Population (Black and White)"
	
	save "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", replace	

	rm "$PROJ_PATH/analysis/processed/temp/nhgis_tables.dta"
	
}



******************************************************
// Process ICPSR data *****
******************************************************

if `icpsr' {
	
	// Process ICPSR 36603 data: Extract county-by-year of birth population data
	use "$PROJ_PATH/analysis/raw/icpsr/36603-0001-Data.dta", clear
	
	rename *, lower
	rename statename state
	rename v_h_countycode countyicp

	drop if missing(cofips)
	gen fips = cofips*10
	keep if race == 0 & year >= 1915 & year <= 1962
	
	keep year fips statefip state countyicp births_occ im_occ mort_occ pop
	
	duplicates tag  statefip state countyicp year, gen(check)

	ds fips statefip state countyicp year, not
	foreach z in `r(varlist)' {
		bysort statefip countyicp year: egen `z'_sum = sum(`z')
		replace `z'_sum  = . if check == 0
		replace `z' = `z'_sum if check != 0 & `z'_sum != 0
	}
	bysort statefip countyicp  year state: gen order = _n
	keep if order == 1
	
	drop check 
	drop order 
	drop *sum	
	
	gisid statefip countyicp year, missok 
	gsort statefip countyicp year
	compress
	save "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_year_births.dta", replace
	
}	
	
**********************************
// Create hospital crosswalk *****
**********************************

if `hosp_xwk' {
		
	// Load all raw data files with locations of hospitals in North Carolina
	use "$PROJ_PATH/analysis/processed/intermediate/duke/labc_locations_1925_1962.dta", clear
	keep year hospitals location county state
	compress
	tempfile temp_1
	save `temp_1', replace
	
	use "$PROJ_PATH/analysis/processed/intermediate/duke/ce_locations_1927_1938.dta", clear 
	rename Year year
	rename State state
	rename Hospital hospitals
	rename Town location 
	rename County county
	keep year hospitals location county state
	gduplicates drop
	tempfile temp_2
	save `temp_2', replace

	use "$PROJ_PATH//analysis/processed/intermediate/duke/ce_locations_1939_1962.dta", clear
	rename project hospitals
	keep year hospitals location 
	tempfile temp_3
	save `temp_3', replace

	use "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta", clear
	rename statename state
	rename countyname county 
	rename hospitalname hospitals
	rename cityname_orginal location 
	keep state county hospitals location 
	tempfile temp_4
	save `temp_4', replace

	use "$PROJ_PATH/analysis/processed/intermediate/ama/intership_hospitals.dta", clear
	drop in 1/2
	
	rename A state
	rename B location
	rename D institution
	
	keep state location institution
	
	replace state = "NC" if state == "North Carolina"
	replace state = "SC" if state == "South Carolina"
	
	keep if state == "NC" | state == "SC"
	
	replace institution = "State Hospital" if institution == "State Hospital of Raleigh"
	rename institution hospitals
	keep state location hospitals
	replace state = proper(state)
	
	compress

	forvalues x = 1(1)4 {
		append using `temp_`x''
	}
	
	// Fix state name issues
	replace state = "North Carolina" if state == "NC" | state == "NC " 
	replace state = "South Carolina" if state == "SC" | state == "S.C." 
	
	tab state, m

	// Keep only North Carolina hospitals 
	keep if state == "North Carolina" | missing(state)
	
	// Preserve raw location string so we can merge into other files on raw string
	gen locstr = location

	// Fix a few location variables
	replace location = "Albemarle" if location == "Albermarle"
	replace location = "Banner Elk" if location == "Banners Elk"
	replace location = "High Point" if location == "HIgh Point"
	replace location = "Huntersville" if location == "Hunterville"
	replace location = "North Wilkesboro" if location == "N. Wilkesboro"
	replace location = "Kinston" if location == "Kingston"
	replace location = "Winston-Salem" if location == "Winston Salem"
	replace location = "Siler City" if location == "Sivler City"
	replace location = "Mount Airy" if location == "Mt. Airy"
	replace location = "" if location == "na"

	// Fix a few misc. errors
	drop if hospitals == "0" | hospitals == "1"
	drop if missing(hospitals)
	drop state year

	// Drop duplicates
	keep locstr location hospitals
	gduplicates drop 
	gunique location hospitals locstr 
	assert r(unique) == r(N)
	gsort location hospitals locstr
	
	// Create fixed-string across time. 
	qui bysort location (hospitals locstr): strgroup hospitals, gen(temp_unique_hosp_id) threshold(0.25)

	sum temp_unique_hosp_id
	local max_number = r(max)
	gen edited_id = . 

	gunique location temp_unique_hosp_id hospitals locstr
	assert r(unique) == r(N)
	gsort location temp_unique_hosp_id hospitals locstr
	compress

	// Now to fix the data
	replace edited_id = 10008 if hospitals == "Roanoke-Chowan"
	replace edited_id = 10008 if hospitals == "Roanoke-Chowan Hospital"

	replace edited_id = 10011 if hospitals == "Stanly County Hospital"

	replace edited_id = 10016 if hospitals == "Anderson County Hospital"
	replace edited_id = 10016 if hospitals == "Anderson County Memorial Hospital"
	replace edited_id = 10016 if hospitals == "Anderson Memorial Hospital"

	replace edited_id = 10023 if hospitals == "Ambler Heights Sanat. (T.B.)"
	replace edited_id = 10023 if hospitals == "Ambler Heights Sanit"
	replace edited_id = 10023 if hospitals == "Ambler Heights Sanit."
	replace edited_id = 10023 if hospitals == "Ambler Heights Sanitarium"

	replace edited_id = 10026 if hospitals == "Appalachian Hall"	
	replace edited_id = 10026 if hospitals == "Appalachian Hall (N. & M.)"	
	replace edited_id = 10026 if hospitals == "Applachian Hall"
		
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Inst."
	replace edited_id = 10032 if hospitals == "Asheville Physiatrie Inst"
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Institute"
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Institute,Wesnoca"
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Institue, Wesnoca"
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Institute Wesnoca"
	replace edited_id = 10032 if hospitals == "Asheville Psychiatric Institute, Wesnoca"
	replace edited_id = 10032 if hospitals == "Asheville Physiatric Institute, Wesnoca"

	replace edited_id = 10035 if hospitals == "Blue Ridge Hospital (col.)"
	replace edited_id = 10035 if hospitals == "Blue Ridge Hosp. (col.)"
	replace edited_id = 10035 if hospitals == "Blue Ridge Hospital"

	replace edited_id = 10038 if hospitals == "Edgewood Cottage"
	replace edited_id = 10038 if hospitals == "Edgewood Cottage (T.B.)"

	replace edited_id = 10041 if hospitals == "Fairview Cottage Sanitarium"
	replace edited_id = 10041 if hospitals == "Fairview Cottage Sanit"
	replace edited_id = 10041 if hospitals == "Fairview Cottage Sanit."
	replace edited_id = 10041 if hospitals == "Fairview Cottages Sanit. (T.B.)"
	replace edited_id = 10041 if hospitals == "Fairview Cottage Sanitarium (T.B.)"

	replace edited_id = 10044 if hospitals == "Highland Hospital"
	replace edited_id = 10044 if hospitals == "Highland Hospital (N. & M.)"

	replace edited_id = 10048 if hospitals == "Meriwether Hosp. and Tr. School"
	replace edited_id = 10048 if hospitals == "Meriwether Hospital"
	 
	replace edited_id = 10054 if hospitals == "Roye Cottage"
	replace edited_id = 10054 if hospitals == "Roye Cottage Sanitarium"

	replace edited_id = 10056 if hospitals == "St. Joseph's Hospital"
	replace edited_id = 10056 if hospitals == "Saint Joseph's Hospital"        
	replace edited_id = 10056 if hospitals == "St. Joseph's Hospital (Converted into a general hospital 1939)"
	replace edited_id = 10056 if hospitals == "St. Joseph's Sanatorium (T.B.)"
	replace edited_id = 10056 if hospitals == "St. Joseph's Sanatorium."
	replace edited_id = 10056 if hospitals == "St. Joseph's Sanatorium"
			  
	replace edited_id = 10061 if hospitals == "Stonchedge Sanitarium (T.B.)"
	replace edited_id = 10061 if hospitals == "Stonehedge Sanitarium"

	replace edited_id = 10064 if hospitals == "Sunset Heights"
	replace edited_id = 10064 if hospitals == "Sunset Heights, Inc. (T.B.)"

	replace edited_id = 10066 if hospitals == "Sunset Lodge"
	replace edited_id = 10066 if hospitals == "Sunset Lodge (T.B.)"

	replace edited_id = 10068 if hospitals == "Violet Hill Sanatorium"
	replace edited_id = 10068 if hospitals == "Violet Hill Sanatorium (T.B.)"

	replace edited_id = 10071 if hospitals == "Winyah Sanatorium"
	replace edited_id = 10071 if hospitals == "Winyah Sanatorium (T.B.)"
	replace edited_id = 10071 if hospitals == "Winyah Sanatorium operated by Von Ruck Memorial Sanatorium, Inc. (T.B.)"

	replace edited_id = 10069 if hospitals == "Zephyr Hill Sanatorium (T.B.)"
	replace edited_id = 10069 if hospitals == "Zephyr Hill Sanatorium"

	replace edited_id = 79 if hospitals == "Grace Hospital "

	replace edited_id = 10090 if hospitals == "Hilleroft Sanatorium"
	replace edited_id = 10090 if hospitals == "Hillcroft Sanatorium"
	replace edited_id = 10090 if hospitals == "Hillcroft Sanatorium (T.B.)"

	replace edited_id = 10094 if hospitals == "Beallmont Park Sanat."
	replace edited_id = 10094 if hospitals == "Beallmont Park Sanat"
	replace edited_id = 10094 if hospitals == "Beallmont Park Sanatorium"
	replace edited_id = 10094 if hospitals == "Beallmont Park Sanat. (N. & M.)"

	replace edited_id = 10096 if hospitals == "Cragmont Sanatorium"
	replace edited_id = 10096 if hospitals == "Cragmont Sanatorium (T.B.)"

	replace edited_id = 10098 if hospitals == "Fellowship Assn. of the Royal League Hospital"
	replace edited_id = 10098 if hospitals == "Fellowship Association of the Royal League Hosp"
	replace edited_id = 10098 if hospitals == "Fellowship Association of the Royal Leagne Hosp."
	replace edited_id = 10098 if hospitals == "Fellowship Sanatorium"
	replace edited_id = 10098 if hospitals == "Fellowship Sanatorium of the Royal League"
	replace edited_id = 10098 if hospitals == "Fellowship Sanatorium of the Royal League (T.B.)"

	replace edited_id = 10118 if hospitals == "Yancey County Hospital"
	replace edited_id = 10118 if hospitals == "Yancey Hospital"

	replace edited_id = 10123 if hospitals == "Pisgah Rural Sanitarium"
	replace edited_id = 10123 if hospitals == "Pisgah Sanitarium and Hospital"
	replace edited_id = 10123 if hospitals == "Pisgah Sanitarium and Hosp."
	replace edited_id = 10123 if hospitals == "Pisgah Sanit. and Hospital"
	replace edited_id = 10123 if hospitals == "Pisgah Sanit. and Hosp."
	replace edited_id = 10123 if hospitals == "Pisgah Sanitarium"

	replace edited_id = 10132 if hospitals == "Charlotte E, E. and T. Hospital"
	replace edited_id = 10132 if hospitals == "Charlotte, Eye, Ear and Throat Hospital"
	replace edited_id = 10132 if hospitals == "Charlotte Eye, Ear & Throat Hospital"
	replace edited_id = 10132 if hospitals == "Charlotte Eye, Ear and Throat Hospital"
	replace edited_id = 10132 if hospitals == "Charlotte Eye Ear & Throat Hospital"

	replace edited_id = 10135 if hospitals == "Charlotte Rehabil. & Spastics Hosp."
	replace edited_id = 10135 if hospitals == "Charlotte Rehabilitation Hospital"
	replace edited_id = 10135 if hospitals == "Charlotte Rehabilitation and Spastics Hospital"

	replace edited_id = 10139 if hospitals == "Florence Crittenton Home"
	replace edited_id = 10139 if hospitals == "Florence Crittenton Industrial Home"

	replace edited_id = 10141 if hospitals == "Good Samaritan Hosp. (col.)"
	replace edited_id = 10141 if hospitals == "Good Samaritan Hospital (col.)"
	replace edited_id = 10141 if hospitals == "Good Samaritan Hospital (Col.)"
	replace edited_id = 10141 if hospitals == "Good Samaritan Hospital "
	replace edited_id = 10141 if hospitals == "Good Samaritan Hospital"

	replace edited_id = 144 if hospitals == "Mercy General Hospital" & location == "Charlotte"

	replace edited_id = 10158 if hospitals == "Cabarrus County Hospital"
	replace edited_id = 10158 if hospitals == "Cabarrus Memorial Hospital"

	replace edited_id = 10169 if hospitals == "Duke Hospital"
	replace edited_id = 10169 if hospitals == "Duke University Hospital"

	replace edited_id = 10171 if hospitals == "Lincoln Hospital (col.)"
	replace edited_id = 10171 if hospitals == "Lincoln Hosp. (col.)"
	replace edited_id = 10171 if hospitals == "Lincoln Hospital"

	replace edited_id = 10192 if hospitals == "Highsmith Hospital"
	replace edited_id = 10192 if hospitals == "Highsmith Memorial Hospital"

	replace edited_id = 10194 if hospitals == "Pittman Hospital"
	replace edited_id = 10194 if hospitals == "Pittman Hospital, R. I."
	replace edited_id = 10194 if hospitals == "Pittman Hospital, Inc"
	replace edited_id = 10194 if hospitals == "Pittman Hospital, R. L."
	replace edited_id = 10194 if hospitals == "R. L. Pittman Hospital"

	// Combined with Ag. School and Mtn. Sanit.
	replace edited_id = 10198 if hospitals == "Mountain Sanit. and Hosp." 
	replace edited_id = 10198 if hospitals == "Mountain Sanitarium and Hosp."
	replace edited_id = 10198 if hospitals == "Mountain Sanit & Hosp"
	replace edited_id = 10198 if hospitals == "Mountain Sanit. & Hosp."
	replace edited_id = 10198 if hospitals == "Mountain Sanitarium and Hospital"
	replace edited_id = 10198 if hospitals == "Mountain Sanit and Hosp."
	replace edited_id = 10198 if hospitals == "Mountain Sanitarium and Hosp"
	replace edited_id = 10198 if hospitals == "Mountain Sanitarium"

	replace edited_id = 10201 if hospitals == "Angel Brothers Hosp"
	replace edited_id = 10201 if hospitals == "Angel Brothers Hospital"
	replace edited_id = 10201 if hospitals == "Angel Bros. Hospital"
	replace edited_id = 10201 if hospitals == "Angel Clinic"
	replace edited_id = 10201 if hospitals == "Angel Hospital"
	replace edited_id = 10201 if hospitals == "Angel's Hospital"

	replace edited_id = 10204 if hospitals == "Lylo Hospital"
	replace edited_id = 10204 if hospitals == "Lyle Hospital"
	replace edited_id = 10204 if hospitals == "The Lyle Hospital"

	replace edited_id = 10208 if hospitals == "Cherokee County Hospital"
	replace edited_id = 10208 if hospitals == "Cherokee County Memorial Hospital"

	replace edited_id = 10210 if hospitals == "Gaston County Negro Hospital"
	replace edited_id = 10210 if hospitals == "Caston County Negro Hosp."
	replace edited_id = 10210 if hospitals == "Gaston County Negro Hosp."
	replace edited_id = 10210 if hospitals == "Gaston County  Colored Hosp"
	replace edited_id = 10210 if hospitals == "Gaston County Colored Hospital"
	replace edited_id = 10210 if hospitals == "Gaston Colored Hosp. (col.)"
	replace edited_id = 10210 if hospitals == "Gaston Colored Hospital"

	replace edited_id = 10212 if hospitals == "Garrison General Hospital"
	replace edited_id = 10212 if hospitals == "Garrison General Hosp"

	replace edited_id = 10215 if hospitals == "Gaston County Sanatorium"
	replace edited_id = 10215 if hospitals == "Gaston Sanatorium"

	replace edited_id = 10219 if hospitals == "North Carolina Orthopedic Hospital for Crippled Children"
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedic Hosp. for Crippled Chil"
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedic Hosp. for Crippled Child"
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedie Hosp. for Crippled Chil."
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedic Hospital"
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedie Hospital"
	replace edited_id = 10219 if hospitals == "North Carolina Orthopedic Hospital for Crippled Children of Sound Minds"

	replace edited_id = 10223 if hospitals == "Goldsboro City Hospital"
	replace edited_id = 10223 if hospitals == "Goldsboro Hospital"

	replace edited_id = 10225 if hospitals == "I. O. O. F. Home"
	replace edited_id = 10225 if hospitals == "Independent Order of Odd Fellows' Home"

	replace edited_id = 10229 if hospitals == "State Hospital"
	replace edited_id = 10229 if hospitals == "State Hospital (col.)"
	replace edited_id = 10229 if hospitals == "State Hospital at Goldsboro"
	replace edited_id = 10229 if hospitals == "State Hospital at Goldsboro (col.)"

	replace edited_id = 10236 if hospitals == "Glenwood Park Sanitarium"
	replace edited_id = 10236 if hospitals == "Glenwood Park Sanitarium (N. & M.)"

	replace edited_id = 10238 if hospitals == "L. Richardson Mem. Hosp. (col.)"
	replace edited_id = 10238 if hospitals == "Richardson Memorial Hospital"
	replace edited_id = 10238 if hospitals == "Richardson Memorial Hospital, L"
	replace edited_id = 10238 if hospitals == "L. Richardson Memorial Hospital"
	replace edited_id = 10238 if hospitals == "Richardson Memorial Hospital "
	replace edited_id = 10238 if hospitals == "Richardson Memorial Hospital, L."
	replace edited_id = 10238 if hospitals == "L. Richardson Memorial Hospital (col.)"

	replace edited_id = 10243 if hospitals == "Reaves E, E, N. and T. Infirmary"
	replace edited_id = 10243 if hospitals == "Reaves Eye, Ear, Nose and Throat Inflrinary"
	replace edited_id = 10243 if hospitals == "Reaves Eye, Ear, Nose and Throat Infirmary"
	replace edited_id = 10243 if hospitals == "Reaves Eye, Ear,Nose and Throat Infirmary"

	replace edited_id = 10248 if hospitals == "Sternberger Children's Hos."
	replace edited_id = 10248 if hospitals == "Sternberger Children's Hospital"
	replace edited_id = 10248 if hospitals == "Sternberger Children's Hosp."
	replace edited_id = 10248 if hospitals == "Sternberger Hospital for Women and Children"
	replace edited_id = 10248 if hospitals == "Sternberger Hosp. for Women and Children"
	replace edited_id = 10248 if hospitals == "Sternberger Hospital for Women & Children"

	// Same as Piedmont Hospital
	replace edited_id = 10242 if hospitals == "Clinic Hospital" 
	replace edited_id = 10242 if hospitals == "The Clinic Hospital"

	replace edited_id = 10251 if hospitals == "Wesley Long Community Hospital"
	replace edited_id = 10251 if hospitals == "Wesley Long Hospital"

	replace edited_id = 10256 if hospitals == "Pitt Community Hospital"
	replace edited_id = 10256 if hospitals == "Pitt Community Hospital."
	replace edited_id = 10256 if hospitals == "Pitt County Memorial Hospital"
	replace edited_id = 10256 if hospitals == "Pitt General Hospital"

	replace edited_id = 10262 if hospitals == "Halifax Co. Tuber. Sanit."
	replace edited_id = 10262 if hospitals == "Halifax County Sanatorium"
	replace edited_id = 10262 if hospitals == "Halifax County Tubereulosis Sanitarium"
	replace edited_id = 10262 if hospitals == "Halifax County Tuberculosis Sanitarium"

	replace edited_id = 10270 if hospitals == "Jubilee Hospital (col.)"
	replace edited_id = 10270 if hospitals == "Jubilco Hospital (col.)"
	replace edited_id = 10270 if hospitals == "Jubiles Hospital (col.)"
	replace edited_id = 10270 if hospitals == "Jubilee Hospital"

	replace edited_id = 10277 if hospitals == "Edgemont Sanatorium"
	replace edited_id = 10277 if hospitals == "Edgemont Sanatorium (T.B.)"

	replace edited_id = 10288 if hospitals == "Brookside Camp"
	replace edited_id = 10288 if hospitals == "Brookside Camp (T.B.)"

	replace edited_id = 10294 if hospitals == "Onslow County Hospital"
	replace edited_id = 10294 if hospitals == "Onslow Memorial Hospital"

	replace edited_id = 10296 if hospitals == "Guilford Co. Sanat. for the Treatment of Tuber"
	replace edited_id = 10296 if hospitals == "Guilford County Sanatorium"
	replace edited_id = 10296 if hospitals == "Guilford County Sanat"
	replace edited_id = 10296 if hospitals == "Guilford County Sanat."
	replace edited_id = 10296 if hospitals == "Guilford County Sanatorium (T.B.)"
	replace edited_id = 10296 if hospitals == "Guilford County Sanatorium for the Treatment of Tuberculosis"

	replace edited_id = 10304 if hospitals == "Lenoir County Hospital"
	replace edited_id = 10304 if hospitals == "Lenoir Memorial Hospital"

	replace edited_id = 10307 if hospitals == "Parrott Memorial Hospital, Inc."
	replace edited_id = 10307 if hospitals == "Parrott Memorial Hospital"
	replace edited_id = 10307 if hospitals == "Parrott Memorial Hosp"
	replace edited_id = 10307 if hospitals == "Parrott Memorial Hosp."
	replace edited_id = 10307 if hospitals == "Parrott Hospital"
	replace edited_id = 10307 if hospitals == "Parrot Hospital"

	replace edited_id = 10312 if hospitals == "Scotland County Memorial Hospital"
	replace edited_id = 10312 if hospitals == "Scotland Memorial Hospital"

	replace edited_id = 10314 if hospitals == "Leaksville General Hospital"
	replace edited_id = 10314 if hospitals == "Leaksville Hospital"

	replace edited_id = 10319 if hospitals == "Caldwell Hospital"
	replace edited_id = 10319 if hospitals == "Caldwell Memorial Hospital"

	// Same as Gamble Clinic
	replace edited_id = 10324 if hospitals == "Reeves Gamble Hospital" 
	replace edited_id = 10324 if hospitals == "Reeves-Gamble Hospital"
	replace edited_id = 10324 if hospitals == "Reeves Hospital"

	replace edited_id = 10332 if hospitals == "Thompson Hospital"
	replace edited_id = 10332 if hospitals == "Thompson Mem. Hosp."
	replace edited_id = 10332 if hospitals == "Thomson Memorial Hospital"
	replace edited_id = 10332 if hospitals == "Thompson Memorial Hosp"
	replace edited_id = 10332 if hospitals == "Thompson Memorial Hosp."
	replace edited_id = 10332 if hospitals == "Thompson Memorial Hospital"
	replace edited_id = 10332 if hospitals == "Baker-Thompson Memorial Hospital"

	replace edited_id = 10339 if hospitals == "Marion County Memorial Hospital"

	replace edited_id = 10346 if hospitals == "Ellen Fltzgerald Hospital"
	replace edited_id = 10346 if hospitals == "Ellen Fitzgerald Hospital"
	replace edited_id = 10346 if hospitals == "The Ellen Fitzgerald Hosp"

	replace edited_id = 10347 if hospitals == "Quality Hill Sanit. (col.)"
	replace edited_id = 10347 if hospitals == "Quality Hill Sanitarium (col.)"
	replace edited_id = 10347 if hospitals == "Quality Hill Sanatorium (col.)"
	replace edited_id = 10347 if hospitals == "Quality Hill Sanat. (col.)"
	replace edited_id = 10347 if hospitals == "Quality Hill Sanitarium"
	replace edited_id = 10347 if hospitals == "Quality Hill Sanatorium"

	replace edited_id = 10353 if hospitals == "Broadoaks Sanatorium"
	replace edited_id = 10353 if hospitals == "Broadoaks Sanatorium (N.& M.)"

	replace edited_id = 10375 if hospitals == "Wilkes County Tuber. Hut."
	replace edited_id = 10375 if hospitals == "Wilkes County Tuber. Hut"
	replace edited_id = 10375 if hospitals == "Wilkes County Tuberculosis Hut"
	replace edited_id = 10375 if hospitals == "Wilkes County Tuberculosis Hut."

	replace edited_id = 10374 if hospitals == "The Wilkes Hospital"
	replace edited_id = 10374 if hospitals == "Willkes Hospital"
	replace edited_id = 10374 if hospitals == "Wilkes Hospital"

	replace edited_id = 10382 if hospitals == "U. S. Veter. Hosp. No. 60"
	replace edited_id = 10382 if hospitals == "U. S. Veterans' Hosp. No. 60"
	replace edited_id = 10382 if hospitals == "United States Veterans' Hospital, No. 60"
	replace edited_id = 10382 if hospitals == "United States Veterans' Hospital No. 60"
	replace edited_id = 10382 if hospitals == "Veterans Admin. Facility"
	replace edited_id = 10382 if hospitals == "Veterans Admin. Hospital"

	replace edited_id = 10390 if hospitals == "William J. Hicks Memorial Hospital"
	replace edited_id = 10390 if hospitals == "Wm. J. Hicks Mem. Hosp."
	replace edited_id = 10390 if hospitals == "Wm. J. Hicks Memorial Hosp"

	replace edited_id = 10393 if hospitals == "Moore County Hospital"
	replace edited_id = 10393 if hospitals == "Moore County Hospital"
	replace edited_id = 10393 if hospitals == "Moore County Hospital "
	replace edited_id = 10393 if hospitals == "Moore Memorial Hospital"

	replace edited_id = 10402 if hospitals == "McCauley Priv. Hosp. (col.)"
	replace edited_id = 10402 if hospitals == "McCauley Private Hospital (col.)"
	replace edited_id = 10402 if hospitals == "McCauley Private Hosp. (col.)"
	replace edited_id = 10402 if hospitals == "MeCauley Private Hospital (col.)"
	replace edited_id = 10402 if hospitals == "McCauley Private Hospital"

	replace edited_id = 10409 if hospitals == "Saint Agnes Hospital"
	replace edited_id = 10409 if hospitals == "St. Agnes' Hospital"
	replace edited_id = 10409 if hospitals == "St. Agnes Hospital"
	replace edited_id = 10409 if hospitals == "St. Agnes' Hosp. (col.)"
	replace edited_id = 10409 if hospitals == "St. Agnes Hospital (col.)"
	replace edited_id = 10409 if hospitals == "St. Agnes' Hospital (col.)"
	replace edited_id = 10409 if hospitals == "St. Agnes Hosp. (col.)"

	replace edited_id = 10413 if hospitals == "Wake County Sanatorium"
	replace edited_id = 10413 if hospitals == "Wake County Tuberculosis Hospital"
	replace edited_id = 10413 if hospitals == "Wake County Tuberculosis Sanatorium"

	// Leaksville hospital listed in Leaksville in one source and Reidsville in another
	replace edited_id = 10317 if hospitals == "Leaksville General Hospital"
	replace edited_id = 10317 if hospitals == "Leaksville General Hosp." 
	replace edited_id = 10317 if hospitals == "Leaksville Hospital"
	replace edited_id = 10317 if hospitals == "Leaksville Hospital, Inc"

	replace edited_id = 10425 if hospitals == "Atlantic Coast Line Hosp"
	replace edited_id = 10425 if hospitals == "Atlantic Coast Line Hosp."
	replace edited_id = 10425 if hospitals == "Atlantic Coast Line Hospital"
	replace edited_id = 10425 if hospitals == "Atlantic Coast Line Railroad Hosp."

	replace edited_id = 10441 if hospitals == "North Carolina Sanat"
	replace edited_id = 10441 if hospitals == "North Carolina Sanat."
	replace edited_id = 10441 if hospitals == "North Carolina Sanatorium"
	replace edited_id = 10441 if hospitals == "North Carolina Sanat. for Treatment of Tuber"
	replace edited_id = 10441 if hospitals == "North Carolina Sanatorium for the Treatment of Tuberculosis"
	replace edited_id = 10441 if hospitals == "Sanat. for Treatment of Tuberc."

	replace edited_id = 10455 if hospitals == "Chatham Hospital" & location == "Siler City"
	replace edited_id = 10456 if hospitals == "Chatham Hospital" & location == "Silver City"

	// Same as NC Sanitarium two entries above
	replace edited_id = 10459 if hospitals == "Johnston County Hospital"
	replace edited_id = 10459 if hospitals == "Johnston County Hospital."
	replace edited_id = 10459 if hospitals == "Johnston County Hosp."
	replace edited_id = 10459 if hospitals == "Johnston Memorial Hospital"

	replace edited_id = 10462 if hospitals == "Pine Crest Manor Sanat. (T.B.)"
	replace edited_id = 10462 if hospitals == "Pine-Crest Manor Sanat"
	replace edited_id = 10462 if hospitals == "Pine-Crest Manor Sanat."
	replace edited_id = 10462 if hospitals == "Pine-Crest Manor Sanatorium"

	replace edited_id = 10464 if hospitals == "Saint Joseph of the Pines"
	replace edited_id = 10464 if hospitals == "Saint Joseph of the Pines Hospital"

	replace edited_id = 10466 if hospitals == "Brunswick County Hospital"
	replace edited_id = 10466 if hospitals == "Brunswick County Hosp."
	replace edited_id = 10466 if hospitals == "Brunswick County Municipal Hospital"

	// Same as Brunswich County Hospital
	replace edited_id = 10466 if hospitals == "Dosher Memorial Hospital, Dr. J. Arthur"	
	replace edited_id = 10466 if hospitals == "Dr. J. A. Dosher Memorial Hospital"
	replace edited_id = 10466 if hospitals == "J. Arthur Dosher Memorial Hospital"
	replace edited_id = 10466 if hospitals == "Dr. J. Arthur Dosher Memorial Hospital"

	replace edited_id = 10472 if hospitals == "Spruce Pine Community Hospital"
	replace edited_id = 10472 if hospitals == "Spruce Pine Hospital "

	replace edited_id = 10474 if hospitals == "Carpenter-Davis Hospital"
	replace edited_id = 10474 if hospitals == "Davis Hospital"

	replace edited_id = 10476 if hospitals == "H. F. Long Hospital"
	replace edited_id = 10476 if hospitals == "Long Hospital"
	replace edited_id = 10476 if hospitals == "Long Hospital, H. F."
	replace edited_id = 10476 if hospitals == "Long's Sanatorium"

	replace edited_id = 10482 if hospitals == "C. J. Harris Community Hospital"
	replace edited_id = 10482 if hospitals == "C. J. Harris Community Hosp"
	replace edited_id = 10482 if hospitals == "Harris Community Hospital, C. J."

	replace edited_id = 10487 if hospitals == "Edgecombe General Hosp."
	replace edited_id = 10487 if hospitals == "Edgecombe General Hosp"
	replace edited_id = 10487 if hospitals == "Edgecombe Memorial Hospital"
	replace edited_id = 10487 if hospitals == "Edgecomb General Hospital"
	replace edited_id = 10487 if hospitals == "Edgecombe General Hospital"
	replace edited_id = 10487 if hospitals == "Egecombe General Hospital"
	replace edited_id = 10487 if hospitals == "Edgecombe County Hospital"

	replace edited_id = 10495 if hospitals == "Montgomery Hospital"
	replace edited_id = 10495 if hospitals == "Montgomery Memorial Hospital"

	replace edited_id = 10503 if hospitals == "Wake Forest College Hosp"
	replace edited_id = 10503 if hospitals == "Wake Forest College Hosp."
	replace edited_id = 10503 if hospitals == "Wake Forest College Infirmary"

	replace edited_id = 10507 if hospitals == "Fowle Memorial Hospital"
	replace edited_id = 10507 if hospitals == "S. R. Fowle Memorial Hosp."
	replace edited_id = 10507 if hospitals == "S. R. Fowle Mem. Hosp."
	replace edited_id = 10507 if hospitals == "S. R. Fowle Memorial Hospital"

	replace edited_id = 10516 if hospitals == "Laurel Hospital" & location == "White Rock"
	replace edited_id = 10516 if hospitals == "Laurel Hospital" & location == "Whiterock"

	replace edited_id = 10520 if hospitals == "Martin County Hospitals"
	replace edited_id = 10520 if hospitals == "Martin General Hospital"

	replace edited_id = 10524 if hospitals == "Community Hosp. (col.)"
	replace edited_id = 10524 if hospitals == "Community Hospital (col.)"
	replace edited_id = 10524 if hospitals == "Community Hospital" & location == "Wilmington"

	replace edited_id = 10527 if hospitals == "Red Cross Sanatorium"
	replace edited_id = 10527 if hospitals == "Red Cross Sanatorium (T.B.)"
	replace edited_id = 10527 if hospitals == "Wilmington Red Cross Sanit"
	replace edited_id = 10527 if hospitals == "Wihnington Red Cross Sanit."
	replace edited_id = 10527 if hospitals == "Wilmington Red Cross Sanatorium"
	replace edited_id = 10527 if hospitals == "Wilmington Tuberculosis Sanatorium"
	replace edited_id = 10527 if hospitals == "Wilmington Tuberculosis Sanitarium"

	replace edited_id = 10538 if hospitals == "Wilson Colored Hospital (col.)"
	replace edited_id = 10538 if hospitals == "Wilson Hospital and Tubercular Home"
	replace edited_id = 10538 if hospitals == "Wilson Hospital and Tuberc. Home"

	replace edited_id = 10542 if hospitals == "City Hospital" & location != "Thomasville"
	replace edited_id = 10542 if hospitals == "City Memorial Hospital" & location != "Thomasville"
	replace edited_id = 10542 if hospitals == "City Memorial Hosp." & location != "Thomasville"
	replace edited_id = 10542 if hospitals == "City Memorial Hospital White Division of City Hospital" & location != "Thomasville"

	replace edited_id = 10545 if hospitals == "Forsyth Co. Tuber. Hosp."
	replace edited_id = 10545 if hospitals == "Forsyth Co. Tuber. Sanat"
	replace edited_id = 10545 if hospitals == "Forsyth County Hospital"
	replace edited_id = 10545 if hospitals == "Forsyth County Sanat"
	replace edited_id = 10545 if hospitals == "Forsyth County Sanat."
	replace edited_id = 10545 if hospitals == "Forsyth County Sanatorium"
	replace edited_id = 10545 if hospitals == "Forsyth County Tuberculosis Hospital"
	replace edited_id = 10545 if hospitals == "Forsyth County Tuberculosis Hosp."
	replace edited_id = 10545 if hospitals == "Forsyth County Tuberculosis Sanatorium"
	replace edited_id = 10545 if hospitals == "Forsyth County Sanatorium" & location == "Winston Salem"	

	replace edited_id = 10553 if hospitals == "Juvenile Relief Association"
	replace edited_id = 10553 if hospitals == "Juvenile Relief Home"

	replace edited_id = 10555 if hospitals == "Kate Bitting Reynolds Memorial Hospital"
	replace edited_id = 10555 if hospitals == "Kate B. Reynolds Memorial Hospital"
	replace edited_id = 10555 if hospitals == "Kate Bitting Reynolds Memorial Hospital Colored Division of City Hospital"

	replace edited_id = 10557 if hospitals == "Lawrence Clinic"
	replace edited_id = 10557 if hospitals == "Lawrence-Cooke Clinic Hospital"

	replace edited_id = 10564 if hospitals == "Babies' Hospital"
	replace edited_id = 10564 if hospitals == "Babies Hospital"
	replace edited_id = 10564 if hospitals == "Babies Hospital"
	replace edited_id = 10564 if hospitals == "Babies Hospital"
	replace edited_id = 10564 if hospitals == "The Babies' Hospital"
	replace edited_id = 10564 if hospitals == "The Babies Hospital"

	replace edited_id = 10005 if hospitals == "Spartanburg Baby Hosp."
	replace edited_id = 10005 if hospitals == "Spartanburg Baby Hosp"
	replace edited_id = 10005 if hospitals == "Spartanburg Baby Hospital"
	replace edited_id = 10005 if hospitals == "Spartanburg Baby Hospital"

	replace edited_id = 10004 if hospitals == "Roaring Gap Hospital"

	replace edited_id = 10002 if hospitals == "Junior League Baby Home"
	replace edited_id = 10002 if hospitals == "Junior League Baby Hosp"
	replace edited_id = 10002 if hospitals == "Junior League Baby Hospital"
	replace edited_id = 10002 if hospitals == "Junior League Baby Hosp."

	replace edited_id = 10001 if hospitals == "Haywood County Hosp."
	replace edited_id = 10001 if hospitals == "Haywood County Hospital"
	
	replace hospitals = ustrtrim(hospitals)
	
	replace edited_id = 10051 if location == "Asheville" & (hospitals == "Oak Hill Sanatorium" | hospitals == "Oakland Sanitarium")
	replace edited_id = 10053 if location == "Asheville" & (hospitals == "Pisgah Sanitarium and Hosp." | hospitals == "Pisgah Sanitarium and Hospital")
	replace edited_id = 10079 if location == "Banner Elk" & (hospitals == "Grace Hartley Memorial Hospital" | hospitals == "Grace Hospital")
	replace edited_id = 10115 if location == "Burlington" & (hospitals == "Alamance General Hospital" | hospitals == "Rainey Hospital")
	replace edited_id = 10144 if location == "Charlotte" & (hospitals == "Mercy General Hospital" | hospitals == "Mercy Hospital")
	replace edited_id = 10171 if location == "Durham" & hospitals == "Lincoln Hospital"
	replace edited_id = 10184 if location == "Duke" & hospitals == "Good Hope Hospital"
	replace edited_id = 10184 if location == "Erwin" & hospitals == "Good Hope Hospital"
	replace edited_id = 10197 if location == "Fayetteville" & hospitals == "Veterans Admin. Facility"
	replace edited_id = 10202 if location == "Franklin" & hospitals == "Angel Clinic"
	replace edited_id = 10211 if location == "Gastonia" & hospitals == "Gaston Memorial Hospital"
	replace edited_id = 10357 if location == "Morganton" & (hospitals == "State Hospital" | hospitals == "State Hospital for Insane")
	replace edited_id = 10408 if location == "Raleigh" & (hospitals == "Royster Medical Center Unit of State Hospital" | hospitals == "State Hospital")
	replace edited_id = 10416 if location == "Reidsville" & hospitals == "Memorial Hospital"
	replace edited_id = 10428 if location == "Rocky Mount" & (hospitals == "Rocky Mount Sanit." | hospitals == "Rocky Mounty Sanitarium" | hospitals == "Rocky Mount Sanitarium")
	replace edited_id = 10535 if location == "Wilson" & (hospitals == "Mercy Hospital" | hospitals == "Mercy Hospital (col.)")
	replace edited_id = 10538 if location == "Wilson" & (hospitals == "Wilson Hospital and Tubercular Home" | hospitals == "Wilson Hospital and Tuberc. Home")
	replace edited_id = 10541 if location == "Winston-Salem" & (hospitals == "Children's Home" | hospitals == "The Children's Home" | hospitals == "Heath Memorial Infirmary of the Children's Home" | hospitals == "Heath Memorial Infirmary of the Children's Home.")
	replace edited_id = 10542 if location == "Winston-Salem" & hospitals == "City Hospital"
	replace edited_id = 10543 if location == "Winston-Salem" & (hospitals == "City Memorial Hospital" | hospitals == "City Memorial Hosp." | hospitals == "City Memorial Hospital White Division of City Hospital" | hospitals == "Winston-Salem City Mem. Hosp.")
	replace edited_id = 10546 if location == "Winston-Salem" & hospitals == "Forsyth County Hospital"
	replace edited_id = 10555 if location == "Winston-Salem" & hospitals == "Kate Bitting Reynolds Memorial Hospital Colored Division of City Hospital"
	
	replace edited_id = . if location == "Gastonia" & hospitals == "City Hospital"
	replace edited_id = . if location == "Greensboro" & hospitals == "State Hospital (col.)"
	replace edited_id = . if location == "Hickory" & hospitals == "City Memorial Hospital"
	replace edited_id = . if location == "Lincolnton" & hospitals == "Lincoln Hospital"
	
	// Create temporary ID
	gen hosp_unique_id = temp_unique_hosp_id
	replace hosp_unique_id = edited_id if !missing(edited_id)
	replace hosp_unique_id = 10000 + hosp_unique_id if hosp_unique_id < 10000 
	
	keep hosp_unique_id locstr hospitals location
	
	gen phase = 1
	
	tempfile phase_1
	save `phase_1', replace
	
	// Extract locations from raw AHA data - append in 2nd stage of ID construction
	use "$PROJ_PATH/analysis/processed/intermediate/ama/ama_carolina_hospitals_uncleaned.dta", clear

	rename hospitalname hospitals
	rename city location 
	keep state hospitals location 
	replace state = proper(state)
	tab state, m
	compress

	// Keep only North Carolina hospitals 
	keep if state == "North Carolina"
	drop state 
	
	// Preserve raw location string so we can merge into other files on raw string
	gen locstr = location

	// Fix a few location variables
	replace location = ustrtrim(location)
	
	replace location = "Albemarle" if location == "Albermarle"
	replace location = "Asheboro" if location == "Ashboro"
	replace location = "Asheville" if location == "Candler"
	replace location = "Banner Elk" if location == "Banners Elk"
	replace location = "Charlotte" if location == "Chariotte"
	replace location = "Fort Bragg" if location == "Ft. Bragg"
	replace location = "High Point" if location == "Hight Point"
	replace location = "Kinston" if location == "Kingston"
	replace location = "Sanatorium" if location == "McCain"
	replace location = "Mount Airy" if location == "Mt. Airy"
	replace location = "New Bern" if location == "Newbern"
	replace location = "North Wilkesboro" if location == "Northwilkesboro"
	replace location = "Salisbury" if location == "Sailsbury"
	replace location = "Samarcand" if location == "Samareand"
	replace location = "Sanatorium" if location == "Sanatorium (P. O. Only)"
	replace location = "Tryon" if location == "Tyron"
	replace location = "Durham" if location == "West Durham"
	replace location = "Jefferson" if location == "West Jefferson"
	replace location = "Raleigh" if location == "McCauley Private Hospital"

	// Fix a few misc. errors
	drop if hospitals == "Total for community use, 122" | hospitals == "Totals"
	drop if missing(hospitals)
	
	// Drop duplicates
	gduplicates drop 
	gunique location hospitals locstr
	assert r(unique) == r(N)
	gsort location hospitals locstr
	
	gen phase = 2
	
	tempfile phase_2
	save `phase_2', replace
	
	clear
	append using `phase_1'
	append using `phase_2'
	
	egen tot_1 = total(phase == 1), by(locstr hospitals)
	egen tot_2 = total(phase == 2), by(locstr hospitals)
	
	tab tot_1 tot_2
	drop if tot_1 > 0 & phase == 2
	drop tot_1 tot_2
	
	// Create fixed-string across time. 
	gduplicates drop 
	gunique location hospitals locstr 
	assert r(unique) == r(N)
	gsort location hospitals locstr 
	qui bysort location (hospitals locstr): strgroup hospitals, gen(updated_hosp_id) threshold(0.25)
	gduplicates drop
	
	gunique updated_hosp_id hosp_unique_id location locstr hospitals
	assert r(unique) == r(N)
	gsort updated_hosp_id hosp_unique_id location locstr hospitals
	
	// Identify new strings uniquely matched to existing hospitals
	preserve
	
		keep hosp_unique_id updated_hosp_id
		drop if hosp_unique_id == .
		gduplicates drop
		bysort updated_hosp_id: keep if _N == 1
		rename hosp_unique_id temp_hosp_id
		tempfile crosswalk
		save `crosswalk', replace
	
	restore
	
	merge m:1 updated_hosp_id using `crosswalk', keep(1 3) nogen
	
	// Identify new strings that are not matched to any existing hospital
	preserve
	
		egen tot_1 = total(phase == 1), by(updated_hosp_id)
		drop if tot_1 > 0
		drop tot_1
		
		keep if phase == 2
		keep updated_hosp_id
		gduplicates drop
		tempfile new_hospitals
		save `new_hospitals', replace
	
	restore
	
	merge m:1 updated_hosp_id using `new_hospitals', assert(1 3)
	
	replace temp_hosp_id = 20000 + updated_hosp_id if _merge == 3
	drop _merge
	replace temp_hosp_id = . if phase == 1
	
	gunique updated_hosp_id hosp_unique_id location locstr hospitals
	assert r(unique) == r(N)
	gsort updated_hosp_id hosp_unique_id location locstr hospitals
	drop phase updated_hosp_id
	
	// Manual edits
	replace temp_hosp_id = 10020 if hospitals == "Barnes-Griffin Clinic Hosp." | hospitals == "Barnes-Griffin Clinic Hospital" | hospitals == "Barnes-Griffin Clinic-Hospital"
	replace temp_hosp_id = 10050 if hospitals == "Victoria Hospital" & location == "Asheville"
	replace temp_hosp_id = 10064 if hospitals == "Sunset Heights Sanitarium"
	replace temp_hosp_id = 10047 if hospitals == "Memorial Mission Hospital"
	replace temp_hosp_id = 10050 if hospitals == "Norburn Hospital and Clinic"
	replace temp_hosp_id = 10053 if hospitals == "Pisgah Sanitarium" & location == "Asheville"
	replace temp_hosp_id = 10123 if regexm(hospitals,"Pisgah") & locstr == "Candler"
	replace temp_hosp_id = 10164 if hospitals == "Preyer Infirmary" & location == "Davidson"
	replace temp_hosp_id = 10188 if hospitals == "Cumberland County Sanatorium"
	replace temp_hosp_id = 10197 if (hospitals == "Veterans Admin. Center" | hospitals == "Veterans Admin. Hospital") & location == "Fayetteville"
	replace temp_hosp_id = 10202 if hospitals == "Angel Clinic Hospital" | hospitals == "Angel Clinic-Hospital"
	replace temp_hosp_id = 10206 if (hospitals == "Station Hospital" | hospitals == "Regional Hospital" | hospitals == "U. S. Army Hospital") & (location == "Fort Bragg" | location == "Ft. Bragg")
	replace temp_hosp_id = 10307 if hospitals == "Parrott Memorial Hospital" | hospitals == "Parrott Memorial Hospital."
	replace temp_hosp_id = 10317 if hospitals == "Leaksville Hospital, Inc."
	replace temp_hosp_id = 10365 if (hospitals == "Nash County Tuberculosis Sanatorium" | hospitals == "Tuberculosis Sanatorium") & location == "Nashville"
	replace temp_hosp_id = 10373 if hospitals == "Catawba Hospital" & location == "Newton"
	replace temp_hosp_id = 10430 if hospitals == "Speight-Stone-Bell Clinic" | hospitals == "Stone-Bell-Way-Robertson Clinic-Hospital"
	replace temp_hosp_id = 10431 if hospitals == "Brewer-Starling Clinic Hosp." | hospitals == "Brewer-Starling Clinic-Hosp." | hospitals == "Brewer-Starling Clinic-Hospital"
	replace temp_hosp_id = 10448 if hospitals == "Halifax County Clinic-Hospital"
	replace temp_hosp_id = 10515 if hospitals == "Blevin's Sanatorium" | hospitals == "Blevins Sanatorium"
	replace temp_hosp_id = 10522 if hospitals == "Bulluck Hospital Clinic" | hospitals == "Bulluck Hospital-Clinic"
	replace temp_hosp_id = 20137 if hospitals == "U. S. Naval Dispensary" & location == "Chapel Hill"
	replace temp_hosp_id = 20593 if hospitals == "Casstevens Clinic"
	
	drop if hospitals == "Eighteen General Hospitals of less than 25 beds"
	
	replace hosp_unique_id = temp_hosp_id if hosp_unique_id == .
	assert hosp_unique_id != .

	keep hosp_unique_id locstr hospitals location
	gduplicates drop
	gunique hosp_unique_id locstr hospitals location
	assert r(unique) == r(N)
	gsort hosp_unique_id locstr hospitals location
	
	gen phase = 1

	tempfile phase_1
	save `phase_1', replace
	
	// Set up phase 3
	use "$PROJ_PATH/analysis/processed/intermediate/duke/ce_locations_1927_1938_entry_2.dta", clear
	keep hospital location state
	gduplicates drop
	rename hospital hospitals

	compress

	// Keep only North Carolina hospitals
	tab state, m
	keep if state == "NC"
	drop state

	gen locstr = location
	replace location = ustrtrim(location)

	// Drop duplicates
	gduplicates drop 
	gunique location hospitals locstr
	assert r(unique) == r(N)
	gsort location hospitals locstr

	replace location = "Morehead City" if location == "Morehead"

	gen phase = 3

	tempfile phase_3
	save `phase_3', replace

	clear
	append using `phase_1'
	append using `phase_3'

	egen tot_1 = total(phase == 1), by(locstr hospitals)
	egen tot_3 = total(phase == 3), by(locstr hospitals)

	tab tot_1 tot_3
	drop if tot_1 > 0 & phase == 3
	drop tot_1 tot_3

	// Create fixed-string across time
	gunique location hospitals locstr 
	assert r(unique) == r(N)
	gsort location hospitals locstr 
	qui bysort location (hospitals locstr): strgroup hospitals, gen(updated_hosp_id) threshold(0.25)
	gduplicates drop

	gunique updated_hosp_id hosp_unique_id location locstr hospitals
	assert r(unique) == r(N)
	gsort updated_hosp_id hosp_unique_id location locstr hospitals

	// Identify new strings uniquely matched to existing hospitals
	preserve

		keep hosp_unique_id updated_hosp_id
		drop if hosp_unique_id == .
		gduplicates drop
		bysort updated_hosp_id: keep if _N == 1
		rename hosp_unique_id temp_hosp_id
		tempfile crosswalk
		save `crosswalk', replace

	restore

	merge m:1 updated_hosp_id using `crosswalk', keep(1 3) nogen

	// Identify new strings that are not matched to any existing hospital
	preserve

		egen tot_1 = total(phase == 1), by(updated_hosp_id)
		drop if tot_1 > 0
		drop tot_1
		
		keep if phase == 3
		keep updated_hosp_id
		gduplicates drop
		tempfile new_hospitals
		save `new_hospitals', replace

	restore

	merge m:1 updated_hosp_id using `new_hospitals', assert(1 3)

	replace temp_hosp_id = 30000 + updated_hosp_id if _merge == 3
	drop _merge
	replace temp_hosp_id = . if phase == 1

	gunique updated_hosp_id hosp_unique_id location locstr hospitals
	assert r(unique) == r(N)
	gsort updated_hosp_id hosp_unique_id location locstr hospitals
	drop phase updated_hosp_id

	// Manual edits 
	replace temp_hosp_id = 10029 if hospitals == "Asheville Mission Hospital"
	replace temp_hosp_id = 10466 if hospitals == "Brunswick County Hospital"
	replace temp_hosp_id = 10367 if hospitals == "Good Shepherd Hospital"
	replace temp_hosp_id = 10555 if hospitals == "Kate Bitting Reynolds Memorial Hospital"
	replace temp_hosp_id = 10446 if hospitals == "Lee County Hospital"
	replace temp_hosp_id = 10351 if hospitals == "Lowrance Hospital"
	replace temp_hosp_id = 10340 if hospitals == "Marion General Hospital"
	replace temp_hosp_id = 10144 if hospitals == "Mercy Hospital"
	replace temp_hosp_id = 10022 if hospitals == "Randolph Hospital"
	replace temp_hosp_id = 10014 if hospitals == "Yadkin Hospital"

	replace hosp_unique_id = temp_hosp_id if hosp_unique_id == .
	assert hosp_unique_id != .
	
	// Final steps
	keep hosp_unique_id locstr hospitals
	gduplicates drop
	gunique hosp_unique_id locstr hospitals
	assert r(unique) == r(N)
	gsort hosp_unique_id locstr hospitals
	
	rename hosp_unique_id hosp_id
	rename hospitals hospstr
	
	// Additional corrections checking hospital name changes
	
	// Yadkin also merged in 1950 but these were separate buildings
	// Source: https://www.facebook.com/170847259695381/posts/earlier-i-posted-information-about-the-hospital-in-badin-it-was-built-in-1917-an/779732202140214/
	// Source: https://www.thesnaponline.com/2018/12/27/throwbackthursday-yadkin-hospital/#:~:text=The%20Yadkin%20Hospital%2C%20located%20in,it%20was%20expanded%20to%2040).&text=In%201929%2C%20with%20the%20support,public%20hospital%20in%20Stanly%20County.
	replace hosp_id = 10013 if hosp_id == 10012
	replace hosp_id = 10013 if hosp_id == 10011

	// French Broad Hospital turns to Aston Park Hospital
	// SOURCE: https://www.citizen-times.com/story/life/2015/07/20/ashevilles-growth-began-th-century-tb-treatment/30408281/
	replace hosp_id = 10043 if hosp_id == 10033
	
	// Ambler Heights Sanatorium sold and renamed Wesnoca
	replace hosp_id = 10023 if hosp_id == 10070 

	// Biltmore Hospital merges with Asheville Mission Hospital in 1949: https://www.nps.gov/Nr/Travel/Asheville/cla.htm
	// Biltmore and Asheville Mission Hospital form Memorial Miission Hospital 
	// Clarence Barker is Biltmore: https://www.nps.gov/Nr/Travel/Asheville/cla.htm
	replace hosp_id = 10088 if hosp_id == 10089

	// Lyday hospital is the same as Transylvania community: https://missionhealth.org/member-hospitals/transylvania/history/
	replace hosp_id = 10107 if hosp_id == 10108

	// Brevard Hospital funtioned until 1928. Then it was sold and renamed Transylvania Hospital. 
	// Note also that in 1930 it closed for two years due to Great Depression but reopened thereafter 
	// Source: http://www.transylvaniaheritage.org/1912-1961_tc
	replace hosp_id = 10106 if hosp_id == 10109

	// Elizabeth City Hospital and Albemarle are the same. It was operational prior to 1925 though: 
	// Source: https://en.wikipedia.org/wiki/Sentara_Albemarle_Medical_Center
	// Source: https://nursinghistory.appstate.edu/counties/pasquotank-county
	replace hosp_id = 10180 if hosp_id == 10179

	// Gaston Sanatorium turned into Garrison General Hospital but it also changed its function: https://files.nc.gov/ncdcr/nr/GS1539.pdf
	replace hosp_id = 10212 if hosp_id == 10215

	// Goldsboro Hospital turned into Wayne County Memorial Hospital: https://www.wayneunc.org/about-us/
	replace hosp_id = 10223 if hosp_id == 10233

	// High Point Hospital and Burrus Memoorial Hospital are the same thing. 
	// Then it became High Pint Memorial Hospital: https://www.wakehealth.edu/Locations/Hospitals/High-Point-Medical-Center/About-Us
	replace hosp_id = 10285 if hosp_id == 10283
	replace hosp_id = 10285 if hosp_id == 10286

	// Lincoln Hospital and Gordon Cromwell are the same: https://en.wikipedia.org/wiki/South_Aspen_Street_Historic_District
	replace hosp_id = 10326 if hosp_id == 10325

	// Baker Sanatoriun was opened in 1921 and merged with Thompson Hospital in 1946. 
	replace hosp_id = 10332 if hosp_id == 10333

	// Brantwood and Grainville Hospital are the same: 
	// Source: https://www.ghshospital.org/patients-visitors/about-us#:~:text=In%20early%201920%2C%20a%20consensus,in%20the%20town%20of%20Oxford.
	replace hosp_id = 10386 if hosp_id == 10387

	// Candler-Nicchols and CJ Harrris are the same hospital: http://www.thesylvaherald.com/history/article_36f4327e-562e-11e9-ac40-57429ed44cb2.html
	replace hosp_id = 10483 if hosp_id == 10482

	// Willson Hospital and Tubercular Home and Mercy Hospital are the same:
	// SOURCE: https://wilsoncountylocalhistorylibrary.wordpress.com/2017/04/19/mercy-hospital-medical-care-for-african-americans-in-east-wilson/
	replace hosp_id = 10538 if hosp_id == 10535
	
	// Edgecombe County Sanatorium is the same as Edgecombe County Sanitarium
	replace hosp_id = 10490 if hosp_id == 10489

	// Biltmore Hospital - Biltmore is a village in Asheville
	replace hosp_id = 10034 if hosp_id == 10088
	
	order hosp_id locstr hospstr 
	compress
	
	desc, f
	save "$PROJ_PATH/analysis/processed/data/crosswalks/hospital_xwalk.dta", replace
	
}


*******************************
// Process raw Duke files *****
*******************************

if `duke' {

	// Clean financial data
	use "$PROJ_PATH/analysis/processed/intermediate/duke/returns_by_year.dta", clear
	desc
	
	// Set time
	drop if missing(year_end)
	tsset year_end
	tsfill, full
	
	// Interpolate missing years' values
	ipolate balance_net_of_corpus year_end, gen(balance_interpolated)
	format balance_interpolated %14.2fc
	
	// Create the amount after corpus earned
	gen double amount_to_distribute = balance_interpolated - balance_interpolated[_n-1]
	format amount_to_distribute %14.2fc
	
	// Make sure the first year has an amount
	replace amount_to_distribute = balance_interpolated if missing(amount_to_distribute)

	rename year_end year
	
	// Alter data by inflation factor
	fmerge m:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) keep(3) nogen
	rename year year_end

	// Alter appropriations by inflation factor
	replace amount_to_distribute  = amount_to_distribute*inv_inflation_factor

	// Keep only the variables we want
	keep year_end amount_to_distribute

	// Drop missing obs at the end 
	drop if missing(year_end)
	rename year_end year

	la var year "Year"
	la var amount_to_distribute "Amount to distribute"
	
	save "$PROJ_PATH/analysis/processed/data/duke/financials_1925_1962.dta", replace


	// Generate crosswalks using LABC locations 
	use "$PROJ_PATH/analysis/processed/intermediate/duke/labc_locations_1925_1962.dta", clear

	rename year Year
	rename hospitals Institution
	rename location Location
	rename county County
	rename state State 

	replace State = "NC" if State == "N.C."
	replace State = "SC" if State == "S.C."

	tab State, m
	
	// Add hospital IDs
	gen sort_order = _n
	gen locstr = Location
	gen hospstr = Institution
	
	fmerge m:1 locstr hospstr using "$PROJ_PATH/analysis/processed/data/crosswalks/hospital_xwalk.dta", keepusing(hosp_id) keep(1 3)
	replace hosp_id = . if State == "SC"
	gsort sort_order
	tab _merge State
	
	drop sort_order locstr hospstr _merge	
		
	replace Location = "Albemarle" if Location == "Albermarle"
	replace Location = "Huntersville" if Location == "Hunterville"
	replace Location = "Kinston" if Location == "Kingston"
	replace Location = "Moncks Corner" if Location == "Moneks Corner"
	replace Location = "Mount Airy" if Location == "Mt. Airy"
	replace Location = "North Wilkesboro" if Location == "N. Wilkesboro"
	replace Location = "Winston-Salem" if Location == "Winston Salem"
	replace Location = "Wrightsville" if Location == "Wrightsville Sound"

	gen flag_missing_location = (Location == "")
	tab flag_missing_location

	replace Location = "Biltmore" if Institution == "Biltmore Hospital"
	replace Location = "Charlotte" if Location == "" & Institution == "Junior League Baby Hospital"
	replace Location = "Winston-Salem" if Location == "" & Institution == "Juvenile Relief Association"
	replace Location = "Roaring Gap" if Location == "" & Institution == "Roaring Gap Hospital"
	replace Location = "Saluda" if Location == "" & Institution == "Spartanburg Baby Hospital"
	replace Location = "Greensboro" if Location == "" & Institution == "Sternberger Children's Hospital"
	replace Location = "Greenville" if Location == "" & (Institution == "Maternity Shelter Hospital" | Institution == "Shriners' Hospital for Crippled Children")
	replace County = "Pasquotank" if County == "Pasqoutank"

	assert !missing(Location)
	 
	replace County = "" if flag_missing_location == 1
	drop flag_missing_location

	replace County = "Colleton" if County == "Collecton"
	replace County = "Yadkin" if County == "Yadkinville"

	// Two entries were out of order
	gen flag_1 = (Year == 1937 & Institution == "St. Francis Hospital")
	gen flag_2 = (Year == 1937 & Institution == "St. Francis Xavier Infirmary")

	tab flag_1 flag_2

	replace Institution = "St. Francis Xavier Infirmary" if flag_1 == 1
	replace Institution = "St. Francis Hospital" if flag_2 == 1

	replace Location = "Charleston" if Location == "Greenville" & flag_1 == 1
	replace Location = "Greenville" if Location == "Charleston" & flag_2 == 1

	replace County = "Charleston" if County == "Greenville" & flag_1 == 1
	replace County = "Greenville" if County == "Charleston" & flag_2 == 1

	drop flag_1 flag_2 

	// Generate temporary location-county crosswalk
	preserve
	
		keep State County Location 
		keep if County != ""
		duplicates drop
		rename County County1
		save "$PROJ_PATH/analysis/processed/temp/locations.dta", replace
		gisid State Location
		gsort State Location
		save "$PROJ_PATH/analysis/processed/temp/locations-unique-by-state.dta", replace
		bysort Location: keep if _N == 1
		save "$PROJ_PATH/analysis/processed/temp/locations-unique.dta", replace

	restore
		
	// Fill in locations with missing county information
	gen sort_order = _n
	fmerge m:1 State Location using "$PROJ_PATH/analysis/processed/temp/locations-unique-by-state.dta", assert(3) nogen
	replace County = County1 if County == ""
	drop County1	
	
	// Merge with NHGIS county information
	rename County county_nhgis
	rename State state

	replace state = "NORTH CAROLINA" if state == "NC"
	replace state = "SOUTH CAROLINA" if state == "SC"
	
	replace county_nhgis = upper(county_nhgis)
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties_carolinas.dta", verbose assert(2 3) keep(3) nogen
	
	la var Institution "Hospital name"
	
	rename Institution institution
	rename Location location
	rename Year year
	
	// Edit institution names
	replace institution = subinstr(institution,"'","",.)
	replace institution = regexr(institution,"Albemarle","Albermarle")
	replace institution = regexr(institution,"Hospitals","Hospital")
	replace institution = regexr(institution,"Parrott Hospital","Parrot Hospital")
	replace institution = regexr(institution,"Samaritan-Waverley","Samaritan-Waverly")
	replace institution = regexr(institution,"Sanitorium","Sanatorium")
	replace institution = regexr(institution,"Shriners","Shriners'")
	replace institution = regexr(institution,"Woodward-Herring","Woodard-Herring")
	replace institution = "Harris Community Hospital, C. J." if regexm(institution,"Harris Community Hospital")
	replace institution = "Pittman Hospital, R. L." if regexm(institution,"Pittman Hospital")
	replace institution = "Richardson Memorial Hospital, L." if regexm(institution,"Richardson Memorial Hospital")
	replace institution = "Rowan Memorial Hospital" if institution == "Rowan General Hospital" & (year == 1936 | year == 1937)
	replace institution = "St. Leo's Hospital" if regexm(institution,"Leos")
	replace institution = "St. Luke's Hospital" if regexm(institution,"Luke")
	
	order state county_nhgis statefip countyicp fips gisjoin location year hosp_id
	
	// Check if hospital ID assigned to more than one location in data
	gduplicates drop
	gisid hosp_id fips location institution year, missok
	gsort hosp_id fips location institution year
	qui gunique fips location, by(hosp_id) gen(tot_loc)
	gsort + hosp_id - tot_loc + fips + location + institution + year
	by hosp_id: carryforward tot_loc, replace
	
	assert tot_loc == 1 if statefip == 37
	drop tot_loc
	
	gsort sort_order
	drop sort_order
	
	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/duke/labc_hospital_locations_cleaned.dta", replace
	
	
	// Create appropriation for Haywood County Hospital, New hospital unit, 1927
	// See 1929 Annual Report of the Hospital Section, p. 208, Chapter VI (Assistance in Construction, Equipment and Purchase of Hospitals)
	// First appropriation made 26 April 1927 
	clear 
	set obs 1 
	gen state = "NC"
	gen year = 1927 
	gen hospital = "Haywood County Hospital"
	gen location = "Waynesville"
	gen county = "Haywood"
	gen appropriation = 10000
	gen app_payments = 10000
	gen local_contrib = 108000
	gen estimated_cost = 118000
	gen purpose = "New hospital unit"

	tempfile haywood_1927
	save `haywood_1927', replace 

	replace year = 1928
	tempfile haywood_1928
	save `haywood_1928', replace

	// Create appropriation for Haywood County Hospital, Home for nurses, 1929
	// NOTE: See Table 26 (Constribution, Equipment and Purchase Appropriations) in 1929 Annual Report of the Hospital Section 
	clear 
	set obs 1 
	gen state = "NC"
	gen year = 1929
	gen hospital = "Haywood County Hospital"
	gen location = "Waynesville"
	gen county = "Haywood"
	gen appropriation = 12500
	gen app_payments = 0
	gen local_contrib = 12500
	gen estimated_cost = 25000
	gen purpose = "Home for nurses"

	tempfile haywood_1929
	save `haywood_1929', replace 

	// Create appropriation for Newberry County Hospital, Home for nurses, 1929
	// NOTE: See Table 26 (Constribution, Equipment and Purchase Appropriations) in 1929 Annual Report of the Hospital Section 
	clear 
	set obs 1 
	gen state = "SC"
	gen year = 1929
	gen hospital = "Newberry County Hospital"
	gen location = "Newberry"
	gen county = "Newberry"
	gen appropriation = 3500
	gen app_payments = 0
	gen local_contrib = 3500
	gen estimated_cost = 7000
	gen purpose = "Home for nurses"

	tempfile newberry_1929
	save `newberry_1929', replace 

	// Create appropriation for Good Samaritan Hospital, Home for nurses, 1930
	clear 
	set obs 1 
	gen state = "NC"
	gen year = 1930
	gen hospital = "Good Samaritan Hospital"
	gen location = "Charlotte"
	gen county = "Mecklenburg"
	gen appropriation = 2000
	gen app_payments = 2000
	gen local_contrib = 0
	gen estimated_cost = 2000
	gen purpose = "Home for nurses"

	tempfile good_samaritan_1930
	save `good_samaritan_1930', replace 

	replace year = 1931
	tempfile good_samaritan_1931
	save `good_samaritan_1931', replace 

	// Create appropriation for Richardson Memorial, Home for nurses, 1931
	clear 
	set obs 1 
	gen state = "NC"
	gen year = 1930
	gen hospital = "Richardson Memorial Hospital, L."
	gen location = "Greensboro"
	gen county = "Guilford"
	gen appropriation = 17000
	gen app_payments = 17000
	gen local_contrib = 17000
	gen estimated_cost = 34000
	gen purpose = "Home for nurses"

	tempfile richardson_1931
	save `richardson_1931', replace 
	 
	// Load raw 1928 to 1931 data
	clear
	forvalues y = 1928(1)1931 {
		append using "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-`y'.dta"
		
	}

	// Add year 
	gen year = regexs(1) if regexm(filename,"([0-9][0-9][0-9][0-9])")
	destring year, replace 

	// Add state 
	gen state = ""
	order state
	replace state = "NC" if regexm(hospital,"NORTH CAROLINA")
	replace state = "SC" if regexm(hospital,"SOUTH CAROLINA")
	carryforward state, replace 

	order state year 

	// Drop things we don't need
	drop imageno notes filename

	// Drop summary observations
	list hospital if regexm(hospital,"^[0-9]+")
	drop if regexm(hospital,"^[0-9]+")

	// Rename variables 
	rename appropriationamount appropriation
	rename appropriationpaid app_payments
	rename localcontribution local_contrib
	rename estimatedcostofproject estimated_cost

	format appropriation %8.0g
	format app_payments %9.2g
	format local_contrib %8.0g
	format estimated_cost %8.0g

	// Check totals
	recode local_contrib app_payments (mis = 0)
	assert estimated_cost == appropriation + local_contrib

	// Standardize purpose 
	tab purpose, m
	replace purpose = "New hospital unit" if purpose == "New plant"
	replace purpose = "Home for nurses" if purpose == "Nurses home"

	tab purpose, m

	// Standardize hospital name
	replace hospital = "Brunswick County Hospital" if hospital == "Brunswick County Municipal Hospital"
	replace hospital = "Duke University Hospital" if hospital == "Duke Hospital"
	replace hospital = "Harris Community Hospital, C. J." if hospital == "Candler-Nichols Hospital"
	replace hospital = "Richardson Memorial Hospital, L." if hospital == "Richardson Memorial Hospital"

	// Standardize location 
	replace location = "Banner Elk" if location == "Banners Elk"
	replace location = "Biltmore" if hospital == "Biltmore Hospital"

	// Fix inconsistency with Haywood County Hospital in 1929 
	replace appropriation = 10000 if hospital == "Haywood County Hospital" & year == 1929 & appropriation == 22500
	replace local_contrib = 108000 if hospital == "Haywood County Hospital" & year == 1929 & local_contrib == 120500
	replace estimated_cost = 118000 if hospital == "Haywood County Hospital" & year == 1929 & estimated_cost == 143000

	// Fix inconsistency with Newberry County Hospital in 1929 
	replace appropriation = 25000 if hospital == "Newberry County Hospital" & year == 1929 & appropriation == 28500
	replace local_contrib = 25000 if hospital == "Newberry County Hospital" & year == 1929 & local_contrib == 28500
	replace estimated_cost = 50000 if hospital == "Newberry County Hospital" & year == 1929 & estimated_cost == 57000

	// Fix typo with Duke University Hospital in 1931 
	replace appropriation = 140500 if hospital == "Duke University Hospital" & year == 1931 

	// Fix inconsistency with Good Samaritan Hospital in 1930 and 1931
	replace appropriation = 30000 if hospital == "Good Samaritan Hospital" & year >= 1930 & appropriation == 32000
	replace app_payments = 30000 if hospital == "Good Samaritan Hospital" & year >= 1930 & app_payments == 32000
	replace estimated_cost = 65000 if hospital == "Good Samaritan Hospital" & year >= 1930 & estimated_cost == 67000

	// Separate out addition component for Richardson Memorial Hospital 
	replace appropriation = 3000 if hospital == "Richardson Memorial Hospital, L." & year == 1931 & appropriation == 20000
	replace app_payments = 3000 if hospital == "Richardson Memorial Hospital, L." & year == 1931 & app_payments == 20000
	replace local_contrib = 4000 if hospital == "Richardson Memorial Hospital, L." & year == 1931 & local_contrib == 21000
	replace estimated_cost = 7000 if hospital == "Richardson Memorial Hospital, L." & year == 1931 & estimated_cost == 41000

	// Separately out equipment component for Spartanburg General Hospital 
	replace purpose = "Equipment" if hospital == "Spartanburg General Hospital" & year == 1931
	gisid hospital location year purpose
	gsort hospital location year purpose
	replace appropriation = appropriation - appropriation[_n-1] if hospital == "Spartanburg General Hospital" & year == 1931
	replace app_payments = app_payments - app_payments[_n-1] if hospital == "Spartanburg General Hospital" & year == 1931
	replace local_contrib = local_contrib - local_contrib[_n-1] if hospital == "Spartanburg General Hospital" & year == 1931
	replace estimated_cost = estimated_cost - estimated_cost[_n-1] if hospital == "Spartanburg General Hospital" & year == 1931

	// Add extra appropriations
	append using `haywood_1927'
	append using `haywood_1928'
	append using `haywood_1929'
	append using `newberry_1929'
	append using `good_samaritan_1930'
	append using `good_samaritan_1931'
	append using `richardson_1931'

	// Back out annual appropriations 
	gunique state hospital location purpose year 
	gsort state hospital location purpose year 

	// Generate appropriation ID 
	egen app_id = group(state hospital location purpose)

	// Recognize that the tables show cumulative appropriations and payments up to year t
	rename appropriation tot_app
	rename app_payments tot_payments

	gen appropriation = 0
	gen app_payments = 0
	gen unpaid_app_t_1 = 0
	gen unpaid_app_t = 0

	gsort app_id year

	by app_id: replace appropriation = tot_app if _n == 1
	by app_id: replace app_payments = tot_payments if _n == 1
	by app_id: replace unpaid_app_t = appropriation - app_payments if _n == 1

	by app_id: replace appropriation = tot_app - tot_app[_n-1] if _n > 1
	by app_id: replace app_payments = tot_payments - tot_payments[_n-1] if _n > 1

	by app_id: replace unpaid_app_t_1 = tot_app[_n-1] - tot_payments[_n-1] if _n > 1
	by app_id: replace unpaid_app_t = tot_app - tot_payments if _n > 1

	order app_id unpaid_app_t_1 appropriation app_payments unpaid_app_t local_contrib estimated_cost, last

	// Add expired 
	gen expired = 0
	replace expired = 1 if hospital == "Grace Hospital" & year == 1928
	replace expired = 1 if hospital == "Cherokee County Hospital" & year >= 1929
	replace expired = 1 if hospital == "Madison County Hospital" & year >= 1929
	replace expired = 1 if hospital == "Municipal Hospital" & year >= 1929
	replace expired = 1 if hospital == "Columbus County Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Harris Memorial Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Haywood County Hospital" & year >= 1930 & purpose == "Home for nurses"
	replace expired = 1 if hospital == "Shelby Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Yancey County Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Emma Moss Booth Memorial Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Newberry County Hospital" & year >= 1930 & purpose == "Addition"
	replace expired = 1 if hospital == "South Carolina Baptist Hospital" & year >= 1930 
	replace expired = 1 if hospital == "Mercy Hospital" & location == "Wilson" & year == 1931
	replace expired = 1 if hospital == "Spruce Pine Hospital" & year == 1931

	// Track new appropriations
	egen min_year = min(year), by(hospital location)
	gen new_project = (year == min_year)
	drop min_year 

	// Sanity checks 
	egen temp = total(tot_app*(year == 1928))
	assert floor(temp) == 430527
	drop temp 

	egen temp = total(app_payments*(year<=1928))
	assert floor(temp) == 65266 
	drop temp 

	egen temp = total(tot_app*(year == 1929)*(expired == 0)), by(state)
	assert floor(temp) == 1029527 if state == "NC"
	assert floor(temp) == 546000 if state == "SC"
	drop temp

	egen temp = total(appropriation*(year == 1929)), by(state)
	assert floor(temp) == 881500 + 20000 if state == "NC" // Total appropriations in 1929 in NC are 20000 too high
	assert floor(temp) == 436000 if state == "SC"
	drop temp 

	egen temp = total(appropriation*(year == 1930)*(purpose != "Home for nurses")), by(state)
	assert floor(temp) == 331000 if state == "NC"
	assert floor(temp) == 45000 if state == "SC"
	drop temp

	egen temp = total(appropriation*(year == 1930)*(new_project == 1)), by(state)
	assert floor(temp) == 275500 if state == "NC"
	assert floor(temp) == 25000 if state == "SC"
	drop temp

	egen temp = total(unpaid_app_t_1*(year == 1930)*(expired == 1)), by(state)
	assert floor(temp) == 340000 if state == "NC"
	assert floor(temp) == 162500 if state == "SC"
	drop temp

	egen temp = total(app_payments*(year == 1930)), by(state)
	assert floor(temp) == 435811 + 2000 if state == "NC" // Home for nurses for Good Samaritan
	assert floor(temp) == 231450 if state == "SC"
	drop temp

	egen temp = total(unpaid_app_t*(year == 1930)*(expired == 0))
	assert floor(temp) == 343041
	drop temp

	egen temp = total(appropriation*(year == 1931)*(new_project == 1)), by(state)
	assert floor(temp) == 47500 if state == "NC"
	assert floor(temp) == 125000 if state == "SC"
	drop temp

	egen temp = total(app_payments*(year == 1931)), by(state)
	assert floor(temp) == 274641 if state == "NC" 
	assert floor(temp) == 48550 if state == "SC"
	drop temp

	egen temp = total(unpaid_app_t*(year == 1931)*(expired == 0))
	assert floor(temp) == 164500 + 40000 // Adjustment to Duke Hospital between 1930 and 1931 not accounted for 
	drop temp

	drop new_project tot_app tot_payments 

	// Ensure first observation has non-missing appropriation 
	egen temp = seq(), by(app_id)
	assert appropriation > 0 if temp == 1
	drop temp 

	// Drop after first year expired
	egen min_exp = min(year) if expired == 1, by(app_id)
	drop if year > min_exp & expired == 1
	drop min_exp

	// Drop completed after completed
	drop if appropriation == 0 & app_payments == 0 & expired == 0
	replace hospital = "St. Francis Hospital" if hospital == "Emma Moss Booth Memorial Hospital"

	// Final fix to Duke University Hospital
	replace appropriation = 100500 if hospital == "Duke University Hospital" & year == 1930
	replace unpaid_app_t = 100500 if hospital == "Duke University Hospital" & year == 1930
	replace estimated_cost = 100500 if hospital == "Duke University Hospital" & year == 1930
	replace unpaid_app_t_1 = 100500 if hospital == "Duke University Hospital" & year == 1931
	replace appropriation = 0 if hospital == "Duke University Hospital" & year == 1931
	replace unpaid_app_t = 30500 if hospital == "Duke University Hospital" & year == 1931

	tempfile appropriations_1928_1931
	save `appropriations_1928_1931', replace


	// Load 1932-1938 data - current appropriations
	use "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-1932-1938_current.dta", clear
	drop if missing(year) & missing(hospital)

	rename appropriatedyeart appropriation 
	rename paymentsyeart app_payments 
	rename estimatedcost estimated_cost

	tempfile current
	save `current', replace

	// Load 1932-1938 data - outstanding appropriations
	use "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-1932-1938_outstanding.dta", clear
	drop if missing(year) & missing(hospital)

	rename unpaidappropriationsbalancede unpaid_app_t_1
	rename paymentsyeart app_payments
	rename estimatedcost estimated_cost

	append using `current'

	// Add state 
	gen state = ""
	order state
	replace state = "NC" if regexm(hospital,"North Carolina")
	replace state = "SC" if regexm(hospital,"South Carolina")
	carryforward state, replace 

	// Drop summary observations
	list hospital if regexm(hospital,"^[0-9]+")
	drop if regexm(hospital,"^[0-9]+")

	// Standardize hospital name 
	replace hospital = "Greenville General Hospital" if hospital == "Greenville City Hospital"
	replace hospital = "Long Hospital, H. F." if hospital == "Long Hospital, H.F."

	// City Memorial Hospital in Winston-Salmem - appropriation in 1936 is for Kate Bitting Reynolds Memorial Hospital
	// Source: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2608830/pdf/jnma00500-0084.pdf
	// Source: https://www.cityofws.org/DocumentCenter/View/4053/26---Kate-Bitting-Reynolds-Memorial-Hospital-PDF
	replace hospital = "Kate Bitting Reynolds Memorial Hospital" if hospital == "City Memorial Hospital" & location == "Winston-Salem"

	// Standardize purpose 
	replace purpose = "Addition" if purpose == "Addition and Equipment"
	replace purpose = "New hospital unit" if hospital == "Kate Bitting Reynolds Memorial Hospital"

	recode unpaid_app_t_1 app_payments estimated_cost expired appropriation (mis = 0)
	 
	gunique state hospital location year purpose app_payments 
	gsort state hospital location year purpose app_payments

	// There are multiple payments per year per hospital/appropriation
	gcollapse (sum) unpaid_app_t_1 appropriation app_payments (max) estimated_cost expired, by(state year hospital location purpose)

	gunique state hospital location year purpose  
	gsort state hospital location year purpose 

	// Generate appropriation ID 
	egen app_id = group(state hospital location purpose), m
	gsort app_id year

	// Create cumulative appropriations 
	by app_id: gen tot_app = unpaid_app_t_1 + appropriation if _n == 1 & year == 1932
	by app_id: gen tot_payments = app_payments if _n == 1

	by app_id: replace tot_app = appropriation if _n == 1 & year != 1932
	by app_id: replace tot_app = tot_app[_n-1] + appropriation if _n > 1
	by app_id: replace tot_payments = tot_payments[_n-1] + app_payments if _n > 1

	// Verify unpaid app t-1
	by app_id: gen verify_unpaid_t_1 = unpaid_app_t_1 if _n == 1
	by app_id: replace verify_unpaid_t_1 = tot_app[_n-1] - tot_payments[_n-1] if _n > 1

	assert round(verify_unpaid_t_1) == round(unpaid_app_t_1)
	drop verify_unpaid_t_1

	// Generate unpaid app t
	by app_id: gen unpaid_app_t = unpaid_app_t_1 + appropriation - app_payments if _n == 1
	by app_id: replace unpaid_app_t = tot_app - tot_payments if _n > 1

	drop tot_*
	order unpaid_app_t_1 appropriation app_payments unpaid_app_t estimated_cost expired, last 

	tempfile appropriations_1932_1938
	save `appropriations_1932_1938', replace



	// Load raw 1939 to 1942 data
	clear
	forvalues y = 1939(1)1962 {
		append using "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-`y'.dta"
		
	}

	// Add year 
	gen year = regexs(1) if regexm(filename,"([0-9][0-9][0-9][0-9])")
	destring year, replace 

	// Add state 
	gen state = ""
	order state
	replace state = "NC" if regexm(upper(hospital),"NORTH CAROLINA")
	replace state = "SC" if regexm(upper(hospital),"SOUTH CAROLINA")
	carryforward state, replace 

	order state year 

	// Drop things we don't need
	drop imageno filename

	// Drop summary observations
	list hospital if regexm(hospital,"^[0-9]+")
	drop if regexm(hospital,"^[0-9]+")

	// Fix payments 
	gen expired = 0
	replace expired = 1 if regexm(upper(app_payments), "EXPIRED") | regexm(upper(app_payments), "CANCELLED")

	replace app_payments = "" if app_payments == "Cancelled" | app_payments == "Expired August 1, 1943" | app_payments == "Expired Jan. 1, 1941" | app_payments == "Expired March 1, 1943" | app_payments == "Expired Nov. 1, 1942" 

	destring app_payments unpaid* appropriation estimated_cost, replace
	recode app_payments unpaid* appropriation estimated_cost (mis = 0)

	// Standardize hospital 
	replace hospital = regexr(hospital,"Hosp\.$","Hospital")
	replace hospital = regexr(hospital,"Hospitals","Hospital")

	replace hospital = "Duke University Hospital" if hospital == "Duke Hospital"
	replace hospital = "Harris Community Hospital, C. J." if hospital == "C. J. Harris Community Hospital"
	replace hospital = "St. Peter's Hospital" if hospital == "Saint Peter's Hospital"
	replace hospital = "Alamance County Hospital" if hospital == "Alamance General Hospital" | hospital == "Memorial Hospital of Alamance County"
	replace hospital = "Charlotte Rehabilitation and Spastics Hospital" if hospital == "Charlotte Rehabil. & Spastics Hosp." | hospital == "Charlotte Rehabilitation Hospital" | hospital == "Charlotte Rehabil. & Spastics Hospital"
	replace hospital = "Dosher Memorial Hospital, Dr. J. Arthur" if hospital == "Dr. J. Arthur Dosher Memorial Hospital"
	replace hospital = "Chowan Hospital" if hospital == "Edenton Hospital (Sponsoring Group)"
	replace hospital = "Edgecombe Memorial Hospital" if hospital == "Edgecombe County Hospital"
	replace hospital = "Richardson Memorial Hospital, L." if hospital == "L. Richardson Memorial Hospital"
	replace hospital = "Roanoke-Chowan Hospital" if hospital == "Roanoke-Chowan"
	replace hospital = "St. Joseph's Hospital" if hospital == "Saint Joseph's Hospital"
	replace hospital = "St. Luke's Hospital" if hospital == "Saint Luke's Hospital"
	replace hospital = "Anderson County Hospital" if hospital == "Anderson County Memorial Hospital" | hospital == "Anderson Memorial Hospital" // Source: https://anmed.org/about/history
	replace hospital = "Woodruff General Hospital" if hospital == "Spartanburg General Hospital (Woodruff Division)"
	replace hospital = "Grace Hospital" if hospital == "Grace Hartley Memorial Hospital"
	replace hospital = "Cabarrus County Hospital" if hospital == "Cabarrus Memorial Hospital" // Source: https://cabarrushealthcarefoundation.org/history/
	replace hospital = "Annie Penn Memorial Hospital" if hospital == "Memorial Hospital" & location == "Reidsville"
	replace hospital = "Marlboro County Memorial Hospital" if hospital == "Marlboro County General Hospital"
	replace hospital = "Cherokee County Hospital" if hospital == "Cherokee County Memorial Hospital"
	replace hospital = "Tri-City Hospital" if hospital == "Morehead Memorial Hospital"
	replace hospital = "Robeson County Memorial Hospital" if hospital == "Southeastern General Hospital"
	replace hospital = "Martin County Hospitals" if hospital == "Martin County Hospital"

	// Standardize location 
	replace location = "Siler City" if location == "Silver City"

	// Standardize purpose 
	tab purpose, m

	replace purpose = "New hospital unit" if purpose == "New Plant"  
	replace purpose = "Home for nurses" if purpose == "Home for Nurses" | purpose == "Nursing Home" | purpose == "Nurses' Home" | purpose == "Nurses' Residence"
	replace purpose = "Purchase" if purpose == "Purchase of Plant" | purpose == "Purchase of Property"
	replace purpose = "Addition, Home for nurses" if purpose == "Home for Nurses Addition" 
	replace purpose = "Addition, Equipment" if purpose == "Addition and Equipment" | purpose == "Addition & Equipment"
	replace purpose = "New hospital unit, Equipment" if purpose == "New Plant and Equipment"
	replace purpose = "Purchase, Equipment" if purpose == "Purchase and Equipment"

	tab purpose, m

	// // Standardize purpose over time within hospitals and appropriations 
	replace purpose = "Addition, Equipment" if hospital == "Asheville Colored Hospital" & year == 1948
	replace purpose = "New hospital unit" if hospital == "Chowan Hospital" & inrange(year,1948,1949)
	replace purpose = "New hospital unit, Home for nurses" if hospital == "High Point Memorial Hospital" & inrange(year,1945,1954)
	replace purpose = "Addition, Equipment" if hospital == "North Carolina Baptist Hospital" & year == 1955
	replace purpose = "Addition, Equipment" if hospital == "Anderson County Hospital" & inrange(year,1947,1948)

	// From 1942, purpose only listed in year when appropriation is completed 
	// Impute purpose backwards 
	gunique state hospital location year purpose  
	gsort + state + hospital + location - year - purpose 
	by state hospital location: carryforward purpose, replace 
	gsort state hospital location year purpose 

	tab purpose, m

	tempfile appropriations_1939_1962
	save `appropriations_1939_1962', replace

	// Append everything together 
	clear
	append using `appropriations_1928_1931'
	append using `appropriations_1932_1938'
	append using `appropriations_1939_1962'

	gunique state hospital location purpose year 
	gsort state hospital location purpose year 

	// Generate appropriation ID 
	drop app_id

	gen split_point = (appropriation > 0 & unpaid_app_t == 0) | expired == 1
	by state hospital location purpose : gen app_counter = 1 if _n == 1
	by state hospital location purpose : replace app_counter = app_counter[_n-1] + split_point[_n-1] if _n > 1
	drop split_point 

	egen app_id = group(state hospital location purpose app_counter), m
	order app_id 
	drop app_counter 

	// Ensure first observation has non-missing appropriation 
	gsort app_id year
	egen temp = seq(), by(app_id)
	assert appropriation > 0 if temp == 1
	drop temp 

	// Create cumulative appropriations 
	gsort app_id year 
	by app_id: gen cumul_app = appropriation if _n == 1 
	by app_id: gen cumul_pay = app_payments if _n == 1

	by app_id: replace cumul_app = cumul_app[_n-1] + appropriation if _n > 1
	by app_id: replace cumul_pay = cumul_pay[_n-1] + app_payments if _n > 1

	// Generate max cost and local contribution
	format estimated_cost %9.0f
	recode local_contrib (mis = 0)

	egen max_cost = max(estimated_cost), by(app_id)
	egen max_payment = max(cumul_pay), by(app_id)

	egen max_contrib = max(local_contrib), by(app_id)
	replace max_contrib = max(max_cost - max_payment,0) if max_contrib == 0
	replace max_cost = max_payment if max_cost == 0
	gen duke_cost_share = max_payment/max_cost 
	recode duke_cost_share (mis = 0)

	preserve

		keep app_id max_*
		gduplicates drop
		gcollapse (sum) max_*
		
		format max_* %12.2fc
		gen duke_cost_share = max_payment/max_cost 
		sum duke_cost_share
		
	restore 

	// Fill in county 
	gunique hospital location year purpose 
	gsort hospital location year purpose 

	by hospital location: carryforward county, replace

	gen Location = location
	gen State = state 
	merge m:1 State Location using "$PROJ_PATH/analysis/processed/temp/locations-unique-by-state.dta", keep(1 3) nogen

	rename County1 County 
	replace County = "Hampton" if Location == "Hampton"
	replace County = "Jasper" if Location == "Richland"
	replace County = "Dare" if Location == "Buxton"
	replace County = "Florence" if Location == "Lake City"
	replace County = "Greenville" if Location == "Simpsonville"
	replace County = "Burke" if Location == "Valdese"
	replace County = "New Hanover" if Location == "Wrightsville Beach"
	replace County = "York" if Location == "York"
	replace County = "Laurens" if hospital == "Bailey Memorial Hospital" & Location == "Clinton"

	replace county = County if missing(county)
	assert !missing(county)
	drop Location State County

	// Track new appropriations
	egen min_year = min(year), by(hospital location)
	gen new_project = (year == min_year)
	drop min_year 

	// Track completed projects 
	egen max_year = max(year), by(hospital location purpose)
	gen completed_project = (year == max_year & unpaid_app_t == 0)
	drop max_year 

	// Add hospital IDs
	gen locstr = location
	gen hospstr = hospital

	fmerge m:1 locstr hospstr using "$PROJ_PATH/analysis/processed/data/crosswalks/hospital_xwalk.dta", keepusing(hosp_id) keep(1 3)
	replace hosp_id = . if state == "SC"

	tab _merge state
	assert _merge == 3 if state == "NC"

	drop locstr hospstr _merge 
	
	// Edit hospital names
	replace hospital = subinstr(hospital,"'","",.)
	replace hospital = regexr(hospital,"Albemarle","Albermarle")
	replace hospital = regexr(hospital,"Hospitals","Hospital")
	replace hospital = regexr(hospital,"Parrott Hospital","Parrot Hospital")
	replace hospital = regexr(hospital,"Samaritan-Waverley","Samaritan-Waverly")
	replace hospital = regexr(hospital,"Sanitorium","Sanatorium")
	replace hospital = regexr(hospital,"Shriners","Shriners'")
	replace hospital = regexr(hospital,"Woodward-Herring","Woodard-Herring")
	replace hospital = "Harris Community Hospital, C. J." if regexm(hospital,"Harris Community Hospital")
	replace hospital = "Pittman Hospital, R. L." if regexm(hospital,"Pittman Hospital")
	replace hospital = "Richardson Memorial Hospital, L." if regexm(hospital,"Richardson Memorial Hospital")
	replace hospital = "Rowan Memorial Hospital" if hospital == "Rowan General Hospital" & (year == 1936 | year == 1937)
	replace hospital = "St. Leo's Hospital" if regexm(hospital,"Leos")
	replace hospital = "St. Luke's Hospital" if regexm(hospital,"Luke")
	replace hospital = "St. Agnes Hospital" if regexm(hospital,"Agnes")
	replace hospital = "Duke University Hospital" if hospital == "Duke Hospital"
	replace hospital = "Rowan Memorial Hospital" if hospital == "Rowan General Hospital" & (year >= 1933 & year <= 1935)
	replace hospital = "Dosher Memorial Hospital, Dr. J. Arthur" if hospital == "Dosher Memorial Hospital"
	replace hospital = "Long Hospital, H. F." if hospital == "Long Hospital"
	replace hospital = "Edgecombe County Hospital" if hospital == "Edgecombe General Hospital" & year == 1934
	replace hospital = "Brunswick County Municipal Hospital" if hospital == "Brunswick County Hospital"	

	// Check if hospital ID assigned to more than one location in data
	gunique hosp_id state county location hospital year appropriation app_payments 
	assert r(unique) == r(N)
	gsort hosp_id state county location hospital year appropriation app_payments
	qui gunique state county location , by(hosp_id) gen(tot_loc)
	gsort + hosp_id - tot_loc + state + county + location + hospital + year
	by hosp_id: carryforward tot_loc, replace

	assert tot_loc == 1 if state == "NC"
	drop tot_loc

	// Add county variables 
	replace state = "NORTH CAROLINA" if state == "NC"
	replace state = "SOUTH CAROLINA" if state == "SC"
	gen county_nhgis = upper(county)
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose assert(2 3) keep(3) nogen keepusing(statefip countyicp fips)
	drop county 
	
	// Flag appropriations with unknown purpose 
	gen not_stated = 0
	replace not_stated = 1 if purpose == ""

	// Create separate appropriation variables by category 
	gen capp_all = appropriation
	gen capp_ex_nurse  = appropriation*(regexm(upper(purpose),"NURS") == 0)	
	gen capp_new_hosp  = appropriation*(regexm(upper(purpose),"NEW"))
	gen capp_addition  = appropriation*(regexm(upper(purpose),"ADDITION")) 
	gen capp_equipment = appropriation*(regexm(upper(purpose),"EQUIPMENT"))
	gen capp_purchase  = appropriation*(regexm(upper(purpose),"PURCHASE"))
	gen capp_not_stated  = appropriation*not_stated

	// Create separate payment variables by category 
	gen pay_all = app_payments
	gen pay_ex_nurse  = app_payments*(regexm(upper(purpose),"NURS") == 0)	
	gen pay_new_hosp  = app_payments*(regexm(upper(purpose),"NEW"))
	gen pay_addition  = app_payments*(regexm(upper(purpose),"ADDITION")) 
	gen pay_equipment = app_payments*(regexm(upper(purpose),"EQUIPMENT"))
	gen pay_purchase  = app_payments*(regexm(upper(purpose),"PURCHASE"))
	gen pay_not_stated  = app_payments*not_stated
	
	la var pay_all "Capital appropriation - paid out"
	la var pay_ex_nurse "Capital appropriation - paid out"
	la var capp_all "First capital appropriation - any purpose"
	la var capp_ex_nurse "First capital appropriation - any purpose"
	la var capp_new_hosp "First capital appropriation - new hospital"
	la var capp_addition "First capital appropriation - addition to hospital"
	la var capp_equipment "First capital appropriation - equipment"
	la var capp_purchase "First capital appropriation - purchases"
	
	la var hosp_id "Unique hospital ID"
	assert hosp_id != . if statefip == 37

	gunique hosp_id year purpose 
	assert r(unique) == r(N)
	gsort hosp_id year purpose

	order state county_nhgis statefip countyicp fips location year hosp_id

	desc, f
	save "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta", replace
		
}

**********************************************************
// Extract community health department (CHD) data ********
**********************************************************

if `chd' {

	clear
	local start_year = 1910
	local end_year = 1962

	local n = `end_year' - `start_year' + 1
	set obs `n'

	gen year = _n + `start_year' - 1
	
	tempfile years
	save `years'
	
	use "$PROJ_PATH/analysis/processed/intermediate/chd/chd_operation_dates.dta", clear
	
	drop if county == ""
	
	replace startdate = "1/07/1919" if county == "Cumberland"
	replace county = "Greenwood" if county == "Greenwodd"
	
	gen start_year_1 = regexs(1) if regexm(startdate,"([0-9][0-9][0-9][0-9])$")
	gen end_year_1 = regexs(1) if regexm(endyear,"([0-9][0-9][0-9][0-9])$")
	
	gen start_year_2 = regexs(1) if regexm(reorganized,"([0-9][0-9][0-9][0-9])$")
	
	destring start_year_1 end_year_1 start_year_2, replace
	gen end_year_2 = year(ended)
	
	// Clean state variable 
	replace state = "Delaware" if state == "Delware"
	replace state = "Florida" if state == "Floria"
	replace state = "Louisiana" if state == "Luisiana"
	
	// Create variable with state FIPS code 
	gen statefip = ""
	replace statefip = "01" if state == "Alabama"
	replace statefip = "02" if state == "Alaska"
	replace statefip = "04" if state == "Arizona"
	replace statefip = "05" if state == "Arkansas"
	replace statefip = "06" if state == "California"
	replace statefip = "08" if state == "Colorado"
	replace statefip = "09" if state == "Connecticut"
	replace statefip = "10" if state == "Delaware"
	replace statefip = "11" if state == "District of Columbia"
	replace statefip = "12" if state == "Florida"
	replace statefip = "13" if state == "Georgia"
	replace statefip = "15" if state == "Hawaii"
	replace statefip = "16" if state == "Idaho"
	replace statefip = "17" if state == "Illinois"
	replace statefip = "18" if state == "Indiana"
	replace statefip = "19" if state == "Iowa"
	replace statefip = "20" if state == "Kansas"
	replace statefip = "21" if state == "Kentucky"
	replace statefip = "22" if state == "Louisiana"
	replace statefip = "23" if state == "Maine"
	replace statefip = "24" if state == "Maryland"
	replace statefip = "25" if state == "Massachusetts"
	replace statefip = "26" if state == "Michigan"
	replace statefip = "27" if state == "Minnesota"
	replace statefip = "28" if state == "Mississippi"
	replace statefip = "29" if state == "Missouri"
	replace statefip = "30" if state == "Montana"
	replace statefip = "31" if state == "Nebraska"
	replace statefip = "32" if state == "Nevada"
	replace statefip = "33" if state == "New Hampshire"
	replace statefip = "34" if state == "New Jersey"
	replace statefip = "35" if state == "New Mexico"
	replace statefip = "36" if state == "New York"
	replace statefip = "37" if state == "North Carolina"
	replace statefip = "38" if state == "North Dakota"
	replace statefip = "39" if state == "Ohio"
	replace statefip = "40" if state == "Oklahoma"
	replace statefip = "41" if state == "Oregon"
	replace statefip = "42" if state == "Pennsylvania"
	replace statefip = "44" if state == "Rhode Island"
	replace statefip = "45" if state == "South Carolina"
	replace statefip = "46" if state == "South Dakota"
	replace statefip = "47" if state == "Tennessee"
	replace statefip = "48" if state == "Texas"
	replace statefip = "49" if state == "Utah"
	replace statefip = "50" if state == "Vermont"
	replace statefip = "51" if state == "Virginia"
	replace statefip = "53" if state == "Washington"
	replace statefip = "54" if state == "West Virginia"
	replace statefip = "55" if state == "Wisconsin"
	replace statefip = "56" if state == "Wyoming"
	replace statefip = "72" if state == "Puerto Rico"
	replace statefip = "99" if state == "State not identified" | state == "Total"
	
	assert !missing(statefip)
	destring statefip, replace
	
	// Restrict to southern states 
	keep if `southern_states' 
	drop statefip 
	
	gen county_nhgis = upper(county)
	replace state = upper(state)
	
	// Clean county names 
	replace county_nhgis = "CONECUH" if county_nhgis == "CONECUCH" & state == "ALABAMA"
	replace county_nhgis = "COVINGTON" if county_nhgis == "CONVINGTON" & state == "ALABAMA"
	replace county_nhgis = "ETOWAH" if county_nhgis == "ETWOAH" & state == "ALABAMA"
	replace county_nhgis = "CRENSHAW" if county_nhgis == "ORENSHAW" & state == "ALABAMA"
	replace county_nhgis = "TALLADEGA" if county_nhgis == "TALLEDEGA" & state == "ALABAMA"
	replace county_nhgis = "GARLAND" if county_nhgis == "GARTLAND" & state == "ARKANSAS"
	replace county_nhgis = "LITTLE RIVER" if county_nhgis == "LITTLE RIVER COUNTY" & state == "ARKANSAS"
	replace county_nhgis = "JEFFERSON" if county_nhgis == "JEFERSON" & state == "GEORGIA"
	replace county_nhgis = "GRAYSON" if county_nhgis == "GRAYDON" & state == "KENTUCKY"
	replace county_nhgis = "HANCOCK" if county_nhgis == "HANOCK" & state == "KENTUCKY"
	replace county_nhgis = "ST LANDRY" if county_nhgis == "ST. LANDRY" & state == "LOUISIANA"
	replace county_nhgis = "ST MARTIN" if county_nhgis == "ST. MARTIN" & state == "LOUISIANA"
	replace county_nhgis = "ST MARY" if county_nhgis == "ST. MARY" & state == "LOUISIANA"
	replace county_nhgis = "GARRETT" if county_nhgis == "GARETT" & state == "MARYLAND"
	replace county_nhgis = "ST MARYS" if county_nhgis == "ST. MARYS" & state == "MARYLAND"
	replace county_nhgis = "WORCESTER" if county_nhgis == "WORCHESTER" & state == "MARYLAND"
	replace county_nhgis = "GRENADA" if county_nhgis == "GREENADA" & state == "MISSISSIPPI"
	replace county_nhgis = "POTTOWATOMIE" if county_nhgis == "POTTAWATOMIE" & state == "OKLAHOMA"
	replace county_nhgis = "FENTRESS" if county_nhgis == "FENTREES" & state == "TENNESSEE"
	replace county_nhgis = "FALLS" if county_nhgis == "FALLAS" & state == "TEXAS"
	replace county_nhgis = "ACCOMACK" if county_nhgis == "ACCOMAO" & state == "VIRGINIA"
	replace county_nhgis = "ISLE OF WIGHT" if county_nhgis == "ISLE OF WEIGHT" & state == "VIRGINIA"
	replace county_nhgis = "NOTTOWAY" if county_nhgis == "NOTTAWAY" & state == "VIRGINIA"
	replace county_nhgis = "RUSSELL" if county_nhgis == "RUSSEL" & state == "VIRGINIA"
	replace county_nhgis = "TAZEWELL" if county_nhgis == "TAZWELL" & state == "VIRGINIA"
	replace county_nhgis = "FAYETTE" if county_nhgis == "PAYETTE" & state == "WEST VIRGINIA"
	
	fmerge 1:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose keepusing(statefip countyicp fips) assert(2 3) nogen
	
	drop county
	
	drop if state == "OKLAHOMA TERRITORY" & startdate == ""
	drop if state == "VIRGINIA" & county_nhgis == "ALEXANDRIA" & startdate == ""
	
	gisid fips
	gsort fips
	
	order fips state statefip county_nhgis countyicp fips 

	save "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_by_county.dta", replace
	
	cross using `years'
	
	gisid fips year 
	gsort fips year 
	order state statefip county_nhgis countyicp fips 
		
	gen chd_presence = .
	
	replace chd_presence = 0 if missing(start_year_1)
	
	replace chd_presence = 1 if year >= start_year_1 & year <= end_year_1 & !missing(end_year_1)
	replace chd_presence = 1 if year >= start_year_1 & missing(end_year_1)
	
	replace chd_presence = 1 if year >= start_year_2 & year <= end_year_2 & !missing(start_year_2) & !missing(end_year_2)
	replace chd_presence = 1 if year >= start_year_2 & !missing(start_year_2) & missing(end_year_2)
	
	recode chd_presence (mis = 0)
	
	drop start* end* reorganized
	sort fips year
	keep statefip fips year chd_presence
	drop if missing(year)
	drop if missing(fips)
	compress
	save "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", replace
	
}

************************************
// Process NC vital stats data *****
************************************

if `vital_stats' {

	// Births by race 
	forvalues year = 1922/1948 {
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/births_by_race_`year'.dta", clear
		
		// Add year
		gen year = `year'
			
		// Drop first row and destring if after 1922
		if `year' >= 1923 & `year' <= 1932  {
			drop in 1
			
			qui ds
			foreach x in `r(varlist)' {
				destring `x', replace
			}
		}

		if `year' >= 1933 {
			drop in 1/2
			
			qui ds
			foreach x in `r(varlist)' {
				capture replace `x' = "" if `x' == "--"
				capture replace `x' = "18" if `x' == "IS" & year == 1935
				destring `x', replace
			}
		}

		if `year' == 1922 {

			// Assign variable by column position since name changes across time
			qui ds 
			capture gen WhiteDoctors = `:word 2 of `r(varlist)''
			replace WhiteDoctors = 0 if missing(WhiteDoctors)
		
			capture gen WhiteMidwives = `:word 3 of `r(varlist)''
			replace WhiteMidwives = 0 if missing(WhiteMidwives)

			capture gen BlackDoctors = `:word 4 of `r(varlist)''
			replace BlackDoctors = 0 if missing(BlackDoctors)
			
			capture gen BlackMidwives = `:word 5 of `r(varlist)''
			replace BlackMidwives = 0 if missing(BlackMidwives)

			
			// Create total births by race
			egen total_births_white = rowtotal(WhiteDoctors WhiteMidwives)
			replace total_births_white = 0 if missing(total_births_white)

			egen total_births_black = rowtotal(BlackDoctors BlackMidwives)
			replace total_births_black = 0 if missing(total_births_black)

			egen total_births = rowtotal(total_births_black total_births_white)


			// Create share attended by physician
			gen share_phys_att_white = WhiteDoctors/total_births_white
			replace share_phys_att_white = 0 if missing(share_phys_att_white)

			gen share_phys_att_black = BlackDoctors/total_births_black
			replace share_phys_att_black = 0 if missing(share_phys_att_black)

			gen share_phys_att = (WhiteDoctors + BlackDoctors)/total_births

		}

		if `year' >= 1923 & `year' <= 1930 {

			// Assign variable by column position since name changes across time
			qui ds 
			capture gen WhiteDoctors = `:word 2 of `r(varlist)''
			replace WhiteDoctors = 0 if missing(WhiteDoctors)
			
			capture gen BlackDoctors = `:word 3 of `r(varlist)''
			replace BlackDoctors = 0 if missing(BlackDoctors)

			capture gen WhiteMidwives = `:word 4 of `r(varlist)''
			replace WhiteMidwives = 0 if missing(WhiteMidwives)

			capture gen BlackMidwives = `:word 5 of `r(varlist)''
			replace BlackMidwives = 0 if missing(BlackMidwives)

			
			// Create total births by race
			egen total_births_white = rowtotal(WhiteDoctors WhiteMidwives)
			replace total_births_white = 0 if missing(total_births_white)

			egen total_births_black = rowtotal(BlackDoctors BlackMidwives)
			replace total_births_black = 0 if missing(total_births_black)

			egen total_births = rowtotal(total_births_black total_births_white)


			// Create share attended by physician
			gen share_phys_att_white = WhiteDoctors/total_births_white
			replace share_phys_att_white = 0 if missing(share_phys_att_white)

			gen share_phys_att_black = BlackDoctors/total_births_black
			replace share_phys_att_black = 0 if missing(share_phys_att_black)

			gen share_phys_att = (WhiteDoctors + BlackDoctors)/total_births

		}

		if `year' >= 1931 & `year' <= 1932 {
			// Assign variable by column position since name changes across time
			qui ds 
			gen share_phys_att_white = `:word 8 of `r(varlist)''/100
			replace share_phys_att_white = 0 if missing(share_phys_att_white)
			
			gen share_phys_att_black = `:word 9 of `r(varlist)''/100
			replace share_phys_att_black = 0 if missing(share_phys_att_black)

			
			gen total_births_white = `:word 4 of `r(varlist)''
			replace total_births_white = 0 if missing(total_births_white)

			gen total_births_black = `:word 6 of `r(varlist)''
			replace total_births_black = 0 if missing(total_births_black)
			
			gen total_births = `:word 2 of `r(varlist)''
			
			gen share_phys_att = (total_births_white*share_phys_att_white + total_births_black*share_phys_att_black)/(total_births_white + total_births_black)

		}

		if `year' >= 1933 & `year' <= 1944 {
			// Assign variable by column position since name changes across time
			qui ds 
			
			gen share_phys_att_white = `:word 14 of `r(varlist)''/100
			replace share_phys_att_white = 0 if missing(share_phys_att_white)
			//Fix error
			if year == 1934 {
				replace share_phys_att_white = .91 if COUNTY == "Surry"
				replace share_phys_att_white = .66 if COUNTY == "Swain"
				replace share_phys_att_white = .80 if COUNTY == "Transylvania"
				replace share_phys_att_white = .79 if COUNTY == "Tyrrell"
				replace share_phys_att_white = .87 if COUNTY == "Union"
				replace share_phys_att_white = .93 if COUNTY == "Vance"
				replace share_phys_att_white = .96 if COUNTY == "Wake"
				replace share_phys_att_white = .72 if COUNTY == "Warren"
				replace share_phys_att_white = .82 if COUNTY == "Washington"
				replace share_phys_att_white = .74 if COUNTY == "Watauga"
				replace share_phys_att_white = .95 if COUNTY == "Wayne"
				replace share_phys_att_white = .58 if COUNTY == "Wilkes"
				replace share_phys_att_white = .95 if COUNTY == "Wilson"
				replace share_phys_att_white = .86 if COUNTY == "Yadkin"
				replace share_phys_att_white = .62 if COUNTY == "Yadkin"
			}
			
			// Fix error
			if year == 1935 {
				replace share_phys_att_white = .83 if COUNTY == "Scotland"
			}
			
			gen share_phys_att_black = `:word 15 of `r(varlist)''/100
			replace share_phys_att_black = 0 if missing(share_phys_att_black)
			
			// Fix error
			if year == 1935 {
				replace share_phys_att_black = .78 if COUNTY == "Alamance"
			}
			
			if year == 1944 {
				replace share_phys_att_black = 1 if COUNTY == "Alamance"
			}
			
			gen total_births_white = `:word 6 of `r(varlist)''
			replace total_births_white = 0 if missing(total_births_white)

			gen total_births_black = `:word 10 of `r(varlist)''
			replace total_births_black = 0 if missing(total_births_black)
			
			gen total_births = `:word 2 of `r(varlist)''
			
			gen share_phys_att = (total_births_white*share_phys_att_white + total_births_black*share_phys_att_black)/(total_births_white + total_births_black)

		}

		if `year' == 1945  {
			
			// Assign variable by column position since name changes across time
			qui ds 
			gen share_phys_att_white = `:word 8 of `r(varlist)''/100
			// Fix error 
			replace share_phys_att_white = 1 if COUNTY == "Pamlico"
			replace share_phys_att_white = 0 if missing(share_phys_att_white)
			
			gen share_phys_att_black = `:word 9 of `r(varlist)''/100
			// Fix error
			replace share_phys_att_black = 1 if COUNTY == "Jackson"
			replace share_phys_att_black = 1 if COUNTY == "Madison"
			replace share_phys_att_black = 0 if missing(share_phys_att_black)

			
			gen total_births_white = `:word 4 of `r(varlist)''
			replace total_births_white = 0 if missing(total_births_white)

			gen total_births_black = `:word 6 of `r(varlist)''
			replace total_births_black = 0 if missing(total_births_black)
			
			gen total_births = `:word 2 of `r(varlist)''
			
			gen share_phys_att = (total_births_white*share_phys_att_white + total_births_black*share_phys_att_black)/(total_births_white + total_births_black)

		}

		if `year' >= 1946  {
			// Assign variable by column position since name changes across time
			qui ds 
			gen share_phys_att_white = `:word 11 of `r(varlist)''/100
			replace share_phys_att_white = 0 if missing(share_phys_att_white)
			
			gen share_phys_att_black = `:word 12 of `r(varlist)''/100
			
			// Fix error 
			if year == 1946 {
				replace share_phys_att_black = 1 if County == "Alleghany"
			}
			replace share_phys_att_black = 0 if missing(share_phys_att_black)

			
			gen total_births_white = `:word 7 of `r(varlist)''
			replace total_births_white = 0 if missing(total_births_white)

			gen total_births_black = `:word 9 of `r(varlist)''
			replace total_births_black = 0 if missing(total_births_black)
			
			gen total_births = `:word 5 of `r(varlist)''
			
			gen share_phys_att = (total_births_white*share_phys_att_white + total_births_black*share_phys_att_black)/(total_births_white + total_births_black)

		}
		// Add county name 
		qui ds
		rename `:word 1 of `r(varlist)'' countyname


		// Drop total or those missing county (often happens at then end of the spreadsheet) 
		drop if countyname == "Total"
		drop if countyname == "Grand Total"
		drop if countyname == "Entire State"
		drop if countyname == "North Carolina"
		drop if countyname == "NORTH CAROLINA"
		drop if missing(countyname)
		
		// Keep only variables we need
		keep countyname year total* share*

		// Save as temp year
		compress
		save "$PROJ_PATH/analysis/processed/temp/share_phys_att_`year'.dta", replace
	}
	
	// Append data
	clear all
	forvalues year = 1922/1948 {
		append using "$PROJ_PATH/analysis/processed/temp/share_phys_att_`year'.dta"
	}

	// Add location information 
	gen state = "NORTH CAROLINA"
	gen county_nhgis = upper(countyname)
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose keepusing(statefip countyicp fips) assert(2 3) keep(3) nogen
		
	// Add labels
	la var fips "(statefip*10000 + countyicp*10) codes by county and state"
	la var year "Year"
	la var total_births_white "Total births, white"
	la var total_births_black "Total births, black"
	la var total_births "Total births"
	la var share_phys_att_white "Physician-attended births, white"
	la var share_phys_att_black "Physician-attended births, black"
	la var share_phys_att "Physician-attended births"
	
	// Save data
	gisid fips year
	gsort fips year
	order fips year
	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/nc_vital_stats/share_phys_att_1922_1948.dta", replace
	
	// Process NC births by race 
	keep fips statefip countyicp year total_births_black total_births_white share_phys_att*

	rename total_births_white births_pub1
	rename total_births_black births_pub2

	gen id = _n
	greshape long births_pub, i(id) j(race)
	drop id

	rename year byr 
	gisid statefip countyicp race byr
	gsort statefip countyicp race byr
	order statefip countyicp fips byr race births_pub
	desc, f

	save "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_by_race_1922_1948.dta", replace
	
	// Collapse by race to get overall estimated birth cohort size
	gcollapse (sum) births_pub, by(statefip countyicp fips byr)

	rename byr year
	tab year, m
	
	desc, f
	tempfile births_est
	save `births_est', replace

	// Reshape estimated birth cohort size by race
	forvalues r = 1(1)2 {

		use "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_by_race_1922_1948.dta" if race == `r', clear
		
		keep statefip countyicp fips byr births_pub 
		
		rename byr year
			
		if `r' == 1 rename births_pub births_pub_wt
		if `r' == 2 rename births_pub births_pub_bk
		
		tempfile births_est_`r'
		save `births_est_`r'', replace
	}

	use `births_est', clear
	fmerge 1:1 statefip countyicp fips year using `births_est_1', assert(3) nogen
	fmerge 1:1 statefip countyicp fips year using `births_est_2', assert(3) nogen

	la var fips "(statefip*10000 + countyicp*10) codes by county and state"
	la var year "Year of birth"

	la var births_pub "Published births"
	la var births_pub_wt "Published births, white"
	la var births_pub_bk "Published births, black"

	compress
	desc, f
	save "$PROJ_PATH/analysis/processed/data/nc_vital_stats/births_pub_cohorts_by_year.dta", replace
	

	forvalues year = 1922/1948 {
		rm "$PROJ_PATH/analysis/processed/temp/share_phys_att_`year'.dta"
	}
	
	
		
	// Pre-period pneumonia mortality data 1920-1926 for shift-share instrument design
	forvalues y = 1922(1)1926 {
		
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/pneumonia_mortality_`y'.dta", clear
		
		drop if fips == "N/A" // Rows with totals
		destring fips, replace

		* Fix cancer variable names
	
		rename j cancer_1
		rename k cancer_2
		rename l cancer_3
		rename m cancer_4
		rename n cancer_5
		rename o cancer_6
		
		capture rename bronchopneumoniaincludingcapi bronchopneumonia
		capture rename meningitisdoesnotincludemen meningitis
		
		gen year = `y'
		desc, f
		
		tempfile pneumonia_mort_`y'
		save `pneumonia_mort_`y'', replace

	}
		
	// Combine all years
	clear
	forvalues y = 1922(1)1926 {
		append using `pneumonia_mort_`y''
	}
	
	capture drop if fips == .
	desc, f
	
	// Clean county names
	replace county = regexr(county, " [B|W]$","")
	compress county
	
	egen tcases = rowtotal(pneumonia bronchitis bronchopneumonia)
	keep county race tcases year
	
	// Add location information 
	gen state = "NORTH CAROLINA"
	gen county_nhgis = upper(county)
	
	replace county_nhgis = "RUTHERFORD" if county_nhgis == "RUTNERFORD"
	replace county_nhgis = "CHEROKEE" if county_nhgis == "CHEROOKEE"
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose keepusing(statefip countyicp fips) assert(2 3) keep(3) nogen
	drop county 	
			
	// Create pooled version
	preserve
		gcollapse (sum) tcases, by(fips year)
		tempfile cases_pooled
		save `cases_pooled', replace
	restore 
	
	// Create versions by race and reshape 
	gcollapse (sum) tcases, by(fips year race)
	egen id = group(fips year)
	greshape wide tcases, i(id) j(race)
	drop id 
	order fips year 
	rename tcases1 tcases_wt
	rename tcases2 tcases_bk

	fmerge 1:1 fips year using `cases_pooled', assert(3) nogen
	
	fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total pop_black pop_other_race)
	gen pop_white = pop_total - pop_black - pop_other_race 
	assert pop_white > 0 
		
	drop pop_other_race 
	
	gen case_rate = tcases*100000/pop_total
	gen case_rate_bk = tcases_bk*100000/pop_black 
	gen case_rate_wt = tcases_wt*100000/pop_white 
	
	// Add discrete shift-share variables by race 
	gcollapse (mean) base_pneumonia_22to26 = case_rate base_pneumonia_22to26_bk = case_rate_bk base_pneumonia_22to26_wt = case_rate_wt, by(fips)
	
	la var base_pneumonia_22to26 "Average pooled pneumonia mortality rate, 1922 to 1926"
	la var base_pneumonia_22to26_bk "Average Black pneumonia mortality rate, 1922 to 1926"
	la var base_pneumonia_22to26_wt "Average White pneumonia mortality rate, 1922 to 1926"
	
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", replace
	
	
	// Prepare maternal and infant mortality data
	
	// Import infant mortality rate from 1918 to 1922
	use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_1918_1922.dta", clear 

	// Make county name
	qui ds
	rename `:word 1 of `r(varlist)'' countyname
	rename `:word 2 of `r(varlist)'' imr_1918
	rename `:word 3 of `r(varlist)'' imr_1919
	rename `:word 4 of `r(varlist)'' imr_1920
	rename `:word 5 of `r(varlist)'' imr_1921
	rename `:word 6 of `r(varlist)'' imr_1922

	drop if countyname == "Total" 

	// Fix errors 
	replace imr_1918 = "105" if countyname == "Cabarrus"
	replace imr_1919 = "120" if countyname == "Craven"
	replace imr_1919 = "56" if countyname == "Jones"

	// Destring 
	qui ds
	foreach x in `r(varlist)' {
		destring `x', replace
	}
	drop if missing(countyname)

	// Keep only what we need
	keep countyname imr*

	// Reshape
	reshape long imr_@, i(countyname) j(year)
	rename *_ *

	// Save 
	compress
	save "$PROJ_PATH/analysis/processed/temp/imr_1918_1922.dta", replace

	forvalues year = 1923/1924 {
		
		// Import data
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_`year'.dta", clear
		
		// Add year
		gen year = `year'
		
		// Make county name
		qui ds
		rename `:word 1 of `r(varlist)'' countyname
		rename `:word 2 of `r(varlist)'' infant_deaths
		rename `:word 3 of `r(varlist)'' imr
		rename `:word 4 of `r(varlist)'' maternal_deaths
		rename `:word 5 of `r(varlist)'' mmr
		
		drop if countyname == "Total"
		drop if missing(countyname)
		replace mmr = "" if mmr == "__________"
		
		// Keep only the three we need
		keep countyname imr mmr year *_deaths
		
		// Destring 
		qui ds
		foreach x in `r(varlist)' {
			destring `x', replace
			capture replace `x' = 0 if missing(`x')
		}
		
		// Keep only what we need 
		keep countyname year mmr imr *_deaths
		
		// Save 
		compress
		save "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta", replace
	}

	local year 1925
	
		// Import data
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_`year'.dta", clear
			
		// Add year
		gen year = `year'
		
		// Make county name
		qui ds
		rename `:word 1 of `r(varlist)'' countyname
		rename `:word 4 of `r(varlist)'' infant_deaths
		rename `:word 5 of `r(varlist)'' imr
		rename `:word 2 of `r(varlist)'' maternal_deaths
		rename `:word 3 of `r(varlist)'' mmr
		
		drop if countyname == "Total"
		drop if countyname == "Total  "
		drop if missing(countyname)
		
		// Keep only the three we need
		keep countyname imr mmr year *_deaths
		
		// Destring 
		qui ds
		foreach x in `r(varlist)' {
			destring `x', replace
			capture replace `x' = 0 if missing(`x')
		}

		// Keep only what we need 
		keep countyname year mmr imr *_deaths
		
		// Save 
		compress
		save "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta", replace

	forvalues year = 1926/1931 {
		
		// Import data
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_`year'.dta", clear
			
		// Add year
		gen year = `year'
		
		// Make county name
		qui ds
		rename `:word 1 of `r(varlist)'' countyname
		rename `:word 2 of `r(varlist)'' infant_deaths
		rename `:word 3 of `r(varlist)'' imr
		rename `:word 4 of `r(varlist)'' maternal_deaths
		rename `:word 5 of `r(varlist)'' mmr
		
		drop if countyname == "Total"
		drop if countyname == "Total  "
		drop if countyname == "Total for entire State"
		drop if missing(countyname)
		replace mmr = "" if mmr == "__________"
		
		// Keep only the three we need
		keep countyname imr* mmr* year *_deaths
		
		// Destring 
		qui ds
		foreach x in `r(varlist)' {
			destring `x', replace
			capture replace `x' = 0 if missing(`x')
		}
		
		// Keep only what we need 
		keep countyname year mmr imr *_deaths
		
		// Save 
		compress
		save "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta", replace
	}

	forvalues year = 1932/1942 {
		
		// Import data
		use "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_`year'.dta", clear
			
		// Add year
		gen year = `year'
		
		// Make county name
		qui ds
		rename `:word 1 of `r(varlist)'' countyname
		rename `:word 2 of `r(varlist)'' infant_deaths
		rename `:word 3 of `r(varlist)'' imr
		rename `:word 6 of `r(varlist)'' maternal_deaths
		rename `:word 7 of `r(varlist)'' mmr
		
		rename `:word 4 of `r(varlist)'' infant_deaths_res
		rename `:word 5 of `r(varlist)'' imr_res
		rename `:word 8 of `r(varlist)'' maternal_deaths_res
		rename `:word 9 of `r(varlist)'' mmr_res
		
		drop if countyname == "Total"
		drop if countyname == "Total  "
		drop if countyname == "Total for entire State"
		drop if countyname == "Entire State"
		drop if missing(countyname)
		replace mmr = "" if mmr == "__________"
		
		// Keep only the three we need
		keep countyname imr* mmr* year *deaths*
		
		// Destring 
		qui ds
		foreach x in `r(varlist)' {
			destring `x', replace
			capture replace `x' = 0 if missing(`x')
		}

		// Keep only what we need 
		keep countyname year mmr* imr* *deaths*
		
		// Save 
		compress
		save "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta", replace
	}



	// Append data
	clear all
	use "$PROJ_PATH/analysis/processed/temp/imr_1918_1922.dta"
	forvalues year = 1923/1942 {
		append using "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta"
	}

	// Rename imr and mmr so it's clear these are nc-archive
	rename imr* nc_arc_imr*
	rename mmr* nc_arc_mmr*

	// Clean counties 
	drop if countyname == "NORTH CAROLINA" | ustrtrim(countyname) == "Total"
	
	// Add location information 
	gen state = "NORTH CAROLINA"
	gen county_nhgis = upper(countyname)
	
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose keepusing(statefip countyicp fips) assert(2 3) keep(3) nogen
	drop state county_nhgis countyname	
		
	// Save data
	compress
	save "$PROJ_PATH/analysis/processed/data/nc_vital_stats/imr_mmr_1922_1942.dta", replace
	
}

*******************************
// Clean raw AMA files ********
*******************************

if `ama' {

	// Load raw AMA data 	
	use "$PROJ_PATH/analysis/processed/intermediate/ama/ama_carolina_hospitals_uncleaned.dta", clear

	drop pdfno
	rename state city county, proper
	rename yearest yearestablished 
	order Year State category City population hospitalname typeofservice totalbeds bassinets averagebedsinuse control yearestablished births outpatientdepartment averagepatients outpatients ratedcapacity County notes
	tostring totalbeds ratedcapacity bedsratedcapacity averagecensus, replace

	desc, f
	
	// Drop empty row that were imported from Excel
	drop if State == ""
	tab State, m
	
	// Drop total rows
	drop if hospitalname == "Eighteen General Hospitals of less than 25 beds" | hospitalname == "Total for community use, 122" | hospitalname == "Totals"
	
	// NOTE: checked source pdf. The extra 1 was a footnote.
	replace beds = "2324" if beds == "23241" 
		
	// Add hospital IDs
	gen sort_order = _n
	gen locstr = City
	gen hospstr = hospitalname
	
	merge m:1 locstr hospstr using "$PROJ_PATH/analysis/processed/data/crosswalks/hospital_xwalk.dta", keepusing(hosp_id) keep(1 3)
	replace hosp_id = . if State == "South Carolina" | State == "SOUTH CAROLINA"
	gsort sort_order
	
	tab _merge State
	assert _merge == 3 if State == "NORTH CAROLINA"
	
	drop sort_order locstr hospstr _merge
	
	// Clean county and city variables
	replace State = "NC" if upper(State) == "NORTH CAROLINA"
	replace State = "SC" if upper(State) == "SOUTH CAROLINA"
	
	replace County = trim(County)
	replace County = regexr(County," Co\.$","")
	
	gen cit = City 
	replace cit = "Albemarle" if State == "NC" & cit == "Albermarle"
	replace cit = "Asheboro" if State == "NC" & cit == "Ashboro"
	replace cit = "Banner Elk" if State == "NC" & cit == "Banners Elk"
	replace cit = "Burlington" if State == "NC" & cit == "Burlington "
	replace cit = "Charlotte" if State == "NC" & cit == "Chariotte"
	replace cit = "Erwin" if State == "NC" & cit == "Duke"
	replace cit = "Fort Bragg" if State == "NC" & cit == "Ft. Bragg"
	replace cit = "Goldsboro" if State == "NC" & cit == "Goldsboro "
	replace cit = "High Point" if State == "NC" & cit == "Hight Point"
	replace cit = "Kinston" if State == "NC" & cit == "Kingston"
	replace cit = "Lincolnton" if State == "NC" & cit == "Lincolnton "
	replace cit = "Sanatorium" if State == "NC" & cit == "McCain"
	replace cit = "Mount Airy" if State == "NC" & cit == "Mt. Airy"
	replace cit = "New Bern" if State == "NC" & cit == "Newbern"
	replace cit = "North Wilkesboro" if State == "NC" & cit == "Northwilkesboro"
	replace cit = "Salisbury" if State == "NC" & cit == "Sailsbury"
	replace cit = "Samarcand" if State == "NC" & cit == "Samareand"
	replace cit = "Sanatorium" if State == "NC" & cit == "Sanatorium (P. O. Only)"
	replace cit = "Tryon" if State == "NC" & cit == "Tyron"
	replace cit = "Durham" if State == "NC" & cit == "West Durham"
	replace cit = "Jefferson" if State == "NC" & cit == "West Jefferson"
	replace cit = "Raleigh" if State == "NC" & cit == "McCauley Private Hospital"
	replace cit = "Cedar Springs" if State == "SC" & cit == "Cedar Spring"
	replace cit = "Charleston" if State == "SC" & cit == "Navy Yard"
	replace cit = "Ridgewood" if State == "SC" & (cit == "Ridgewood (Columbia P. O)" | cit == "Ridgewood, (Columbia P. O.)" | cit == "Ridgewood (Columbia P.O.)" | cit == "Ridgewood (Columbia P. O.)")
	replace cit = "Seneca" if State == "SC" & (cit == "Sencca" | cit == "Seneea")
	replace cit = "Sumter" if State == "SC" & cit == "Sumpter"
	replace cit = "Taylors" if State == "SC" & cit == "Taylor"
	replace cit = "Walterboro" if State == "SC" & cit == "Waterboro"
	replace cit = "Columbia" if State == "SC" & cit == "West Columbia"

	drop City 
	rename cit City

	gen cty = County
	replace cty = "Alamance" if State == "NC" & cty == "Alamace"
	replace cty = "Buncombe" if State == "NC" & (cty == "Buncomb" | cty == "Buneombe")
	replace cty = "Cabarrus" if State == "NC" & cty == "Carbarrus"
	replace cty = "Craven" if State == "NC" & cty == "Oraven"
	replace cty = "Edgecombe" if State == "NC" & cty == "Edgecomb"
	replace cty = "Mecklenburg" if State == "NC" & (cty == "Meeklenburg" | cty == "Mecklenberg")
	replace cty = "Surry" if State == "NC" & cty == "Surrey"
	replace cty = "Swain" if State == "NC" & cty == "Swam"
	replace cty = "Vance" if State == "NC" & cty == "Vances"
	replace cty = "Nash" if State == "NC" & cty == "Nash R. R. Gay Nash County"
	replace cty = "Richland" if State == "SC" & cty == "Richmond"

	drop County
	rename cty County

	// Check if hospital ID assigned to more than one location in data
	gisid hosp_id State County City hospitalname Year, missok
	qui gunique State County City, by(hosp_id) gen(tot_loc)
	gsort + hosp_id - tot_loc + State + County + City + hospitalname + Year
	by hosp_id: carryforward tot_loc, replace
	tab tot_loc if State == "NC"
	drop tot_loc
	
	// Check if more multiple copies of same hospital ID in single year
	gunique hosp_id Year if State == "NC"
	assert r(N) == r(unique)
		
	// Clean missing observations
	foreach var of varlist notes totalbeds beds ratedcapacity bedsratedcapacity averagebedsinuse averagecensus averagepatients { // 
		replace `var' = "" if `var' == "."
	}

	// Consolidate multiple versions of same variable with different variable names
	replace totalbeds = beds if totalbeds == "" & beds != "" & beds != totalbeds
	replace totalbeds = "111" if totalbeds == "111(a)"
	drop beds
	destring totalbeds, replace

	assert !(births != . & numberofbirths != .) | (births != . & totalbirths != .)
	
	replace births = numberofbirths if births == . & numberofbirths != .
	replace births = totalbirths if births == . & totalbirths != .
	drop numberofbirths totalbirths

	count if ratedcapacity != "" & bedsratedcapacity != ""
	assert r(N) == 0
	
	replace ratedcapacity = bedsratedcapacity if ratedcapacity == "" & bedsratedcapacity != ""
	drop bedsratedcapacity
	destring ratedcapacity, replace
	
	replace totalbeds = ratedcapacity if totalbeds == . & ratedcapacity != .

	assert !(averagebedsinuse != "" & averagecensus != "") | (averagebedsinuse != "" & averagepatients != "") 
	
	replace averagebedsinuse = averagecensus if averagebedsinuse == "" & averagecensus != ""
	replace averagebedsinuse = averagepatients if averagebedsinuse == "" & averagepatients != ""
	replace averagebedsinuse = "" if averagebedsinuse == "New"
	drop averagecensus averagepatients
	destring averagebedsinuse, replace

	assert !(control != "" & ownershiporcontrol != "")
	
	replace control = ownershiporcontrol if control == "" & ownershiporcontrol != ""
	drop ownershiporcontrol

	assert !(patientsadmitted != . & admissions != .)

	replace patientsadmitted = admissions if patientsadmitted == . & admissions != .
	drop admissions
	rename patientsadmitted patients
	order patients, last

	gen temp_est_yr = regexs(1) if regexm(notes,"([0-9]+)")
	destring temp_est_yr, replace
	replace yearestablished = temp_est_yr if !missing(temp_est_yr) & missing(yearestablished)
	drop temp_est_yr
	rename yearestablished EstYear

	drop notes-rnsfornursing

	drop if typeofservice == "Unit of South Carolina Sanatorium"

	gen Service = ""
	replace Service = "TB" if typeofservice == "TBChil" | typeofservice == "TB"
	replace Service = "General" if typeofservice == "Gen"
	replace Service = "General and TB" if typeofservice == "G & TB" | typeofservice == "G&TB" | typeofservice == "Gen, TB" | typeofservice == "GenTB" | typeofservice == "GenTb" 
	replace Service = "Children and maternity" if typeofservice == "Chil" | typeofservice == "Mater" | typeofservice == "Mat"
	replace Service = "Mental health" if typeofservice == "Ment" | typeofservice == "Mental" | typeofservice == "MenDef" | typeofservice == "MenDef " | typeofservice == "Metab" | typeofservice == "McDe" | typeofservice == "MeDe" | typeofservice == "N&M" | typeofservice == "N & M" | typeofservice == "NerConv" | typeofservice == "NervConv" | typeofservice == "NervDrug" | typeofservice == "Dr & A1" | typeofservice == "Al & Dr"
	replace Service = "Institutional" if typeofservice == "Inst" | typeofservice == "Inst'l" | typeofservice == "Inst."
	replace Service = "Specializing" if typeofservice == "Orth" | typeofservice == "Ortho" | typeofservice == "Surg" | typeofservice == "EENT" | typeofservice == "ENT" | typeofservice == "Ven"
	replace Service = "Convalescence" if typeofservice == "Conv"
	replace Service = "Industrial" if typeofservice == "Indus"

	tab typeofservice if missing(Service)
	drop typeofservice

	gen Contr = ""
	replace Contr = "Army & Veteran" if control == "Army" | control == "Navy" | control == "Vet" | control == "VetAd" | control == "VetBur" | control == "USAF" | control == "VetBur"  
	replace Contr = "Church" if control == "Church" | control == "Chrch"
	replace Contr = "Public" if control == "City" | control == "Co" | control == "Counties" | control == "County" | control == "Cy & Co" | control == "CyCo" | control == "Fed" | control == "State" | control == "StateFed" | control == "USPHS"
	replace Contr = "Non-profit" if control == "NPAssn" | control == "Fart" | control == "Frat" | control == "Indep"
	replace Contr = "Proprietary" if control == "Corp" | control == "Indiv" | control == "Part"
	replace Contr = "Indian affairs" if control == "I A" | control == "IA" | control == "Indian"
	replace Contr = "Industrial" if control == "Indus"
	
	tab control if missing(Contr)
	drop control 

	rename Contr Control

	drop if hospitalname == "Eighteen General Hospitals of less than 25 beds"
	drop if hospitalname == "Nine General Hospitals of less than 25 beds"
	drop if hospitalname == "Total for community use, 122" | hospitalname == "Total for community use, 44" | hospitalname == "Totals"

	gen temp_hospital = hospitalname

	gen hname = ""
	replace hname = "Abbeville County Memorial Hospital" if hname == "" & temp_hospital == "Abbeville Co. Mem. Hosp." | temp_hospital == "Abbeville Co. Memorial Hospital" | temp_hospital == "Abbeville County Memorial Hospital"
	replace hname = "Aiken Cottages Sanatorium" if hname == "" & temp_hospital == "Aiken Cottage Sanatorium" | temp_hospital == "Aiken Cottages (T. B.)" | temp_hospital == "The Aiken Cottage Sanat"
	replace hname = "Aiken County Hospital" if hname == "" & temp_hospital == "Aiken County Hospital" | temp_hospital == "Aiken Hospital" 
	replace hname = "Alamance County Sanatorium" if hname == "" & temp_hospital == "Alamance County Sanatorium"
	replace hname = "Alamance General Hospital" if hname == "" & temp_hospital == "Alamance General Hospital"
	replace hname = "Albemarle Hospital" if hname == "" & temp_hospital == "Albemarle Hospital" | temp_hospital == "Albemarie Hospital" | temp_hospital == "Albermarle Hospital"
	replace hname = "Alexander County Hospital" if hname == "" & temp_hospital == "Alexander County Hospital"
	replace hname = "Ambler Heights Sanatorium" if hname == "" & temp_hospital == "Ambler Heights Sanat. (T. B.)" | temp_hospital == "Ambler Heights Sanit" | temp_hospital == "Ambler Heights Sanitarium"
	replace hname = "Anderson County Hospital" if hname == "" & temp_hospital == "Anderson County Hosp." | temp_hospital == "Anderson County Hospital" | temp_hospital == "Anderson County Memorial Hospital"
	replace hname = "Andes Sanatorium" if hname == "" & temp_hospital == "Andes Sanitarium" | temp_hospital == "The Andes Sanitarium"
	replace hname = "Angel Brothers Hospital" if hname == "" & temp_hospital == "Angel Bros. Hospital" | temp_hospital == "Angel Brothers Hosp." | temp_hospital == "Angel Brothers Hospital" |  temp_hospital == "Angel's Hospital" | temp_hospital == "Angel Hospital"
	replace hname = "Angel Clinic" if hname == "" & temp_hospital == "Angel Clinic" | temp_hospital == "Angel Clinic Hospital" | temp_hospital == "Angel Clinic-Hospital"
	replace hname = "Annie Penn Memorial Hospital" if hname == "" & (temp_hospital == "Annie Penn Memorial Hospital" | temp_hospital == "Annie Penn Mem. Hospital" | temp_hospital == "Annie Penn Memorial Hosp." | temp_hospital == "Memorial Hospital") & City == "Reidsville" & State == "NC"
	replace hname = "Anson Sanatorium" if hname == "" & temp_hospital == "Anson Sanatorium"
	replace hname = "Appalachian Hall" if hname == "" & temp_hospital == "Appalachian Hall" | temp_hospital == "Appalachian Hall " | temp_hospital == "Appalachian Hall (N. & M.)" | temp_hospital == "Applachian Hall"
	replace hname = "Arthur B Lee Hospital" if hname == "" & temp_hospital == "Arthur B. Lee Hosp. (col.)" | temp_hospital == "Arthur B. Lee Hospital" | temp_hospital == "Arthur B. Lee Hospital (col.)"
	replace hname = "Ashe County Memorial Hospital" if hname == "" & temp_hospital == "Ashe County Memorial Hospital" | temp_hospital == "Ashe County Memorial Hosp."
	replace hname = "Ashe-Faison Children's Clinic and Hospital" if hname == "" & temp_hospital == "Ashe-Faison Children's Clinic and Hospital"
	replace hname = "Asheville Colored Hospital" if hname == "" & temp_hospital == "Asheville Colored Hospital"
	replace hname = "Asheville Mission Hospital" if hname == "" & temp_hospital == "Asheville Mission Hospital" | temp_hospital == "Asheville Mission Hosp."
	replace hname = "Asheville Orthopedic Home" if hname == "" & temp_hospital == "Asheville Orthopedic Home" | temp_hospital == "Asheville Orthopedic Hosp." | temp_hospital == "Asheville Orthopedic Hospital" | temp_hospital == "Ashville Orthopedic Home" | temp_hospital == "Asheville Orthopedie Home"
	replace hname = "Asheville Physiatric Institute" if hname == "" & temp_hospital == "Asheville Physiatric Institute" | temp_hospital == "Asheville Physiatric Inst." | temp_hospital == "Asheville Physiatric Institute Wesnoca" | temp_hospital == "Asheville Psychiatric Institute, Wesnoca" | temp_hospital == "Asheville Physiatric Institute, Wesnoca"
	replace hname = "Aston Park Hospital" if hname == "" & temp_hospital == "Aston Park Hospital" | temp_hospital == "Ashton Park Hospital"
	replace hname = "Atlantic Coast Line Hospital" if hname == "" & temp_hospital == "Atlantic Coast Line Hospital" | temp_hospital == "Atlantic Coast Line Hosp." | temp_hospital == "Atlantic Coast Line Railroad Hosp."
	replace hname = "Babies Hospital" if hname == "" & (temp_hospital == "Babies Hospital" | temp_hospital == "The Babies Hospital" | temp_hospital == "The Babies' Hospital") & City == "Wrightsville Sound" & State == "NC"
	replace hname = "Babies Hospital" if hname == "" & (temp_hospital == "Babies Hospital" | temp_hospital == "Babies' Hospital") & City == "Wilmington" & State == "NC"
	replace hname = "Badin Hospital" if hname == "" & temp_hospital == "Badin Hospital"
	replace hname = "Baker Sanatorium" if hname == "" & (temp_hospital == "Baker Sanatorium" | temp_hospital == "Baker Memorial Sanat" | temp_hospital == "Baker Memorial Sanat." | temp_hospital == "Baker Memorial Sanatorium") & City == "Charleston" & State == "SC"
	replace hname = "Baker Sanatorium" if hname == "" & (temp_hospital == "Baker Sanatorium" | temp_hospital == "The Baker Sanatorium") & City == "Lumberton" & State == "NC"
	replace hname = "Baker-Thompson Memorial Hospital" if hname == "" & (temp_hospital == "Baker-Thompson Memorial Hospital" | temp_hospital == "Thompson Memorial Hospital" | temp_hospital == "Thompson Memorial Hosp." |  temp_hospital == "Thompson Mem. Hosp." | temp_hospital == "Thompson Hospital")
	replace hname = "Barnes and Griffin Clinic" if hname == "" & (temp_hospital == "Barnes and Griffin Clinic" | temp_hospital == "Barnes-Griffin Clinic" | temp_hospital == "Barnes-Griffin Clinic Hosp." | temp_hospital == "Barnes-Griffin Clinic Hospital" | temp_hospital == "Barnes-Griffin Clinic-Hospital")
	replace hname = "Bass Memorial Hospital" if hname == "" & temp_hospital == "Bass Memorial Hospital"
	replace hname = "Beallmont Park Sanatorium" if hname == "" & (temp_hospital == "Beallmont Park Sanatorium" | temp_hospital == "Beallmont Park Sanat" | temp_hospital == "Beallmont Park Sanat. (N. & M.)")
	replace hname = "Beaufort County Hospital" if hname == "" & temp_hospital == "Beaufort County Hospital"
	replace hname = "Bennettsville Hospital" if hname == "" & temp_hospital == "Bennettsville Hospital"
	replace hname = "Berkeley County Hospital" if hname == "" & temp_hospital == "Berkeley County Hospital" | temp_hospital == "Berkeley County Hosp."
	replace hname = "Bethel Home" if hname == "" & temp_hospital == "Bethel Home"
	replace hname = "Biltmore Hospital" if hname == "" & temp_hospital == "Biltmore Hospital"
	replace hname = "Blackwelder Hospital" if hname == "" & temp_hospital == "Blackwelder Hospital"
	replace hname = "Blevins Sanatorium" if hname == "" & temp_hospital == "Blevins Sanatorium" | temp_hospital == "Blevin's Sanatorium"
	replace hname = "Blue Ridge Hospital" if hname == "" & temp_hospital == "Blue Ridge Hospital" | temp_hospital == "Blue Ridge Hosp. (Col.)" | temp_hospital == "Blue Ridge Hospital (col.)"
	replace hname = "Brantwood Hospital" if hname == "" & temp_hospital == "Brantwood Hospital"
	replace hname = "Brevard Hospital" if hname == "" & temp_hospital == "Brevard Hospital"
	replace hname = "Brewer Hospital" if hname == "" & temp_hospital == "Brewer Hospital" | temp_hospital == "Brewer Hospital (col.)"
	replace hname = "Brewer-Starling Clinic" if hname == "" & temp_hospital == "Brewer-Starling Clinic" | temp_hospital == "Brewer-Starling Clinic Hosp." | temp_hospital == "Brewer-Starling Clinic-Hosp." | temp_hospital == "Brewer-Starling Clinic-Hospital"
	replace hname = "Broadoaks Sanatorium" if hname == "" & temp_hospital == "Broadoaks Sanatorium" | temp_hospital == "Broadoaks Sanatorium (N. & M.)"
	replace hname = "Broadview Sanitarium" if hname == "" & temp_hospital == "Broadview Sanitarium"
	replace hname = "Brookside Camp" if hname == "" & temp_hospital == "Brookside Camp" | temp_hospital == "Brookside Camp (T.B.)"
	replace hname = "Brookside Cottage" if hname == "" & temp_hospital == "Brookside Cottage"
	replace hname = "Brown Community Hospital" if hname == "" & temp_hospital == "Brown Community Hospital"
	replace hname = "Brunswick County Hospital" if hname == "" & temp_hospital == "Brunswick County Hospital" | temp_hospital == "Brunswick County Hosp."
	replace hname = "Bryson City Hospital" if hname == "" & temp_hospital == "Bryson City Hospital"
	replace hname = "Bulluck Hospital" if hname == "" & temp_hospital == "Bulluck Hospital" | temp_hospital == "Bulluck Hospital Clinic" | temp_hospital == "Bulluck Hospital-Clinic" | temp_hospital == "The Bulluck Hospital"
	replace hname = "Burrus Memorial Hospital" if hname == "" & temp_hospital == "Burrus Memorial Hospital" | temp_hospital == "Burrus Memorial Hosp."
	replace hname = "Byerly Hospital" if hname == "" & temp_hospital == "Byerly Hospital"
	replace hname = "C. J. Harris Community Hospital" if hname == "" & temp_hospital == "C. J. Harris Community Hospital" | temp_hospital == "C. J. Harris Community Hosp."
	replace hname = "Cabarrus County Hospital" if hname == "" & temp_hospital == "Cabarrus County Hospital"
	replace hname = "Caldwell Hospital" if hname == "" & temp_hospital == "Caldwell Hospital"
	replace hname = "Camden Hospital" if hname == "" & temp_hospital == "Camden Hospital"
	replace hname = "Camp Alice Sanatorium" if hname == "" & temp_hospital == "Camp Alice" | temp_hospital == "Camp Alice Sumter County Tuberculosis Sanitarium" | temp_hospital == "Camp Alice, Sumter County Tuberculosis Sanitarium" | temp_hospital == "Camp Alice, Sumter Co. T. B. Sanit."
	replace hname = "Camp Wirth Hospital" if hname == "" & temp_hospital == "Camp Wirth Hospital"
	replace hname = "Candler-Nichols Hospital" if hname == "" & temp_hospital == "Candler-Nichols Hospital" | temp_hospital == "Candler-Tidmarsh Hospital"
	replace hname = "Cannon Memorial Hospital" if hname == "" & temp_hospital == "Cannon Memorial Hospital"
	replace hname = "Carolina General Hospital" if hname == "" & (temp_hospital == "Carolina General Hospital" | temp_hospital == "Carolina General Hosp.") & City == "Wilson" & State == "NC"
	replace hname = "Casstevens Clinic" if hname == "" & temp_hospital == "Casstevens Clinic" | temp_hospital == "Casstevans Clinic" | temp_hospital == "Casstevens Clinic Hospital" | temp_hospital == "Casstevens Clinic-Hospital" 
	replace hname = "Caswell Training School" if hname == "" & temp_hospital == "Caswell Training School" | temp_hospital == "The Caswell Training School"
	replace hname = "Catawba County Hospital" if hname == "" & temp_hospital == "Catawba County Hospital"
	replace hname = "Catawba General Hospital" if hname == "" & temp_hospital == "Catawba General Hospital" | temp_hospital == "Catawba Hospital"
	replace hname = "Central Carolina Convalescent Hospital" if hname == "" & temp_hospital == "Central Carolina Convalescent Hospital"
	replace hname = "Central Carolina Hospital" if hname == "" & temp_hospital == "Central Carolina Hospital" | temp_hospital == "Central Carolina Hosp."
	replace hname = "Central Prison Hospital" if hname == "" & temp_hospital == "Central Prison Hospital"
	replace hname = "Charles Es'Dorn Hospital" if hname == "" & temp_hospital == "Charles Es'Dorn Hospital" | temp_hospital == "Charles Es' Dorn Hospital" | temp_hospital == "Charles Es'Dorn Hosp." | temp_hospital == "Charles-Esdorn Hospital"   
	replace hname = "Charleston Orphan House" if hname == "" & temp_hospital == "Charleston Orphan House"
	replace hname = "Charlotte Eye, Ear and Throat Hospital" if hname == "" & temp_hospital == "Charlotte Eye, Ear and Throat Hospital" | temp_hospital == "Charlotte E, E. and T. Hospital" | temp_hospital == "Charlotte Eye, Ear & Throat Hospital" | temp_hospital == "Charlotte, Eye, Ear and Throat Hospital"   
	replace hname = "Charlotte Memorial Hospital" if hname == "" & temp_hospital == "Charlotte Memorial Hospital" | temp_hospital == "Charlotte Memorial Hosp."
	replace hname = "Chatham Hospital" if hname == "" & temp_hospital == "Chatham Hospital"   
	replace hname = "Cherokee County Hospital" if hname == "" & temp_hospital == "Cherokee County Hospital"
	replace hname = "Chester County Hospital" if hname == "" & temp_hospital == "Chester County Hospital"   
	replace hname = "Chester Sanatorium" if hname == "" & temp_hospital == "Chester Sanatorium"
	replace hname = "Chick Springs Sanitarium and Steedly Clinic" if hname == "" & temp_hospital == "Chick Springs Sanitarium and Steedly Clinic"   
	replace hname = "Chick Springs Sanatorium" if hname == "" & temp_hospital == "Chick Springs Hotel Sanit" | temp_hospital == "Chick Springs Hotel Sanit." | temp_hospital == "Chick Springs Hotel-Sanit"
	replace hname = "Children's Home" if hname == "" & (temp_hospital == "Children's Home" | temp_hospital == "The Children's Home" | temp_hospital == "Health Memorial Infirmary of the Children's Home" | temp_hospital == "Heath Memorial Infirmary of the Children's Home." | temp_hospital == "Heath Memorial Infirmary of the Children's Home") & City == "Winston-Salem" & State == "NC" 
	replace hname = "Chowan Hospital" if hname == "" & temp_hospital == "Chowan Hospital"
	replace hname = "Citadel Hospital" if hname == "" & temp_hospital == "Citadel Hospital" | temp_hospital == "The Citadel Hospital" | temp_hospital == "The Citadel Hospital"  
	replace hname = "City Hospital" if hname == "" & temp_hospital == "City Hospital" & City == "Gaffney"
	replace hname = "City Hospital" if hname == "" & temp_hospital == "City Hospital" & City == "Gastonia"
	replace hname = "City Hospital" if hname == "" & temp_hospital == "City Hospital" & City == "Winston-Salem"
	replace hname = "City Memorial Hospital" if hname == "" & temp_hospital == "City Memorial Hospital" & City == "Thomasville"   
	replace hname = "City Memorial Hospital" if hname == "" & temp_hospital == "City Memorial Hospital" & City == "Hickory"   
	replace hname = "City Memorial Hospital" if hname == "" & (temp_hospital == "City Memorial Hosp." | temp_hospital == "City Memorial Hospital" | temp_hospital == "Winston-Salem City Memorial Hospital" | temp_hospital == "Winston-Salem City Mem. Hosp.") & City == "Winston-Salem"
	replace hname = "Clarence Barker Memorial Hospital and Dispensary" if hname == "" & temp_hospital == "Clarence Barker Memorial Hospital and Dispensary"   
	replace hname = "Clark Hall Hospital" if hname == "" & temp_hospital == "Clark Hall Hospital"
	replace hname = "Clinton Hospital" if hname == "" & temp_hospital == "Clinton Hospital"     
	replace hname = "Clio Hospital" if hname == "" & temp_hospital == "Clio Hospital"     
	replace hname = "Coleman Hospital" if hname == "" & temp_hospital == "Coleman Hospital"     
	replace hname = "Colleton County Hospital" if hname == "" & temp_hospital == "Colleton County Hospital"     
	replace hname = "Columbia Hospital" if hname == "" & temp_hospital == "Columbia Hospital" & State == "NC" & County == "Tyrrell"    
	replace hname = "Columbia Hospital" if hname == "" & (temp_hospital == "Columbia Hospital" | temp_hospital == "Columbia Hospital of Richland County")& State == "SC" & County == "Richland"     
	replace hname = "Columbus County Hospital" if hname == "" & temp_hospital == "Columbus County Hospital" | temp_hospital == "Columbus County Hosp."     
	replace hname = "Community Hospital" if hname == "" & temp_hospital == "Community Hospital" & State == "NC" & City == "Roxboro"     
	replace hname = "Community Hospital" if hname == "" & (temp_hospital == "Community Hospital" | temp_hospital == "Community Hosp. (col.)" | temp_hospital == "Community Hospital (col.)") & State == "NC" & City == "Wilmington"     
	replace hname = "Concord Hospital" if hname == "" & temp_hospital == "Concord Hospital" | temp_hospital == "The Concord Hospital"     
	replace hname = "Confederate Infirmary" if hname == "" & temp_hospital == "Confederate Infirmary"     
	replace hname = "Connie Maxwell Orphanage" if hname == "" & temp_hospital == "Connie Maxwell Orphanage"     
	replace hname = "Conway Hospital" if hname == "" & temp_hospital == "Conway Hospital"     
	replace hname = "Cragmont Sanatorium" if hname == "" & temp_hospital == "Cragmont Sanatorium" | temp_hospital == "Cragmont Sanatorium (T.B)" | temp_hospital == "Cragmont Sanatorium (T.B.)"     
	replace hname = "Cumberland County Sanatorium" if hname == "" & temp_hospital == "Cumberland County Sanatorium" | temp_hospital == "Cumberland County Tuberculosis Sanatorium"     
	replace hname = "Cumberland General Hospital" if hname == "" & temp_hospital == "Cumberland General Hospital"     
	replace hname = "Davidson College Infirmary" if hname == "" & temp_hospital == "Davidson College Infirmary" | temp_hospital == "Davidson College Infirm" | temp_hospital == "Preyer Infirmary"    
	replace hname = "Davidson Hospital" if hname == "" & temp_hospital == "Davidson Hospital"     
	replace hname = "Davis Hospital" if hname == "" & temp_hospital == "Davis Hospital" | temp_hospital == "Carpenter-Davis Hospital"    
	replace hname = "Dixon Health Resort" if hname == "" & temp_hospital == "Dixon Health Resort"     
	replace hname = "Dorchester County Hospital" if hname == "" & temp_hospital == "Dorchester County Hospital"  | temp_hospital == "Dorchester County Hosp."  
	replace hname = "Dorothy Carolyn Hospital" if hname == "" & temp_hospital == "Dorothy Carolyn Hospital"     
	replace hname = "Dr. Hays' Hospital" if hname == "" & temp_hospital == "Dr. Hays' Hospital" | temp_hospital == "Dr. Hay's Hospital" | temp_hospital == "Hays Hospital"    
	replace hname = "Dr. Jervey's Private Hospital" if hname == "" & temp_hospital == "Dr. Jervey's Private Hospital" | temp_hospital == "Dr. Jervey's Private Hosp."     
	replace hname = "Dr. Peek's Hospital" if hname == "" & temp_hospital == "Dr. Peek's Hospital" | temp_hospital == "Dr. Peck's Hospital" | temp_hospital == "Dr. Peeks Hospital"     
	replace hname = "Dr. Tyler's Hospital" if hname == "" & temp_hospital == "Dr. Tyler's Hospital"                 
	replace hname = "Duke Hospital" if hname == "" & temp_hospital == "Duke Hospital"     
	replace hname = "Dula Hospital" if hname == "" & temp_hospital == "Dula Hospital"     
	replace hname = "Dunlap Hospital" if hname == "" & temp_hospital == "Dunlap Hospital"     
	replace hname = "Dunn Hospital" if hname == "" & temp_hospital == "Dunn Hospital"     
	replace hname = "Durham County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Durham County Tuberculosis Sanatorium"     			  
	replace hname = "Eastern Cherokee Indian Hospital" if hname == "" & temp_hospital == "Eastern Cherokee Indian Hospital" | temp_hospital == "Eastern Cherokee Indian Hosp."     
	replace hname = "Eastern Medical Center" if hname == "" & temp_hospital == "Eastern Medical Center"                 
	replace hname = "Eastern North Carolina Sanatorium" if hname == "" & temp_hospital == "Eastern North Carolina Sanatorium"     
	replace hname = "Edgecombe General Hospital" if hname == "" & temp_hospital == "Edgecombe General Hospital" | temp_hospital == "Edgecomb General Hospital" | temp_hospital == "Edgecombe General Hosp."     
	replace hname = "Edgecombe County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Edgecombe County Tuberculosis Sanatorium" | temp_hospital == "Edgecombe County Tuberculosis Sanitarium" | temp_hospital == "Edgecombe County Tubercular Sanatorium"     
	replace hname = "Edgemont Sanatorium" if hname == "" & temp_hospital == "Edgemont Sanatorium" | temp_hospital == "Edgemont Sanatorium (T.B.)"     
	replace hname = "Edgewood Cottage" if hname == "" & temp_hospital == "Edgewood Cottage" |  temp_hospital == "Edgewood Cottage (T.B.)"   
	replace hname = "Edgewood Sanitarium" if hname == "" & temp_hospital == "Edgewood Sanitarium"   
	replace hname = "Elizabeth City Hospital" if hname == "" & temp_hospital == "Elizabeth City Hospital"   
	replace hname = "Elkin Hospital" if hname == "" & temp_hospital == "Elkin Hospital"   
	replace hname = "Ellen Fitzgerald Hospital" if hname == "" & temp_hospital == "Ellen Fitzgerald Hospital" |  temp_hospital == "The Ellen Fitzgerald Hosp."   
	replace hname = "Elmhurst Cottage Sanatorium" if hname == "" & temp_hospital == "Elmhurst Cottage Sanit" | temp_hospital == "Elmhurst Cottage Sanit." | temp_hospital == "Elmhurst Cottage Sanitarium"   
	replace hname = "Emma Moss Booth Memorial Hospital" if hname == "" & temp_hospital == "Emma Moss Booth Memorial Hospital" | temp_hospital == "Emma Moss Booth Mem. Hosp."  
	replace hname = "Epworth Orphanage" if hname == "" & temp_hospital == "Epworth Orphanage"   
	replace hname = "Evelyn Ritter Hospital" if hname == "" & temp_hospital == "Evelyn Ritter Hospital"   
	replace hname = "Fairview Cottage Sanatorium" if hname == "" & temp_hospital == "Fairview Cottage Sanit" | temp_hospital == "Fairview Cottage Sanitarium" | temp_hospital == "Fairview Cottage Sanitarium (T.B.)" | temp_hospital == "Fairview Cottages Sanit. (T.B.)"   
	replace hname = "Fayetteville Eye, Ear, Nose and Throat Hospital" if hname == "" & temp_hospital == "Fayetteville Eye, Ear, Nose and Throat Hospital"   
	replace hname = "Fellowship Sanatorium of the Royal League" if hname == "" & temp_hospital == "Fellowship Sanatorium of the Royal League" | temp_hospital == "Fellowship Sanatorium of the Royal League (T.B)" | temp_hospital == "Fellowship Sanatorium" | temp_hospital == "Fellowship Association of the Royal League Hosp." | temp_hospital == "Fellowship Assn. of the Royal League Hospital"   
	replace hname = "Fennell Infirmary" if hname == "" & temp_hospital == "Fennell Infirmary" | temp_hospital == "Fennel Infirmary"   
	replace hname = "Florence Crittenton Home" if hname == "" & temp_hospital == "Florence Crittenton Home" | temp_hospital == "Florence Crittenton Industrial Home" | temp_hospital == "Florence Orittenton Industrial Home"    
	replace hname = "Florence Williams Hospital" if hname == "" & temp_hospital == "Florence Williams Hospital (col.)" | temp_hospital == "Florence Williams Hosp. (col.)"   
	replace hname = "Florence-Darlington Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Florence-Darlington Tuberculosis Sanatorium" | temp_hospital == "Florence-Darlington Tuberculolsis Sanatorium"   
	replace hname = "Forsyth County Hospital" if hname == "" & temp_hospital == "Forsyth County Hospital"   
	replace hname = "Forsyth County Tuberculosis Hospital and Sanatorium" if hname == "" & temp_hospital == "Forsyth County Sanatorium" | temp_hospital == "Forsyth County Sanat" | temp_hospital == "Forsyth County Sanat." | temp_hospital == "Forsyth County Tuberculosis Sanatorium" | temp_hospital == "Forsyth Co. Tuber. Sanat." | temp_hospital == "Forsyth Co. Tuber. Hosp." | temp_hospital == "Forsyth County Tuberculosis Hosp." | temp_hospital == "Forsyth County Tuberculosis Hospital"
	replace hname = "Fowle Memorial Hospital" if hname == "" & temp_hospital == "Fowle Memorial Hospital" | temp_hospital == "S. R. Fowle Memorial Hospital" | temp_hospital == "S. R. Fowle Memorial Hosp." | temp_hospital == "S. R. Fowle Mem. Hosp."
	replace hname = "French Broad Hospital" if hname == "" & temp_hospital == "French Broad Hospital" | temp_hospital == "French Broad Hospital, Inc."
	replace hname = "Furlonge's General Hospital" if hname == "" & temp_hospital == "Furlonge's General Hospital (col.)" 
	replace hname = "Gardner-Webb College Community Health Center" if hname == "" & temp_hospital == "Gardner-Webb College Community Health Center" 
	replace hname = "Garrett Memorial Hospital" if hname == "" & temp_hospital == "Garrett Memorial Hospital" | temp_hospital == "Garrett Memorial Hosp." | temp_hospital == "Garratt Memorial Hospital"
	replace hname = "Garrison General Hospital" if hname == "" & temp_hospital == "Garrison General Hospital" |  temp_hospital == "Garrison General Hosp." 
	replace hname = "Gaston County Negro Hospital" if hname == "" & temp_hospital == "Gaston County Negro Hospital" | temp_hospital == "Gaston County Negro Hosp." | temp_hospital == "Gaston Colored Hospital" | temp_hospital == "Gaston Colored Hosp. (col.)" | temp_hospital == "Gaston County Colored Hosp." |  temp_hospital == "Gaston County Colored Hospital"
	replace hname = "Gaston Sanatorium" if hname == "" & temp_hospital == "Gaston Sanatorium" | temp_hospital == "Gaston County Sanatorium"
	replace hname = "Gaston Memorial Hospital" if hname == "" & temp_hospital == "Gaston Memorial Hospital" 
	replace hname = "Gastonia Eye, Ear, Nose and Throat Hospital" if hname == "" & temp_hospital == "Gastonia Eye, Ear, Nose and Throat Hospital" 
	replace hname = "Georgetown County Memorial Hospital" if hname == "" & temp_hospital == "Georgetown County Memorial Hospital" 
	replace hname = "Glenwood Park Sanitarium" if hname == "" & temp_hospital == "Glenwood Park Sanitarium" | temp_hospital == "Glenwood Park Sanitarium (N. & M.)" 
	replace hname = "Goldsboro Hospital" if hname == "" & temp_hospital == "Goldsboro Hospital" | temp_hospital == "Goldsboro City Hospital"
	replace hname = "Good Hope Hospital" if hname == "" & temp_hospital == "Good Hope Hospital" 
	replace hname = "Good Samaritan Hospital" if hname == "" & (temp_hospital == "Good Samaritan Hospital" |  temp_hospital == "Good Samaritan Hospital (col.)" | temp_hospital == "Good Samaritan Hosp. (col.)") & City == "Charlotte" & State == "NC"
	replace hname = "Good Samaritan-Waverly Hospital" if hname == "" & (temp_hospital == "Good Samaritan-Waverly Hospital" | temp_hospital == "Good Samaritan Hosp. (col.)" | temp_hospital == "Good Samaritan Hospital" | temp_hospital == "Good Samaritan Hospital (col.)" | temp_hospital == "Good Samaritan-Waverly Hospitals (col.)") & City == "Columbia" & State == "SC"
	replace hname = "Good Samaritan Hospital" if hname == "" & temp_hospital == "Good Samaritan Hospital" & City == "Spartanburg" & County == "Spartanburg" & State == "SC"
	replace hname = "Good Shepherd Hospital" if hname == "" & temp_hospital == "Good Shepherd Hospital" |  temp_hospital == "Good Shephard Hospital"
	replace hname = "Gordon Crowell Memorial Hospital" if hname == "" & temp_hospital == "Gordon Crowell Memorial Hospital" 
	replace hname = "Grace Hospital" if hname == "" & temp_hospital == "Grace Hospital" & City == "Banner Elk"
	replace hname = "Grace Hospital" if hname == "" & temp_hospital == "Grace Hospital" & City == "Morganton"
	replace hname = "Granville Hospital" if hname == "" & temp_hospital == "Granville Hospital" 
	replace hname = "Graylyn, Bowman Gray School of Medicine" if hname == "" & temp_hospital == "Graylyn, Bowman Gray School of Medicine" 
	replace hname = "Greenville City Hospital" if hname == "" & temp_hospital == "Greenville City Hospital" | temp_hospital == "Greenville City Hosp." |  temp_hospital == "Greenville Gen. Hosp." | temp_hospital == "Greenville General Hosp." | temp_hospital == "Greenville General Hospital"
	replace hname = "Greenville County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Greenville County Tuberculosis Sanatorium" |  temp_hospital == "Greenville Co. Tuber. Hosp." | temp_hospital == "Greenville County Sanat" | temp_hospital == "Greenville County Sanatorium" | temp_hospital == "Greenville County Sanat."
	replace hname = "Greenwood City Hospital" if hname == "" & temp_hospital == "Greenwood City Hospital" | temp_hospital == "Greenwood City Hosp." | temp_hospital == "Greenwood Hospital"
	replace hname = "Guilford County Sanatorium" if hname == "" & temp_hospital == "Guilford County Sanatorium" | temp_hospital == "Guilford County Sanatorium for the Treatment of Tuberculosis" | temp_hospital == "Guilford Co. Sanat. for the Treatment of Tuber" | temp_hospital == "Guilford County Sanatorium (T.B.)" | temp_hospital == "Guilford County Sanat" | temp_hospital == "Guilford County Sanat."
	replace hname = "Guilford General Hospital" if hname == "" & temp_hospital == "Guilford General Hospital" | temp_hospital == "Guilford General Hosp."
	replace hname = "H. F. Long Hospital" if hname == "" & temp_hospital == "H. F. Long Hospital" 
	replace hname = "Halifax County Sanatorium" if hname == "" & temp_hospital == "Halifax Co. Tuber. Sanit." | temp_hospital == "Halifax County Tuberculosis Sanitorium" | temp_hospital == "Halifax County Tuberculosis Sanitarium" | temp_hospital == "Halifax County Sanitarium"
	replace hname = "Halifax County Clinic-Hospital" if hname == "" & temp_hospital == "Halifax County Clinic-Hospital" 
	replace hname = "Hamlet Hospital" if hname == "" & temp_hospital == "Hamlet Hospital" 
	replace hname = "Haywood County Hospital" if hname == "" & temp_hospital == "Haywood County Hospital" | temp_hospital == "Haywood County Hosp." 
	replace hname = "Henderson-Crumpler Clinic Hospital" if hname == "" & temp_hospital == "Henderson-Crumpler Clinic Hospital" 
	replace hname = "Hickory Memorial Hospital" if hname == "" & temp_hospital == "Hickory Memorial Hospital" 
	replace hname = "High Point Hospital" if hname == "" & temp_hospital == "High Point Hospital" 
	replace hname = "High Point Memorial Hospital" if hname == "" & temp_hospital == "High Point Memorial Hospital" | temp_hospital == "High Point Memorial Hosp."
	replace hname = "Highland Hospital" if hname == "" & temp_hospital == "Highland Hospital" | temp_hospital == "Highland Hospital (N. & M.)" 
	replace hname = "Highsmith Hospital" if hname == "" & temp_hospital == "Highsmith Hospital" 
	replace hname = "Hillcroft Sanatorium" if hname == "" & temp_hospital == "Hillcroft Sanatorium" | temp_hospital == "Hillcroft Sanatorium (T.B.)" | temp_hospital == "Hilleroft Sanatorium"
	replace hname = "Hiwassee Dam Hospital" if hname == "" & temp_hospital == "Hiwassee Dam Hospital" 
	replace hname = "Holman Hospital" if hname == "" & temp_hospital == "Holman Hospital" 
	replace hname = "Hopewell Sanatorium" if hname == "" & temp_hospital == "Hopewell Sanatorium" | temp_hospital == "Hopewell Sanatorium (T.B.)" | temp_hospital == "Hopewell Sanatorium (T. B.)"
	replace hname = "Hugh Chatham Memorial Hospital" if hname == "" & temp_hospital == "Hugh Chatham Memorial Hospital" | temp_hospital == "Hugh Chatham Memorial Hosp." | temp_hospital == "Hugh Chatham Mem. Hospital"
	replace hname = "Independent Order of Odd Fellows Home" if hname == "" & temp_hospital == "Independent Order of Odd Fellows Home" | temp_hospital == "Independent Order of Odd Fellows' Home" | temp_hospital == "I. O. O. F. Home"
	replace hname = "Infants and Children's Sanatorium" if hname == "" & (temp_hospital == "Infaute and Children's Sanitarium" | temp_hospital == "Infants and Childrens Sanitarium" | temp_hospital == "Infants and Children's Sanitarium" | temp_hospital == "Infants and Children's Sanit." | temp_hospital == "Infants and Children's Sanit" | temp_hospital == "Infants & Children's Sanit." | temp_hospital == "Infants & Children's Sanit") & City == "Saluda" & State == "NC"
	replace hname = "Infirmary of the South Carolina School for Deaf and Blind" if hname == "" & temp_hospital == "South Carolina School for Deaf and Blind Hospital" | temp_hospital == "Infirmary of the South Carolina School for Deaf and Blind" | temp_hospital == "Infirmary of the South Carolina School for the Deaf and Blind"
	replace hname = "J. Arthur Dosher Memorial Hospital" if hname == "" & temp_hospital == "J. Arthur Dosher Memorial Hospital"
	replace hname = "James Walker Memorial Hospital" if hname == "" & temp_hospital == "James Walker Memorial Hospital" | temp_hospital == "James Walker Memorial Hosp." | temp_hospital == "James Walker Mem. Hosp."
	replace hname = "Johnson Memorial Hospital" if hname == "" & temp_hospital == "Johnson Memorial Hospital" 
	replace hname = "Johnston County Hospital" if hname == "" & temp_hospital == "Johnston County Hospital" | temp_hospital == "Johnston County Hosp."
	replace hname = "Jubilee Hospital" if hname == "" & temp_hospital == "Jubilee Hospital" | temp_hospital == "Jubilee Hospital (col.)"
	replace hname = "Junior League Baby Home" if hname == "" & temp_hospital == "Junior League Baby Home" | temp_hospital == "Junior League Baby Hosp."
	replace hname = "Kafer Memorial Hospital" if hname == "" & temp_hospital == "Kafer Memorial Hospital" 
	replace hname = "Kate Bitting Reynolds Memorial Hospital" if hname == "" & temp_hospital == "Kate Bitting Reynolds Memorial Hospital" 
	replace hname = "Kelley Memorial Hospital" if hname == "" & temp_hospital == "Kelley Memorial Hospital" | temp_hospital == "Kelley Sanatorium" 
	replace hname = "L. Richardson Memorial Hospital" if hname == "" & temp_hospital == "L. Richardson Memorial Hospital" | temp_hospital == "L. Richardson Memorial Hospital (col.)" | temp_hospital == "L. Richardson Mem. Hosp. (col.)"
	replace hname = "Lancaster Hospital" if hname == "" & temp_hospital == "Lancaster Hospital" 
	replace hname = "Laurel Hospital" if hname == "" & temp_hospital == "Laurel Hospital" 
	replace hname = "Laurens County Hospital" if hname == "" & temp_hospital == "Laurens County Hospital" 
	replace hname = "Laurens Hospital" if hname == "" & temp_hospital == "Laurens Hospital" 
	replace hname = "Laurinburg Hospital" if hname == "" & temp_hospital == "Laurinburg Hospital" 
	replace hname = "Lawrence Clinic" if hname == "" & temp_hospital == "Lawrence Clinic" | temp_hospital == "Lawrence-Cooke Clinic Hospital" 
	replace hname = "Leaksville General Hospital" if hname == "" & temp_hospital == "Leaksville Hospital" | temp_hospital == "Leaksville Hospital, Inc." | temp_hospital == "Leaksville General Hospital" | temp_hospital == "Leaksville General Hosp."
	replace hname = "Lee County Hospital" if hname == "" & temp_hospital == "Lee County Hospital" 
	replace hname = "Leesville Infirmary" if hname == "" & temp_hospital == "Leesville Infirmary" | temp_hospital == "The Leesville Infirmary"
	replace hname = "Lenoir Hospital" if hname == "" & temp_hospital == "Lenoir Hospital" 
	replace hname = "Lesh Infirmary of Thornwell Orphanage" if hname == "" & temp_hospital == "Lesh Infirmary of Thornwell Orphanage" | temp_hospital == "Lesh Infirmary of Thornwell Orphange" | temp_hospital == "Thornwell Orphanage"
	replace hname = "Lexington Memorial Hospital" if hname == "" & temp_hospital == "Lexington Memorial Hospital" | temp_hospital == "Lexington Memorial Hosp."
	replace hname = "Lincoln Hospital" if hname == "" & (temp_hospital == "Lincoln Hospital" | temp_hospital == "Lincoln Hospital ") & City == "Lincolnton" & State == "NC"
	replace hname = "Lincoln Hospital" if hname == "" & (temp_hospital == "Lincoln Hospital" | temp_hospital == "Lincoln Hospital (col.)" | temp_hospital == "Lincoln Hosp. (col.)") & City == "Durham" & State == "NC" 
	replace hname = "Long's Sanatorium" if hname == "" & temp_hospital == "Long's Sanatorium" 
	replace hname = "Lowrance Hospital" if hname == "" & temp_hospital == "Lowrance Hospital" 
	replace hname = "Lyday Memorial Hospital" if hname == "" & temp_hospital == "Lyday Memorial Hospital" 
	replace hname = "Lyle Hospital" if hname == "" & (temp_hospital == "Lyle Hospital" | temp_hospital == "The Lyle Hospital") & City == "Franklin" & State == "NC"
	replace hname = "Lyle Hospital" if hname == "" & temp_hospital == "Lyle Hospital" & City == "Rock Hill" & State == "SC"
	replace hname = "Lynch Infirmary" if hname == "" & temp_hospital == "Lynch Infirmary" | temp_hospital == "The Lynch Infirmary"
	replace hname = "Magnolia Grove Hospital" if hname == "" & temp_hospital == "Magnolia Grove Hospital" 
	replace hname = "Majority Hospital" if hname == "" & temp_hospital == "Majority Hospital (col.)" & City == "Union" & State == "SC"
	replace hname = "Maria Parham Hospital" if hname == "" & temp_hospital == "Maria Parham Hospital" 
	replace hname = "Marion County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Marion County Tuberculosis Sanatorium (col.)" 
	replace hname = "Marion General Hospital" if hname == "" & temp_hospital == "Marion General Hospital" 
	replace hname = "Marion Sims Memorial Hospital" if hname == "" & temp_hospital == "Marion Sims Memorial Hospital" | temp_hospital == "Marion Sims Memorial Hosp."
	replace hname = "Marlboro County General Hospital" if hname == "" & temp_hospital == "Marlboro County General Hospital" | temp_hospital == "Marlboro County General Hosp." | temp_hospital == "Marlboro Co. Gen. Hosp."
	replace hname = "Marshall Hospital" if hname == "" & temp_hospital == "Marshall Hospital" 
	replace hname = "Martin General Hospital" if hname == "" & temp_hospital == "Martin General Hospital" & City == "Williamston" & State == "NC"
	replace hname = "Martin Private Hospital" if hname == "" & (temp_hospital == "Martin Private Hospital" | temp_hospital == "Martin Hospital" | temp_hospital == "Martins Private Hospital" | temp_hospital == "Martin's Private Hospital") & City == "Mullins" & State == "SC"
	replace hname = "Martin Memorial Hospital" if hname == "" & (temp_hospital == "Martin Memorial Hospital" |  temp_hospital == "Martin Memorial Hosp.") & City == "Mount Airy" & State == "NC"
	replace hname = "Mary Black Memorial Hospital" if hname == "" & temp_hospital == "Mary Black Memorial Hospital" | temp_hospital == "The Mary Black Clinic and Private Hospital" | temp_hospital == "Mary Black Memorial Hosp." | temp_hospital == "Mary Black Mem. Hosp." | temp_hospital == "Mary Black Clinic and Privato Hospital" | temp_hospital == "Mary Black Clinic and Private Hospital" | temp_hospital == "Mary Black Clinic & Priv. Hosp."
	replace hname = "Mary Elizabeth Hospital" if hname == "" & temp_hospital == "Mary Elizabeth Hospital" 
	replace hname = "Mary Smith Sanatorium" if hname == "" & temp_hospital == "Mary Smith Sanit. (col.)" & City == "Asheville" & State == "NC"
	replace hname = "McBee Clinic" if hname == "" & temp_hospital == "McBee Clinic" 
	replace hname = "McCauley Private Hospital" if hname == "" & temp_hospital == "McCauley Private Hospital" | temp_hospital == "McCauley Priv. Hosp. (col.)" | temp_hospital == "McCauley Private Hosp. (col.)" | temp_hospital == "McCauley Private Hospital (col.)"
	replace hname = "McClaren Medical Shelter" if hname == "" & temp_hospital == "McClaren Medical Shelter" 
	replace hname = "McClennan Hospital" if hname == "" & temp_hospital == "McClennan Hospital" | temp_hospital == "McClennan Hospital & Training School"
	replace hname = "McLeod Infirmary" if hname == "" & temp_hospital == "McLeod Infirmary" | temp_hospital == "The McLeod Infirmary" | temp_hospital == "Florence Infirmary" 
	replace hname = "McPherson Hospital" if hname == "" & temp_hospital == "McPherson Hospital" 
	replace hname = "Mecklenburg Sanatorium" if hname == "" & temp_hospital == "Mecklenburg Sanatorium" 
	replace hname = "Medical Center Hospital" if hname == "" & temp_hospital == "Medical Center Hospital" 
	replace hname = "Memorial General Hospital" if hname == "" & (temp_hospital == "Memorial General Hospital" | temp_hospital == "Memorial General Hospital." | temp_hospital == "Memorial General Hosp.") & City == "Kinston" & State == "NC"
	replace hname = "Memorial Hospital" if hname == "" & temp_hospital == "Memorial Hospital" & City == "Asheboro" & State == "NC"
	replace hname = "Memorial Hospital" if hname == "" & temp_hospital == "Memorial Hospital" & City == "Wilson" & State == "NC"
	replace hname = "Memorial Mission Hospital" if hname == "" & temp_hospital == "Memorial Mission Hospital" & City == "Asheville" & State == "NC"
	replace hname = "Mercy Hospital" if hname == "" & temp_hospital == "Mercy Hospital" & City == "Charleston" & State == "SC"
	replace hname = "Mercy Hospital" if hname == "" & (temp_hospital == "Mercy Hospital" | temp_hospital == "Mercy General Hospital") & City == "Charlotte" & State == "NC" 
	replace hname = "Mercy Hospital" if hname == "" & (temp_hospital == "Mercy Hospital" | temp_hospital == "Mercy Hospital (col.)") & City == "Wilson" & State == "NC"
	replace hname = "Meriwether Hospital" if hname == "" & temp_hospital == "Meriwether Hospital" | temp_hospital == "Meriwether Hosp. and Tr. School"
	replace hname = "Methodist Orphanage Infirmary" if hname == "" & temp_hospital == "Methodist Orphanage Infirmary" 
	replace hname = "Mills Home Infirmary" if hname == "" & temp_hospital == "Mills Home Infirmary" | temp_hospital == "Mils Home Infirmary"
	replace hname = "Mocksville Hospital" if hname == "" & temp_hospital == "Mocksville Hospital" 
	replace hname = "Moncure Hospital" if hname == "" & temp_hospital == "Moncure Hospital" 
	replace hname = "Montgomery Hospital" if hname == "" & temp_hospital == "Montgomery Hospital" 
	replace hname = "Montgomery Memorial Hospital" if hname == "" & temp_hospital == "Montgomery Memorial Hosp." 
	replace hname = "Moore Clinic Hospital" if hname == "" & (temp_hospital == "Moore Clinic Hospital" | temp_hospital == "Orthopedic Hospital") & City == "Columbia" & State == "SC"
	replace hname = "Moore County Hospital" if hname == "" & temp_hospital == "Moore County Hospital" 
	replace hname = "Moore-Herring Hospital" if hname == "" & temp_hospital == "Moore-Herring Hospital" 
	replace hname = "Morehead City Hospital" if hname == "" & temp_hospital == "Morehead City Hospital" 
	replace hname = "Mountain Sanitarium and Hospital" if hname == "" & temp_hospital == "Mountain Sanitarium and Hospital" | temp_hospital == "Mountain Sanitarium and Hosp." | temp_hospital == "Mountain Sanit. And Hosp." | temp_hospital == "Mountain Sanit. & Hosp." | temp_hospital == "Mountain Sanit and Hosp." | temp_hospital == "Asheville Agricultural School and Mountain Sanatorium" | temp_hospital == "Asheville Agricultural School and Mountain Sanat"
	replace hname = "Mullins Hospital" if hname == "" & temp_hospital == "Mullins Hospital" | temp_hospital == "The Mullins Hospital"
	replace hname = "Murphy Hospital" if hname == "" & temp_hospital == "Murphy Hospital" 
	replace hname = "Nash County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Nash County Tuberculosis Sanatorium" 
	replace hname = "New Bern General Hospital" if hname == "" & temp_hospital == "New Bern General Hospital" 
	replace hname = "New Charlotte Sanatorium" if hname == "" & temp_hospital == "New Charlotte Sanatorium" | temp_hospital == "New Charlotte Sanat" 
	replace hname = "Newberry County Hospital" if hname == "" & temp_hospital == "Newberry County Hospital" | temp_hospital == "Newberry County Hosp."
	replace hname = "Norburn Hospital" if hname == "" & temp_hospital == "Norburn Hospital" | temp_hospital == "Noburn Hospital" | temp_hospital == "Norburn Hospital and Clinic" | temp_hospital == "The Norburn Hospital"
	replace hname = "North Carolina Baptist Hospital" if hname == "" & temp_hospital == "North Carolina Baptist Hospital" | temp_hospital == "North Carolina Baptist Hosp."
	replace hname = "North Carolina Cerebral Palsy Hospital" if hname == "" & temp_hospital == "North Carolina Cerebral Palsy Hospital" 
	replace hname = "North Carolina Orthopedic Hospital" if hname == "" & temp_hospital == "North Carolina Orthopedic Hospital" | temp_hospital == "North Carolina Orthopedic Hospital for Crippled Children of Sound Minds" | temp_hospital== "North Carolina Orthopedic Hospital for Crippled Children" | temp_hospital == "North Carolina Orthopedic Hosp. for Crippled Child" | temp_hospital == "North Carolina Orthopedic Hosp. for Crippled Chil."
	replace hname = "North Carolina Sanatorium" if hname == "" & temp_hospital == "North Carolina Sanatorium for the Treatment of Tuberculosis" & City == "McCain" & State == "NC"
	replace hname = "North Carolina Sanatorium" if hname == "" & (temp_hospital == "North Carolina Sanatorium" | temp_hospital == "Sanat. for Treatment of Tuberc." | temp_hospital == "North Carolina Sanat" | temp_hospital == "North Carolina Sanat. For Treatment of Tuber" | temp_hospital == "North Carolina Sanatorium for the Treatment of Tuberculosis" | temp_hospital == "North Carolina Sanat." | temp_hospital == "North Carolina Sanatorium for the Treatment of Tuberculosis") & City == "Sanatorium" & State == "NC"
	replace hname = "North Carolina School for the Deaf" if hname == "" & temp_hospital == "North Carolina School for the Deaf" 
	replace hname = "North Carolina State School for the Blind and Deaf" if hname == "" & temp_hospital == "North Carolina State School for the Blind and Deaf" | temp_hospital == "North Carolina State School for the Blind and Deaf." | temp_hospital == "North Carolina School for the Blind and Deaf"
	replace hname = "Oakland Sanatorium" if hname == "" & temp_hospital == "Oakland Sanitarium" | temp_hospital == "Oak Hill Sanatorium"
	replace hname = "Oconee County Hospital" if hname == "" & temp_hospital == "Oconee County Hospital" | temp_hospital == "Oconee Memorial Hospital"
	replace hname = "Onslow County Hospital" if hname == "" & temp_hospital == "Onslow County Hospital" 
	replace hname = "Onteora Lodge" if hname == "" & temp_hospital == "Onteora Lodge" 
	replace hname = "Orangeburg Hospital" if hname == "" & temp_hospital == "Orangeburg Hospital" | temp_hospital == "The Orangeburg Hospital" | temp_hospital == "Tri-County Hospital" 
	replace hname = "Palmetto Sanatorium" if hname == "" & temp_hospital == "Palmetto Sanatorium" | temp_hospital == "Palmetto Sanatorium (col.)" | temp_hospital == "Palmetto Sanat. (col.)" 
	replace hname = "Park View Hospital" if hname == "" & temp_hospital == "Park View Hospital" |  temp_hospital == "Parkview Hospital"
	replace hname = "Parrott Memorial Hospital" if hname == "" & temp_hospital == "Parrott Memorial Hospital" | temp_hospital == "Parrott Memorial Hosp." | temp_hospital == "Parrott Memorial Hospital." | temp_hospital == "Parrott Memorial Hospital, Inc."
	replace hname = "Patton Memorial Hospital" if hname == "" & temp_hospital == "Patton Memorial Hospital" |  temp_hospital == "Patton Memorial Hosp."
	replace hname = "Penmar Sanitarium" if hname == "" & temp_hospital == "Penmar Sanitarium" 
	replace hname = "People's Hospital" if hname == "" & temp_hospital == "People's Hospital" |  temp_hospital == "Peoples Hospital"
	replace hname = "Person County Memorial Hospital" if hname == "" & temp_hospital == "Person County Memorial Hospital" 
	replace hname = "Petrie Hospital" if hname == "" & temp_hospital == "Petrie Hospital" 
	replace hname = "Piedmont Memorial Hospital" if hname == "" & temp_hospital == "Piedmont Memorial Hospital" | temp_hospital == "Piedmont Memorial Hosp." | temp_hospital == "Pledmont Memorial Hosp." | temp_hospital == "Clinic Hospital" |  temp_hospital == "The Clinic Hospital" 
	replace hname = "Pine Cove Sanitarium" if hname == "" & temp_hospital == "Pine Cove Sanitarium" 
	replace hname = "Pinehaven Sanatorium" if hname == "" & temp_hospital == "Pinehaven Sanatorium" | temp_hospital == "Pine Haven Sanatorium" | temp_hospital == "Pinehaven Sanatorium (T.B.)"
	replace hname = "Pine-Crest Manor Sanatorium" if hname == "" & temp_hospital == "Pine-Crest Manor Sanatorium" | temp_hospital == "Pine Crest Manor Sanat. (T.B.)" | temp_hospital == "Pine-Crest Manor Sanat." | temp_hospital == "Pine-Crest Manor Sanat"
	replace hname = "Pine Heights Sanatorium" if hname == "" & temp_hospital == "Pine Heights Sanatorium" 
	replace hname = "Pinebluff Sanitarium" if hname == "" & temp_hospital == "Pinebluff Sanitarium" | temp_hospital == "Pine Bluff Sanitarium"
	replace hname = "Pisgah Sanatorium and Hospital" if hname == "" & temp_hospital == "Pisgah Sanitarium and Hospital" | temp_hospital == "Pisgah Sanitarium and Hosp." | temp_hospital == "Pisgah Sanitarium" | temp_hospital == "Pisgah Sanit. and Hospital" | temp_hospital == "Pisgah Sanit. and Hosp." | temp_hospital == "Pisgah Sanit and Hosp."
	replace hname = "Pitt General Hospital" if hname == "" & temp_hospital == "Pitt General Hospital" | temp_hospital == "Pitt Community Hospital" |  temp_hospital == "Pitt County Memorial Hospital" 
	replace hname = "Pittman Hospital" if hname == "" & temp_hospital == "Pittman Hospital" | temp_hospital == "Pittman Hospital, Inc." | temp_hospital == "R. L. Pittman Hospital" 
	replace hname = "Potter Emergency Hospital" if hname == "" & temp_hospital == "Potter Emergency Hospital" | temp_hospital == "Potter Emergency Hosp." | temp_hospital == "The Potter Emergency Hospital"
	replace hname = "Powe Hospital" if hname == "" & temp_hospital == "Powe Hospital" 
	replace hname = "Presbyterian Hospital" if hname == "" & temp_hospital == "Presbyterian Hospital" 
	replace hname = "Presbyterian Orphans Home" if hname == "" & temp_hospital == "Presbyterian Orphans Home" | temp_hospital == "Presbyterian Orphans' Home"
	replace hname = "Providence Hospital" if hname == "" & temp_hospital == "Providence Hospital" 
	replace hname = "Provident Hospital" if hname == "" & temp_hospital == "Provident Hospital" | temp_hospital == "Provident Hospital (col.)"
	replace hname = "Pryor Hospital" if hname == "" & temp_hospital == "Pryor Hospital" 
	replace hname = "Quality Hill Sanatorium" if hname == "" & temp_hospital == "Quality Hill Sanatorium" | temp_hospital == "Quality Hill Sanitarium (col.)" | temp_hospital == "Quality Hill Sanitarium" | temp_hospital == "Quality Hill Sanit. (col.)" | temp_hospital == "Quality Hill Sanatorium (col.)" | temp_hospital == "Quality Hill Sanat. (col.)"
	replace hname = "Quarantine Hospital for Venereal Disease" if hname == "" & temp_hospital == "Quarantine Hospital for Venereal Disease" 
	replace hname = "Quigless Clinic-Hospital" if hname == "" & temp_hospital == "Quigless Clinic-Hospital" 
	replace hname = "Nash County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "R. R. Gay Nash County Tuberculosis Sanatorium" 
	replace hname = "Nash County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Tuberculosis Sanatorium" & City == "Nashville" & State == "NC"
	replace hname = "Rainey Hospital" if hname == "" & temp_hospital == "Rainey Hospital" 
	replace hname = "Randolph Hospital" if hname == "" & temp_hospital == "Randolph Hospital" 
	replace hname = "Rapid Treatment Center" if hname == "" & temp_hospital == "Rapid Treatment Center" 
	replace hname = "Reaves Eye, Ear, Nose and Throat Infirmary" if hname == "" & temp_hospital == "Reaves Eye, Ear, Nose and Throat Infirmary" | temp_hospital == "Reaves E, E, N. and T. Infirmary"
	replace hname = "Red Cross Sanatorium" if hname == "" & (temp_hospital == "Red Cross Sanatorium" | temp_hospital == "Red Cross Sanatorium (T.B.)" | temp_hospital == "Wilmington Tuberculosis Sanatorium" |  temp_hospital == "Wilmington Tuberculosis Sanitarium" | temp_hospital == "Wilmington Red Cross Sanit." | temp_hospital == "Wilmington Red Cross Sanit" | temp_hospital == "Wilmington Red Cross Sanatorium") & City == "Wilmington" & State == "NC"
	replace hname = "Reeves Clinic-Hospital" if hname == "" & temp_hospital == "Reeves Clinic-Hospital" & City == "Hope Mills" & State == "NC" 
	replace hname = "Reeves Gamble Hospital" if hname == "" & temp_hospital == "Reeves Gamble Hospital" | temp_hospital == "Reeves Hospital" | temp_hospital == "Gamble Clinic" 
	replace hname = "Rex Hospital" if hname == "" & temp_hospital == "Rex Hospital" 
	replace hname = "Richard Baker Hospital" if hname == "" & temp_hospital == "Richard Baker Hospital" 
	replace hname = "Ridgewood Tuberculosis Camp" if hname == "" & temp_hospital == "Ridgewood Tuberculosis Camp" | temp_hospital == "Ridgewood Tuberculosis Sanatorium" | temp_hospital == "Ridgewood Tuber. Camp." | temp_hospital == "Ridgewood Tuber. Camp" | temp_hospital == "Ridgewood Tuber Camp" | temp_hospital == "Richwood Tuberculous Camp" | temp_hospital == "Richwood Tuberculosis Camp"
	replace hname = "Ridgeland Hospital" if hname == "" & temp_hospital == "Ridgeland Hospital" 
	replace hname = "River View Hospital" if hname == "" & temp_hospital == "River View Hospital" | temp_hospital == "Riverview Hospital"
	replace hname = "Riverside Public Health Hospital" if hname == "" & temp_hospital == "Riverside Public Health Hosp." 
	replace hname = "Riverside Infirmary" if hname == "" & temp_hospital == "Riverside Infirmary" 
	replace hname = "Roanoke Rapids Hospital" if hname == "" & temp_hospital == "Roanoke Rapids Hospital" | temp_hospital == "Roanoke Rapids Hosp."
	replace hname = "Roanoke-Chowan Hospital" if hname == "" & temp_hospital == "Roanoke-Chowan Hospital" 
	replace hname = "Roaring Gap Baby Hospital" if hname == "" & temp_hospital == "Roaring Gap Baby Hospital" | temp_hospital == "Roaring Gap Baby Hosp."
	replace hname = "Robeson County Memorial Hospital" if hname == "" & temp_hospital == "Robeson County Memorial Hospital" 
	replace hname = "Rocky Mount Sanitarium" if hname == "" & temp_hospital == "Rocky Mount Sanitarium" | temp_hospital == "Rocky Mount Sanit."
	replace hname = "Roper Hospital" if hname == "" & temp_hospital == "Roper Hospital" 
	replace hname = "Rowan General Hospital" if hname == "" & temp_hospital == "Rowan General Hospital" | temp_hospital == "Rowan Memorial Hospital"
	replace hname = "Roye Cottage Sanitarium" if hname == "" & temp_hospital == "Roye Cottage Sanitarium" | temp_hospital == "Roye Cottage"
	replace hname = "Royster Medical Center" if hname == "" & temp_hospital == "Royster Medical Center" 
	replace hname = "Rutherford Hospital" if hname == "" & temp_hospital == "Rutherford Hospital" |  temp_hospital == "Rutherfordton Hospital"
	replace hname = "Salisbury Hospital" if hname == "" & temp_hospital == "Salisbury Hospital" 
	replace hname = "Salvation Army Home and Hospital" if hname == "" & temp_hospital == "Salvation Army Home and Hospital" 
	replace hname = "Sampson County Memorial Hospital" if hname == "" & temp_hospital == "Sampson County Memorial Hospital" 
	replace hname = "Sandhill Public Health Hospital" if hname == "" & temp_hospital == "Sandhill Public Health Hosp." 
	replace hname = "Sarah Elizabeth Hospital" if hname == "" & temp_hospital == "Sarah Elizabeth Hospital" 
	replace hname = "Saunders Memorial Hospital" if hname == "" & temp_hospital == "Saunders Memorial Hospital" | temp_hospital == "Saunders' Memorial Hosp." | temp_hospital == "Saunders Memorial Hosp." | temp_hospital == "Saunders Mem. Hosp."
	replace hname = "Scotland County Memorial Hospital" if hname == "" & temp_hospital == "Scotland County Memorial Hospital" 
	replace hname = "Scott Hospital" if hname == "" & temp_hospital == "Scott Hospital" 
	replace hname = "Scott Parker Sanatorium" if hname == "" & temp_hospital == "Scott Parker Sanatorium" 
	replace hname = "Shelby Hospital" if hname == "" & temp_hospital == "Shelby Hospital" 
	replace hname = "Sherwood Sanatorium" if hname == "" & temp_hospital == "Sherwood Sanatorium" | temp_hospital == "The Sherwood Sanatorium"
	replace hname = "Shriners Hospital for Crippled Children" if hname == "" & temp_hospital == "Shriners Hospital for Crippled Children" | temp_hospital == "Shriners' Hospital for Crippled Children"
	replace hname = "Smith-White Sanatorium" if hname == "" & temp_hospital == "Smith-White Sanat. (col.)" | temp_hospital == "Smith-White Sanat. (Col.)"
	replace hname = "Smithfield Hospital" if hname == "" & temp_hospital == "Smithfield Hospital" 
	replace hname = "South Carolina Baptist Hospital" if hname == "" & temp_hospital == "South Carolina Baptist Hospital" | temp_hospital == "South Carolina Baptist Hosp."
	replace hname = "South Carolina Penitentiary Hospital" if hname == "" & temp_hospital == "South Carolina Penitentiary Hospital" 
	replace hname = "South Carolina Public Health Hospital" if hname == "" & temp_hospital == "South Carolina Public Health Hospital" 
	replace hname = "South Carolina Sanatorium" if hname == "" & temp_hospital == "South Carolina Sanatorium" | temp_hospital == "South Carolina Sanatorium (T.B.)" | temp_hospital == "South Carolina Sanat." | temp_hospital == "South Carolina Sanat"
	replace hname = "South Carolina State Hospital" if hname == "" & temp_hospital == "South Carolina State Hospital" | temp_hospital == "South Carolina State Hos." | temp_hospital == "South Carolina State Hosp." 
	replace hname = "South Carolina University Infirmary" if hname == "" & temp_hospital == "South Carolina University Infirmary" 
	replace hname = "Spartanburg Baby Hospital" if hname == "" & temp_hospital == "Spartanburg Baby Hospital" | temp_hospital == "Spartanburg Baby Hosp."
	replace hname = "Spartanburg General Hospital" if hname == "" & temp_hospital == "Spartanburg Gen. Hosp." | temp_hospital == "Spartanburg General Hosp." | temp_hospital == "Spartanburg General Hospital"
	replace hname = "Spartanburg Hospital" if hname == "" & temp_hospital == "Spartanburg Hospital" 
	replace hname = "Spartanburg County Hospital for Colored" if hname == "" & temp_hospital == "Spartanburg County Hospital for Colored" 
	replace hname = "Spartanburg Tuberculosis Hospital" if hname == "" & temp_hospital == "Spartanburg Tuberculosis Hospital" 
	replace hname = "Speight-Stone-Bunn Clinic-Hospital" if hname == "" & temp_hospital == "Speight-Stone-Bunn Clinic-Hospital" | temp_hospital == "Speight-Stone-Bunn Clinic Hospital" | temp_hospital == "Speight-Stone-Bell Clinic-Hospital" | temp_hospital == "Speight-Stone-Bell Clinic and Hospital" | temp_hospital == "Speight-Stone-Bell Clinic Hospital" | temp_hospital == "Speight-Stone-Bell Clinic"
	replace hname = "Spicer's Sanatorium" if hname == "" & temp_hospital == "Spicer's Sanatorium" 
	replace hname = "Spring Garden Sanitarium" if hname == "" & temp_hospital == "Spring Garden Sanitarium" 
	replace hname = "St. Agnes Hospital" if hname == "" & temp_hospital == "St. Agnes Hospital" | temp_hospital == "St. Agnes' Hospital (col.)" | temp_hospital == "St. Agnes' Hospital" | temp_hospital == "St. Agnes' Hosp. (col.)" | temp_hospital == "St. Agnes Hospital (col.)" | temp_hospital == "St. Agnes Hosp. (col.)"
	replace hname = "St. Eugene Hospital" if hname == "" & temp_hospital == "St. Eugene Hospital"     
	replace hname = "St. Francis Hospital" if hname == "" & temp_hospital == "St. Francis Hospital" 
	replace hname = "St. Francis Xavier Infirmary" if hname == "" & temp_hospital == "St. Francis Xavier Infirmary" | temp_hospital == "St. Francis Xavier Infirm." | temp_hospital == "St. Francis Xavier Infirm"     
	replace hname = "St. Joseph's Hospital" if hname == "" & temp_hospital == "St. Joseph's Hospital" | temp_hospital == "St. Joseph's Sanatorium (T.B.)" | temp_hospital == "St. Joseph's Sanatorium" | temp_hospital == "St. Joseph's Hospital (Converted into a general hospital, 1939)"
	replace hname = "St. Leo's Hospital" if hname == "" & temp_hospital == "St. Leo's Hospital"     
	replace hname = "St. Luke's Hospital" if hname == "" & temp_hospital == "St. Luke's Hospital" & City == "New Bern" & State == "NC"
	replace hname = "St. Luke's Hospital" if hname == "" & temp_hospital == "St. Luke's Hospital" & City == "Tryon" & State == "NC"     
	replace hname = "St. Luke's Hospital" if hname == "" & temp_hospital == "St. Luke's Hospital" & City == "Greenville" & State == "SC" 
	replace hname = "St. Mary's Hospital" if hname == "" & temp_hospital == "St. Mary's Hospital"     
	replace hname = "St. Peter's Hospital" if hname == "" & temp_hospital == "St. Peter's Hospital" 
	replace hname = "St. Philip's Mercy Hospital" if hname == "" & temp_hospital == "St. Philip's Mercy Hospital" | temp_hospital == "St. Philip's Mercy Hosp."     
	replace hname = "Stanly General Hospital" if hname == "" & temp_hospital == "Stanly General Hospital" 
	replace hname = "Stanly County Hospital" if hname == "" & temp_hospital == "Stanly County Hospital"     
	replace hname = "State Home and Industrial School for Girls" if hname == "" & temp_hospital == "State Home and Industrial School for Girls" 
	replace hname = "State Hospital for Insane" if hname == "" & (temp_hospital == "State Hospital" | temp_hospital == "State Hospital for Insane") & City == "Morganton" & State == "NC"    
	replace hname = "State Hospital" if hname == "" & temp_hospital == "State Hospital" & City == "Raleigh" & State == "NC" 
	replace hname = "State Hospital" if hname == "" & (temp_hospital == "State Hospital" | temp_hospital == "State Hospital (col.)" | temp_hospital == "State Hospital at Goldsboro" | temp_hospital == "State Hospital at Goldsboro (col.)") & City == "Goldsboro" & State == "NC"    
	replace hname = "State Hospital" if hname == "" & temp_hospital == "State Hospital" & City == "Butner" & State == "NC"
	replace hname = "State Training School" if hname == "" & temp_hospital == "State Training School"     
	replace hname = "Station Hospital" if hname == "" & (temp_hospital == "Station Hospital" | temp_hospital == "U. S. Army Hospital" | temp_hospital == "Regional Hospital") & City == "Fort Bragg" & State == "NC" 
	replace hname = "Station Hospital" if hname == "" & temp_hospital == "Station Hospital"  & City == "Moultrieville" & State == "SC" 
	replace hname = "Station Hospital" if hname == "" & (temp_hospital == "Station Hospital" | temp_hospital == "U. S. Army Hospital")  & City == "Fort Jackson" & State == "SC" 
	replace hname = "Station Hospital" if hname == "" & temp_hospital == "Station Hospital"  & City == "Greenville" & State == "SC" 
	replace hname = "Steedly Hospital" if hname == "" & temp_hospital == "Steedly Hospital"   
	replace hname = "Sternberger Hospital for Women and Children" if hname == "" & temp_hospital == "Sternberger Hospital for Women and Children" | temp_hospital == "Sternberger Hosp. for Women and Children" | temp_hospital == "Sternberger Children's Hospital" |  temp_hospital == "Sternberger Children's Hosp." | temp_hospital == "Sternberger Children's Hos."   
	replace hname = "Stokes Clinic Hospital" if hname == "" & temp_hospital == "Stokes Clinic Hospital"   
	replace hname = "Stone-Bell-Way-Robertson Clinic-Hospital" if hname == "" & temp_hospital == "Stone-Bell-Way-Robertson Clinic-Hospital"   
	replace hname = "Stonehedge Sanatorium" if hname == "" & temp_hospital == "Stonehedge Sanitarium" | temp_hospital == "Stonehedge Sanitarium (T.B.)"   
	replace hname = "Strawberry Hill Sanatorium" if hname == "" & temp_hospital == "Strawberry Hill Sanat. (T.B.)"   
	replace hname = "Summerville Infirmary" if hname == "" & temp_hospital == "Summerville Infirmary"   
	replace hname = "Sunset Heights Sanatorium" if hname == "" & temp_hospital == "Sunset Heights Sanitarium" | temp_hospital == "Sunset Heights, Inc. (T.B.)" | temp_hospital == "Sunset Heights"   
	replace hname = "Sunset Lodge Sanatorium" if hname == "" & temp_hospital == "Sunset Lodge" | temp_hospital == "Sunset Lodge (T.B.)"   
	replace hname = "Susie Clayton Cheatham Memorial Hospital" if hname == "" & temp_hospital == "Susie Clayton Cheatham Memorial Hospital" | temp_hospital == "Susie Clayton Cheatham Memorial Hospital (col.)" | temp_hospital == "Susie Clay Cheatham Memorial Hospital (col.)" | temp_hospital == "Susie Clay Cheatham Mem. Hosp. (col.)"  
	replace hname = "Swananoa Hill Sanatorium" if hname == "" & temp_hospital == "Swananoa Hill Sanitarium (T.B)"   
	replace hname = "Tally-Brunson Hospital" if hname == "" & temp_hospital == "Tally-Brunson Hospital"   
	replace hname = "Tayloe Hospital" if hname == "" & temp_hospital == "Tayloe Hospital"   
	replace hname = "Thomasville Baptist Orphanage Infirmary" if hname == "" & temp_hospital == "Thomasville Baptist Orphanage Infirmary"   
	replace hname = "Thompson Orphanage and Training Institution" if hname == "" & temp_hospital == "Thompson Orphanage and Training Institution"   
	replace hname = "Transylvania Community Hospital" if hname == "" & temp_hospital == "Transylvania Community Hospital"   
	replace hname = "Transylvania Hospital" if hname == "" & temp_hospital == "Transylvania Hospital"   
	replace hname = "Trivette Clinic" if hname == "" & temp_hospital == "Trivette Clinic"   
	replace hname = "Tryon Infirmary" if hname == "" & temp_hospital == "Tryon Infirmary"   
	replace hname = "Tuomey Hospital" if hname == "" & temp_hospital == "Tuomey Hospital" | temp_hospital == "Toumey Hospital"      
	replace hname = "U. S. Marine Corps Air Station Dispensary" if hname == "" & (temp_hospital == "U. S. Marine Corps Air Station Dispensary" | temp_hospital == "U. S. Marine Corps Air Station Infirmary") & City == "Cherry Point" & State == "NC"   
	replace hname = "U. S. Army Hospital" if hname == "" & temp_hospital == "U. S. Army Hospital"   
	replace hname = "U. S. Naval Air Station Dispensary" if hname == "" & (temp_hospital == "U. S. Naval Air Station Dispensary" | temp_hospital == "U. S. Naval Dispensary") & City == "Chapel Hill" & State == "NC"  
	replace hname = "U. S. Naval Air Station Dispensary" if hname == "" & temp_hospital == "U. S. Naval Air Station Dispensary" & City == "Beaufort" & State == "SC"
	replace hname = "U. S. Naval Convalescent Hospital" if hname == "" & temp_hospital == "U. S. Naval Convalescent Hospital"   
	replace hname = "U. S. Naval Hospital" if hname == "" & temp_hospital == "U. S. Naval Hospital" | temp_hospital == "U.S. Naval Hospital" | temp_hospital == "United States Naval Hosp." | temp_hospital == "United States Naval Hospital"  
	replace hname = "U. S. Public Health Service Medical Center" if hname == "" & temp_hospital == "U. S. Public Health Service Medical Center"   
	replace hname = "U. S. Veterans' Hosp. No. 60" if hname == "" & (temp_hospital == "Veterans Admin. Facility" | temp_hospital == "Veterans Admin. Hospital" | temp_hospital == "U. S. Veterans' Hosp. No. 60" | temp_hospital == "U. S. Veter. Hosp. No. 60" | temp_hospital == "United States Veterans' Hospital, No. 60" | temp_hospital == "United States Veterans' Hospital No. 60") & City == "Oteen" & State == "NC"   
	replace hname = "University Infirmary" if hname == "" & temp_hospital == "University Infirmary"   
	replace hname = "University Sanitarium" if hname == "" & temp_hospital == "University Sanitarium"   
	replace hname = "Urological Institute" if hname == "" & temp_hospital == "Urological Institute"   
	replace hname = "Valdese General Hospital" if hname == "" & temp_hospital == "Valdese General Hospital"   
	replace hname = "Vance County Hospital" if hname == "" & temp_hospital == "Vance County Hospital"   
	replace hname = "Veterans Administrative Hospital" if hname == "" & (temp_hospital == "Veterans Admin. Hospital" | temp_hospital == "Veterans Admin. Facility" | temp_hospital == "Veterans Admin. Center")
	replace hname = "Veterans Administrative Hospital" if hname == "" & (temp_hospital == "Veterans Admin. Facility" | temp_hospital == "Veterans Admin. Center") & City == "Columbia" & State == "SC" 
	replace hname = "Victoria Hospital" if hname == "" & temp_hospital == "Victoria Hospital"   
	replace hname = "Violet Hill Sanatorium" if hname == "" & temp_hospital == "Violet Hill Sanatorium" | temp_hospital == "Violet Hill Sanatorium (T.B.)"   
	replace hname = "Wake County Home Hospital" if hname == "" & temp_hospital == "Wake County Home Hospital" | temp_hospital == "Wake County Home Hosp."  
	replace hname = "Wake County Sanatorium" if hname == "" & temp_hospital == "Wake County Sanatorium" |  temp_hospital == "Wake County Tuberculosis Hospital" | temp_hospital == "Wake County Tuberculosis Sanatorium " | temp_hospital == "Wake County Tuberculosis Sanatorium"  
	replace hname = "Wake Forest College Hospital" if hname == "" & temp_hospital == "Wake Forest College Hosp." | temp_hospital == "Wake Forest College Infirmary"  
	replace hname = "Wallace Thompson Hospital" if hname == "" & temp_hospital == "Wallace Thompson Hospital" | temp_hospital == "Wallace Thomson Hospital" | temp_hospital == "Wallace Thomson Hosp." | temp_hospital == "Wallace Thompson Hosp."  
	replace hname = "Wallace Thomson Infirmary" if hname == "" & temp_hospital == "Wallace Thomson Infirmary"   
	replace hname = "Washington County Hospital" if hname == "" & temp_hospital == "Washington County Hospital"   
	replace hname = "Washington Hospital" if hname == "" & temp_hospital == "Washington Hospital"   
	replace hname = "Watauga Hospital" if hname == "" & temp_hospital == "Watauga Hospital"   
	replace hname = "Watts Hospital" if hname == "" & temp_hospital == "Watts Hospital" | temp_hospital == "Watts' Hospital"   
	replace hname = "Waverley Sanatorium" if hname == "" & temp_hospital == "Waverley Sanitarium" |  temp_hospital == "Waveley Sanitarium" | temp_hospital == "Waverley Sanitarium (N. & M.)" 
	replace hname = "Waverley Hospital" if hname == "" & temp_hospital == "Waverley Hospital" | temp_hospital == "Waverly Fraternal Hospital (col.)" | temp_hospital == "Waverly Fraternal Hosp. (col.)" | temp_hospital == "Waverley Fraternal Hospital (col.)" | temp_hospital == "Waverley Hospital (col.)"  
	replace hname = "Wayne County Memorial Hospital" if hname == "" & temp_hospital == "Wayne County Memorial Hospital" | temp_hospital == "Wayne County Memorial Hosp."   
	replace hname = "Waynesville Hospital" if hname == "" & temp_hospital == "Waynesville Hospital"   
	replace hname = "Webb Memorial Infirmary" if hname == "" & temp_hospital == "Webb Memorial Infirmary"   
	replace hname = "Weinstein Clinic Hospital" if hname == "" & temp_hospital == "Weinstein Clinic Hospital"  
	replace hname = "Wesley Long Hospital" if hname == "" & temp_hospital == "Wesley Long Hospital"   
	replace hname = "Wesnoca" if hname == "" & temp_hospital == "Wesnoca"  
	replace hname = "West Harper Clinic-Hospital" if hname == "" & temp_hospital == "West Harper Clinic-Hospital" | temp_hospital == "West Harper Clinic Hosp."   
	replace hname = "Western Medical Center" if hname == "" & temp_hospital == "Western Medical Center"  
	replace hname = "Western North Carolina Sanatorium" if hname == "" & temp_hospital == "Western North Carolina Sanatorium"   
	replace hname = "Wheathead-Stokes Sanatorium" if hname == "" & temp_hospital == "Wheathead-Stokes Sanatorium"  
	replace hname = "Whispering Cedars Rest Home" if hname == "" & temp_hospital == "Whispering Cedars Rest Home"   
	replace hname = "Whitehead Infirmary" if hname == "" & temp_hospital == "Whitehead Infirmary"  
	replace hname = "Wilkes Hospital" if hname == "" & temp_hospital == "Wilkes Hospital" | temp_hospital == "The Wilkes Hospital"   
	replace hname = "Wilkes County Tuberculosis Hospital" if hname == "" & temp_hospital == "Wilkes County Tuberculosis Hospital" | temp_hospital == "Wilkes County Tuberculosis Hut." | temp_hospital == "Wilkes County Tuberculosis Hut" | temp_hospital == "Wilkes County Tuber. Hut." |  temp_hospital == "Wilkes County Tuber. Hut"   
	replace hname = "William J. Hicks Memorial Hospital" if hname == "" & temp_hospital == "William J. Hicks Memorial Hospital" | temp_hospital == "Wm. J. Hicks Mem. Hosp." | temp_hospital == "Wm. J. Hicks Memorial Hosp." 
	replace hname = "Williams Clinic Hospital" if hname == "" & temp_hospital == "Williams Clinic Hospital"  
	replace hname = "Williams Clinic-Hospital" if hname == "" & temp_hospital == "Williams Clinic-Hospital"  
	replace hname = "Williams Private Sanitarium" if hname == "" & temp_hospital == "Williams Private Sanitarium"  
	replace hname = "Wilson Hospital and Tubercular Home" if hname == "" & temp_hospital == "Wilson Hospital and Tubercular Home" | temp_hospital == "Wilson Hospital and Tuberc. Home" | temp_hospital == "Wilson Colored Hospital (col.)"
	replace hname = "Wilson County Tuberculosis Sanatorium" if hname == "" & temp_hospital == "Wilson County Tuberculosis Sanatorium"  
	replace hname = "Winyah Sanatorium" if hname == "" & temp_hospital == "Winyah Sanatorium" | temp_hospital == "Winyah Sanatorium (T.B.)" | temp_hospital == "Winyah Sanatorium operated by Von Ruck Memorial Sanatorium, Inc. (T.B.)"  
	replace hname = "Woffard Infirmary" if hname == "" & temp_hospital == "Woffard Infirmary"  
	replace hname = "Woodard-Herring Hospital" if hname == "" & temp_hospital == "Woodard-Herring Hospital" | temp_hospital == "Woodard-Herring Hosp."  
	replace hname = "Working Benevolent Hospital" if hname == "" & temp_hospital == "Working Benevolent Hospital" | temp_hospital == "Working Benevolent Society Hospital (col.)" | temp_hospital == "Working Benevolent Hospital (col.)" | temp_hospital == "Working Benevolent Hosp. (col.)" | temp_hospital == "Working Benevolent Hosp." 
	replace hname = "Workman Memorial Hospital" if hname == "" & temp_hospital == "Workman Memorial Hospital" | temp_hospital == "Workman Memorial Hosp."  
	replace hname = "Yadkin Hospital" if hname == "" & temp_hospital == "Yadkin Hospital"  
	replace hname = "York County Hospital" if hname == "" & temp_hospital == "York County Hospital"  
	replace hname = "Zephyr Hill Sanatorium" if hname == "" & temp_hospital == "Zephyr Hill Sanatorium" | temp_hospital == "Zephyr Hill Sanatorium (T.B.)" 

	drop if Year == 1942 & State == "SC" & totalbeds == 90 & Control == "Public" // Check why we drop this

	replace City = "Greenwood" if hname == "Connie Maxwell Orphanage" & State == "SC" & Year == 1931
	replace County = "Greenwood" if hname == "Connie Maxwell Orphanage" & State == "SC" & Year == 1931

	replace County = "Hoke" if City == "Sanatorium" & (Year == 1928 | Year == 1929)

	// Each year's report refers to statistics from previous year
	replace Year = Year - 1 
	drop temp_hospital hospitalname
	rename hname institution
	
	rename Year year
	rename State state
	rename County county
	rename City location
	rename Service hosp_type
	rename Control hosp_control
	
	// Final location and county cleaning to standardize with Duke locations
	replace location = "White Rock" if location == "Whiterock"
	replace location = "Wrightsville" if regexm(location, "Wrightsville")
	
	replace county = "Nash" if location == "Rocky Mount"
	
	replace state = "North Carolina" if state == "NC"
	replace state = "South Carolina" if state == "SC"
	
	replace state = "37" if state == "North Carolina"
	replace state = "45" if state == "South Carolina"
	
	assert state == "37" | state == "45"
	destring state, replace 
	rename state statefip 
	
	// Merge with NHGIS county information
	gen county_nhgis = upper(county)
	merge m:1 statefip county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties_carolinas.dta", assert(2 3) keep(3) nogen
	drop county 
	
	la var location "City"
	la var county_nhgis "County"
	la var hosp_type "Type of hospital"
	la var hosp_control "Controlling entity"
	
	gisid fips hosp_id location institution year, missok 
	gsort fips hosp_id location institution year
	compress
	desc, f
	
	save "$PROJ_PATH/analysis/processed/data/ama/ama_carolina_hospitals_1920-1950.dta", replace
	
}


***********************************
// Standardize hospital names *****
***********************************

if `hosp_name' {

	use hosp_id institution year fips location statefip using "$PROJ_PATH/analysis/processed/data/ama/ama_carolina_hospitals_1920-1950.dta", clear
	tab year
	replace location = "Biltmore" if institution == "Biltmore Hospital" // Move earlier 
	gduplicates drop
	keep if hosp_id != .
	tempfile aha
	save `aha', replace
	
	use hosp_id hospital year fips location statefip using "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta" if year <= 1950, clear
	rename hospital institution 
	gduplicates drop
	keep if hosp_id != .
	gen duke_cap = 1
	tempfile duke_cap
	save `duke_cap', replace
	
	use hosp_id institution year fips location statefip using "$PROJ_PATH/analysis/processed/data/duke/labc_hospital_locations_cleaned.dta" if year <= 1950, clear
	duplicates drop
	keep if hosp_id != .
	gen duke_free = 1

	merge m:1 hosp_id year fips location statefip using `duke_cap', nogen
	
	rename institution raw_name
	merge m:1 hosp_id year fips location statefip using `aha'
	
	replace institution = raw_name if _merge == 1
	drop raw_name
	
	gen aha = (_merge == 2 | _merge == 3)
	drop _merge
	
	recode duke_cap duke_free aha (mis = 0)
	order aha duke_*, last
	
	gduplicates drop 
	gisid hosp_id year
	gsort hosp_id year
	bysort hosp_id (year): replace institution = institution[_n-1] if aha == 0 & aha[_n-1] == 1
	
	gsort + hosp_id - year
	by hosp_id: replace institution = institution[_n-1] if aha == 0 & aha[_n-1] == 1
	
	replace institution = "Juvenile Relief Association of Winston-Salem Home" if institution == "Juvenile Relief Association" | institution == "Juvenile Relief Home"
	replace institution = "Junior League Hospital for Incurables" if institution == "Junior League Hospital For Incurables"
	
	gsort hosp_id year
	
	drop aha duke*
	
	egen min_year = min(year), by(hosp_id)
	egen max_year = max(year), by(hosp_id)
	
	drop year
	gduplicates drop
	
	bysort hosp_id: gen flag_multiple_names = (_N > 1)
	tab flag_multiple_names
	
	la var flag_multiple_names "Multiple hospital names per ID"
	la var hosp_id "Unique hospital ID"
	la var institution "Standardized hospital name"
	la var min_year "First year for ID"
	la var max_year "Last year for ID"
	
	gisid fips location min_year hosp_id institution
	gsort fips location min_year hosp_id institution
	compress
	desc
	
	duplicates tag hosp_id, gen(d) /* This flags institutions that have the same hospital ID but different names */
	
	save "$PROJ_PATH/analysis/processed/data/crosswalks/hosp_id_name_year_xwk.dta", replace
	
}
 
 
 
******************************************
// Process first-stage hospital data *****
******************************************

if `first_stage' {
	
	// Get hospital ID to FIPS crosswalks
	use "$PROJ_PATH/analysis/processed/data/crosswalks/hosp_id_name_year_xwk.dta", clear
	drop institution
	gduplicates drop
	keep statefip fips location hosp_id
	tempfile hosp_id_fips_xwk
	save `hosp_id_fips_xwk', replace


	// Create location to FIPS crosswalks 
	keep location fips 
	gduplicates drop
	gunique location
	gsort location 
	tempfile location_fips_xwk
	save `location_fips_xwk', replace


	// Get largest hospital ID and start new sequence
	use "$PROJ_PATH/analysis/processed/data/crosswalks/hosp_id_name_year_xwk.dta", clear
	sum hosp_id

	local first_new_id = floor((r(max) + 10000)/10000)*10000
	di "`first_new_id'"


	// Load African American hospitals from Pollitt
	use "$PROJ_PATH/analysis/processed/intermediate/hospitals/pollitt_nc_african_american_hospitals.dta", clear

	// Clear open and close dates (Assume closure in middle of decade if only decade known)
	replace yearclosed = regexr(yearclosed,"mid-","")
	replace yearclosed = regexr(yearclosed,"circa ","")
	replace yearclosed = regexr(yearclosed,"0s","5")
	replace yearopen = regexr(yearopen,"circa ","")

	destring yearopen yearclosed, replace

	// Drop if closed before or open after sample period
	drop if yearclosed < 1920 | yearopen > 1942

	// Drop specialty hospitals 
	drop if regexm(lower(nameofhospital),"psychiatric") | regexm(lower(nameofhospital),"clinic") | regexm(lower(nameofhospital),"sanitarium") | regexm(lower(nameofhospital),"sanatorium") | regexm(lower(nameofhospital),"orthopedic")

	// Drop branches 
	drop if regexm(lower(nameofhospital),"branch")

	// Clean location
	replace town = "Wilson" if town == "WIlson"

	// Clean hospital name 
	replace nameofhospital = "Gaston County Negro Hospital" if nameofhospital == "Gaston County Colored Hospital"
	replace nameofhospital = "Kate Bitting Reynolds Memorial Hospital" if nameofhospital == "Kate B. Reynolds Memorial Hospital"
	replace nameofhospital = "Susie Clayton Cheatham Memorial Hospital" if nameofhospital == "Susie Cheatham Memorial Hospital"
	replace nameofhospital = "Furlonge's General Hospital" if nameofhospital == "Dr. Furlonge's Hospital"
	replace nameofhospital = "Wilson Hospital and Tubercular Home" if nameofhospital == "Mercy Hospital and Tubercular Home" | nameofhospital == "Wilson Colored Hospital"

	keep nameofhospital town yearopen yearclosed 

	rename nameofhospital institution
	rename town location 

	gen pollitt = 1
	append using "$PROJ_PATH/analysis/processed/data/crosswalks/hosp_id_name_year_xwk.dta"
	compress 

	replace location = upper(location)
	replace institution = upper(institution)

	gsort location institution fips 
	gunique location institution

	// Group strings based on Levenshtein edit distance
		gen no_spaces = subinstr(institution," ","",.)
		gen name_15_characters = substr(no_spaces,1,15)

		by location: strgroup name_15_characters, generate(hosp_group) threshold(0.1)

		gsort hosp_group location hosp_id institution

		egen tot_coded = max(!missing(hosp_id)), by(hosp_group)
		egen tot_uncod = max(missing(hosp_id)), by(hosp_group)

		by hosp_group: carryforward hosp_id statefip fips hosp_id min_year max_year flag_* d, replace 
		drop hosp_group tot_coded tot_uncod no_spaces name_15_characters 

	keep if !missing(hosp_id) & pollitt == 1

	drop min_year max_year flag_* d pollitt

	keep hosp_id yearopen yearclosed
	egen aa_hosp_open = min(yearopen), by(hosp_id)
	egen aa_hosp_closed = min(yearclosed), by(hosp_id)
	drop year*
	gduplicates drop

	tempfile aa_hosp
	save `aa_hosp', replace


	// Load new hospital data which includes years before 1927 
	use "$PROJ_PATH/analysis/processed/intermediate/hospitals/aha_amd_hospitals_combined.dta" if year <= 1926, clear

	// We only need NC
	keep if consistent_state == "NORTH CAROLINA" 

	// Some years are from AMA 
	tab source if year == 1920 | year == 1925
	drop if year == 1920 | year == 1925

	tab year, m
	tab source, m

	rename consistent_city city 
	rename hosp_name institution 
	rename beds std_beds

	keep city institution standardized_hosp_name std_beds year 

	// Determine if ever a "long-term" facility like an orphanage or convalescent home
	gen long_term = 0 
	replace long_term = 1 if regexm(lower(institution), "orphan") 
	replace long_term = 1 if regexm(lower(institution), "ophan") 
	replace long_term = 1 if regexm(lower(institution), "lodge") 
	replace long_term = 1 if regexm(lower(institution), "home") 

	tempfile clean_amd_hosp 
	save `clean_amd_hosp', replace


	// Load raw AMD hospital data 
	local year_list "1906 1909 1912 1916 1918 1921 1923"
	local another_year_list "1925 1927 1929 1931 1934 1936 1938 1940 1942"

	clear
	foreach y of local year_list {
		append using "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/Final_AMD_`y'.dta"
	}

	append using "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/amd_state_and_federal_institutions.dta"

	foreach z of local another_year_list {
		append using "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/Final_AMD_`z'.dta"
	}

	desc, f

	tab state, m 
	keep if state == "North Carolina"

	tab year, m

	// Create hospital type 
	gen hosp_type = ""

	tab publicorprivate, m
	tab type, m

	replace hosp_type = "General" if regexm(lower(publicorprivate), "general") | regexm(lower(type), "general")

	tab tuberculosisorcontagious, m
	tab tuberculosisorcontagious if hosp_type == "General", m

	tab patients, m

	replace hosp_type = "TB" if tuberculosisorcontagious == "Tuberculosis" | regexm(lower(hospitalname),"tuberc") | regexm(lower(hospitalname),"sanatorium") | regexm(lower(hospitalname),"sanitarium") | type == "TB" | regexm(lower(type),"tuberculosis") | regexm(lower(patients),"tuberculosis")

	replace hosp_type = "Specialty" if missing(hosp_type) & ( ///
										!missing(patients) | regexm(lower(type),"maternity") | regexm(lower(departmentorschool),"school infirmary") )

	tab hosp_type, m
										
	// Clean hospital control 
	gen hosp_control = ""

	tab publicorprivate, m 

	replace hosp_control = 	"Public" if regexm(lower(publicorprivate), "federal") | regexm(lower(publicorprivate), "public") | ///
										regexm(lower(publicorprivate), "city") | regexm(lower(publicorprivate), "county") | ///
										regexm(lower(publicorprivate), "municipal") | regexm(lower(publicorprivate), "state")

	tab publicorprivate if missing(hosp_control)
										
	tab control, m

	replace hosp_control = "Industrial" if regexm(lower(control), "industrial")
	replace hosp_control = "Church" if regexm(lower(control), "church") | regexm(lower(control), "adventist") | regexm(lower(control), "sisters") | regexm(lower(control), "methodist") | regexm(lower(control), "episcopal") | regexm(lower(control), "daughters")
	replace hosp_control = "Non-profit" if regexm(lower(control),"nonprofit association") | regexm(lower(control),"association") | regexm(lower(control),"assn\.") | regexm(lower(control),"frat") | regexm(lower(control),"lodge") 
	replace hosp_control = "Proprietary" if control == "individual" | control == "partnership" | regexm(lower(control),"corp") | regexm(lower(control),"co\.$") | regexm(lower(control),"drs\.") | publicorprivate == "corporation"

	tab control if missing(hosp_control)

	// Determine if ever a "long-term" facility like an orphanage or convalescent home
	gen long_term = 0 
	replace long_term = 1 if regexm(lower(hospitalname), "orphan") 
	replace long_term = 1 if regexm(lower(hospitalname), "ophan") 
	replace long_term = 1 if regexm(lower(hospitalname), "lodge") 
	replace long_term = 1 if regexm(lower(hospitalname), "home") 

	replace hosp_control = "Church" if regexm(lower(control), "church")

	destring yearestablished, replace 

	// Flag observations with two bed totals listed 
	gen flag_two_bed_counts = regexm(beds,",")

	// If two numbers are listed, first number is any beds and second number is hospital beds
	tab beds if regexm(beds,"[^0-9]")
	split beds, parse(", ") gen(beds_)
	destring beds_1 beds_2, replace 

	gen tot_beds = beds_2 if !missing(beds_2)
	replace tot_beds = beds_1 if missing(tot_beds)
	gen any_beds = beds_1 if !missing(beds_2) // Keep all beds if hospital beds also reported 
	drop beds beds_*

	// Flag Black hospitals
	gen black_hospital = 1 if regexm(lower(hospitalname), "colored") | regexm(lower(hospitalname), "col\.") | regexm(lower(patients), "colored")

	keep year state city hospitalname yearestablished hosp_type hosp_control tot_beds black_hospital any_beds flag_two_bed_counts 

	rename hospitalname institution 
	rename yearestablished est_year 

	replace institution = subinstr(institution,`"""',"",.)
	replace institution = ustrtrim(institution)

	replace city = upper(city)
	replace institution = upper(institution)
	replace state = upper(state)

	// Manual fixes to city names to match cleaned AMD data from Peter Nencka
	replace city = "FAYETTEVILLE" if city == "FAYETTVILLE"
	replace city = "NEW BERN" if city == "NEWBERN" | city == "NEWBORN"
	replace city = "SPENCER" if city == "SPENEER"
	replace city = "LINCOLNTON" if city == "LINCOINTON"
	replace city = "MOUNT AIRY" if city == "MT. AIRY"
	replace city = "WHITEROCK" if city == "WHITE ROCK"
	replace city = "ASHEBORO" if city == "ASHBORO"
	replace city = "BILTMORE" if regexm(city,"BILTMORE")

	merge 1:1 year city institution using `clean_amd_hosp', assert(1 3) 

	replace std_beds = tot_beds if _merge == 1
	replace standardized_hosp_name = institution if _merge == 1
	drop _merge 

	drop institution 
	rename standardized_hosp_name institution

	gsort + city + institution - year
	by city institution: carryforward hosp_type hosp_control black_hospital long_term, replace
	gsort + city + institution + year
	by city institution: carryforward hosp_type hosp_control black_hospital long_term, replace

	rename city location 

	// Manual fix: First number is beds, second number is TB beds 
	replace tot_beds = 16 if year == 1923 & institution == "WILSON HOSPITAL AND TUBERCULAR HOME"
	assert tot_beds == std_beds
	drop std_beds 

	gsort year location institution
	order year state location institution est_year hosp_type hosp_control tot_beds black_hospital long_term

	rename state consistent_state
	rename location consistent_city
	rename institution standardized_hosp_name
	rename tot_beds beds

	// These data are from the American Medical Directory (AMD) not JAMA/AMA/AHA
	gen source = "AMD"

	// We only need NC
	keep if consistent_state == "NORTH CAROLINA" 

	// Manual corrections to hospital names
	gen location = consistent_city 
	gen institution = standardized_hosp_name 

	replace institution = regexr(institution,"^THE ","")
	replace institution = regexr(institution," INC\.$","")

	replace institution = "BAKER-THOMPSON MEMORIAL HOSPITAL" if institution == "THOMPSON HOSPITAL" & location == "LUMBERTON"
	replace institution = "CITY HOSPITAL" if institution == "TWIN-CITY HOSPITAL" & location == "WINSTON-SALEM" // ??
	replace institution = "DAVIS HOSPITAL" if institution == "CARPENTER-DAVIS HOSPITAL" & location == "STATESVILLE"
	replace institution = "FAIRVIEW HOSPITAL" if institution == "FAIRVIEW NEWBERN HOSPITAL" & location == "NEW BERN"
	replace institution = "FOWLE MEMORIAL HOSPITAL" if (institution == "FOWLE, S. R. MEMORIAL HOSPITAL" | institution == "S. R. FOWLE MEMORIAL HOSPITAL") & location == "WASHINGTON"
	replace institution = "LAWRENCE CLINIC" if institution == "LAWRENCE HOSPITAL" & location == "WINSTON-SALEM"
	replace institution = "MARTIN MEMORIAL HOSPITAL" if institution == "MEMORIAL HOSPITAL" & location == "MOUNT AIRY"
	replace institution = "MERCY HOSPITAL" if institution == "MERCY GENERAL HOSPITAL" & location == "CHARLOTTE"
	replace institution = "PARROTT MEMORIAL HOSPITAL" if institution == "ROBERT BRUCE MCDANIEL MEMORIAL HOSPITAL" & location == "KINSTON"
	replace institution = "PITTMAN SANATORIUM" if institution == "PITTMAN HOSPITAL" & location == "TARBORO"
	replace institution = "SCOTLAND COUNTY MEMORIAL HOSPITAL" if institution == "SCOTLAND HOSPITAL" & location == "LAURINBURG"
	replace institution = "SMITHFIELD HOSPITAL" if institution == "SMITHFIELD MEMORIAL HOSPITAL (JOHNSTON COUNTY HOSPITAL)" & location == "SMITHFIELD"
	replace institution = "WAKE FOREST COLLEGE HOSPITAL" if institution == "WAKE FOREST HOSPITAL" & location == "WAKE FOREST"
	replace institution = "WATTS HOSPITAL" if institution == "WATTS' HOSPITAL" & location == "WEST DURHAM"

	replace institution = "FELLOWSHIP SANATORIUM OF THE ROYAL LEAGUE" if institution == "FELLOWSHIP ASSOCIATION OF THE ROYAL LEAGUE HOSPITAL"
	replace institution = "WATTS HOSPITAL" if institution == "WATT'S HOSPITAL" & location == "DURHAM"
	replace institution = "LINCOLN HOSPITAL" if institution == "LINCOLN HOSPITAL (COLORED)" & location == "DURHAM"
	replace institution = "HIGHSMITH HOSPITAL" if institution == "HIGHSMITH HOSPITAL COMPANY"
	replace institution = "PITMAN HOSPITAL" if institution == "R. L. PITTMAN HOSPITAL" & location == "FAYETTEVILLE"
	replace institution = "ANGEL BROTHERS HOSPITAL" if institution == "ANGEL HOSPITAL" & location == "FRANKLIN"
	replace institution = "LYLE HOSPITAL" if institution == "LYLE'S HOSPITAL"
	replace institution = "GOLDSBORO HOSPITAL" if institution == "GOLDSBORO CITY HOSPITAL" & location == "GOLDSBORO"
	replace institution = "GASTON COUNTY COLORED HOSPITAL" if institution == "GASTON COLORED HOSPITAL" & location == "GASTONIA"
	replace institution = "STERNBERGER HOSPITAL FOR WOMEN AND CHILDREN" if institution == "STERNBERGER CHILDREN'S HOSPITAL" & location == "GREENSBORO"
	replace institution = "PITT GENERAL HOSPITAL" if institution == "PITT COMMUNITY HOSPITAL" & location == "GREENVILLE"
	replace institution = "HALIFAX COUNTY TUBERCULOSIS SANITARIUM" if institution == "HALIFAX COUNTY HOSPITAL" & location == "HALIFAX"
	replace institution = "HALIFAX COUNTY TUBERCULOSIS SANITARIUM" if institution == "HALIFAX COUNTY TUBERCULOSIS SANITARIUM (HALIFAX COUNTY HOME)" & location == "HALIFAX"
	replace institution = "LEAKSVILLE GENERAL HOSPITAL" if institution == "LEAKSVILLE HOSPITAL" & location == "LEAKSVILLE"
	replace institution = "REEVES GAMBLE HOSPITAL" if institution == "REEVES HOSPITAL" & location == "LINCOLNTON"
	replace institution = "BAKER-THOMPSON MEMORIAL HOSPITAL" if institution == "THOMPSON MEMORIAL HOSPITAL" & location == "LUMBERTON"
	replace institution = "NEW BERN GENERAL HOSPITAL" if institution == "NEWBERN GENERAL HOSPITAL" & location == "NEW BERN"
	replace institution = "SUSIE CLAY CHEATHAM MEMORIAL HOSPITAL" if institution == "SUSIE CLAY CHEATHAM MEMORIAL HOSPITAL (COLORED)" & location == "OXFORD"
	replace institution = "ANNIE PENN MEMORIAL HOSPITAL" if institution == "MEMORIAL HOSPITAL" & location == "REIDSVILLE"
	replace institution = "PARK VIEW HOSPITAL" if institution == "PARKVIEW HOSPITAL ASSOCIATION" | location == "PARK VIEW HOSPITAL ASSOCIATION"
	replace institution = "ROWAN GENERAL HOSPITAL" if institution == "ROWAN MEMORIAL HOSPITAL" & location == "SALISBURY"
	replace institution = "EDGECOMBE GENERAL HOSPITAL" if institution == "EDGECOMB GENERAL HOSPITAL"
	replace institution = "WILSON HOSPITAL AND TUBERCULAR HOME" if institution == "WILSON COLORED HOSPITAL"
	replace institution = "LAWRENCE CLINIC" if institution == "LAWRENCE-COOKE CLINIC HOSPITAL"
	replace institution = "FORSYTH COUNTY TUBERCULOSIS HOSPITAL AND SANATORIUM" if institution == "FORSYTH COUNTY SANATORIUM"

	replace location = "BANNER ELK" if location == "BANNERS ELK"
	replace location = "DURHAM" if location == "WEST DURHAM"
	replace location = "NORTH WILKESBORO" if location == "WILKESBORO" | location == "NORTHWILKESBORO"
	replace location = "PINEHURST" if location == "SOUTHERN PINES" & institution == "MOORE COUNTY HOSPITAL"
	replace location = "WHITE ROCK" if location == "WHITEROCK"
	replace location = "WRIGHTSVILLE" if location == "WRIGHTSVILLE SOUND"
	replace location = "ERWIN" if location == "DUKE"

	desc, f
	compress

	tempfile amd_input
	save `amd_input', replace

	// Assign hospital IDs
	keep institution location
	gsort institution location
	gduplicates drop 

	append using "$PROJ_PATH/analysis/processed/data/crosswalks/hosp_id_name_year_xwk.dta"
	compress 

	replace location = upper(location)
	replace institution = upper(institution)

	gsort location institution fips 
	gunique location institution

	by location institution: carryforward statefip fips hosp_id min_year max_year flag_* d, replace  
	gduplicates drop 

	// Round 1: Group strings based on Levenshtein edit distance
		gen no_spaces = subinstr(institution," ","",.)
		gen name_15_characters = substr(no_spaces,1,15)

		by location: strgroup name_15_characters, generate(hosp_group) threshold(0.1)

		gunique hosp_id if !missing(hosp_id), by(hosp_group) gen(tot_coded)
		gsort hosp_group tot_coded
		by hosp_group: carryforward tot_coded, replace
		
		// Manual fix if coded incorrectly
		replace hosp_group = . if institution == "NORTH CAROLINA SOLDIERS HOME AND HOSPITAL"
		replace hosp_group = . if institution == "NORTH CAROLINA SANATORIUM FOR THE TREATMENT OF TUBERCULOSIS, DIVISION FOR NEGROES"
		
		// Fill in missing values
		gsort hosp_group location hosp_id institution
		by hosp_group: carryforward hosp_id statefip fips hosp_id min_year max_year flag_* d if tot_coded == 1 & !missing(hosp_group), replace  

		// Round 2: Group strings based on Levenshtein edit distance
		drop hosp_group tot_coded 
		gsort location institution fips 
		by location: strgroup name_15_characters, generate(hosp_group) threshold(0.2)

		gunique hosp_id if !missing(hosp_id), by(hosp_group) gen(tot_coded)
		gsort hosp_group tot_coded
		by hosp_group: carryforward tot_coded, replace
		
		// Manual fix if coded incorrectly 
		replace hosp_group = . if institution == "GASTON COUNTY SANATORIUM"
		replace hosp_group = . if institution == "NORTH CAROLINA SANATORIUM FOR THE TREATMENT OF TUBERCULOSIS, DIVISION FOR NEGROES"
		replace hosp_group = . if institution == "NORTH CAROLINA SOLDIERS HOME AND HOSPITAL"
		replace hosp_group = . if institution == "STATE HOSPITAL FOR THE DANGEROUS INSANE"
		
		// Fill in missing values
		gsort hosp_group hosp_id
		by hosp_group: carryforward hosp_id statefip fips hosp_id min_year max_year flag_* d if tot_coded == 1 & !missing(hosp_group), replace  
		drop hosp_group tot_coded 
		drop no_spaces name_15_characters 

	keep if !missing(hosp_id)

	drop min_year max_year flag_* d

	tempfile updated_hosp_id
	save `updated_hosp_id', replace


	// Load AMD hospital data 
	use `amd_input', clear 

	keep location institution year beds est_year hosp_type hosp_control black_hospital long_term source any_beds flag_two_bed_counts 
	merge m:1 location institution using `updated_hosp_id', keep(1 3) nogen

	// Manual fixes to hospital type based on most common type
	replace hosp_type = "General" if institution == "GOLDSBORO HOSPITAL"
	replace hosp_type = "TB" if institution == "HALIFAX COUNTY TUBERCULOSIS SANITARIUM"
	replace hosp_type = "TB" if institution == "WILSON HOSPITAL AND TUBERCULAR HOME"

	replace est_year = 1924 if location == "BANNER ELK" & institution == "GRACE HOSPITAL"
	replace est_year = 1915 if location == "ELIZABETH CITY" & institution == "ALBEMARLE HOSPITAL"
	replace est_year = 1899 if location == "FAYETTEVILLE" & regexm(institution, "HIGHSMIGH HOSPITAL")
	replace est_year = 1923 if location == "GREENVILLE" & institution == "PITT GENERAL HOSPITAL"
	replace est_year = 1925 if location == "HALIFAX" & institution == "HALIFAX COUNTY TUBERCULOSIS SANITARIUM"

	compress 
	gsort institution year

	// Update hospital type, established year, and colored status
	gsort + location + institution - year
	by location institution: carryforward hosp_type hosp_control est_year black_hospital long_term, replace
	gsort + location + institution + year
	by location institution: carryforward hosp_type hosp_control est_year black_hospital long_term, replace

	// Further coding of hospital type and control using institution name 
	replace hosp_type = "TB" if missing(hosp_type) & ( regexm(institution, "SANATORIUM") | regexm(institution, "TUBERCULOSIS") )

	replace hosp_type = "Specialty" if missing(hosp_type) & ( ///
											regexm(institution, "HOSPITAL") == 0 | ///
											regexm(institution," EYE HOSPITAL") | regexm(institution, "HOUSE") | ///
											regexm(institution, "INSANE") | regexm(institution,"MARINE") | ///
											regexm(institution, "RAILROAD") | regexm(institution, "RAILWAY") )
											
	replace hosp_control = "Army & Veteran" if regexm(institution, "VETERAN")
	replace hosp_control = "State" if regexm(institution,"PUBLIC HEALTH")

	// Manually check hospitals without IDs and create new IDs
	preserve 

		keep if missing(hosp_id)
		keep location institution
		gduplicates drop
		replace location = proper(location)
		replace institution = proper(institution)
		
		merge m:1 location using `location_fips_xwk', keep(1 3) nogen 
		
		// Manual fix for two locations not appearing elsewhere: Caroleen is in Rutherford Cty. and Maxton is mostly in Robeson County (also partly in Scotland)
		replace fips = 371610 if location == "Caroleen"
		replace fips = 371650 if location == "Maxton"
		
		gsort location institution		
		
		rename fips new_fips 
		gen new_hosp_id = `first_new_id' + _n
		order new_hosp_id
		
		desc, f 
		
		tempfile new_hosp_id
		save `new_hosp_id', replace 
		
	restore 

	replace location = proper(location)
	replace institution = proper(institution)

	// Merge in FIPS codes
	merge m:1 hosp_id location using `hosp_id_fips_xwk', keepusing(statefip fips) keep(1 3) nogen

	// Merge in IDs for hospitals only in AMD
	merge m:1 institution location using `new_hosp_id', keep(1 3) 

	replace fips = new_fips if _merge == 3
	replace hosp_id = new_hosp_id if _merge == 3 
	replace statefip = floor(fips/10000) if _merge == 3

	assert !missing(hosp_id)
	drop _merge new_hosp_id new_fips

	gen countyicp = fips - statefip*10000

	// Check issue with non-hospital beds reported pre-1925
		* Ignore bed totals in 1925 or early if more than x2 high-quality total from 1923 
	egen max_hq_beds = max(beds*(flag_two_bed_counts == 1)), by(hosp_id)
	replace beds = . if !missing(max_hq_beds) & max_hq_beds > 0 & beds/max_hq_beds > 2 & year <= 1925
	drop max_*q* any_beds flag_two_bed_counts 

	rename beds tot_beds
	rename location city 

	gunique fips hosp_id year
	gsort fips hosp_id year
	compress 
	desc, f

	tempfile amd_output
	save `amd_output', replace

	
	
	// Load Duke capital appropriations data
	use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta", clear
	rename hospital institution 
	rename county_nhgis county 
	
	// Drop observations after 1950 since we don't have AMA data after 1950 
	keep if year <= 1950 

	keep state county statefip countyicp fips location hosp_id institution year appropriation purpose app_payments capp_* pay_*

	// Collapse Duke capital appropriation data to hospital-by-year level 
	foreach v of varlist appropriation app_payments capp_* pay_* {
		local `v'_label: var label `v'
	}

	collapse (sum) appropriation app_payments capp_* pay_*, by(state county statefip countyicp fips location hosp_id institution year)

	foreach v of varlist appropriation app_payments capp_* pay_* {
		label var `v' `"``v'_label'"'
	}

	// Restrict to NC
	keep if statefip == 37 

	gsort hosp_id year
	gisid hosp_id year, missok

	rename institution duke_institution

	// Fill in zero capital appropriations
	recode capp_* pay_* appropriation app_payments (mis = 0)
	tempfile duke_hospitals
	save `duke_hospitals', replace 


	// Get full set of years 
	clear 
	local start = 1906 // We will keep all years for robustness
	local end = 1950
	local obs = `end' - `start' + 1
	set obs `obs'
	gen year = _n + `start' - 1
	tab year
	tempfile yearlist
	save `yearlist'


	// Get full set of hospitals 
	use statefip countyicp fips hosp_id using `amd_output', clear 
	gduplicates drop 
	gunique hosp_id
	tempfile amd_hosp_list 
	save `amd_hosp_list', replace

	use statefip countyicp fips hosp_id using "$PROJ_PATH/analysis/processed/data/ama/ama_carolina_hospitals_1920-1950.dta" if hosp_id != ., clear
	append using `amd_hosp_list'
	gduplicates drop 
	gunique hosp_id
	cross using `yearlist'
	tempfile hosp_yearlist
	save `hosp_yearlist', replace 


	// Load AMA hospital data for NC
	use statefip countyicp fips year hosp_id hosp_type hosp_control institution location EstYear totalbeds bassinets births averagebedsinuse patients population using "$PROJ_PATH/analysis/processed/data/ama/ama_carolina_hospitals_1920-1950.dta" if hosp_id != ., clear

	replace hosp_type = "Specialty" if hosp_type == "Specializing"
	gen source = "AHA"
	gen black_hospital = 1 if regexm(lower(institution),"colored")

	rename totalbeds tot_beds
	rename patients tot_admit
	rename averagebedsinuse usage
	rename births births_inhosp
	rename EstYear est_year 
	rename population city_pop
	rename location city 

	// Append hospitals from AMD
	append using `amd_output'

	// Update Black hospitals using Pollitt data 
	merge m:1 hosp_id using `aa_hosp', keep(1 3) keepusing(hosp_id)
	replace black_hospital = 1 if _merge == 3 
	tab black_hospital, m
	drop _merge 

	// Use modal year of establishment (deals with typos)
	egen modal_est_year = mode(est_year), by(hosp_id)
	replace est_year = modal_est_year if !missing(modal_est_year)
	drop modal_est_year

	// Identify "long-term" facilities like an orphanage or convalescent home
	replace long_term = 1 if regexm(lower(institution), "orphan") 
	replace long_term = 1 if regexm(lower(institution), "ophan") 
	replace long_term = 1 if regexm(lower(institution), "lodge") 
	replace long_term = 1 if regexm(lower(institution), "home") 
	
	// Create separate bed variables that prioritize AHA (main) or AMD (robust)
	gsort hosp_id year source 
	egen tot_beds_aha = max(tot_beds*(source == "AHA")), by(hosp_id year)
	egen tot_beds_amd = max(tot_beds*(source == "AMD")), by(hosp_id year)
	drop tot_beds 
	recode tot_beds* (0 = .)
	replace tot_beds_aha = tot_beds_amd if missing(tot_beds_aha)
	replace tot_beds_amd = tot_beds_aha if missing(tot_beds_amd)
	order year statefip city_pop tot_beds*

	// Fill in gaps in data within years 
	gsort hosp_id year source 
	by hosp_id year: carryforward hosp_type hosp_control est_year black_hospital long_term, replace
	gsort + hosp_id + year - source 
	by hosp_id year: carryforward hosp_type hosp_control est_year black_hospital long_term, replace

	// Collapse entries that appear in both sources 
	egen tot_aha = max(source == "AHA"), by(hosp_id year)
	drop if tot_aha == 1 & source == "AMD"
	drop tot_aha source 
	gunique hosp_id year 

	// Fill in gaps in data across missing years 
	gsort hosp_id year  
	by hosp_id: carryforward hosp_type hosp_control est_year black_hospital long_term, replace
	gsort + hosp_id - year
	by hosp_id: carryforward hosp_type hosp_control est_year black_hospital long_term, replace

	// Merge in Duke data 
	merge m:1 hosp_id year using `duke_hospitals', keepusing(appropriation app_payments capp_* pay_* duke_institution)

	// Drop hospitals supported by Duke that never appear in AHA or AMD data 
	egen ever_in_ama = max(_merge == 1 | _merge == 3), by(hosp_id)
	tab duke_institution if ever_in_ama == 0
	drop if ever_in_ama == 0
	drop ever_in_ama 

	tab _merge 
	drop _merge 

	// Save first and last year 
	gegen frst_year = min(year), by(hosp_id)
	gegen last_year = max(year), by(hosp_id)

	// Fill in gaps in AMA
	merge 1:1 hosp_id year using `hosp_yearlist', assert(2 3) nogen 
	gsort hosp_id year
	xtset hosp_id year

	// Fill in gaps in first and last year 
	gsort hosp_id year
	by hosp_id: carryforward frst_year last_year est_year, replace
	gsort + hosp_id - year
	by hosp_id: carryforward frst_year last_year est_year, replace

	// Fill in state FIPS code, city
	gsort + hosp_id - year
	by hosp_id: carryforward statefip city, replace
	gsort hosp_id year
	by hosp_id: carryforward statefip city, replace

	gsort hosp_id year

	// Check for errors in established year 
	count if frst_year < est_year & !missing(est_year)

	// Use first entry year instead of established year if inconsistent
	replace est_year = frst_year if frst_year < est_year & !missing(est_year)

	// Drop years before established year if established year not missing and precedes first entry
	drop if year < est_year & !missing(est_year) & est_year <= frst_year

	// Drop years before first reported year if established year missing
	drop if year < frst_year & missing(est_year)

	// Drop years after last reported year
	drop if year > last_year 

	// Drop hospitals that drop out before 1920
	drop if last_year < 1920

	// Fill in missing values 
	gsort hosp_id year
	by hosp_id: carryforward statefip hosp_type hosp_control black_hospital long_term institution countyicp fips duke_institution, replace
	 
	gsort + hosp_id - year
	by hosp_id: carryforward statefip hosp_type hosp_control black_hospital long_term institution countyicp fips duke_institution, replace

	// Linearly interpolate population 

	// Make sure Duke is never missing
	recode capp_* pay_* appropriation app_payments (mis = 0)

	// Recode any remaining missing variables 
	recode black_hospital (mis = 0)

	// Check what types of hospitals Duke funded
	gen duke = (capp_all > 0 & !missing(capp_all))
	tab hosp_type if duke == 1

	// Fix hospital type 
	tab hosp_type, sort m
					
	// Flag sanatorium (Anson and Baker)
	tab duke if (regexm(lower(institution),"tuberc") | regexm(lower(institution),"sanatorium") | regexm(lower(institution),"sanitarium")) & regexm(lower(institution),"hospital") == 0
	replace hosp_type = "TB" if (regexm(lower(institution),"tuberc") | regexm(lower(institution),"sanatorium") | regexm(lower(institution),"sanitarium")) & regexm(lower(institution),"hospital") == 0

	// Flag clinics 
	tab duke if regexm(lower(institution),"clinic") & regexm(lower(institution),"hospital") == 0
	gen flag_clinic = regexm(lower(institution),"clinic") & regexm(lower(institution),"hospital") == 0

	// Flag homes (includes IOOF)
	tab duke if regexm(lower(institution),"home") & regexm(lower(institution),"hospital") == 0
	gen flag_homes = regexm(lower(institution),"home") & regexm(lower(institution),"hospital") == 0

	// Flag infirmaries
	tab duke if regexm(lower(institution),"infirmary") & regexm(lower(institution),"hospital") == 0
	gen flag_infirm = regexm(lower(institution),"infirmary") & regexm(lower(institution),"hospital") == 0

	// Flag schools 
	tab duke if regexm(lower(institution),"school") & regexm(lower(institution),"hospital") == 0
	gen flag_school = regexm(lower(institution),"school") & regexm(lower(institution),"hospital") == 0

	// Flag dispensaries
	tab duke if regexm(lower(institution),"dispensary") & regexm(lower(institution),"hospital") == 0 
	gen flag_dispensary = regexm(lower(institution),"dispensary") & regexm(lower(institution),"hospital") == 0 

	// Flag orphanages
	tab duke if regexm(lower(institution),"orphanage") & regexm(lower(institution),"hospital") == 0 
	gen flag_orphanage = regexm(lower(institution),"orphanage") & regexm(lower(institution),"hospital") == 0

	// Flag hospital for women and children 
	tab duke if regexm(lower(institution), "for women") 
	gen flag_women = regexm(lower(institution), "for women")

	// Flag ever long-term care 
	egen flag_ever_long_term = max(long_term), by(hosp_id)
	tab duke if flag_ever_long_term == 1
	
	// Fix Wilson Hospital and Tubercular Home aka Mercy Hospital
	replace hosp_type = "General" if hosp_id == 10538
	replace long_term = 0 if hosp_id == 10538
	replace flag_ever_long_term = 0 if hosp_id == 10538

	tab duke if flag_ever_long_term == 1
	
	foreach source in amd aha {

		// Interpolate 
		gsort hosp_id year
		by hosp_id: ipolate tot_beds_`source' year, gen(i_tot_beds_`source') 
		
		// Type of beds 
		gen np_beds_`source' = (hosp_control == "Non-profit")*tot_beds_`source'
		gen i_np_beds_`source' = (hosp_control == "Non-profit")*i_tot_beds_`source'

		gen prop_beds_`source' = (hosp_control == "Proprietary")*tot_beds_`source' 
		gen i_prop_beds_`source' = (hosp_control == "Proprietary")*i_tot_beds_`source' 
		
	}
		
	by hosp_id: ipolate usage year, gen(i_usage) 
	by hosp_id: ipolate births_inhosp year, gen(i_births_inhosp) 

	// Use NHGIS data for controls/weights
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", keep(1 3) nogen keepusing(pop_total)

	// Merge with ICPSR county births
	merge m:1 fips year using "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_year_births.dta", keep(1 3) nogen keepusing(births_occ)

	gsort hosp_id year 

	// Create usage variable 
	foreach source in amd aha {
		gen usage_rate_`source' = usage/tot_beds_`source'
	}

	// Scale beds by 100,000 population
	gen i_beds_per_pop_aha = i_tot_beds_aha*100000/pop_total 
	la var i_beds_per_pop_aha "Total beds per 100,000 population in county"

	la var hosp_id "Hospital ID"
	la var institution "Hospital name"
	la var black_hospital "Black hospital"

	la var tot_beds_aha "Total Beds (prioritize AHA)"
	la var tot_beds_amd "Total Beds (prioritize AMD)"

	la var i_tot_beds_aha "Interpolated Total Beds (prioritize AHA)"
	la var i_tot_beds_amd "Interpolated Total Beds (prioritize AMD)"

	la var np_beds_aha "Total Beds in Non-Profit Hospitals (prioritize AHA)"
	la var np_beds_amd "Total Beds in Non-Profit Hospitals (prioritize AMD)"

	la var i_np_beds_aha "Interpolated Beds in Non-Profit Hospitals (prioritize AHA)"
	la var i_np_beds_amd "Interpolated Beds in Non-Profit Hospitals (prioritize AMD)" 

	la var prop_beds_aha "Total Beds in Proprietary Hospitals (prioritize AHA)"
	la var prop_beds_amd "Total Beds in Proprietary Hospitals (prioritize AMD)"

	la var i_prop_beds_aha "Interpolated Beds in Proprietary Hospitals (prioritize AHA)"
	la var i_prop_beds_amd "Interpolated Beds in Proprietary Hospitals (prioritize AMD)"

	la var usage_rate_aha "Share of Beds in Use (prioritize AHA)"
	la var usage_rate_amd "Share of Beds in Use (prioritize AMD)"

	la var births_inhosp "Births in Hospital"
	la var births_occ "Births, by Place of Occurrence"

	la var flag_clinic "Flag Clinics"
	la var flag_homes "Flag Homes"
	la var flag_infirm "Flag Infirmaries"
	la var flag_school "Flag Schools"
	la var flag_dispensary "Flag Dispensaries"
	la var flag_women "Flag Hospitals for Women and Children"
	la var flag_orphanage "Flag Orphanages"
	la var flag_ever_long_term "Flag Ever Long-Term Care"
	
	la var duke "=1 if funded by Duke Endowment"
	la var frst_year "First Year Hospital in AMA/AMD"
	la var last_year "Last Year Hospital in AMA/AMD"

	order year statefip city city_pop countyicp fips hosp_id institution hosp_type hosp_control black_hospital *beds* *births* *usage* flag_* 
	compress
	desc, f 

	save "$PROJ_PATH/analysis/processed/data/hospitals/hospital-by-year_panel_data.dta", replace
	
}


*********************************
// Clean AMD physician data *****
*********************************

if `amd_physicians' {
	
	local amd_year_list "1912 1914 1918 1921 1923 1925 1927 1929 1931 1934 1936 1938 1940 1942"

	clear
	foreach year of local amd_year_list {
		append using "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_`year'.dta"
	}
	compress
	
	// Drop unused variables 
	drop symbol* notes 
	
	// Standardize state name for North Carolina 
	replace state = "North Carolina" if state == "NORTH CAROLANA" | state == "NORTH CAROLINA"
	tab state, m

	// Clean population variable 
	rename pop city_pop	
	replace city_pop = subinstr(city_pop,",","",.)
	replace city_pop = subinstr(city_pop," ","",.)
	replace city_pop = "" if regexm(city_pop,"\?")
	destring city_pop, replace 

	// Clean AMA member variable
	rename nametypesetinuppercase ama_member
	destring ama_member, replace 
	recode ama_member (mis = 0)
	tab ama_member, m

	// Separate names
	split name, p(",")
	
	gen last_name = name1
	egen first_name = concat(name2 name3 name4) 
	drop name1 name2 name3 name4 
	rename name raw_name 

	replace last_name = "" if strpos(last_name, "?") > 0
	replace first_name = "" if strpos(first_name, "?") > 0

	// Generate Black indicator 
	rename col colored 
	destring colored, replace
	recode colored (mis = 0)
	tab colored, m

	// Clean birth year variable 
	rename yearofbirthb raw_birth_year 
	gen byr_abb = raw_birth_year 

	replace byr_abb = "88" if byr_abb == "88,15"
	replace byr_abb = "" if byr_abb == "ss"
	replace byr_abb = "" if strpos(byr_abb, "(??)") > 0
	replace byr_abb = trim(byr_abb)
	destring byr_abb, replace 

	// Convert birth year to four digits 
	tab byr_abb if year == 1912, m
	tab byr_abb if year == 1914, m
	tab byr_abb if year == 1918, m
	tab byr_abb if year == 1921, m 
	tab byr_abb if year == 1923, m
	tab byr_abb if year == 1925, m
	tab byr_abb if year == 1927, m
	tab byr_abb if year == 1929, m
	tab byr_abb if year == 1931, m
	tab byr_abb if year == 1934, m
	tab byr_abb if year == 1936, m
	tab byr_abb if year == 1938, m
	tab byr_abb if year == 1940, m
	tab byr_abb if year == 1942, m


	gen birth_year = .
	replace birth_year = 1800 + byr_abb if byr_abb < 100 & year == 1912
	replace birth_year = 1900 + byr_abb if byr_abb <= 4 & year == 1921
	replace birth_year = 1800 + byr_abb if byr_abb > 4 & byr_abb < 100 & year == 1921	
	replace birth_year = byr_abb if byr_abb >= 100 & !missing(byr_abb) & (year == 1912 | year == 1921)
	replace birth_year = byr_abb + 1800 if year <= 1923
	replace birth_year = byr_abb + 1800 if byr_abb > 2 & !missing(byr_abb) & year == 1925
	replace birth_year = byr_abb + 1900 if byr_abb <= 2 & !missing(byr_abb) & year == 1925
	replace birth_year = byr_abb + 1800 if byr_abb >= 12 & !missing(byr_abb) & year == 1927
	replace birth_year = byr_abb + 1900 if byr_abb <= 9 & !missing(byr_abb) & year == 1927
	replace birth_year = byr_abb + 1800 if byr_abb > 6 & !missing(byr_abb) & year == 1929
	replace birth_year = byr_abb + 1900 if byr_abb <= 6 & !missing(byr_abb) & year == 1929
	replace birth_year = byr_abb + 1800 if byr_abb >= 13 & !missing(byr_abb) & year == 1931
	replace birth_year = byr_abb + 1900 if byr_abb <= 9 & !missing(byr_abb) & year == 1931
	replace birth_year = byr_abb + 1800 if byr_abb > 11 & !missing(byr_abb) & year == 1934
	replace birth_year = byr_abb + 1900 if byr_abb <= 11 & !missing(byr_abb) & year == 1934
	replace birth_year = byr_abb + 1800 if byr_abb >= 30 & !missing(byr_abb) & year == 1936
	replace birth_year = byr_abb + 1900 if byr_abb <= 13 & !missing(byr_abb) & year == 1936
	replace birth_year = byr_abb + 1800 if byr_abb > 15 & !missing(byr_abb) & year == 1938
	replace birth_year = byr_abb + 1900 if byr_abb <= 15 & !missing(byr_abb) & year == 1938
	replace birth_year = byr_abb + 1800 if byr_abb >= 30 & !missing(byr_abb) & year == 1940
	replace birth_year = byr_abb + 1900 if byr_abb <= 18 & !missing(byr_abb) & year == 1940
	replace birth_year = byr_abb + 1800 if byr_abb > 18 & !missing(byr_abb) & year == 1942
	replace birth_year = byr_abb + 1900 if byr_abb <= 18 & !missing(byr_abb) & year == 1942

	tab birth_year, m
	tab byr_abb if missing(birth_year), m 

	// Clean HEPM variable 
	replace categoryhepm = ustrtrim(categoryhepm)
	tab categoryhepm, m
	gen eclectic = (categoryhepm == "E")
	gen homeopath = (categoryhepm == "H")
	
	tab categoryhepm if eclectic == 0 & homeopath == 0 
	tab eclectic
	tab homeopath
	
	drop categoryhepm

	// Create AMA fellow indicator 
	rename crossincircle ama_fellow
	destring ama_fellow, replace 
	recode ama_fellow (mis = 0)
	tab ama_fellow, m

	// Clean medical school code and graduation year variables
	gen med_school = medschool
	rename medschool raw_med_school

	rename medschoolgradyear raw_grad_year
	gen grad_year = raw_grad_year

	// Clean entries with N.B. (certificate from National Board)
	replace grad_year = regexr(grad_year,"[;|,](.)*$","") if regexm(lower(raw_med_school),"n\.b\.")
	replace grad_year = "'12" if raw_med_school == "N.C.3,12"
	replace med_school = regexr(med_school,"[;|,][ ]*[N|A|M][\.|B\.](.)*$","") if regexm(lower(raw_med_school),"[n|a|m]\.b\.")
	replace med_school = regexr(med_school,"[;|,][ ]*[N|A|M][\.|B](.)*$","") if regexm(lower(raw_med_school),"[n|a|m]\.b")
	
	replace med_school = "" if raw_med_school == "Conn.1,  Ct. Am. Bd. Oph., Ex."

	// Clean med school codes
	replace med_school = subinstr(med_school,"Ill.Ia","Ill.1a",.)
	replace med_school = subinstr(med_school,"I.a","Iowa",.)
	replace med_school = subinstr(med_school,"Ia","Iowa",.)
	replace med_school = regexr(med_school,"Austria 7","Ger.26")
	replace med_school = regexr(med_school,"Denmark 1","Den.1")
	replace med_school = regexr(med_school,"France 6","Fra.6")
	replace med_school = regexr(med_school,"Germany 19","Ger.19")
	replace med_school = regexr(med_school,"Scotland 3","Scot.3")
	replace med_school = regexr(med_school,"Switzerland 2","Switz.2")
	replace med_school = regexr(med_school,"Rus\.5","U.S.S.R.5")
	replace med_school = regexr(med_school,"YY","Y")

	replace med_school = "D.C.1" if med_school == "B.C.1"
	replace med_school = "Ga.5" if med_school == "Ca.5"
	replace med_school = "Pa.1" if med_school == "P.1"
	replace med_school = "Pa.2" if med_school == "Pd.2" | med_school == "Pa.2; R.D. 1"
	replace med_school = "Pa.7" if med_school == "Pa.6"
	replace med_school = "Va.1" if med_school == "Ya.1"
	replace med_school = "Va.4" if med_school == "Va.4; R.D. 2"
	replace med_school = "Md.1" if med_school == "Md.1; N.C."
	replace med_school = "Mich.5" if med_school == "Mic.5"
	replace med_school = "Va.2" if med_school == "Va.2, 6"
	replace med_school = "N.C.3" if med_school == "N.C.3,12"
	replace med_school = "N.Y.20,N.Y.1" if med_school == "N.Y.20 (N.Y.1)"

	replace med_school = "Tenn.1" if med_school == "Tenn,1"
	replace med_school = "Tenn.10" if med_school == "Tenn,10"
	replace med_school = "Tenn.14" if med_school == "Tenn,14"
	replace med_school = "Ga.12" if med_school == "Ga,12"
	replace med_school = "Ga.12,Ga.11" if med_school == "Ga.12,11"
	replace med_school = "Scot.9,Scot.12,Scot.14" if med_school == "Scot.9,12,14"

	replace med_school = strtrim(lower(med_school))
	replace med_school = regexr(med_school,"\)","),") if regexm(med_school,"\)[a-z]")
	replace med_school = subinstr(med_school," ","",.)
	forvalues x = 0(1)9 {
		forvalues y = 0(1)9 {
				qui replace med_school = regexr(med_school,"`x',`y'","`x';`y'") 
		}
	}

	replace med_school = subinstr(med_school,";",",",.)
	split med_school, parse(",") gen(ms_)

	forvalues i = 1/3 { 
		replace ms_`i' = "" if regexm(ms_`i',"\?")
		replace ms_`i' = regexr(ms_`i',"calif","cal")
		replace ms_`i' = regexr(ms_`i',"teen","tenn")
		replace ms_`i' = regexr(ms_`i',"^nyy","ny")
		replace ms_`i' = regexr(ms_`i',"^kv","ky")
		replace ms_`i' = regexr(ms_`i',"^mc","nc")
		replace ms_`i' = regexr(ms_`i',"^ss","sc")
		
		la var ms_`i' "Medical School"
	}

	replace ms_2 = "" if ms_2 == "ct.nat.bd.med.ex."

	drop med_school

	// Clean med school graduation year 
	replace grad_year = "07" if raw_med_school == "Md.1; N.C."
	replace grad_year = "97" if raw_grad_year == "97, 17"

	replace grad_year = subinstr(grad_year,",",";",.)
	replace grad_year = subinstr(grad_year,"'","",.)
	replace grad_year = subinstr(grad_year,"#dg","",.)
	replace grad_year = subinstr(grad_year," ","",.)

	split grad_year, parse(";") gen(gyr)

	forvalues k = 1/3 { 
		replace gyr`k' = "" if strpos(gyr`k', "(??)") | regexm(gyr`k',"\?")
		destring gyr`k', replace 
		
		gen grad_year`k' = .
		replace grad_year`k' = 1800 + gyr`k' if gyr`k' >= (year - 1900) & !missing(gyr`k')
		replace grad_year`k' = 1900 + gyr`k' if gyr`k' < (year - 1900) & !missing(gyr`k')
		
		drop gyr`k'
		
		la var grad_year`k' "Medical school graduation year"
		
	}

	drop grad_year 

	// Clean affiliated with med school variables 
	rename affiliatedwithmedschool raw_details

	// Clean address variable 
	rename other raw_address

	// Clean license year 
	rename yearoflicensel raw_license_year
	gen license_year = raw_license_year

	replace license_year = subinstr(license_year,",",";",.)
	replace license_year = subinstr(license_year,"'","",.)
	replace license_year = subinstr(license_year," ","",.)
	
	replace license_year = strtrim(license_year)
	replace license_year = "09" if license_year == "09(Limited)"
	replace license_year = "09" if license_year == "(Lim.Ter.L09)"
	replace license_year = "" if license_year == "()" 
	
	split license_year, parse(";") gen(lyr)

	forvalues k = 1/2 { 
		replace lyr`k' = "" if regexm(lyr`k',"\?") 
		destring lyr`k', replace 
		
		gen license_year`k' = .
		replace license_year`k' = 1800 + lyr`k' if lyr`k' >= (year - 1900) & !missing(lyr`k')
		replace license_year`k' = 1900 + lyr`k' if lyr`k' < (year - 1900) & !missing(lyr`k')
		
		drop lyr`k'
		
		la var license_year`k' "Year obtained medical license"
		
	}

	drop license_year

	// Clean not practicing variable
	tab notinpractic, m
	gen not_practicing = 0 
	replace not_practicing = 1 if regexm(lower(notinpractic),"in pra") 
	tab notinpractic if not_practicing == 1, m
	tab notinpractic if not_practicing == 0, m
	tab not_practicing
	
	// Generate retired variable 
	gen retired = 0
	tab year if regexm(lower(notinpractic),"retir")
	tab year if regexm(lower(raw_details),"retir")
	replace retired = 1 if regexm(lower(notinpractic),"retir")
	replace retired = 1 if regexm(lower(raw_details),"retir")
	
	drop notinpractic

	// Generate society member variable 
	tab society
	gen society_member = !missing(society)
	tab society_member 

	// Clean specialty variable
	replace specialty = subinstr(specialty,".","",.)
	tab specialty

	gen md_specialist = !missing(specialty)
	tab md_specialist

	// Identify surgeons
	gen md_surgeon = (specialty == "S" | regexm(upper(specialty),"SURG"))
	tab md_surgeon 

	// Flag repeated entries 
	gen flag_repeat = 0
	tab year if regexm(lower(raw_name), "\(see") & raw_birth_year == ""
	tab year if regexm(lower(raw_details), "\(see") & raw_birth_year == ""
	replace flag_repeat = 1 if regexm(lower(raw_name), "\(see") & raw_birth_year == ""
	replace flag_repeat = 1 if regexm(lower(raw_details), "\(see") & raw_birth_year == ""
	tab flag_repeat

	// Drop summary rows 
	drop if regexm(lower(raw_details), "number of") & missing(raw_name)

	order raw_*, last 

	// Label variables
	la var state "State"
	la var city "City"
	la var city_pop "City population"
	la var county "County"
	la var raw_name "Name"
	la var last_name "Last Name"
	la var first_name "First Name"
	la var colored "=1 if Black"
	la var byr_abb "Two-digit Birth Year"
	la var birth_year "Birth year"
	la var eclectic "=1 if Eclectic"
	la var homeopath "=1 if Homeopath"
	la var md_specialist "=1 if Specialist"
	la var md_surgeon "=1 if Surgeon"
	la var ama_member "AMA member"
	la var ama_fellow "AMA fellow"
	la var society_member "Member of state or county society"
	la var not_practicing "Not practicing"
	la var retired "Retired"
	la var specialty "Specialty"
	la var year "AMD Volume Year"
	la var raw_address "Address"
	la var raw_details "Other details"

	compress
	desc, f 

	// Check race 
	tab year colored, col m

	egen index = seq(), by(year)
	gsort year index

	order ms_* grad_year* license_year* md_*, last
	compress
	desc, f 

	save "$PROJ_PATH/analysis/processed/data/amd_physicians/amd_physicians_cleaned.dta", replace 

}


***************************************
// AMD History of medical schools *****
***************************************

if `amd_med_schools' {
	
	use "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/us_medical_schools_alphabetical_1942.dta", clear
	
	// Add missing entry 
	count 
	local obs = r(N) + 1
	set obs `obs'
	replace FileName = "PXL_20230427_162933479.jpg" in `obs'
	replace MedicalSchoolName = "College of Phys. and Surgs. Of Baltimore" in `obs'
	replace Location = "Baltimore" in `obs'
	replace Code = "Md.3" in `obs'

	// Standardize codes 
	replace Code = regexr(Code,"Calif","Cal")
	replace Code = regexr(Code,"Oka","Okla")
	replace Code = regexr(Code,"Ia","Iowa")

	// Fix error where code is location
	replace Code = "N.J.2" if MedicalSchoolName == "New Jersey, Medical and Surgical College of the State of"
	replace Location = "" if MedicalSchoolName == "New Jersey, Medical and Surgical College of the State of"

	// Fix error in code 
	replace Code = "Pa.1" if Code == "Pa.13" & MedicalSchoolName == "Univ. of Pennsylvania School of Med."

	// Fix issue that some school codes report multiple with an "and"
	split Code, p(" and " " And ")

	* identify those that should have same prefix (e.g. , Ill.8 and 43) vs those that are alright (e.g., Ill.24 and Ia.1)
	gen period_present = regexm(Code2, "\.")

	gen first_prefix = ""

	quietly foreach var of varlist Code {
		qui replace first_prefix = regexs(1) if regexm(`var', "([A-Za-z.]+)[0-9]+")
	}

	gen CodeSecond = first_prefix + Code2 if period_present == 0 & Code2 != ""
	replace CodeSecond = Code2 if period_present == 1 

	keep MedicalSchoolName Code1 CodeSecond
	rename CodeSecond Code2

	// Reshape data 
	gen id = _n
	reshape long Code@, i(id MedicalSchoolName) j(Code_Number) string
	drop if missing(Code)
	drop id Code_Number 

	// Get rid of leading/training whitespace 
	replace MedicalSchoolName = ustrtrim(MedicalSchoolName)

	// Drop observation with multiple codes 
	drop if MedicalSchoolName == "Drake University College of Medicine" & Code == "Iowa.12"

	// Manual fix 
	replace MedicalSchoolName = "Medical College of Indiana, Indianapolis" if Code == "Ind.8" & MedicalSchoolName == "Medical College of Indiana"

	// Create lowercase medical school name variable for Stata merge 
	gen ms_merge_name = lower(MedicalSchoolName)

	replace ms_merge_name = "college of medicine and surgery, physio-medical of chicago" if ms_merge_name == "college of medicine and surgery, physio-medical"
	replace ms_merge_name = "hahnemann medical college and hospital" if ms_merge_name == "hahnemann medical college"
	replace ms_merge_name = "leland stanford junior college" if ms_merge_name == "leland stanford junior university school of medicine"
	replace ms_merge_name = "new york university, university and bellevue hospital medical college" if ms_merge_name == "new york university, university and bellevue hospital medical ocllege"
	replace ms_merge_name = "medical college of the state of south carolina" if ms_merge_name == "medical college of south carolina"
	replace ms_merge_name = "ohio-miami medical college of the university of cincinnati" if ms_merge_name == "ohio-miami med. coll."
	replace ms_merge_name = "western reserve university medical department" if ms_merge_name == "western reserve university school of medicine"
	replace ms_merge_name = "university of southern california medical department" if ms_merge_name == "university of southern california med. dept. (coll. of phys. and surgs.)"
	replace ms_merge_name = "university of maryland school of medicine" if ms_merge_name == "university of marland school of med. and coll. of phys. and srugs."
	replace ms_merge_name = "university of colorado school of medicine" if ms_merge_name == "university of colo. school of med."
	replace ms_merge_name = "university of alabama school of medicine" if ms_merge_name == "university of ala. school of med."
	replace ms_merge_name = "marion-sims-beaumont medical college" if ms_merge_name == "marlong-sims beaumont med. coll."
	replace ms_merge_name = "medical college of the state of south carolina" if ms_merge_name == "south carolina, medical college of the state of"

	replace ms_merge_name = regexr(ms_merge_name,"coll\.","college")
	replace ms_merge_name = regexr(ms_merge_name,"dept\.","department")
	replace ms_merge_name = regexr(ms_merge_name,"med\. coll","medical coll")
	replace ms_merge_name = regexr(ms_merge_name,"med\. dept","medical dept")
	replace ms_merge_name = regexr(ms_merge_name,"med\. sch","medical sch")
	replace ms_merge_name = regexr(ms_merge_name,"of med\.","of medicine")
	replace ms_merge_name = regexr(ms_merge_name,"phys\.","physicians")
	replace ms_merge_name = regexr(ms_merge_name,"sch\.","school")
	replace ms_merge_name = regexr(ms_merge_name,"surg\.","surgery")
	replace ms_merge_name = regexr(ms_merge_name,"surgs\.","surgeons")
	replace ms_merge_name = regexr(ms_merge_name,"univ\.","university")

	// Sort uniquely
	drop MedicalSchoolName 
	gduplicates drop 
	gisid ms_merge_name Code 
	gsort ms_merge_name Code

	desc, f

	// Save data
	compress
	save "$PROJ_PATH/analysis/processed/data/amd_med_schools/us_medical_schools_alphabetical_1942.dta", replace

	////////////////////////////////////////////////////////////////////////////////
	// One and a half, add AMA A/A+ ratings. 
	////////////////////////////////////////////////////////////////////////////////

	// Import AMA ratings
	use "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/med_school_ratings.dta", clear
	gisid code 
	reshape long y, i(code) j(year)

	rename y ama_rating 
	label variable ama_rating "AMA rating"

	// Only keep if rating 
	drop if missing(ama_rating)

	tab ama_rating, m 
	tab year, m

	// Standardize codes for merging 
	replace code = ustrtrim(code)
	replace code = regexr(code,"Calif","Cal")
	replace code = regexr(code,"^Ia","Iowa")
	replace code = regexr(code,"Oka","Okla")

	// Create ever A rating variable 
	egen ama_a_level = max(ama_rating == "A"), by(code)

	keep code ama_a_level 
	gduplicates drop 
	gisid code ama_a_level 
	gsort code ama_a_level 

	rename code Code

	tempfile ama_ratings 
	save `ama_ratings', replace 
	
	////////////////////////////////////////////////////////////////////////////////
	// One point seven five, add 1- or 2-year college pre-requisite requirement. 
	////////////////////////////////////////////////////////////////////////////////
		
	use "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/med_school_college_requirements.dta", clear
	rename school school_from_req_data
	destring one_yr_coll two_yr_coll internship, replace ignore(".")
	keep code one_yr_coll two_yr_coll

	// Create one- or two-year college requirement 
	replace one_yr_coll = two_yr_coll if missing(one_yr_coll) & !missing(two_yr_coll)

	// Gen rid of duplicates 
	egen nm_twoyr = max(!missing(two_yr_coll)), by(code)
	drop if nm_twoyr == 1 & missing(two_yr_coll)
	drop nm_twoyr 

	egen nm_oneyr = max(!missing(one_yr_coll)), by(code)
	drop if nm_oneyr == 1 & missing(one_yr_coll)
	drop nm_oneyr 

	// Standardize codes for merging 
	replace code = ustrtrim(code)
	replace code = regexr(code,"Calif","Cal")
	replace code = regexr(code,"^Ia","Iowa")
	replace code = regexr(code,"Oka","Okla")

	gisid code
	gunique code
	gsort code 

	rename code Code

	tempfile college_req
	save `college_req', replace

	
	////////////////////////////////////////////////////////////////////////////////
	// Second, clean the history file. 
	////////////////////////////////////////////////////////////////////////////////

	// Import U.S. Medical schools history file
	use "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/history_medical_schools_1942.dta", clear

	// Standardize codes 
	replace Code = ustrtrim(Code)
	replace Code = regexr(Code,"Calif","Cal")
	replace Code = regexr(Code,"lll","Ill") // Code starts with an L instead of an I
	replace Code = regexr(Code,"Oka","Okla")

	// Fix case where coeducational year entered in extinct field
	replace CoeducationalYear = "1880" if Code == "Kan.2"
	replace Extinct = "" if Code == "Kan.2" 

	// Clean extinct variable
	replace Extinct = "1891" if Extinct == "1,891"

	// Fix bugs in merged into year 
	replace MergedIntoYear = "" if Code == "Ark.1"
	replace MergedIntoYear = "" if Code == "Colo.2"
	replace MergedIntoYear = "" if Code == "Md.1"
	replace MergedIntoYear = "" if Code == "Mo.22"
	replace MergedIntoYear = "" if Code == "Mich.8"
	replace MergedIntoYear = "" if Code == "S.C.1"
	replace MergedIntoYear = "1884" if MergedIntoYear == "1884, 1886"
	replace MergedIntoYear = "1902" if Code == "Ark.5" & missing(MergedIntoYear)
	replace MergedIntoYear = "1914" if Code == "N.C.4" & missing(MergedIntoYear)

	// Fix bugs in merged into name 
	replace MergedIntoName = "" if Code == "Colo.2"
	replace MergedIntoName = "" if Code == "Md.1"
	replace MergedIntoName = "" if Code == "Mich.8"
	replace MergedIntoName = "" if Code == "Mo.22"
	replace MergedIntoName = "" if Code == "S.C.1"
	replace MergedIntoName = "University of Colorado School of Medicine" if Code == "Colo.5"
	replace MergedIntoName = "Michigan College of Medicine and Surgery" if Code == "Mich.9"
	replace MergedIntoName = "Starling-Ohio Medical College" if Code == "O.3"
	replace MergedIntoName = "Hahnemann Medical College and Hospital of Chicago" if Code == "Ill.10"
	replace MergedIntoName = "National University of Arts and Sciences Medical Department" if Code == "Mo.28"

	// Extract code for merged into school  
	gen MergedIntoCodeHistory = regexs(1) if regexm(MergedIntoName, "\(([A-Z|a-z]+[\.][0-9]+)\)")
	replace MergedIntoName = regexr(MergedIntoName,"[ ]*\([A-Z|a-z]+[\.][0-9]+\)","")

	// Get rid of leading/trailing whitespace and convert to lowercase
	replace MergedIntoName = ustrtrim(MergedIntoName)

	// Create a black school variable 
	gen black_school = regexm(lower(MedicalSchoolName),"colored") | regexm(lower(Notes),"colored") | regexm(lower(Notes),"negro")
	replace black_school = 1 if Code == "D.C.3" // Howard University College of Medicine (Black and white students)
	tab Code if black_school == 1

	// Merge in AMA rating 
	merge m:1 Code using `ama_ratings', assert(1 3) nogen
	recode ama_a_level (mis = 0)

	// Merge in 1- or 2-year college requirement year 
	merge m:1 Code using `college_req', keep(1 3) nogen // _merge == 2 cases are all foreign schools with no requirements

	// Save a tempfile of all schools
	gsort Code 
	desc, f

	tempfile all_schools
	save `all_schools', replace

	// Only keep those observations with information on mergers
	keep if !missing(MergedIntoYear) | !missing(MergedIntoName)
	assert !missing(MergedIntoYear) & !missing(MergedIntoName)

	// Get list of schools
	keep MergedIntoName MergedIntoCodeHistory

	// Prioritize observations with merged into code 
	egen any_code = max(!missing(MergedIntoCodeHistory)), by(MergedIntoName)
	drop if missing(MergedIntoCodeHistory) & any_code == 1
	drop any_code 

	// Ensure names are sorted and unique
	gduplicates drop
	gisid MergedIntoName
	gsort MergedIntoName

	// Create variable for Stata merge 
	gen ms_merge_name = lower(MergedIntoName)

	// Clean merged into name
	replace ms_merge_name = "college of medicine and surgery, physio-medical of chicago" if ms_merge_name == "college of medicine and surgery, physio-medical"
	replace ms_merge_name = "university of alabama school of med." if ms_merge_name == "graduate school of medicine of the university of alabama"
	replace ms_merge_name = "univ. of pennsylvania school of med." if ms_merge_name == "graduate school of medicine of the university of pennsylvania"
	replace ms_merge_name = "ohio state university coll. of med." if ms_merge_name == "property transferred to ohio state university"
	replace ms_merge_name = "university of maryland school of medicine" if ms_merge_name == "university of maryland school of medicine and college of physicians and surgeons"
	replace ms_merge_name = "univ. of minnesota college of medicine and surgery" if ms_merge_name == "minnesota hospital college/university of minnesota college of medicine and surgery"
	replace ms_merge_name = "univ. of minnesota college of medicine and surgery" if ms_merge_name == "university of minnesota college of medicine and surgery"
	replace ms_merge_name = "ohio state university college of medicine" if ms_merge_name == "starling-ohio medical college" | ms_merge_name == "starling medical college"
	replace ms_merge_name = "university of southern california school of medicine" if ms_merge_name == "university of southern california medical department"
	replace ms_merge_name = "ensworth-central medical college" if ms_merge_name == "ensworth central medical college"

	replace ms_merge_name = regexr(ms_merge_name,"coll\.","college")
	replace ms_merge_name = regexr(ms_merge_name,"of med\.","of medicine")
	replace ms_merge_name = regexr(ms_merge_name,"surg\.","surgery")
	replace ms_merge_name = regexr(ms_merge_name,"univ\.","university")

	// Joinby with full alphabetical list of medical school names
	joinby ms_merge_name using "$PROJ_PATH/analysis/processed/data/amd_med_schools/us_medical_schools_alphabetical_1942.dta", unmatched(master)
	tab _merge
	drop _merge 

	gunique MergedIntoName Code
	gsort MergedIntoName Code

	gen MergedIntoCode = MergedIntoCodeHistory
	drop MergedIntoCodeHistory

	replace MergedIntoCode = Code if missing(MergedIntoCode) & !missing(Code)
	drop Code

	joinby MergedIntoName using "`all_schools'", unmatched(both) 
	tab _merge 
	assert _merge == 2 | _merge == 3

	order Code MergedIntoCode MergedIntoYear
	gunique Code MergedIntoCode MergedIntoYear
	gsort Code MergedIntoCode MergedIntoYear

	replace MergedIntoYear = "" if Code == MergedIntoCode
	replace MergedIntoCode = "" if Code == MergedIntoCode
	 
	// Manual corrections to merged into code
	replace MergedIntoCode = "Mo.2" if ms_merge_name == "washington university school of medicine" & Code == "Mo.1"
	replace MergedIntoCode = "Ill.15" if ms_merge_name == "hering medical college" & Code == "Ill.18"

	gduplicates drop 
	gisid Code 
	gsort Code 

	drop _merge
	destring MergedIntoYear, replace 

	save "$PROJ_PATH/analysis/processed/temp/all-schools.dta", replace
	
	
	////////////////////////////////////////////////////////////////////////////////
	// Third, for those schools that merge, figure out what school they "became" in 1942
	////////////////////////////////////////////////////////////////////////////////
	use "$PROJ_PATH/analysis/processed/temp/all-schools.dta", clear
	rename * *_i1
	rename Code_i1 Code_i0
		keep Code* MergedIntoCode* MergedIntoYear*
	local merge_max = 3
	local i = 1
	while `merge_max' > 2 {

		rename MergedIntoCode_i`i' Code
		merge m:1 Code using "$PROJ_PATH/analysis/processed/temp/all-schools.dta", keepusing(Code* MergedIntoCode* MergedIntoYear*)
		drop if _merge == 2
		sum _merge
		local merge_max = `r(max)'
		keep Code* MergedIntoCode* MergedIntoYear* 

		rename Code MergedIntoCode_i`i' 
		local i = `i' + 1

		rename MergedIntoCode MergedIntoCode_i`i'
		rename MergedIntoYear MergedIntoYear_i`i'


		
		if `merge_max' == 1 {
			drop  MergedIntoCode_i`i' MergedIntoYear_i`i'
			local j = `i' - 1
		}
		
	}
	sort Code_i0

	// Gen max_follow up year 
	egen max_year_merger = rowmax(MergedIntoYear_i*)

	// reshape 
	reshape long MergedIntoCode_i@ MergedIntoYear_i@ , i(Code_i0) j(merge_number) string 
	destring merge_number, replace
	replace merge_number = merge_number - 1 if missing(MergedIntoCode_i)
	 
	drop if missing(MergedIntoCode_i) & !missing(max_year_merger)
	drop if missing(MergedIntoCode_i) & missing(max_year_merger) & merge_number > 0

	// Assign final school 
	gen final_school = ""
	replace final_school = MergedIntoCode_i if MergedIntoYear_i == max_year_merger
	replace final_school = Code_i0 if MergedIntoCode_i == ""

	order  max_year_merger Code_i0 MergedIntoCode_i 

	keep if MergedIntoYear_i == max_year_merger
	keep if final_school != Code_i0 | merge_number != 0
	keep final_school Code_i0 MergedIntoYear_i merge_number

	gisid Code_i0
	gsort Code_i0

	compress
	desc, f

	save "$PROJ_PATH/analysis/processed/temp/merged-schools-final-match.dta", replace

	////////////////////////////////////////////////////////////////////////////////
	// Fourth, set up final data with original school and 1942 school variables
	////////////////////////////////////////////////////////////////////////////////

	use Code MedicalSchoolName Location BoldfaceExistingandApproved OrganizedYear CharterYear FirstClassGraduated CoeducationalYear Extinct Notes MergedIntoName black_school ama_a_level one_yr_coll two_yr_coll using `all_schools', clear
	gen Code_i0 = Code 
	merge 1:1 Code_i0 using "$PROJ_PATH/analysis/processed/temp/merged-schools-final-match.dta", assert(1 3) nogen 

	gen approved = 0 
	replace approved = 1 if BoldfaceExistingandApproved == "Y"

	// Clean extinct variable
	gen extinct_yr = regexs(1) if regexm(Extinct,"([0-9][0-9][0-9][0-9])")
	destring extinct_yr, replace 

	gen extinct = 0 
	replace extinct = 1 if !missing(extinct_yr)

	// Clean medical school name 
	replace MedicalSchoolName = ustrtrim(MedicalSchoolName)

	keep Code approved extinct extinct_yr MergedIntoYear_i final_school MedicalSchoolName Location merge_number MergedIntoName black_school ama_a_level one_yr_coll two_yr_coll
	compress

	tempfile all_schools_cleaned
	save `all_schools_cleaned', replace

	rename * *_42
	gen match = Code_42

	keep match approved_42 extinct_42 extinct_yr_42 ama_a_level_42 one_yr_coll_42 two_yr_coll_42

	// Save a tempfile of all schools
	tempfile all_schools_42
	save `all_schools_42', replace

	use "`all_schools_cleaned'", clear
	gen match = final_school

	merge m:1 match using "`all_schools_42'", keep(1 3) nogen
	drop match 
	replace approved_42 = approved if missing(approved_42) & missing(MergedIntoYear_i)
	replace extinct_42 = extinct if missing(extinct_42) & missing(MergedIntoYear_i)
	replace ama_a_level_42 = ama_a_level if missing(ama_a_level_42) & missing(MergedIntoYear_i)

	order Code approved extinct extinct_yr ama_a_level one_yr_coll two_yr_coll approved_42 extinct_42 extinct_yr_42 ama_a_level_42 one_yr_coll_42 two_yr_coll_42 black_school MergedIntoName final_school MergedIntoYear_i merge_number Location MedicalSchoolName 
	compress
	gsort Code final_school

	rename MergedIntoYear_i MergedIntoYear

	rename _all, lower 

	// Prep school code variable for merging 
	gen med_school = code
	replace med_school = strtrim(lower(med_school))
	replace med_school = subinstr(med_school,".","",.)

	// Prep school code variable for merging 
	gen final_med_school = final_school
	replace final_med_school = strtrim(lower(final_med_school))
	replace final_med_school = subinstr(final_med_school,".","",.)

	compress
	save "$PROJ_PATH/analysis/processed/data/amd_med_schools/medical_school_mergers_cleaned.dta", replace

	// Rm temp files 
	rm "$PROJ_PATH/analysis/processed/temp/all-schools.dta"
	rm "$PROJ_PATH/analysis/processed/temp/merged-schools-final-match.dta"	
	
}


//////////////////////////////////////////////////////////
// Assign MD quality based on AMD medical schools ////////
//////////////////////////////////////////////////////////

if `amd_quality' {
	
	// Load raw AMD med school data with foreign medical schools  
	use school_code foreign using "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/foreign_medical_schools_list_1923.dta", clear
	
	// Prep school code variable for merging 
	gen med_school = school_code
	replace med_school = strtrim(lower(med_school))
	replace med_school = subinstr(med_school,".","",.)

	gduplicates drop
	order med_school
	gsort med_school
	gunique med_school
	
	tempfile ms_foreign
	save `ms_foreign', replace
	
	// Load cleaned AMD physician data
	use "$PROJ_PATH/analysis/processed/data/amd_physicians/amd_physicians_cleaned.dta", clear

	// Drop doctors who are not practicing or retired
	tab not_practicing 
	tab retired
	drop if not_practicing == 1 | retired == 1
	drop not_practicing retired 

	// Drop eclectic, homeopaths
	tab year if eclectic == 1 | homeopath == 1
	drop if eclectic == 1 | homeopath == 1
	drop eclectic homeopath 

	// Drop repeated entries 
	tab flag_repeat
	drop if flag_repeat == 1
	drop flag_repeat 

	// Reshape to create separate observation for each medical degree 
	gen long md_id = _n 
	reshape long ms_ grad_year, i(md_id) j(ms_index)
	gen med_school = subinstr(ms_,".","",.)
	drop ms_
	drop if ms_index > 1 & missing(med_school)

	// Merge in foreign medical schools 
	fmerge m:1 med_school using `ms_foreign', keepusing(foreign) keep(1 3) nogen
	recode foreign (mis = 0)

	// Merge in existing and approved indicator and extinct year using original medical school code 
	fmerge m:1 med_school using "$PROJ_PATH/analysis/processed/data/amd_med_schools/medical_school_mergers_cleaned.dta", keepusing(approved extinct extinct_yr one_yr_coll two_yr_coll ama_a_level approved_42 extinct_42 extinct_yr_42 one_yr_coll_42 two_yr_coll_42 ama_a_level_42 black_school mergedintoyear) keep(1 3) 
	tab med_school if _merge == 1
	drop _merge

	// Generate closure year variable 
	gen yr_closed = .
	replace yr_closed = extinct_yr if !missing(extinct_yr) & extinct_yr < 1921 
	replace yr_closed = mergedintoyear if missing(yr_closed) & mergedintoyear < 1921 
	drop mergedintoyear 

	// Code black and white doctors

	// Generate individual identifier - to link individuals over time - to code race
	egen indiv_id = group(last_name first_name birth_year raw_med_school raw_grad_year), m
	egen ever_colored = max(colored == 1), by(indiv_id)

	// Identify black medical schools 
	egen black_med_school = max(black_school == 1), by(md_id)
	drop black_school
	tab black_med_school ever_colored, row
	tab black_med_school colored, row

	gen md_black = (black_med_school == 1 | ever_colored == 1) // colored == 1 
	tab md_black, m
	gen md_white = (md_black == 0)

	// Generate a doctor with a foreign medical degree
	egen md_foreign = max(foreign == 1), by(md_id)
	drop foreign

	// Generate good vs. bad doctor
		* Good doctor should be based on graduation year 
		* Med program was 4 years 

	// List of quality variables:
		* Graduated from a medical school:
			* that introduced two-year college prerequisite in 1926 or earlier 
			* with AMA rating A or A+ (H) vs. rest (L)
			* that remained open in 1926 (H) vs. closed (L)
			* within past 10 years 

	// High vs. low quality doctors - Using AMA rating A or A+ (Did your med school have it <= 1926?)
	egen md_good_ama = max(ama_a_level == 1), by(md_id)
	gen md_bad_ama = (md_good_ama == 0)

	// High vs. low quality based on whether your original medical school is "existing and approved" in 1942
	egen md_good_approve = max(approved == 1), by(md_id)
	gen md_bad_approve = (md_good_approve == 0)

	// High vs. low quality based on whether your final medical school is "existing and approved" in 1942
	egen md_good_approve_42 = max(approved_42 == 1), by(md_id)
	gen md_bad_approve_42 = (md_good_approve_42 == 0)

	// High vs. low quality based on whether your original medical school is "extinct" in 1942 
	egen md_bad_extinct = max(extinct == 1), by(md_id)
	gen md_good_extinct = (md_bad_extinct == 0)

	// High vs. low quality based on whether your original medical school is "extinct" in 1942 
	egen md_bad_extinct_42 = max(extinct_42 == 1), by(md_id)
	gen md_good_extinct_42 = (md_bad_extinct_42 == 0)

	// High vs. low quality based on whether your med school is still open 
	egen md_bad_close = max(!missing(yr_closed)), by(md_id)
	gen md_good_close = (md_bad_close == 0)

	// High vs. low quality doctors - Using 2-year college requirement 
	egen md_good_2yr = max((grad_year > two_yr_coll + 4)*!missing(two_yr_coll)*!missing(grad_year)), by(md_id) 
	egen md_bad_2yr = max( (missing(two_yr_coll) | !missing(grad_year)*!missing(two_yr_coll)*(grad_year <= two_yr_coll + 4))*(md_good_2yr != 1) ), by(md_id)
		
	// Now using 1-year requirement 
	egen md_good_1yr = max((grad_year > one_yr_coll + 4)*!missing(one_yr_coll)*!missing(grad_year)), by(md_id)
	egen md_bad_1yr = max( (missing(one_yr_coll) | !missing(grad_year)*!missing(one_yr_coll)*(grad_year <= one_yr_coll + 4))*(md_good_1yr != 1) ), by(md_id)
	
	egen grad_always_missing = min( missing(grad_year) ), by(md_id)
	tab grad_always_missing
	replace md_good_2yr = . if grad_always_missing == 1
	replace md_bad_2yr = . if grad_always_missing == 1
	tab md_good_2yr md_bad_2yr , m

	// Generate young vs. old doctors based on graduation date 
	egen md_good_recent = max( year - grad_year <= 10), by(md_id) 
	gen md_bad_recent = (md_good_recent == 0) if grad_always_missing != 1
	replace md_good_recent = . if grad_always_missing == 1
	drop grad_always_missing

	// Reshape data to return to one observation per doctor 
	drop med_school grad_year one_yr_coll two_yr_coll ama_a_level yr_closed ms_index black_med_school indiv_id approved approved_42 extinct extinct_42 extinct_yr extinct_yr_42 one_yr_coll_42 two_yr_coll_42 ama_a_level_42
	gduplicates drop
	gunique md_id
	gisid md_id 
	drop md_id 

	// Generate young vs. old doctors based on age 
	gen md_good_young = ( year - birth_year < 45) if !missing(birth_year)
	gen md_bad_young = (md_good_young == 0) if !missing(birth_year)

	// Generate pooled quality measure 
	tab md_good_ama md_good_2yr 
	tab md_good_ama md_bad_close

	gen md_good_all = ((md_good_ama == 1 & md_good_2yr == 1 & md_good_approve == 1 & md_good_approve_42 == 1) & md_bad_extinct == 0 & md_bad_extinct_42 == 0)
	tab md_good_all
	gen md_bad_all = (md_good_all == 0)

	// Generate good vs. bad doctors by race
	*drop md_foreign md_surgeon md_specialist

	foreach var of varlist md_good* md_bad* {
		gen `var'_black = md_black*`var'
		gen `var'_white = md_white*`var'
	}

	// Ensure MD variables are not missing 
	recode md* (mis = 0)

	// Edit county string
	replace county = upper(county)
	replace county = regexr(county,"[ ]\(SEE[ ][A-Z]+\)$","")
	replace county = regexr(county,"^\([A-Z|\.\ ]+\)[ ]","")
	replace county = trim(county)
	replace county = "EDGECOMBE" if county == "EDGECOMBE-NASH"
	replace county = "HARTNETT" if county == "HART-NETT"
	replace county = "PERQUIMANS" if county == "FERQUIMAN"
	replace county = "SAMPSON" if county == "SMAPSON"
	replace county = "DURHAM" if city == "East Durham, Durham (See Durham)"

	replace state = upper(state)

	preserve

		keep state county
		drop if county == ""

		gen obs = 1
		collapse (sum) obs, by(state county)

		// Group strings based on Levenshtein edit distance
		by state: strgroup county, generate(cty_group) threshold(0.2)

		// Assign most common string for each string group
		egen max_obs = max(obs), by(cty_group)
		gen county_nhgis = county if obs == max_obs

		gsort + state + cty_group - county_nhgis
		by state cty_group: carryforward county_nhgis, replace
		drop obs max_obs cty_group

		// Merge in NHGIS county names and GISJOIN 
		fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", assert(2 3) keep(3) nogen keepusing(countyicp statefip fips gisjoin)

		sort state county
		tempfile counties
		save `counties', replace

	restore

	fmerge m:1 state county using `counties', assert(3) nogen
	drop county


	// Edit city string 

	replace city = "Durham" if city == "East Durham, Durham (See Durham)"
	replace city = regexr(city,"^Mt\.","Mount")
	replace city = regexr(city," \((.)*\)$","")
	replace city = lower(city)

	preserve 

		keep fips city 
		drop if city == ""

		gen obs = 1
		collapse (sum) obs, by(fips city)

		// Group strings based on Levenshtein edit distance
		by fips: strgroup city, generate(cty_group) threshold(0.2)

		// Assign most common string for each string group
		egen max_obs = max(obs), by(cty_group)
		gen std_city = city if obs == max_obs

		gsort + fips + cty_group - std_city
		by fips cty_group: carryforward std_city, replace
		drop obs max_obs cty_group
		
		gsort fips city 
		tempfile cities
		save `cities', replace

	restore
		
	merge m:1 fips city using `cities', assert(3) nogen 
	drop city
	rename std_city city

	// Fix population 
	replace city_pop = 1500 if city == "west durham" & year < 1920
	replace city_pop = 2000 if city == "west durham" & year >= 1920
	replace city_pop = 52037 if city == "durham" & city_pop == . & year == 1931

	desc, f 
	compress 
	save "$PROJ_PATH/analysis/processed/data/amd_physicians/amd_physicians_with_med_school_quality.dta", replace 

}


*************************************
// Create NHGIS/ICPSR crosswalk *****
*************************************

if `geoxwk' {

	if !`nhgis' | !`icpsr_cty' {
		di "You have tried to run the AMD code without running a dependency first (NHGIS)."
		break
	}
	
	use "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1920_counties.dta", clear
	
	// NOTE: Kalawao, Hawaii Territory (G1550055) does not have an ICPSR code
	// NOTE: There are 179 observations in the ICPSR file not in the 1920 NHGIS file
	fmerge 1:1 statefip countyicp using "$PROJ_PATH/analysis/processed/data/icpsr/icpsr_county_codes_1850-1930.dta", keepusing(stateicp county_icpsr)
	
	tab _merge
	keep if _merge == 3
	drop _merge 
	
	// Restrict to Carolinas 	
	keep if statefip == 37 | statefip == 45
	
	keep state statefip stateicp county_nhgis countyicp fips gisjoin
	order state statefip stateicp county_nhgis countyicp fips gisjoin
	gisid statefip countyicp
	gsort statefip countyicp
	compress
	save "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", replace
	
}

******************************************************************************************
// Set up GNIS for assigning locations to 1920 counties **********************************
******************************************************************************************

if `gnis' {

	// Load raw GNIS data
	use "$PROJ_PATH/analysis/processed/intermediate/gnis/gnis.dta", clear
	
	drop if lat_dec == "0" | long_dec == "0" | lat_dec == "" | long_dec == ""
	
	gen link_string = lower(feature_name)
	
	replace link_string = regexr(link_string,"^st ","saint ")
	replace link_string = regexr(link_string,"^mt ","mount ")
	
	gen feat_twp  = regexm(link_string,"township")
	gen feat_hist = regexm(link_string,"\(historical\)")

	replace link_string = regexr(link_string,"^township of ","")
	replace link_string = regexr(link_string,"^township[ ][0-9]+[-]","")
	replace link_string = regexr(link_string,"[ ]township$","")
	replace link_string = regexr(link_string,"( )*\(historical\)$","")
	replace link_string = regexr(link_string,"[ ]post[ ]office$", "")
	
	replace link_string = lower(feature_name)
	
	replace link_string = subinstr(link_string," ","",.)
	replace link_string = subinstr(link_string,"-","",.)
	replace link_string = regexr(link_string,"\(historical\)$","")
	
	gen first_letter = substr(link_string,1,1)
	
	compress
	save "$PROJ_PATH/analysis/processed/temp/gnis.dta", replace
	
	
	***** Run code in R to add 1920 counties *****
	cd "$PROJ_PATH"
	shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/_gnis_nhgis_overlay.R"	

	
	// Merge 1920 counties into GNIS
	
	use "$PROJ_PATH/analysis/processed/temp/gnis.dta", clear

	merge m:1 feature_id using "$PROJ_PATH/analysis/processed/intermediate/gnis/gnis_nhgis_xwk.dta", assert(3) nogen
	
	order stateabb statefip countyicp fips gisjoin feature_id
	sort fips feature_id
	
	keep if feature_class == "Populated Place" | feature_class == "Civil"
	
	compress
	save "$PROJ_PATH/analysis/processed/data/gnis/gnis.dta", replace
	
	rm "$PROJ_PATH/analysis/processed/temp/gnis.dta"

}


******************************
// Process NARA Numident *****
******************************

if `numident' {

	// Unzip raw GNIS data
	cd "$PROJ_PATH/analysis/raw/gnis"
	unzipfile "NationalFile_20190301.zip"
	cd "$PROJ_PATH"
	
	// Extract GNIS and prepare geo-crosswalk
	import delim using "$PROJ_PATH/analysis/raw/gnis/NationalFile_20190301.txt", case(lower) delim("|") encoding("utf-8") stringcols(1 10/11) stripq(yes) clear
	keep state_alpha state_numeric county_numeric county_name feature_id feature_name
	order state_alpha state_numeric county_numeric county_name feature_id feature_name
	
	destring feature_id, replace
	bysort feature_id: keep if _N == 1

	gen stctyfips = state_numeric*1000 + county_numeric

	merge 1:m feature_id using "$PROJ_PATH/analysis/raw/numident/ferrie_crosswalk.dta", keep(2 3) keepusing(pobcity) 

	drop if _merge == 2
	drop _merge
		
	gsort state_alpha pobcity
	order state_alpha pobcity

	gduplicates drop
	
	drop feature_id feature_name
	gduplicates drop
	bysort state_alpha pobcity: keep if _N == 1 
	save "$PROJ_PATH/analysis/processed/temp/numident_gnis_crosswalk.dta", replace

	rm "$PROJ_PATH/analysis/raw/gnis/NationalFile_20190301.txt"
	
	// Create state abbreviation to state FIPS code crosswalk
	use "$PROJ_PATH/analysis/processed/temp/numident_gnis_crosswalk.dta", clear

	keep state_alpha state_numeric
	gduplicates drop

	tab state_numeric, m
	keep if state_numeric <= 56
	gsort state_alpha

	save "$PROJ_PATH/analysis/processed/temp/stateabb_xwk.dta", replace

	// Save set of unique birth counties for each unique SSN in SS5 files - exclude foreign births
	use ssn pobstctry pobcity foreignbp using "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta" if foreignbp != "f", clear

	tab foreignbp, m

	rename pobstctry state_alpha
	fmerge m:1 state_alpha pobcity using "$PROJ_PATH/analysis/processed/temp/numident_gnis_crosswalk.dta", keep(1 3) nogen 

	// Merge in state FIPS codes
	drop state_numeric
	fmerge m:1 state_alpha using "$PROJ_PATH/analysis/processed/temp/stateabb_xwk.dta", keepusing(state_numeric) keep(1 3) nogen

	// Save uniquely matched state of birth
	preserve
		keep ssn state_numeric
		gduplicates drop
		
		tab state_numeric, m
		
		// Prioritize if state is non-missing
		egen tot_state_nonmissing = total(state_numeric != .), by(ssn)
		drop if tot_state_nonmissing > 0 & state_numeric == .
		drop tot_state_nonmissing
		gduplicates drop
		
		bysort ssn: gen flag_unique_bstate = (_N == 1 & state_numeric != .)
			replace state_numeric = . if flag_unique_bstate == 0
		gduplicates drop
		rename state_numeric statefip
		save "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bstate.dta", replace
	restore

	keep ssn state_alpha state_numeric county_numeric county_name stctyfips

	// Clean junk in state abbreviation
	replace state_alpha = "" if state_alpha == "/"
	gduplicates drop

	// Prioritize if county is non-missing
	egen tot_stcty_nonmissing = total(stctyfips != .), by(ssn)
	drop if tot_stcty_nonmissing > 0 & stctyfips == .
	drop tot_stcty_nonmissing
	gduplicates drop

	// If more than one birth state per SSN or state FIPS code always missing - code state and county as missing
	fmerge m:1 ssn using "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bstate.dta", keep(1 3) keepusing(flag_unique_bstate) nogen
	recode flag_unique_bstate (mis = 0)

	bysort ssn: replace flag_unique_bstate = 1 if _N == 1 & stctyfips != .
		replace state_alpha = "" if flag_unique_bstate == 0
		replace state_numeric = . if flag_unique_bstate == 0
		replace county_numeric = . if flag_unique_bstate == 0
		replace county_name = "" if flag_unique_bstate == 0
		replace stctyfips = . if flag_unique_bstate == 0
	gduplicates drop

	// If birth state unique, prioritize non missing birth state
	egen tot_state_nonmissing = total(state_numeric != .), by(ssn)
	drop if tot_state_nonmissing > 0 & state_numeric == .
	drop tot_state_nonmissing
	gduplicates drop

	// If birth state unique, prioritize non-missing birth county
	egen tot_coded_cty = total(stctyfips != .), by(ssn)
	drop if tot_coded_cty > 0 & stctyfips == .
	drop tot_coded_cty
	gduplicates drop

	// If birth state unique, and more than one birth county per SSN - code county as missing
	bysort ssn: gen flag_unique_bpl = (_N == 1)
		replace county_name = "" if flag_unique_bpl == 0
		replace county_numeric = . if flag_unique_bpl == 0
		replace stctyfips = . if flag_unique_bpl == 0
	gduplicates drop
	gunique ssn	
	save "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bpl.dta", replace
	rm "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bstate.dta"

	// Save set of unique genders for each unique SSN
	use ssn sex using "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta" if sex == 1 | sex == 2, clear
	bysort ssn sex: keep if _n == 1

		// Prioritize if sex matches death files
		rename sex sex_ss5
		fmerge m:1 ssn using "$PROJ_PATH/analysis/processed/intermediate/numident/death/death_files.dta", keep(1 3) nogen keepusing(sex)
		
		egen tot_sex_match = total(sex == sex_ss5 & (sex == 1 | sex == 2)), by(ssn)
		drop if tot_sex_match > 0 & sex != sex_ss5
		drop tot_sex_match 
		
		rename sex sex_dth
		gen flag_sex_mismatch = ((sex_ss5 != sex_dth) & (sex_ss5 == 1 | sex_ss5 == 2) & (sex_dth == 1 | sex_dth == 2))
		
	bysort ssn: gen flag_unique_sex = (_N == 1)
	replace sex_ss5 = 0 if flag_unique_sex == 0 										// Consider gender to be missing if multiple genders reported
	keep ssn sex_ss5 flag_sex_mismatch
	gduplicates drop
	rename sex_ss5 sex

	save "$PROJ_PATH/analysis/processed/temp/cwk_ssn_sex.dta", replace

	// Save set of unique races for each unique SSN
	use ssn race using "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta" if race != 0, clear
	duplicates drop
	bysort ssn: gen flag_unique_race = (_N == 1)
	replace race = 0 if flag_unique_race == 0											// Consider race to be missing if multiple races reported
	keep ssn race
	gduplicates drop
	save "$PROJ_PATH/analysis/processed/temp/cwk_ssn_race.dta", replace

	// Save set of unique birth dates for each unique SSN
	use ssn yobss5 mobss5 dobss5 using "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta", clear
	duplicates drop

	gen bdate_ss5 = mdy(mobss5, dobss5, yobss5)
	format bdate_ss5 %td

		// Prioritize entries with complete date of birth
		egen tot_bdate = total(bdate_ss5 != .), by(ssn)
		drop if tot_bdate > 0 & bdate_ss5 == .
		drop tot_bdate
		
	fmerge m:1 ssn using "$PROJ_PATH/analysis/processed/intermediate/numident/death/death_files.dta", keep(1 3) nogen keepusing(yobdth mobdth dobdth)

	gen bdate_dth = mdy(mobdth, dobdth, yobdth)
	format bdate_dth %td

		// Prioritize entries with matching date of birth in SS5 and death files
		egen tot_bdate_match = total(bdate_ss5 == bdate_dth & bdate_ss5 != .), by(ssn)
		drop if tot_bdate_match > 0 & bdate_ss5 != bdate_dth
		drop tot_bdate_match

	bysort ssn: gen flag_unique_bdate = (_N == 1)
	egen flag_bdate_conflict = max(bdate_dth != . & bdate_dth != bdate_ss5), by(ssn)
	egen flag_bym_conflict = max(yobdth != . & mobdth != . & (yobdth != yobss5 | mobdth != mobss5)), by(ssn)

	// If conflict choose birth date reported in death file
	gen bdate_ssn = .
	format bdate_ssn %td

	gen yobssn = .
	gen mobssn = .
	gen dobssn = .

	replace bdate_ssn = bdate_ss5 if flag_unique_bdate == 1 & flag_bdate_conflict == 0
	replace yobssn = yobss5 if flag_unique_bdate == 1 & flag_bdate_conflict == 0
	replace mobssn = mobss5 if flag_unique_bdate == 1 & flag_bdate_conflict == 0
	replace dobssn = dobss5 if flag_unique_bdate == 1 & flag_bdate_conflict == 0

	replace bdate_ssn = bdate_dth if flag_bdate_conflict == 1
	replace yobssn = yobdth if flag_bdate_conflict == 1
	replace mobssn = mobdth if flag_bdate_conflict == 1
	replace dobssn = dobdth if flag_bdate_conflict == 1

	// If multiple birth dates, check for unique birth year, month, or day
	gegen min_yob = min(yobss5), by(ssn)
	gegen max_yob = max(yobss5), by(ssn)
	replace yobssn = min_yob if yobssn == . & yobss5 != . & min_yob == max_yob
	drop min_yob max_yob

	gegen min_mob = min(mobss5), by(ssn)
	gegen max_mob = max(mobss5), by(ssn)
	replace mobssn = min_mob if mobssn == . & mobss5 != . & min_mob == max_mob
	drop min_mob max_mob

	gegen min_dob = min(dobss5), by(ssn)
	gegen max_dob = max(dobss5), by(ssn)
	replace dobssn = min_dob if dobssn == . & dobss5 != . & min_dob == max_dob
	drop min_dob max_dob

	keep ssn bdate_ssn yobssn mobssn dobssn flag_bdate_conflict flag_bym_conflict
	gduplicates drop

	// Resolve remaining mismatches 
	bysort ssn: gen mult_obs = (_N > 1)

	gegen min_yob = min(yobssn), by(ssn)
	gegen max_yob = max(yobssn), by(ssn)
	replace yobssn = min_yob if yobssn == . & min_yob == max_yob & mult_obs == 1
	drop min_yob max_yob

	gegen min_mob = min(mobssn), by(ssn)
	gegen max_mob = max(mobssn), by(ssn)
	replace mobssn = min_mob if mobssn == . & min_mob == max_mob & mult_obs == 1
	drop min_mob max_mob

	gegen min_dob = min(dobssn), by(ssn)
	gegen max_dob = max(dobssn), by(ssn)
	replace dobssn = min_dob if dobssn == . & min_dob == max_dob & mult_obs == 1
	drop min_dob max_dob

	drop mult_obs
	gduplicates drop

	gunique ssn
	save "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bdate.dta", replace
	
	// Restrict to SSNs with unique values of each variables
	use ssn using "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta", clear
	bysort ssn: keep if _n == 1

	fmerge 1:1 ssn using "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bdate.dta", keep(3) nogen
	fmerge 1:1 ssn using "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bpl.dta", keep(3) nogen 
	
	drop if yobssn == . | mobssn == . | stctyfips == . 

	// Restrict to 1920 to 1942 (last year for which we can calculate death by 65)
	keep if yobssn >= 1920 & yobssn <= 1942
	
	// Restrict to NC, SC, and other southern states 
	keep if  	state_alpha == "AL" | state_alpha == "AR" | state_alpha == "DC" | state_alpha == "FL" | state_alpha == "GA" | state_alpha == "KY" | ///
				state_alpha == "LA" | state_alpha == "MD" | state_alpha == "MS" | state_alpha == "NC" | state_alpha == "OK" | state_alpha == "SC" | ///
				state_alpha == "TN" | state_alpha == "TX" | state_alpha == "VA" | state_alpha == "WV"
				
	tab state_alpha, m
	
	fmerge 1:1 ssn using "$PROJ_PATH/analysis/processed/temp/cwk_ssn_sex.dta", keep(3) nogen
	fmerge 1:1 ssn using "$PROJ_PATH/analysis/processed/temp/cwk_ssn_race.dta", keep(3) nogen
	fmerge 1:1 ssn using "$PROJ_PATH/analysis/processed/intermediate/numident/death/death_files.dta", keep(3) nogen keepusing(yod mod dod)

	rename yod yodssn
	rename mod modssn
	rename dod dodssn

	order flag_*, last
	gsort ssn	
	drop ssn
	
	compress
	save "$PROJ_PATH/analysis/processed/data/numident/numident_south_indiv_1920-1942.dta", replace
	
	// Restrict to NC and SC
	keep if state_alpha == "NC" | state_alpha == "SC"
	
	compress
	save "$PROJ_PATH/analysis/processed/data/numident/numident_carolina_indiv_1920-1942.dta", replace
	
	rm "$PROJ_PATH/analysis/processed/temp/cwk_ssn_sex.dta"
	rm "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bpl.dta"
	rm "$PROJ_PATH/analysis/processed/temp/cwk_ssn_race.dta"
	rm "$PROJ_PATH/analysis/processed/temp/cwk_ssn_bdate.dta"
	rm "$PROJ_PATH/analysis/processed/temp/stateabb_xwk.dta"
	rm "$PROJ_PATH/analysis/processed/temp/numident_gnis_crosswalk.dta"
	
}

**********************
// Final cleanup *****
**********************

// Remove temp files 
forvalues year = 1923/1948 {
	cap rm "$PROJ_PATH/analysis/processed/temp/imr_mmr_`year'.dta"
}

forvalues year = 1922/1948 {
	cap rm "$PROJ_PATH/analysis/processed/temp/share_phys_att_`year'.dta"
}
	
cap rm "$PROJ_PATH/analysis/processed/temp/imr_1918_1922.dta"	
cap rm "$PROJ_PATH/analysis/processed/temp/locations.dta"
cap rm "$PROJ_PATH/analysis/processed/temp/locations-unique-by-state.dta"
cap rm "$PROJ_PATH/analysis/processed/temp/locations-unique.dta"
		

disp "DateTime: $S_DATE $S_TIME"

* EOF
