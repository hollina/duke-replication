version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 3_geocode_nc_deaths.do
* PURPOSE: Identify birth county in NC death certificate data

************

// DEPENDENCIES in 1_process_raw_data.do: nhgis, gnis, icpsr
// DEPENDENCIES in 2_clean_data.do: nhgis, geoxwk, gnis, icpsr_cty

local update		0	// Archive previous version of output files
local dpl_coding	1
local bpl_coding	1
local cleanup		1

*************************************************
// Archive previous version of output files *****
*************************************************

if `update' {

	local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
	di "`datetime'"
	
	use "$PROJ_PATH/analysis/processed/data/nc_deaths/nc_death_certificates_cleaned.dta", clear
	save "$PROJ_PATH/analysis/processed/data/nc_deaths/_archived_`datetime'_nc_death_certificates_cleaned.dta", replace

}

*****************************************
// Clean NC death certificates data *****
*****************************************

if `dpl_coding' {
	
	/* Clean death place */

	// Load raw data 
	use dpl using "$PROJ_PATH/analysis/raw/nc_deaths/nc_deaths_raw.dta", clear
	bysort dpl: keep if _n == 1

	gen dpl_orig = dpl

	split dpl, parse(,) gen(dd)

	gen state = "NORTH CAROLINA"
	gen dctyfips = .
	gen dcounty = ""

	foreach n in 2 3 4 5 1 {
		replace dd`n' = trim(dd`n')
		gen county_nhgis = upper(dd`n')
		fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(fips) keep(1 3)
		replace dd`n' = "" if _merge == 3 & dctyfips == .
		replace dctyfips = fips if _merge == 3 & dctyfips == .
		replace dcounty = county_nhgis if _merge == 3 & dcounty == ""
		drop _merge fips county_nhgis
	}
	egen death_edit = concat(dd*), punct(", ")
	replace death_edit = regexr(death_edit,"[, ]*[, ]*[, ]*[, ]*[, ]$","")
	replace death_edit = regexr(death_edit,", ,",",")
	replace death_edit = regexr(death_edit,", ,",",")
	replace death_edit = regexr(death_edit,"^, ","")
	drop dd* 

	global event_place = "death_edit"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"

	keep dpl_orig death_edit dcounty dctyfips
	order dpl_orig death_edit dcounty dctyfips
	
	rename death_edit d_location
	rename dpl_orig dpl

	gsort dpl
	compress
	save "$PROJ_PATH/analysis/processed/temp/dp_cleaned.dta", replace
	
	// Create temporary file with cleaned death place as input for birth place cleaning
	use "$PROJ_PATH/analysis/raw/nc_deaths/nc_deaths_raw.dta", clear
	fmerge m:1 dpl using "$PROJ_PATH/analysis/processed/temp/dp_cleaned.dta", assert(3) nogen
	save "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", replace
	
}

