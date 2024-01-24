version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 4_1_compile_ipums_data.do
* PURPOSE: Processes IPUMS USA Full-Count datasets in preparation of analysis datasets used in Figure C3.

************

******************************************************
// Process raw IPUMS data for doctors and nurses *****
******************************************************	

local first_census 1910
	
// Load IPUMS data
use "$PROJ_PATH/analysis/raw/ipums/usa_00086.dta" if year >= `first_census' & year <= 1940 & statefip == 37, clear

gen pop = 1	

// Generate dummies for doctors and nurses 
gen md = (occ1950 == 75)
gen nurse  = (occ1950 == 58 | occ1950 == 59)

tab ind1950 if md == 1 & year <= 1930 
tab ind1950 if md == 1 & year == 1940 

// Flag medical and hospital industries
gen ind_hospital = (ind1950 == 868 | ind1950 == 869)
gen ind_other = (ind_hospital == 0)
	
// Sample restriction: All doctors and nurses or anyone else working in medical or hospital industries 
keep if md == 1 | nurse == 1 | ind_hospital == 1

// Flag medical students 
gen in_school = (school == 2)
tab in_school, m 

gen student_md = (md == 1 & in_school == 1)
gen student_nurse = (nurse == 1 & (in_school == 1 | occ1950 == 59))

tab student_md
tab student_nurse 

// Drop students 
drop if in_school == 1 | student_md == 1 | student_nurse == 1

drop in_school student_*
	
// Tab industries of doctors and nurses 
tab ind_hospital if md == 1
tab ind_hospital if nurse == 1

// Generate types of doctors 
gen md_hospital	= (md == 1 & ind_hospital == 1)
gen md_other = (md == 1 & ind_other == 1)

// Generate types of nurses
gen nurse_hospital = (nurse == 1 & ind_hospital == 1)
gen nurse_other = (nurse == 1 & ind_other == 1)

gen hosp_attendant = (ind_hospital == 1 & inlist(occ1950,301,302,730))
gen hosp_clerical = (ind_hospital == 1 & inrange(occ1950,310,390))
gen hosp_other = (ind_hospital == 1 & md == 0 & nurse == 0 & hosp_attendant == 0 & hosp_clerical == 0)

tab md_hospital if ind_hospital == 1
tab nurse_hospital if ind_hospital == 1
tab hosp_attendant if ind_hospital == 1
tab hosp_clerical if ind_hospital == 1
tab hosp_other if ind_hospital == 1

// Generate doctors and nurses by race 
gen white = (race == 1)
gen black = (race == 2)	

gen md_white = white*md 
gen md_black = black*md 	

gen nurse_white = white*nurse 
gen nurse_black = black*nurse 

// Generate control variables
gen share_black = black
gen share_other = pop - black - white
gen share_foreign = (bpl >= 100)
gen share_urban = (city > 0 & city < 9999)
gen share_noocc = (sex == 1 & age >= 18 & age <= 49 & occ1950 == 999)

gen share_under1 = (age == 0)
gen share_1to4 = (age >= 1 & age <= 4)
forvalues bot = 5(10)65 {
	local top = `bot' + 9
	gen share_`bot'to`top' = (age >= `bot' & age <= `top')
}
gen share_75plus = (age >= 75)

collapse (sum) pop white black md nurse md_* nurse_* ind_* hosp_* (mean) share_*, by(year statefip countyicp)

la var pop "Population"
la var white "White"
la var black "Black"
la var md "Doctors"
la var nurse "Nurses"

la var ind_hospital "Medical Industry"
la var ind_other "Other Industries"

la var hosp_attendant "Medical Industry, Attendant"
la var hosp_clerical "Medical Industry, Clerical"
la var hosp_other "Medical Industry, Other"

la var md_hospital "Doctor, Medical Industry"
la var md_other "Doctor, Other Industry"

la var nurse_hospital "Nurse, Medical Industry"
la var nurse_other "Nurse, Other Industry"
	
la var nurse_white "`: var label white' `: var label nurse'"
la var nurse_black "`: var label black' `: var label nurse'"

la var md_white "`: var label white' `: var label md'"
la var md_black "`: var label black' `: var label md'"

la var share_black "Share of Population, Black"
la var share_other "Share of Population, Other Race"
la var share_foreign "Share of Population, Foreign"
la var share_urban "Share of Population, Urban"
la var share_noocc "Share of Population, No Occupation"

// Add FIPS variable 
gen fips = statefip*10000 + countyicp 

// Use NHGIS data for controls/weights instead
fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", assert(2 3) keep(3) nogen keepusing(pop_total percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita)

order year statefip countyicp fips
gisid statefip countyicp year
gsort statefip countyicp year
compress
desc, f

save "$PROJ_PATH/analysis/processed/data/ipums/ipums_doctors_nurses_`first_census'_1940.dta", replace

****************************************************************
// Combine data for IPUMS census doctors/nurses event study
****************************************************************

// Create county-by-year data of number of doctors - NC only! Restrict year in 1942 when our sample ends 
use "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta" if statefip == 37 & year >= `first_census' & year <= 1940, clear

// Make first exposure year variable
local treat capp_all
capture drop exp_year
gen exp_year = year if `treat' != 0 & !missing(`treat')
egen first_exp_year = min(exp_year), by(fips)

keep fips first_exp_year
gduplicates drop

// Create 10-year binned first exposure year 
gen time_treated = .
replace time_treated = ceil((first_exp_year - `first_census')/10) + 1
tab first_exp_year time_treated, m 

// Sort and organize data
keep fips time_treated
order fips time_treated
rename time_treated first_exp_year
gsort fips first_exp_year

tempfile first_duke_exposure_year
save `first_duke_exposure_year', replace

// Merge doctor counts with first Duke exposure year (based on free days)
use "$PROJ_PATH/analysis/processed/data/ipums/ipums_doctors_nurses_`first_census'_1940.dta", clear
fmerge m:1 fips using `first_duke_exposure_year', assert(3) keep(3) nogen 

gsort statefip countyicp fips year

// Merge in CHD presence
fmerge m:1 fips using "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_by_county.dta", assert(2 3) keep(3) nogen keepusing(start_year_* end_year_*)

gen chd_presence = .

replace chd_presence = 0 if missing(start_year_1)

replace chd_presence = 1 if year >= start_year_1 & year <= end_year_1 & !missing(end_year_1)
replace chd_presence = 1 if year >= start_year_1 & missing(end_year_1)

replace chd_presence = 1 if year >= start_year_2 & year <= end_year_2 & !missing(start_year_2) & !missing(end_year_2)
replace chd_presence = 1 if year >= start_year_2 & !missing(start_year_2) & missing(end_year_2)

recode chd_presence (mis = 0)
drop start_year_* end_year_*

// Convert years to sequence of integers
rename year calendar_year 
gen year = floor((calendar_year - `first_census')/10) + 1

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
xtset fips year
desc, f

save "$PROJ_PATH/analysis/processed/data/ipums_doctors_nurses_hospital_staff.dta", replace


disp "DateTime: $S_DATE $S_TIME"
	
** EOF