if `bpl_coding' {
	
	
	/* Clean birth place */

	
	***** Counties *****

	use statefip county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta" if statefip == 37, clear
	save "$PROJ_PATH/analysis/processed/temp/nc_counties.dta", replace

	
	
	***** Cities and towns *****

	use statefip county stdcity total_obs using "$PROJ_PATH/analysis/processed/intermediate/nhgis/ipums_placenhg_codes_1940.dta", clear
	rename county countyicp
	rename stdcity location
	drop if location == ""
	gegen max_obs = max(total_obs), by(countyicp location)
	drop if total_obs != max_obs
	drop if max_obs < 10
	drop *obs
	bysort statefip countyicp location: keep if _n == 1
	fmerge m:1 statefip countyicp using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(fips state county_nhgis gisjoin) assert(2 3) keep(3) nogen
	order statefip countyicp fips state county_nhgis location gisjoin

	replace location = subinstr(location,".","",.)
	drop if regexm(location,"CAROLINA")
	gsort statefip countyicp location

	gen temp = statefip
	drop statefip
	rename temp statefip
	order fips statefip

	compress
	gsort location fips
	egen obs_id = seq(), by(location)
	gegen tot_obs = max(obs_id), by(location)
	gen flag_multcty = (tot_obs > 1)
	drop if obs_id > 1
	drop obs_id tot_obs
	gsort fips location
	keep location county_nhgis
	order location county_nhgis
	save "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", replace
	
	
	
	***** Unincorporated communities *****

	use "$PROJ_PATH/analysis/processed/intermediate/nhgis/unincorporated_placenhg_1910_1940.dta", clear
	
	gen town = upper(unincorporated)

	replace town = subinstr(town,".","",.)

	replace town = regexr(town," STARTS ON (.)*$","")
	replace town = regexr(town," BEGINS ON (.)*$","")
	replace town = regexr(town," BEGIN(.)*$","")
	replace town = regexr(town," BEGANS(.)*$","")
	replace town = regexr(town," BEGAN(.)*$","")
	replace town = regexr(town," ENDS ON (.)*$","")
	replace town = regexr(town," ENDS (.)*$","")
	replace town = regexr(town," ENDINS (.)*$","")
	replace town = regexr(town," ENDIN (.)*$","")
	replace town = regexr(town," LINES (.)*$","")
	replace town = regexr(town," [0-9]+[ TO ](.)*$","")
	replace town = regexr(town," \((.)*$","")
	replace town = regexr(town,"^\((.)*\) ","")
	replace town = regexr(town," NC$","")
	replace town = regexr(town," N CAR$","")
	replace town = regexr(town," RT [0-9]+$","")
	replace town = regexr(town," LINE (.)*$","")
	replace town = regexr(town," [0-9]+-[0-9]+$","")

	gcollapse (sum) obs, by(state county town)

	keep if obs > 100
	drop obs
	drop if town == ""

	replace state = upper(state)
	replace county = upper(county)

	rename county county_nhgis

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3) nogen

	duplicates drop
	
	tempfile towns
	save `towns', replace

	use feature_name statefip countyicp fips using "$PROJ_PATH/analysis/processed/data/gnis/gnis.dta", clear
	recast str feature_name
	
	replace feature_name = upper(feature_name)
	replace feature_name = subinstr(feature_name,"'","",.)
	replace feature_name = regexr(feature_name,"^TOWNSHIP OF ","")
	replace feature_name = regexr(feature_name,"^TOWNSHIP ","")
	replace feature_name = regexr(feature_name," TOWNSHIP "," ")
	replace feature_name = regexr(feature_name,"TOWNSHIP","")
	replace feature_name = regexr(feature_name,"^TOWN OF ","")
	replace feature_name = regexr(feature_name,"^CITY OF ","")
	replace feature_name = regexr(feature_name,"^VILLAGE OF ","")
	replace feature_name = regexr(feature_name," MOBILE HOME PARK$","")
	replace feature_name = regexr(feature_name," \(HISTORICAL\)$","")
	replace feature_name = regexr(feature_name,"^[0-9]+[-]","")
	replace feature_name = regexr(feature_name,"^[0-9]+[, ]","")
	replace feature_name = regexr(feature_name,"[ ]NUMBER[ ][0-9]+$","")
	replace feature_name = regexr(feature_name,"[ ][0-9]+$","")
	
	rename feature_name town
	duplicates drop
	
	merge m:1 fips town using `towns', keep(3) nogen

	keep town county_nhgis
	bysort town county_nhgis: keep if _n == 1
	bysort town: keep if _N == 1
	gen location = town
	fmerge 1:1 location using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", keep(1) nogen keepusing(location)
	drop location
	gsort town
	drop if town == "CAROLINA" | town == "CAROLEEN" | length(town) <= 2
	gsort county_nhgis town
	order county_nhgis town
	compress
	
	save "$PROJ_PATH/analysis/processed/temp/nc_towns.dta", replace
	
	
	
	***** Full GNIS file *****

	use feature_name statefip countyicp fips using "$PROJ_PATH/analysis/processed/data/gnis/gnis.dta", clear
	recast str feature_name
	rename feature_name feature

	replace feature = upper(feature)
	replace feature = subinstr(feature,"'","",.)
	replace feature = regexr(feature,"^TOWNSHIP OF ","")
	replace feature = regexr(feature,"^TOWNSHIP ","")
	replace feature = regexr(feature," TOWNSHIP "," ")
	replace feature = regexr(feature,"TOWNSHIP","")
	replace feature = regexr(feature,"^TOWN OF ","")
	replace feature = regexr(feature,"^CITY OF ","")
	replace feature = regexr(feature,"^VILLAGE OF ","")
	replace feature = regexr(feature," MOBILE HOME PARK$","")
	replace feature = regexr(feature," \(HISTORICAL\)$","")
	replace feature = regexr(feature,"^[0-9]+[-]","")
	replace feature = regexr(feature,"^[0-9]+[, ]","")
	replace feature = regexr(feature,"[ ]NUMBER[ ][0-9]+$","")
	replace feature = regexr(feature,"[ ][0-9]+$","")
	replace feature = regexr(feature," VILLAGE$","")
	replace feature = regexr(feature,"^NORTH ","")
	replace feature = regexr(feature,"^SOUTH ","")
	replace feature = regexr(feature,"^EAST ","")
	replace feature = regexr(feature,"^WEST ","")
	replace feature = regexr(feature," NORTH$","")
	replace feature = regexr(feature," SOUTH$","")
	replace feature = trim(feature)
	rename statefip stfips

	keep feature fips
	drop if feature == "CAROLINA" | feature == "CAROLEEN" | regexm(feature,"SUBDIVISION") | regexm(feature,"COUNTY") | regexm(feature,"MOBILE") | regexm(feature,"ESTATE") | regexm(feature,"MANOR") | ///
		regexm(feature,"ACRES") | regexm(feature,"FARM") | regexm(feature,"HOMES") | regexm(feature,"CLUB") | regexm(feature,"STORE") | regexm(feature,"TRAILER") | regexm(feature,"TERRACE") | regexm(feature,"FOREST") | ///
		regexm(feature,"SHORES") | regexm(feature,"CROSSROADS") | regexm(feature," WOODS$") | regexm(feature," HILLS$") | regexm(feature,"CHURCH") | regexm(feature,"SHANGRI") | regexm(feature,"HEIGHTS") | regexm(feature,"RIDGE") | ///
		regexm(feature," YARD") | regexm(feature,"^THE ") | regexm(feature," SQUARE") | regexm(feature,"RESERVATION") | regexm(feature,"COMMUNITY") | regexm(feature,"HOUSING") | regexm(feature,"CONDOMINIUM") | /// 
		regexm(feature,"LANDING") | regexm(feature,"PRESINCT") | regexm(feature,"PINES") | regexm(feature,"DOWNS") | length(feature) <= 3 | regexm(feature,"^[A-Z][ ]")
	bysort feature fips: keep if _n == 1
	bysort feature: keep if _N == 1
	rename fips bctyfips_gnis

	gen town = feature
	fmerge m:1 town using "$PROJ_PATH/analysis/processed/temp/nc_towns.dta", keep(1) nogen keepusing(town)
	drop town
	gen location = feature
	fmerge m:1 location using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", keep(1) nogen keepusing(location)
	drop location

	gen block_chars = substr(feature,1,2)
	gsort block_chars feature bctyfips_gnis
	order block_chars feature bctyfips_gnis

	drop if regexm(feature,"CAROLINA") & regexm(feature,"BEACH") == 0
	compress
	save "$PROJ_PATH/analysis/processed/temp/nc_features.dta", replace



	/* Identify birth country */

	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	gen bcntry = .

	split birth_place, parse(", ") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		rename bp`n' country
		do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_destring_country.do"
		replace bcntry = country if country != . & bcntry == .
		drop country
	}

	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_country_labels.do"
	la val bcntry bpl_lbl

	// Don't code countries with same/similar to NC county/city names (e.g. Badin, Halifax, Scotland)
	replace bcntry = . if bcntry < 100 | bcntry == 41100 | bcntry == 15052 | bcntry == 30025 | bcntry == 45311 | bcntry == 45316 
	replace bcntry = . if bcntry == 26043 & regexm(birth_place,"[M|N]assa[u|n]") == 0 & regexm(birth_place,"Is") == 0
	replace bcntry = . if bpl == "Durham, Canada" | bpl == "Jackson, Canada" | bpl == "Mcdowell, Canada" | regexm(bpl,"Spain") | bpl == "Cleveland, Canada" | regexm(bpl,"China") | bpl == "Benin" | regexm(bpl,"Berlin") | bpl == "Cooper" | regexm(bpl,"W[i|e]sser") | regexm(bpl,"Wilmington") | regexm(bpl,"Romania") | regexm(bpl,"Turkey") | regexm(bpl,"Cyprus")
	replace bcntry = 26043 if regexm(birth_place,"Bahama") & regexm(birth_place,"Is")

	keep bpl bcntry
	keep if bcntry != . & bcntry != 99700

	compress
	save "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta", replace



	/* Identify birth state [parse on comma] */

	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	keep bpl
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	gen bstate = .
	replace bstate = 37 if regexm(upper(birth_place),"NORTH CAROLIN[A]*") | regexm(upper(birth_place),"[^A-Z]N[ ]*C") | regexm(upper(birth_place),"[^A-Z]N CAROLINA") | regexm(upper(birth_place),"[^A-Z]N CAR") | regexm(upper(birth_place),"^N[ ]*C[^A-Z]")
	replace bstate = 45 if regexm(upper(birth_place),"SO[R|U]TH CAROLIN[A]*") | regexm(upper(birth_place),"[^A-Z]S[ ]*C") | regexm(upper(birth_place),"[^A-Z]S CAROLINA") | regexm(upper(birth_place),"[^A-Z]S CAR")

	global event_place = "birth_place"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"
	compress bpl birth_place

	replace bstate = 37 if regexm(upper(birth_place),"NORTH CAROLINA")
	replace bstate = 45 if regexm(upper(birth_place),"SOUTH CAROLINA")

	compress
	save "$PROJ_PATH/analysis/processed/temp/bstate_split_input.dta", replace


	use "$PROJ_PATH/analysis/processed/temp/bstate_split_input.dta", clear
	split birth_place, parse(",") gen(bp)
	local n_max = r(nvars)

	forvalues n = `n_max'(-1)1 {
		replace bp`n' = trim(bp`n')
		replace bp`n' = proper(bp`n')
		rename bp`n' state
		do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_destring_states.do"
		replace bstate = state if state != . & (bstate == . | bstate == 99)
		drop state
	}

	gen stateabb = regexs(1) if regexm(birth_place,"[^A-Z]([A-Z][ |\.]*[A-Z])$")
	replace stateabb = subinstr(stateabb," ","",.)

	fmerge m:1 stateabb using "$PROJ_PATH/analysis/raw/gnis/stateabb.dta", keep(1 3) nogen keepusing(statefip)

	replace bstate = statefip if statefip != . & (bstate == . | bstate == 99)
	drop statefip stateabb
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_stfips_labels.do"
	la val bstate statefip_lbl

	keep bpl bstate
	recode bstate (mis = 99)
	compress
	
	gisid bpl bstate, missok
	gsort bpl bstate
	
	save "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", replace



	/* Identify birth state [parse on space] */

	use "$PROJ_PATH/analysis/processed/temp/bstate_split_input.dta", clear

	replace birth_place = subinstr(birth_place,","," ",.)
	replace birth_place = subinstr(birth_place,"  "," ",.)
	replace birth_place = subinstr(birth_place,"  "," ",.)

	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)

	forvalues n = `n_max'(-1)1 {
		replace bp`n' = trim(bp`n')
		replace bp`n' = proper(bp`n')
		rename bp`n' state
		do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_destring_states.do"
		replace bstate = state if state != . & (bstate == . | bstate == 99)
		drop state
	}

	gen stateabb = regexs(1) if regexm(birth_place,"[^A-Z]([A-Z][ ]*[A-Z])$")
	replace stateabb = subinstr(stateabb," ","",.)

	fmerge m:1 stateabb using "$PROJ_PATH/analysis/raw/gnis/stateabb.dta", keep(1 3) nogen keepusing(statefip)

	replace bstate = statefip if statefip != . & (bstate == . | bstate == 99)
	drop statefip stateabb
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_stfips_labels.do"
	la val bstate statefip_lbl

	keep bpl bstate
	recode bstate (mis = 99)
	rename bstate bstate_sp
	compress
	
	gisid bpl bstate_sp, missok
	gsort bpl bstate_sp
	
	save "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta", replace



	/* Identify birth state (Cross) [parsed on comma] */

	use statefip using "$PROJ_PATH/analysis/raw/gnis/stateabb.dta", clear
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_stfips_labels.do"
	la val statefip statefip_lbl
	decode statefip, gen(state)
	replace state = proper(state)
	drop statefip
	drop if state == ""
	sort state
	save "$PROJ_PATH/analysis/processed/temp/state_names.dta", replace


	use "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", clear
	tab bstate, m
	keep if bstate == 99
	keep bpl 
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	global event_place = "birth_place"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"

	compress
	split birth_place, parse(",") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}

	cross using "$PROJ_PATH/analysis/processed/temp/state_names.dta"
	save "$PROJ_PATH/analysis/processed/temp/jw_input_states.dta", replace

	qui {
		forvalues m = 1(1)`n_max' {

			use "$PROJ_PATH/analysis/processed/temp/jw_input_states.dta", clear
			
			keep bp`m' state
			bysort bp`m' state: keep if _n == 1
			keep if bp`m' != "" & length(bp`m') >= 3
			rename bp`m' birth_place
			
			tempfile jw_input`m'
			save `jw_input`m'', replace
			
			count
			
			local total_loops = ceil(r(N)/50000)
			display `total_loops'
			forvalues n = 1(1)`total_loops' {
				local bot = (`n' - 1)*50000 + 1
				display `bot'
				local top = `bot' + 49999
				display `top'
				use `jw_input`m'', clear
				keep if _n >= `bot' & _n <= `top'
				count
				jarowinkler birth_place state, gen(jw_st)
				tempfile jw`m'`n'
				save `jw`m'`n'', replace
			}
			
			clear
			
			forvalues n = 1(1)`total_loops' {
				append using `jw`m'`n''
			}
			
			keep if jw_st >= 0.9
			count
			if r(N) > 0 {
				gegen jw_max = max(jw_st), by(birth_place)
				drop if jw_st != jw_max
				drop jw_max
				bysort birth_place: keep if _N == 1
				
				tempfile jw_matched_`m'
				save `jw_matched_`m'', replace
			}
		}

		clear
		forvalues m = 1(1)`n_max' {
			capture append using `jw_matched_`m''
		}
	}

	keep birth_place state jw_st
	gegen jw_max = max(jw_st), by(birth_place state)
	drop if jw_st != jw_max
	drop jw_max 

	bysort birth_place state jw_st: keep if _n == 1
	bysort birth_place: keep if _N == 1

	save "$PROJ_PATH/analysis/processed/temp/jw_matched_states.dta", replace
	rm "$PROJ_PATH/analysis/processed/temp/jw_input_states.dta"

	use "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta" if bstate == 99, clear
	keep bpl 
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	global event_place = "birth_place"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"

	compress
	split birth_place, parse(",") gen(bp)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}
	drop birth_place
	gen matched_state = ""
	gen matched_jw = .
	forvalues n = `n_max'(-1)1 {
		rename bp`n' birth_place
		fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_states.dta", keep(1 3) nogen
		gen accept_match = (state != "" & matched_state == "" & (jw_st > matched_jw | matched_jw == .))
		replace matched_state = state if accept_match == 1
		replace matched_jw = jw_st if accept_match == 1
		drop birth_place state accept_match jw_st
	}
	keep bpl matched_state matched_jw
	rename matched_state state
	rename matched_jw jw_st

	replace state = proper(state)
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_destring_states.do"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_stfips_labels.do"
	rename state bstate_jw
	la val bstate_jw statefip_lbl

	keep bpl bstate_jw jw_st
	keep if bstate_jw != 99 | bstate_jw != 53
	
	gisid bpl bstate_jw jw_st, missok
	gsort bpl bstate_jw jw_st

	save "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta", replace



	/* Identify birth county (Exact) [parsed on comma] */

	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	gen county = ""
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]CO$") 
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]CO,")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]CO$")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]CO,")

	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]COUNTY$") 
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]COUNTY,")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]COUNTY$")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]COUNTY,")

	global event_place = "birth_place"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"

	replace birth_place = regexr(birth_place,"^NORTH CAROLINA ","")
	replace birth_place = regexr(birth_place,"^NORTH CAROLINA, ","")
	replace birth_place = regexr(birth_place,"(,)* NORTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"(,)* NORTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"[ ]NORTH CAROLINA[ ]"," ")
	replace birth_place = regexr(birth_place,", NORTH CAROLINA,",",")

	replace birth_place = regexr(birth_place,"^SOUTH CAROLINA ","")
	replace birth_place = regexr(birth_place,"^SOUTH CAROLINA, ","")
	replace birth_place = regexr(birth_place,"(,)* SOUTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"(,)* SOUTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"[ ]SOUTH CAROLINA[ ]"," ")
	replace birth_place = regexr(birth_place,", SOUTH CAROLINA,",",")
	replace birth_place = "" if birth_place == "NORTH CAROLINA" | birth_place == "SOUTH CAROLINA"

	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = trim(birth_place)
	replace birth_place = regexr(birth_place,"( )*,$","")
	replace birth_place = regexr(birth_place,"^OF ","")
	replace birth_place = regexr(birth_place," OF "," ")
	replace birth_place = regexr(birth_place," RT "," ")
	replace birth_place = regexr(birth_place," RT$","")
	replace birth_place = regexr(birth_place,",$","")
	replace birth_place = trim(birth_place)
	compress bpl birth_place

	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta", assert(1 3) nogen
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", assert(1 3) nogen
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta", assert(1 3) nogen
	replace bstate = bstate_sp if bstate == . & bstate_sp != .
	drop bstate_sp
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta", assert(1 3) nogen keepusing(bstate_jw)
	replace bstate = bstate_jw if bstate == . & bstate_jw != .
	drop bstate_jw

	keep if bstate == 37 | (bstate == 99 & (bcntry == . | bcntry == 99700))
	drop bcntry bstate

	gen bp_raw = birth_place
	replace birth_place = county if county != ""
	drop county
	drop if birth_place == ""

	split birth_place, parse(",") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}	
	compress birth_place

	gen state = "NORTH CAROLINA"
	gen bctyfips = .
	gen bcounty = ""

	forvalues n = `n_max'(-1)1 {
		replace bp`n' = trim(bp`n')
		gen county_nhgis = upper(bp`n')
		fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
		replace bp`n' = "" if _merge == 3 & bctyfips == .
		replace bctyfips = fips if _merge == 3 & bctyfips == .
		replace bcounty = county_nhgis if _merge == 3 & bcounty == ""
		drop _merge fips county_nhgis
	}
	egen bpl_edit = concat(bp1-bp`n_max'), punct(", ")
	replace bpl_edit = regexr(bpl_edit,"[, ]*[, ]*[, ]*[, ]*[, ]$","")
	replace bpl_edit = regexr(bpl_edit,", ,",",")
	replace bpl_edit = regexr(bpl_edit,", ,",",")
	replace bpl_edit = regexr(bpl_edit,"^, ","")
	replace bpl_edit = bp_raw if bctyfips == .

	drop bp1-bp`n_max' birth_place state bp_raw
	rename bpl_edit birth_place
	order bpl birth_place
	
	gisid bpl birth_place bctyfips bcounty, missok
	gsort bpl birth_place bctyfips bcounty

	save "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", replace

	keep if bctyfips != .
	keep bpl bctyfips bcounty
	
	gisid bpl, missok
	gsort bpl
	
	save "$PROJ_PATH/analysis/processed/temp/cty_exact_match_comma.dta", replace



	/* Identify birth county (Exact) [parsed on space] */

	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl: keep if _n == 1
	gen birth_place = bpl

	gen county = ""
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]CO$") 
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]CO,")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]CO$")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]CO,")

	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]COUNTY$") 
	replace county = regexs(1) if regexm(upper(birth_place),"[ ]([A-Z]+)[ ]COUNTY,")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]COUNTY$")
	replace county = regexs(1) if regexm(upper(birth_place),"^([A-Z]+)[ ]COUNTY,")

	global event_place = "birth_place"
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_clean_nc_location_strings.do"

	replace birth_place = regexr(birth_place,"^NORTH CAROLINA ","")
	replace birth_place = regexr(birth_place,"^NORTH CAROLINA, ","")
	replace birth_place = regexr(birth_place,"(,)* NORTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"(,)* NORTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"[ ]NORTH CAROLINA[ ]"," ")
	replace birth_place = regexr(birth_place,", NORTH CAROLINA,",",")

	replace birth_place = regexr(birth_place,"^SOUTH CAROLINA ","")
	replace birth_place = regexr(birth_place,"^SOUTH CAROLINA, ","")
	replace birth_place = regexr(birth_place,"(,)* SOUTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"(,)* SOUTH CAROLINA$","")
	replace birth_place = regexr(birth_place,"[ ]SOUTH CAROLINA[ ]"," ")
	replace birth_place = regexr(birth_place,", SOUTH CAROLINA,",",")
	replace birth_place = "" if birth_place == "NORTH CAROLINA" | birth_place == "SOUTH CAROLINA"

	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"^[A-Z][ ]","")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z][ ]"," ")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = regexr(birth_place,"[ ][A-Z]$","")
	replace birth_place = trim(birth_place)
	replace birth_place = regexr(birth_place,"( )*,$","")
	replace birth_place = regexr(birth_place,"^OF ","")
	replace birth_place = regexr(birth_place," OF "," ")
	replace birth_place = regexr(birth_place," RT "," ")
	replace birth_place = regexr(birth_place," RT$","")
	replace birth_place = regexr(birth_place,",$","")
	replace birth_place = trim(birth_place)
	compress bpl birth_place

	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta", assert(1 3) nogen
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", assert(1 3) nogen
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta", assert(1 3) nogen
	replace bstate = bstate_sp if bstate == . & bstate_sp != .
	drop bstate_sp
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta", assert(1 3) nogen keepusing(bstate_jw)
	replace bstate = bstate_jw if bstate == . & bstate_jw != .
	drop bstate_jw

	keep if bstate == 37 | (bstate == 99 & (bcntry == . | bcntry == 99700))
	drop bcntry bstate

	gen bp_raw = birth_place
	replace birth_place = county if county != ""
	drop county
	drop if birth_place == ""

	replace birth_place = subinstr(birth_place,","," ",.)
	replace birth_place = subinstr(birth_place,"  "," ",.)
	replace birth_place = subinstr(birth_place,"  "," ",.)

	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}	
	compress birth_place

	gen state = "NORTH CAROLINA"
	gen bctyfips = .
	gen bcounty = ""

	forvalues n = `n_max'(-1)1 {
		replace bp`n' = trim(bp`n')
		gen county_nhgis = upper(bp`n')
		fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
		replace bp`n' = "" if _merge == 3 & bctyfips == .
		replace bctyfips = fips if _merge == 3 & bctyfips == .
		replace bcounty = county_nhgis if _merge == 3 & bcounty == ""
		drop _merge fips county_nhgis
	}
	egen bpl_edit = concat(bp1-bp`n_max'), punct(", ")
	replace bpl_edit = regexr(bpl_edit,"[, ]*[, ]*[, ]*[, ]*[, ]$","")
	replace bpl_edit = regexr(bpl_edit,", ,",",")
	replace bpl_edit = regexr(bpl_edit,", ,",",")
	replace bpl_edit = regexr(bpl_edit,"^, ","")
	replace bpl_edit = bp_raw if bctyfips == .

	drop bp1-bp`n_max' birth_place state bp_raw
	rename bpl_edit birth_place
	order bpl birth_place

	rename bctyfips bctyfips_sp
	rename bcounty bcounty_sp

	gisid bpl birth_place bctyfips_sp bcounty_sp, missok
	gsort bpl birth_place bctyfips_sp bcounty_sp
	
	save "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", replace

	keep if bctyfips_sp != .
	keep bpl bctyfips_sp bcounty_sp
	
	gisid bpl, missok 
	gsort bpl
	
	save "$PROJ_PATH/analysis/processed/temp/cty_exact_match_space.dta", replace



	/* Identify birth location (Exact) [parse on comma] */

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", clear

	split birth_place, parse(",") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}	
	compress birth_place

	gen bcounty = ""
	gen bcity = ""

	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
		gen location = upper(bp`n')
		fmerge m:1 location using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", keep(1 3)
		replace bcity = location if _merge == 3 & bcity == ""
		replace bcounty = county_nhgis if _merge == 3 & bcounty == ""
		drop _merge location county_nhgis
	}
	drop bp1-bp`n_max'
	keep if bcity != ""

	gen state = "NORTH CAROLINA"
	rename bcounty county_nhgis
	gen bctyfips_loc = .

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips_loc = fips if _merge == 3 & bctyfips_loc == .
	keep bpl bctyfips_loc bcity 
	gsort bpl
	save "$PROJ_PATH/analysis/processed/temp/location_exact_match_comma.dta", replace



	/* Identify birth location (Exact) [parse on space] */

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear

	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
	}	
	compress birth_place

	gen bcounty = ""
	gen bcity = ""

	forvalues n = 1(1)`n_max' {
		replace bp`n' = trim(bp`n')
		gen location = upper(bp`n')
		fmerge m:1 location using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", keep(1 3)
		replace bcity = location if _merge == 3 & bcity == ""
		replace bcounty = county_nhgis if _merge == 3 & bcounty == ""
		drop _merge location county_nhgis
	}
	drop bp1-bp`n_max'
	keep if bcity != ""

	gen state = "NORTH CAROLINA"
	rename bcounty county_nhgis
	gen bctyfips_loc = .

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips_loc = fips if _merge == 3 & bctyfips_loc == .
	keep bpl bctyfips_loc bcity
	rename bctyfips_loc bctyfips_loc_sp
	rename bcity bcity_sp
	gsort bpl
	save "$PROJ_PATH/analysis/processed/temp/location_exact_match_space.dta", replace
	
	
	
	/* Use death location to identify birth location */

	use bpl dpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl dpl: keep if _n == 1
	drop if bpl == ""

	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", keep(1 3) nogen keepusing(birth_place)
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta", keep(1 3) nogen
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", keep(1 3) nogen
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta", keep(1 3) nogen
	replace bstate = bstate_sp if bstate == . & bstate_sp != .
	drop bstate_sp
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta", keep(1 3) nogen keepusing(bstate_jw)
	replace bstate = bstate_jw if bstate == . & bstate_jw != .
	drop bstate_jw
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_match_comma.dta", keep(1 3) nogen keepusing(bctyfips)
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/location_exact_match_comma.dta", keep(1 3) nogen
	fmerge m:1 dpl using "$PROJ_PATH/analysis/processed/temp/dp_cleaned.dta", keep(1 3) nogen

	replace bstate = 37 if bctyfips != .
	replace bcntry = 9900 if bstate <= 56
	replace bcntry = 99700 if bcntry == .
	
	keep if (bcntry == 9900 | bcntry == 99700) & (bstate == 37 | bstate == 99) & birth_place != "" & length(birth_place) >= 3
	keep bpl dpl dctyfips birth_place d_location dcounty bcity
	order bpl dpl dctyfips birth_place d_location dcounty bcity
	gsort bpl dpl

	gen death_in_birth = strpos(birth_place, d_location)
	gen dcty_in_birth = strpos(birth_place, dcounty)
	gen birth_in_death = strpos(d_location, birth_place)
	gen birth_in_dcty = strpos(dcounty, birth_place)

	gen strpos_match = 0
	replace strpos_match = 0.9 if (death_in_birth > 0 | dcty_in_birth > 0 | birth_in_death > 0 | birth_in_dcty > 0)

	jarowinkler birth_place d_location, gen(jw_death)
	jarowinkler birth_place dcounty, gen(jw_dcty)

	keep if strpos_match == 0.9 | jw_death >= 0.8 | jw_dcty >= 0.8

	gen cty_match_dp = (dcty_in_birth > 0 | birth_in_dcty > 0 | jw_dcty >= 0.8)
	gen bctyfips_dp = .
	gen bcity_dp = ""

	replace bctyfips_dp = dctyfips
	replace bcity_dp = bcity if bcity == birth_place

	gen location = d_location
	fmerge m:1 location using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta", keep(1 3) keepusing(location county_nhgis)
	replace bcity_dp = location if _merge == 3 & (jw_death >= 0.8 | birth_in_death == 1 | death_in_birth == 1)
	drop _merge
	egen jw_dp = rowmax(jw_death jw_dcty strpos_match)

	gen state = "NORTH CAROLINA"
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips_dp = fips if _merge == 3

	keep bpl bctyfips_dp bcity_dp jw_dp cty_match_dp
	order bpl bctyfips_dp bcity_dp jw_dp cty_match_dp
	bysort bpl bctyfips_dp bcity_dp jw_dp cty_match_dp: keep if _n == 1

	gegen max_jw = max(jw_dp), by(bpl)
	drop if jw_dp != max_jw
	drop max_jw

	egen tot_city_match = total(bcity_dp != ""), by(bpl bctyfips_dp)
	drop if bcity_dp == "" & tot_city_match > 0
	drop tot_city_match

	bysort bpl: keep if _N == 1
	compress
	save "$PROJ_PATH/analysis/processed/temp/birth_death_match.dta", replace



	/* Identify birth county (Cross) [parsed on space] */

	use "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta" if bctyfips_sp ==., clear
	keep bpl birth_place
	compress
	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	cross using "$PROJ_PATH/analysis/processed/temp/nc_counties.dta"
	save "$PROJ_PATH/analysis/processed/temp/jw_input_counties.dta", replace

	qui {
		forvalues m = 1(1)`n_max' {
			use "$PROJ_PATH/analysis/processed/temp/jw_input_counties.dta", clear
			keep bp`m' county_nhgis
			bysort bp`m' county_nhgis: keep if _n == 1
			keep if bp`m' != "" & length(bp`m') >= 3
			rename bp`m' birth_place
			tempfile jw_input`m'
			save `jw_input`m'', replace
			count
			local total_loops = ceil(r(N)/50000)
			display `total_loops'
			forvalues n = 1(1)`total_loops' {
				local bot = (`n' - 1)*50000 + 1
				display `bot'
				local top = `bot' + 49999
				display `top'
				use `jw_input`m'', clear
				keep if _n >= `bot' & _n <= `top'
				count
				jarowinkler birth_place county_nhgis, gen(jw_bcty)
				tempfile jw`m'`n'
				save `jw`m'`n'', replace
			}
			clear
			forvalues n = 1(1)`total_loops' {
				append using `jw`m'`n''
			}
			keep if jw_bcty >= 0.8
			gegen jw_max = max(jw_bcty), by(birth_place)
			drop if jw_bcty != jw_max
			drop jw_max
			bysort birth_place: keep if _N == 1
			tempfile jw_matched_`m'
			save `jw_matched_`m'', replace
		}
		clear
		forvalues m = 1(1)`n_max' {
			append using `jw_matched_`m''
		}
	}
	keep birth_place county_nhgis jw_bcty
	gegen jw_max = max(jw_bcty), by(birth_place county_nhgis)
	drop if jw_bcty != jw_max
	drop jw_max 
	bysort birth_place county_nhgis jw_bcty: keep if _n == 1
	bysort birth_place: keep if _N == 1
	save "$PROJ_PATH/analysis/processed/temp/jw_matched_counties.dta", replace
	rm "$PROJ_PATH/analysis/processed/temp/jw_input_counties.dta"

	use "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta" if bctyfips_sp ==., clear
	keep bpl birth_place
	compress
	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	
	drop birth_place
	gen matched_county = ""
	gen matched_jw = .
	forvalues n = `n_max'(-1)1 {
		rename bp`n' birth_place
		fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_counties.dta", keep(1 3) nogen
		gen accept_match = (county_nhgis != "" & matched_county == "" & (jw_bcty > matched_jw | matched_jw == .))
		replace matched_county = county_nhgis if accept_match == 1
		replace matched_jw = jw_bcty if accept_match == 1
		drop birth_place county_nhgis accept_match jw_bcty
	}
	keep bpl matched_county matched_jw
	rename matched_county county_nhgis
	rename matched_jw jw_bcty

	gen state = "NORTH CAROLINA"
	gen bctyfips = .

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips = fips if _merge == 3 & bctyfips == .
	drop _merge fips county_nhgis

	keep bpl bctyfips jw_bcty
	keep if bctyfips != .
	rename bctyfips bctyfips_jw
	
	gisid bpl jw_bcty bctyfips_jw, missok
	gsort bpl jw_bcty bctyfips_jw 

	save "$PROJ_PATH/analysis/processed/temp/bcty_cross_match.dta", replace
	
	

	/* Identify birth location (Cross) [parsed on space] */

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	compress
	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	cross using "$PROJ_PATH/analysis/processed/temp/nc_locations.dta"
	save "$PROJ_PATH/analysis/processed/temp/jw_input_locations.dta", replace

	qui {
		forvalues m = 1(1)`n_max' {
			use "$PROJ_PATH/analysis/processed/temp/jw_input_locations.dta", clear
			keep bp`m' location county_nhgis
			bysort bp`m' location county_nhgis: keep if _n == 1
			keep if bp`m' != "" & length(bp`m') >= 3
			rename bp`m' birth_place
			tempfile jw_input`m'
			save `jw_input`m'', replace
			count
			local total_loops = ceil(r(N)/50000)
			display `total_loops'
			forvalues n = 1(1)`total_loops' {
				local bot = (`n' - 1)*50000 + 1
				display `bot'
				local top = `bot' + 49999
				display `top'
				use `jw_input`m'', clear
				keep if _n >= `bot' & _n <= `top'
				count
				jarowinkler birth_place location, gen(jw_bp)
				tempfile jw`m'`n'
				save `jw`m'`n'', replace
			}
			clear
			forvalues n = 1(1)`total_loops' {
				append using `jw`m'`n''
			}
			keep if jw_bp >= 0.8
			gegen jw_max = max(jw_bp), by(birth_place)
			drop if jw_bp != jw_max
			drop jw_max
			bysort birth_place: keep if _N == 1
			tempfile jw_matched_`m'
			save `jw_matched_`m'', replace
		}
		clear
		forvalues m = 1(1)`n_max' {
			append using `jw_matched_`m''
		}
	}
	keep birth_place location county_nhgis jw_bp
	gegen jw_max = max(jw_bp), by(birth_place location county_nhgis)
	drop if jw_bp != jw_max
	drop jw_max 
	bysort birth_place location county_nhgis jw_bp: keep if _n == 1
	bysort birth_place: keep if _N == 1
	save "$PROJ_PATH/analysis/processed/temp/jw_matched_locations.dta", replace
	rm "$PROJ_PATH/analysis/processed/temp/jw_input_locations.dta"

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	compress
	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	
	drop birth_place
	gen matched_location = ""
	gen matched_county = ""
	gen matched_jw = .

	forvalues n = 1(1)`n_max' {
		rename bp`n' birth_place
		fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_locations.dta", keep(1 3) nogen
		gen accept_match = (location != "" & matched_location == "" & (jw_bp > matched_jw | matched_jw == .))
		replace matched_location = location if accept_match == 1
		replace matched_county = county_nhgis if accept_match == 1
		replace matched_jw = jw_bp if accept_match == 1
		drop birth_place location county_nhgis accept_match jw_bp
	}
	keep bpl matched_location matched_county matched_jw
	rename matched_location bcity
	rename matched_county county_nhgis
	rename matched_jw jw_bp

	gen state = "NORTH CAROLINA"
	gen bctyfips_loc = .

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips_loc = fips if _merge == 3 & bctyfips_loc == .
	drop _merge fips county_nhgis

	keep bpl bctyfips_loc bcity jw_bp
	keep if bctyfips_loc != .
	rename bctyfips_loc bctyfips_loc_jw
	rename bcity bcity_jw

	order bpl bcity_jw bctyfips_loc_jw jw_bp 
	gisid bpl bcity_jw bctyfips_loc_jw jw_bp, missok 
	gsort bpl bcity_jw bctyfips_loc_jw jw_bp 
	
	save "$PROJ_PATH/analysis/processed/temp/bloc_cross_match.dta", replace
	
	
	
	/* Identify unincorporated communities (Cross) [parsed on comma] */

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	compress
	split birth_place, parse(",") gen(bp)
	local n_max = r(nvars)
	
	forvalues n = `n_max'(-1)1 {
		replace bp`n' = trim(bp`n')
	}
	cross using "$PROJ_PATH/analysis/processed/temp/nc_towns.dta"
	save "$PROJ_PATH/analysis/processed/temp/jw_input_towns.dta", replace

	qui {
		forvalues m = 1(1)`n_max' {
			use "$PROJ_PATH/analysis/processed/temp/jw_input_towns.dta", clear
			keep bp`m' town county_nhgis
			bysort bp`m' town county_nhgis: keep if _n == 1
			keep if bp`m' != "" & length(bp`m') >= 3
			rename bp`m' birth_place
			count 
			if r(N) > 0 {
				
				tempfile jw_input`m'
				save `jw_input`m'', replace
				count
				local total_loops = ceil(r(N)/50000)
				display `total_loops'
				forvalues n = 1(1)`total_loops' {
					local bot = (`n' - 1)*50000 + 1
					display `bot'
					local top = `bot' + 49999
					display `top'
					use `jw_input`m'', clear
					keep if _n >= `bot' & _n <= `top'
					count
					jarowinkler birth_place town, gen(jw_uc)
					tempfile jw`m'`n'
					save `jw`m'`n'', replace
				}
				clear
				forvalues n = 1(1)`total_loops' {
					append using `jw`m'`n''
				}
				keep if jw_uc >= 0.85
				gegen jw_max = max(jw_uc), by(birth_place)
				drop if jw_uc != jw_max
				drop jw_max
				bysort birth_place: keep if _N == 1
			}
			
			tempfile jw_matched_`m'
			save `jw_matched_`m'', replace
		}
		clear
		forvalues m = 1(1)`n_max' {
			append using `jw_matched_`m''
		}
	}
	keep birth_place town county_nhgis jw_uc
	gegen jw_max = max(jw_uc), by(birth_place town county_nhgis)
	drop if jw_uc != jw_max
	drop jw_max 
	bysort birth_place town county_nhgis jw_uc: keep if _n == 1
	bysort birth_place: keep if _N == 1
	save "$PROJ_PATH/analysis/processed/temp/jw_matched_towns.dta", replace
	rm "$PROJ_PATH/analysis/processed/temp/jw_input_towns.dta"

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	compress
	split birth_place, parse(" ") gen(bp)
	local n_max = r(nvars)
	
	drop birth_place
	gen matched_town = ""
	gen matched_county = ""
	gen matched_uc = .

	forvalues n = 1(1)`n_max' {
		rename bp`n' birth_place
		fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_towns.dta", keep(1 3) nogen
		gen accept_match = (town != "" & matched_town == "" & (jw_uc > matched_uc | matched_uc == .))
		replace matched_town = town if accept_match == 1
		replace matched_county = county_nhgis if accept_match == 1
		replace matched_uc = jw_uc if accept_match == 1
		drop birth_place town county_nhgis accept_match jw_uc
	}
	keep bpl matched_town matched_county matched_uc
	rename matched_town btown
	rename matched_county county_nhgis
	rename matched_uc jw_uc

	gen state = "NORTH CAROLINA"
	gen bctyfips_uc = .

	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(state county_nhgis fips) keep(1 3)
	replace bctyfips_uc = fips if _merge == 3 & bctyfips_uc == .
	drop _merge fips county_nhgis

	keep bpl bctyfips_uc btown jw_uc
	keep if bctyfips_uc != .
	
	order bpl btown bctyfips_uc jw_uc
	gisid bpl btown bctyfips_uc jw_uc, missok
	gsort bpl btown bctyfips_uc jw_uc

	save "$PROJ_PATH/analysis/processed/temp/btown_cross_match.dta", replace

	
	
	/* Identify birth location (joinby with full GNIS file) [parsed on comma] */

	use birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	bysort birth_place: keep if _n == 1
	compress
	split birth_place, parse(",") gen(bpstr)
	drop birth_place
	replace bpstr1 = trim(bpstr1)
	rename bpstr1 birth_place
	drop bpstr*
	duplicates drop
	keep if length(birth_place) >= 3
	gen block_chars = substr(birth_place,1,2)
	bysort block_chars birth_place: keep if _n == 1
	joinby block_chars using "$PROJ_PATH/analysis/processed/temp/nc_features.dta"
	keep birth_place feature *_gnis
	bysort birth_place feature *_gnis: keep if _n == 1
	rename feature bcity_gnis
	tempfile jw_input
	save `jw_input', replace

	qui {
		count
		local total_loops = ceil(r(N)/50000)
		display `total_loops'
		forvalues n = 1(1)`total_loops' {
			local bot = (`n' - 1)*50000 + 1
			display `bot'
			local top = `bot' + 49999
			display `top'
			use `jw_input', clear
			keep if _n >= `bot' & _n <= `top'
			count
			jarowinkler birth_place bcity_gnis, gen(jw_gnis)
			tempfile jw`n'
			save `jw`n'', replace
		}
		clear
		forvalues n = 1(1)`total_loops' {
			append using `jw`n''
		}
	}
	keep if jw_gnis >= 0.85
	gegen jw_max = max(jw_gnis), by(birth_place)
	drop if jw_gnis != jw_max
	drop jw_max
	bysort birth_place: keep if _N == 1
	save "$PROJ_PATH/analysis/processed/temp/jw_matched_gnis.dta", replace

	use bpl birth_place using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta", clear
	bysort bpl birth_place: keep if _n == 1
	compress
	split birth_place, parse(",") gen(bpstr)
	drop birth_place
	replace bpstr1 = trim(bpstr1)
	rename bpstr1 birth_place
	drop bpstr*
	fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_gnis.dta", keep(3) nogen
	keep bpl bctyfips_gnis bcity_gnis jw_gnis
	
	gisid bpl, missok
	gsort bpl

	save "$PROJ_PATH/analysis/processed/temp/gnis_cross_match.dta", replace



	/* Merge matched results [Pass 1] */
	
	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl: keep if _n == 1
	
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_nc_deaths_merge_matched_results.do"
	
	gsort bpl 

	forvalues n = 1(1)6 {
		gen statefip = 37 if bctyfips`n' != .
		gen fips = bctyfips`n'
		fmerge m:1 statefip fips using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(county_nhgis) keep(1 3) nogen
		rename county_nhgis bcounty`n'
		drop statefip fips
	}

	order bpl bcntry bstate st_mq *1 *2 *3 *4 *5 *6
	gsort bpl

	gen group_id = _n
	greshape long bctyfips mq bcity bcounty cty_match, i(group_id) j(new_id)
	drop new_id 
	gduplicates drop 
	gisid bpl mq cty_match bcounty bcity, missok
	gsort + bpl - mq - cty_match + bcounty + bcity 
	egen new_id = seq(), by(bpl)
	greshape wide bctyfips mq bcity bcounty cty_match, i(group_id) j(new_id)
	drop group_id
	order bpl bcntry bstate st_mq

	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_bpl_manual_extract.do"
	gen manual_match = (!missing(bcity) | !missing(county_nhgis))
	
	replace state = upper(state)
	replace county_nhgis = upper(county_nhgis)
	capture drop fips
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(fips) keep(1 3) nogen
	replace bstate = 37 if manual_match == 1

	forvalues n = 1(1)6 {
		replace bctyfips`n' = . if manual_match == 1
		replace bcounty`n' = "" if manual_match == 1
		replace bcity`n' = "" if manual_match == 1
		replace mq`n' = . if manual_match == 1
		replace cty_match`n' = 0 if manual_match == 1
	}
	replace bctyfips1 = fips if manual_match == 1
	replace mq1 = 1 if manual_match == 1
	replace bcounty1 = county_nhgis if manual_match == 1
	replace bcity1 = upper(bcity) if manual_match == 1
	replace cty_match1 = 1 if manual_match == 1
	drop fips state county_nhgis bcity

	forvalues n = 1(1)6 {
		replace bctyfips`n' = . if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace bcity`n' = "" if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace mq`n' = . if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace cty_match`n' = 0 if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
	}

	replace bstate = 37 if bctyfips1 != .
	replace bcntry = 9900 if bstate <= 56
	replace bcntry = 99700 if bcntry == .

	gisid bpl, missok
	gsort bpl
	save "$PROJ_PATH/analysis/processed/temp/bp_first_pass.dta", replace
	
		
	
	/* Second pass to match unmatched observations */

	use "$PROJ_PATH/analysis/processed/temp/bp_first_pass.dta" if bctyfips1 != ., clear
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", keep(1 3) nogen keepusing(birth_place)
	keep birth_place bctyfips1 bcity1
	rename bctyfips1 bctyfips_coded
	rename bcity1 bcity_coded
	keep if birth_place != "" & length(birth_place) > 3
	split birth_place, parse(",") gen(bp)
	drop birth_place
	rename bp1 birth_place
	drop bp*
	gduplicates drop
	gen block_chars = substr(birth_place,1,2)
	gsort block_chars birth_place
	order block_chars birth_place bctyfips_coded bcity_coded
	rename birth_place bp_matched
	tempfile block_chars
	save `block_chars', replace

	use "$PROJ_PATH/analysis/processed/temp/bp_first_pass.dta" if bctyfips1 == . & (bstate == 37 | bstate == 99) & (bcntry == 9900 | bcntry == 99700), clear
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", keep(1 3) nogen keepusing(birth_place)
	keep if bpl != "" & birth_place != "" & length(birth_place) > 3 & regexm(bpl," [C|c]o$") == 0 & regexm(bpl," [C|c]ounty$") == 0
	keep birth_place
	bysort birth_place: keep if _n == 1
	compress
	split birth_place, parse(",") gen(bpstr)
	drop birth_place
	replace bpstr1 = trim(bpstr1)
	rename bpstr1 birth_place
	drop bpstr*
	gduplicates drop
	gen block_chars = substr(birth_place,1,2)
	bysort block_chars birth_place: keep if _n == 1
	joinby block_chars using `block_chars'
	keep birth_place bp_matched *_coded
	bysort birth_place bp_matched *_coded: keep if _n == 1
	tempfile jw_input
	save `jw_input', replace

	qui {
		count
		local total_loops = ceil(r(N)/50000)
		display `total_loops'
		forvalues n = 1(1)`total_loops' {
			local bot = (`n' - 1)*50000 + 1
			display `bot'
			local top = `bot' + 49999
			display `top'
			use `jw_input', clear
			keep if _n >= `bot' & _n <= `top'
			count
			jarowinkler birth_place bp_matched, gen(jw_r2)
			tempfile jw`n'
			save `jw`n'', replace
		}
		clear
		forvalues n = 1(1)`total_loops' {
			append using `jw`n''
		}
	}
	keep if jw_r2 >= 0.9
	gegen jw_max = max(jw_r2), by(birth_place)
	drop if jw_r2 != jw_max
	drop jw_max
	bysort birth_place: keep if _N == 1
	save "$PROJ_PATH/analysis/processed/temp/jw_matched_rejects.dta", replace

	use "$PROJ_PATH/analysis/processed/temp/bp_first_pass.dta" if bctyfips1 == . & (bstate == 37 | bstate == 99) & (bcntry == 9900 | bcntry == 99700), clear
	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta", keep(1 3) nogen keepusing(birth_place)
	keep bpl birth_place
	compress
	split birth_place, parse(",") gen(bpstr)
	drop birth_place
	rename bpstr1 birth_place
	drop bpstr*
	fmerge m:1 birth_place using "$PROJ_PATH/analysis/processed/temp/jw_matched_rejects.dta", keep(3) nogen
	keep bpl bctyfips_coded bcity_coded jw_r2
	
	gisid bpl, missok 
	gsort bpl

	save "$PROJ_PATH/analysis/processed/temp/reject_cross_match.dta", replace
	
	

	/* Merge matched results [Pass 2] */

	use bpl using "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	bysort bpl: keep if _n == 1

	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_nc_deaths_merge_matched_results.do"

	fmerge 1:1 bpl using "$PROJ_PATH/analysis/processed/temp/reject_cross_match.dta", keep(1 3) nogen
	replace bctyfips1 = bctyfips_coded if bctyfips1 == . & bctyfips_coded != .
	replace bcity1 = bcity_coded if bctyfips1 == bctyfips_coded & bcity1 == "" & bcity_coded != ""
	replace mq1 = jw_r2 if bctyfips1 == bctyfips_coded & mq1 == .
	replace bctyfips2 = bctyfips_coded if bctyfips1 != bctyfips_coded & bctyfips_coded != . & bctyfips2 == .
	replace bcity2 = bcity_coded if bctyfips2 == bctyfips_coded & bcity2 == "" & bcity_coded != ""
	replace mq2 = jw_r2 if bctyfips2 == bctyfips_coded & mq2 == .
	replace bctyfips3 = bctyfips_coded if bctyfips1 != bctyfips_coded & bctyfips2 != bctyfips_coded & bctyfips_coded != . & bctyfips3 == .
	replace bcity3 = bcity_coded if bctyfips3 == bctyfips_coded & bcity3 == "" & bcity_coded != ""
	replace mq3 = jw_r2 if bctyfips3 == bctyfips_coded & mq3 == .
	replace bctyfips4 = bctyfips_coded if bctyfips1 != bctyfips_coded & bctyfips2 != bctyfips_coded & bctyfips3 != bctyfips_coded & bctyfips_coded != . & bctyfips4 == .
	replace bcity4 = bcity_coded if bctyfips4 == bctyfips_coded & bcity4 == "" & bcity_coded != ""
	replace mq4 = jw_r2 if bctyfips4 == bctyfips_coded & mq4 == .
	replace bctyfips5 = bctyfips_coded if bctyfips1 != bctyfips_coded & bctyfips2 != bctyfips_coded & bctyfips3 != bctyfips_coded & bctyfips4 != bctyfips_coded & bctyfips_coded != . & bctyfips5 == .
	replace bcity5 = bcity_coded if bctyfips5 == bctyfips_coded & bcity5 == "" & bcity_coded != ""
	replace mq5 = jw_r2 if bctyfips5 == bctyfips_coded & mq5 == .
	replace bctyfips6 = bctyfips_coded if bctyfips1 != bctyfips_coded & bctyfips2 != bctyfips_coded & bctyfips3 != bctyfips_coded & bctyfips4 != bctyfips_coded & bctyfips5 != bctyfips_coded & bctyfips_coded != . & bctyfips6 == .
	replace bcity6 = bcity_coded if bctyfips6 == bctyfips_coded & bcity6 == "" & bcity_coded != ""
	replace mq6 = jw_r2 if bctyfips6 == bctyfips_coded & mq6 == .
	drop bctyfips_coded jw_r2 bcity_coded

	forvalues n = 1(1)6 {
		gen statefip = 37 if bctyfips`n' != .
		gen fips = bctyfips`n'
		fmerge m:1 statefip fips using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(county_nhgis) keep(1 3) nogen
		rename county_nhgis bcounty`n'
		drop statefip fips
	}

	order bpl bcntry bstate st_mq *1 *2 *3 *4 *5 *6
	gsort bpl

	gen group_id = _n
	greshape long bctyfips mq bcity bcounty cty_match, i(group_id) j(new_id)
	drop new_id 
	gduplicates drop 
	gisid bpl mq cty_match bcounty bcity, missok
	gsort + bpl - mq - cty_match + bcounty + bcity 
	egen new_id = seq(), by(bpl)
	greshape wide bctyfips mq bcity bcounty cty_match, i(group_id) j(new_id)
	drop group_id
	order bpl bcntry bstate
	
	do "$PROJ_PATH/analysis/scripts/code/3_geocode_nc_deaths/_bpl_manual_extract.do"
	gen manual_match = (!missing(bcity) | !missing(county_nhgis))

	replace state = upper(state)
	replace county_nhgis = upper(county_nhgis)
	capture drop fips
	fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/crosswalks/nhgis_icpsr_county_crosswalk.dta", keepusing(fips) keep(1 3) nogen
	replace bstate = 37 if manual_match == 1

	forvalues n = 1(1)6 {
		replace bctyfips`n' = . if manual_match == 1
		replace bcounty`n' = "" if manual_match == 1
		replace bcity`n' = "" if manual_match == 1
		replace mq`n' = . if manual_match == 1
		replace cty_match`n' = 0 if manual_match == 1
	}
	replace bctyfips1 = fips if manual_match == 1
	replace mq1 = 1 if manual_match == 1
	replace bcounty1 = county_nhgis if manual_match == 1
	replace bcity1 = upper(bcity) if manual_match == 1
	replace cty_match1 = 1 if manual_match == 1
	drop fips state county_nhgis bcity

	forvalues n = 1(1)6 {
		replace bctyfips`n' = . if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace bcity`n' = "" if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace mq`n' = . if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
		replace cty_match`n' = 0 if bstate != 37 & bstate != 99 & bctyfips1 != . & (mq1 < 0.98 | bstate == 11)
	}

	replace bstate = 37 if bctyfips1 != .
	replace bcntry = 9900 if bstate <= 56
	replace bcntry = 99700 if bcntry == .
	
	gsort bpl
	save "$PROJ_PATH/analysis/processed/temp/bp_cleaned.dta", replace

	
	
	// Compile cleaned data
	use "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta", clear
	fmerge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bp_cleaned.dta", assert(3) nogen
	
	compress
	order id gender race age byear bmonth bday dyear dmonth dday dpl dcounty d_location dctyfips bpl bcntry bstate *1 *2 *3 *4 manual_match stillborn no_name 

	desc, f
	
	// Add place of death same/county
	gen same_death = 0
	replace same_death = 1 if regexm(upper(bpl),"SAME[^A-Z]") | regexm(upper(bpl),"^PLA[^V]*[ ]D")

	forvalues n = 1(1)6 {
		replace bctyfips`n' = . if same_death == 1
		replace bcounty`n' = "" if same_death == 1
		replace bcity`n' = "" if same_death == 1
		replace mq`n' = . if same_death == 1
		replace cty_match`n' = . if same_death == 1
	}
	replace bctyfips1 = dctyfips if same_death == 1
	replace mq1 = 1 if same_death == 1
	replace bcounty1 = dcounty if same_death == 1
	replace bcity1 = d_location if same_death == 1
	replace cty_match1 = 1 if same_death == 1

	rename bctyfips1 bctyfips
	rename bcity1 bcity
	rename bcounty1 bcounty
	rename mq1 mq

	drop *2 *3 *4 *5 *6 cty_match* manual_match same_death 
	gduplicates drop

	
	// Drop duplicates 
	egen tot_coded = total(bctyfips != .), by(name_id gender race age byear bmonth bday dyear dmonth dday bcntry bstate dctyfips)
	drop if tot_coded > 0 & bctyfips == . & flag_name == 1
	drop tot_coded

	egen tot_city = total(bcity != ""), by(name_id gender race age byear bmonth bday dyear dmonth dday bcntry bstate bctyfips dctyfips)
	drop if tot_city > 0 & bcity == "" & flag_name == 1
	drop tot_city 
	
	gegen max_mq = max(mq), by(name_id gender race age byear bmonth bday dyear dmonth dday bcntry bstate dctyfips)
	drop if mq != max_mq & flag_name == 1
	drop max_mq mq st_mq name_id flag_name 
	
	// Keep only the variables we will use 
	keep id race age byear bmonth bday dyear dmonth dday bstate bctyfips bcounty stillborn no_name
	
	compress 
	desc, f

	save "$PROJ_PATH/analysis/processed/data/nc_deaths/nc_death_certificates_cleaned.dta", replace
	
	// Clean up temp files
	
	if `cleanup' {
	
		cap rm "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bstate_split_input.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/cty_exact_output_comma.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/cty_exact_output_space.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/cty_exact_match_comma.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/cty_exact_match_space.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/location_exact_match_comma.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/location_exact_match_space.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/birth_death_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/state_names.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/nc_counties.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/nc_locations.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/nc_towns.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/nc_features.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_states.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_counties.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_locations.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_towns.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_gnis.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bcty_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bloc_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/btown_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/gnis_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bp_first_pass.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/jw_matched_rejects.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/reject_cross_match.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/nc_deaths_input.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/dates_cleaned.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/dp_cleaned.dta"
		cap rm "$PROJ_PATH/analysis/processed/temp/bp_cleaned.dta"
		
	}

}

disp "DateTime: $S_DATE $S_TIME"

** EOF
