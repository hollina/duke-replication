***********
* SCRIPT: 8_intext_stats.do
* PURPOSE: Statistics reported in slides or in paper
************

// Settings for controls
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"	

// Duke treatment variable 
local treat 		"capp_all"

// Panel start and end dates
local year_start 	1922
local year_end 		1942

// Set first year for numident 
local first_year_numident 1988
local year_start 1922
local year_end 1942
local age_lb 56
local age_ub 65
local first_cohort 1932

******************************************************************************************************************************************
// Decline in infant mortality rate by group and share of overall decline that Duke accounted for. 
******************************************************************************************************************************************

*********************************************************************
* Set up infant mortality analysis
*********************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(capp_all) time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
	*** NOTE change in variable names ****
	* ln_imr --> ln_imr_pub
	* ln_imr_bk --> ln_imr_pub_bk
	* ln_imr_wt --> ln_imr_pub_wt
	* (similarly for levels, just drop the ln_)
	
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

// Get baseline IMR- pooled
sum imr_pub [aw = births_pub] if year < 1927
local imr_pre_pooled = r(mean)

sum imr_pub [aw = births_pub] if year > 1937 
local imr_post_pooled = r(mean)

di (`imr_pre_pooled'-`imr_post_pooled')/(`imr_pre_pooled')

// Get baseline IMR - black
sum imr_pub_bk [aw = births_pub_bk] if year < 1927
local imr_pre_bk = r(mean)

sum imr_pub_bk [aw = births_pub_bk] if year < 1927 & ever_treated == 1
local et_imr_pre_bk = r(mean)

sum imr_pub_bk [aw = births_pub_bk] if year > 1937 
local imr_post_bk = r(mean)

di (`imr_pre_bk'-`imr_post_bk')/(`imr_pre_bk')

// Get baseline IMR - white

sum imr_pub_wt [aw = births_pub_wt] if year < 1927
local imr_pre_wt = r(mean)

sum imr_pub_wt [aw = births_pub_wt] if year < 1927 & ever_treated == 1
local et_imr_pre_wt = r(mean)

sum imr_pub_wt [aw = births_pub_wt] if  year > 1937 
local imr_post_wt = r(mean)
di (`imr_pre_wt'-`imr_post_wt')/(`imr_pre_wt')

egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)


ppmlhdfe imr_pub b0.treated   `baseline_controls' [pw = births_pub], ///
	absorb(fips year ) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat  pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	
	gen saved_lives = ((imr_pub*treated*`treatment')/1000)*births_pub
	
	sumup saved_lives, by(year) s(sum)
	
	sumup saved_lives, s(sum)
	
	// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_pooled')/(`imr_pre_pooled'-`imr_post_pooled')
	
	di (`imr_pre_pooled'-`imr_post_pooled')

	di `treatment'*`imr_pre_pooled'

ppmlhdfe imr_pub_wt b0.treated   `baseline_controls' [pw = births_pub_wt] if ever_zero_births == 0, ///
	absorb(fips year ) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat  pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	di `treatment'*`imr_pre_wt'
	local wt_treatment = `treatment'
	gen saved_lives_wt = ((imr_pub_wt*treated*`treatment')/1000)*births_pub_wt
	
	sumup saved_lives_wt, by(year) s(sum)
	
	sumup saved_lives_wt, s(sum) 
		// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_wt')/(`imr_pre_wt'-`imr_post_wt')
	
	di (`imr_pre_wt'-`imr_post_wt')

ppmlhdfe imr_pub_bk b0.treated   `baseline_controls' [pw = births_pub_bk] if ever_zero_births == 0, ///
	absorb(fips year ) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat  pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	di `treatment'*`imr_pre_bk'
	local bk_treatment = `treatment'

	// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_bk')/(`imr_pre_bk'-`imr_post_bk')
	
	di (`imr_pre_bk'-`imr_post_bk')
	
	
	gen saved_lives_bk = ((imr_pub_bk*treated*`treatment')/1000)*births_pub_bk
	
	sumup saved_lives_bk, by(year) s(sum)
	
	sumup saved_lives_bk, s(sum) 


// Figure out difference in infant mortality gap

// First what is counter factual Infant mortality for whites
sum saved_lives_wt if treated == 1
local saved_wt = r(sum)

sum mort_wt if treated == 1
local act_mort_wt = r(sum)

sum births_pub_wt if treated == 1
local births_wt = r(sum)

* No Duke IMR for whites
local cf_imr_wt = ((`act_mort_wt' - `saved_wt')/`births_wt')*1000
di `cf_imr_wt'

* With Duke IMR for whites
local act_imr_wt = ((`act_mort_wt')/`births_wt')*1000
di `act_imr_wt'

// Second, what is counter factual Infant mortality for Blacks
sum saved_lives_bk if treated == 1
local saved_bk = r(sum)

sum mort_bk if treated == 1
local act_mort_bk = r(sum)

sum births_pub_bk if treated == 1
local births_bk = r(sum)

* No Duke IMR for Blacks 
local cf_imr_bk = ((`act_mort_bk' - `saved_bk')/`births_bk')*1000
di `cf_imr_bk'

* With Duke IMR for Blacks 
local act_imr_bk = ((`act_mort_bk')/`births_bk')*1000
di `act_imr_bk'

* IMR Gap without Duke
local cf_imr_gap = `cf_imr_bk' - `cf_imr_wt'
di `cf_imr_gap'

local act_imr_gap = `act_imr_bk' - `act_imr_wt'
di `act_imr_gap'

* what is the change in gap 
di ((`cf_imr_gap' - `act_imr_gap')/`cf_imr_gap')*100
// 22.48%


// Figure out, implied difference in treated ratio

local imr_ratio_with_duke = ((1+`bk_treatment')*`et_imr_pre_bk')/((1+`wt_treatment')*`et_imr_pre_wt')

di `imr_ratio_with_duke'

local imr_ratio_no_duke = (`et_imr_pre_bk')/(`et_imr_pre_wt')
di `imr_ratio_no_duke'

// look at change in ratio
di (`imr_ratio_with_duke' - `imr_ratio_no_duke')/`imr_ratio_no_duke'
*9.3% smaller .


// 15.1 =  -.136*111.30 vs 3.1 = -.047*65.72


collapse (sum) saved* treated capp_all_adj pay_all_adj, by(year)
	gen saved_tot = saved_lives_bk + saved_lives_wt
	gen lives_per_treatment = saved_tot/treated
	
	collapse (sum) saved* treated capp_all_adj pay_all_adj
		gen lives_per_treatment = saved_tot/treated
		list lives_per_treatment in 1 
		* 5.59 // lives saved per treatment per year.
		
		* What is capp_all_adj? 2017 $, capp_all is in "present" dollars.
		* tot_capp_all_adj is cumulative in millions. 
		
	list capp_all_adj pay_all_adj in 1
	gen app_per_live_saved = capp_all_adj/saved_tot
	gen pay_per_live_saved = pay_all_adj/saved_tot
	list app_per_live_saved pay_per_live_saved in 1
	
	gen vsl = 7.4*1000000*1.216545 //https://www.epa.gov/environmental-economics/mortality-risk-valuation EPA amount time inflation factor. 
	
	gen roi_app = (vsl/app_per_live_saved)
	gen roi_pay = (vsl/pay_per_live_saved)
	
	list roi_app roi_pay in 1
	
******************************************************************************************************************************************
// [p .7] From 1927 to 1942, 130 projects (in 48 counties) received an appropriation, out of which \hl{XXX projects (in XX counties)} received a non-zero payment.
******************************************************************************************************************************************

// Load cleaned capital appropriations data 
use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta", clear

// Assign appropriations and payments to first year of appropriation 
egen app_year = min(year), by(app_id)
drop year 
rename app_year year 

// Restrict to main sample period
keep if statefip == 37 & year <= 1942

// Merge in inflation factor
fmerge m:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) keep(3) nogen

replace appropriation = 0 if missing(appropriation)
replace app_payments = 0 if missing(app_payments)

gen capp_nurse_homes = capp_all - capp_ex_nurse 
gen pay_nurse_homes = pay_all - pay_ex_nurse
	
foreach z in all ex_nurse new_hosp addition equipment purchase not_stated nurse_homes {

	// Make sure no missing values
	replace capp_`z' = 0 if missing(capp_`z')
	replace pay_`z' = 0 if missing(pay_`z')
	
	// Adjust for inflation (i.e. convert to 2017 dollars) and re-scale units to 1,000,000 dollars
	replace capp_`z' = capp_`z'*inv_inflation_factor/1000000
	replace pay_`z' = pay_`z'*inv_inflation_factor/1000000
}

// 
// Collapse by appropriation ID
gcollapse (sum) capp_* pay_*, by(app_id hosp_id fips) labelformat(#sourcelabel#)

// How many appropriations 
assert capp_all > 0
gisid app_id

gunique app_id
local n_projects = r(unique)

gunique hosp_id 
local n_hospitals = r(unique)

gunique fips
local n_counties = r(unique)

di "From 1927 to 1942 Duke approved appropriations for `n_projects' projects at `n_hospitals' hospitals in `n_counties' counties."

// How many funded 
gunique app_id if pay_all > 0 
local n_projects = r(unique)

gunique hosp_id if pay_all > 0 
local n_hospitals = r(unique)

gunique fips if pay_all > 0 
local n_counties = r(unique)

di "From 1927 to 1942 Duke made payments for `n_projects' projects at `n_hospitals' hospitals in `n_counties' counties."

******************************************************************************************************************************************
// [p .2] Considering only infant mortality, one life was saved for every XX (2017 dollars) paid to hospitals between 1928 and 1942
******************************************************************************************************************************************

// What years with payments?
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

keep if pay_all > 0 & !missing(pay_all)
tab year

// Set up infant mortality analysis
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

// Get baseline IMR- pooled
sum imr_pub [aw = births_pub] if year < 1927
local imr_pre_pooled = r(mean)

sum imr_pub [aw = births_pub] if year > 1937 
local imr_post_pooled = r(mean)

di (`imr_pre_pooled'-`imr_post_pooled')/(`imr_pre_pooled')

// Get baseline IMR - black
sum imr_pub_bk [aw = births_pub_bk] if year < 1927
local imr_pre_bk = r(mean)

sum imr_pub_bk [aw = births_pub_bk] if year > 1937 
local imr_post_bk = r(mean)

di (`imr_pre_bk'-`imr_post_bk')/(`imr_pre_bk')

// Get baseline IMR - white
sum imr_pub_wt [aw = births_pub_wt] if year < 1927
local imr_pre_wt = r(mean)

sum imr_pub_wt [aw = births_pub_wt] if  year > 1937 
local imr_post_wt = r(mean)
di (`imr_pre_wt'-`imr_post_wt')/(`imr_pre_wt')

egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

ppmlhdfe imr_pub b0.treated `baseline_controls' [pw = births_pub], ///
	absorb(fips year) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	
	gen saved_lives = ((imr_pub*treated*`treatment')/1000)*births_pub
	
	sumup saved_lives, by(year) s(sum)
	sumup saved_lives, s(sum) //-2603.941
	
	// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_pooled')/(`imr_pre_pooled'-`imr_post_pooled')
	di (`imr_pre_pooled'-`imr_post_pooled')

ppmlhdfe imr_pub_wt b0.treated `baseline_controls' [pw = births_pub_wt] if ever_zero_births == 0, ///
	absorb(fips year) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	
	gen saved_lives_wt = ((imr_pub_wt*treated*`treatment')/1000)*births_pub_wt
	
	sumup saved_lives_wt, by(year) s(sum)
	sumup saved_lives_wt, s(sum) 
	
	// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_wt')/(`imr_pre_wt'-`imr_post_wt')
	di (`imr_pre_wt'-`imr_post_wt')

ppmlhdfe imr_pub_bk b0.treated `baseline_controls' [pw = births_pub_bk] if ever_zero_births == 0, ///
	absorb(fips year) vce(cluster fips)  
	nlcom exp(_b[1.treated]) - 1
	mat pooled_treatment = r(b)
	local treatment = pooled_treatment[1,1]
	di `treatment'
	
	gen saved_lives_bk = ((imr_pub_bk*treated*`treatment')/1000)*births_pub_bk
	
	sumup saved_lives_bk, by(year) s(sum)
	sumup saved_lives_bk, s(sum) 

	// Counterfactal reduction in IMR
	di (`treatment'*`imr_pre_bk')/(`imr_pre_bk'-`imr_post_bk')
	di (`imr_pre_bk'-`imr_post_bk')
	
// Figure out difference in infant mortality gap

// First what is counter factual Infant mortality for whites
sum saved_lives_wt if treated == 1
local saved_wt = r(sum)

sum mort_wt if treated == 1
local act_mort_wt = r(sum)

sum births_pub_wt if treated == 1
local births_wt = r(sum)

* No Duke IMR for whites
local cf_imr_wt = ((`act_mort_wt' - `saved_wt')/`births_wt')*1000
di `cf_imr_wt'

* With Duke IMR for whites
local act_imr_wt = ((`act_mort_wt')/`births_wt')*1000
di `act_imr_wt'

// Second, what is counter factual Infant mortality for Blacks
sum saved_lives_bk if treated == 1
local saved_bk = r(sum)

sum mort_bk if treated == 1
local act_mort_bk = r(sum)

sum births_pub_bk if treated == 1
local births_bk = r(sum)

* No Duke IMR for Blacks 
local cf_imr_bk = ((`act_mort_bk' - `saved_bk')/`births_bk')*1000
di `cf_imr_bk'

* With Duke IMR for Blacks 
local act_imr_bk = ((`act_mort_bk')/`births_bk')*1000
di `act_imr_bk'

* IMR Gap without Duke
local cf_imr_gap = `cf_imr_bk' - `cf_imr_wt'
di `cf_imr_gap'

local act_imr_gap = `act_imr_bk' - `act_imr_wt'
di `act_imr_gap'

* what is the change in gap 
di ((`cf_imr_gap' - `act_imr_gap')/`cf_imr_gap')*100
// 22.48%
	
// Estimate saved lives 
collapse (sum) saved* treated capp_all_adj pay_all_adj, by(year)
	gen saved_tot = saved_lives_bk + saved_lives_wt
	gen lives_per_treatment = saved_tot/treated
	
	collapse (sum) saved* treated capp_all_adj pay_all_adj
		gen lives_per_treatment = saved_tot/treated
		list lives_per_treatment in 1 
		* 4.67 // lives saved per treatment per year.
		
		* What is capp_all_adj? 2017 $, capp_all is in "present" dollars.
		* tot_capp_all_adj is cumulative in millions. 
		
	list capp_all_adj pay_all_adj in 1

	gen app_per_live_saved = capp_all_adj/saved_tot
	gen pay_per_live_saved = pay_all_adj/saved_tot
	list app_per_live_saved pay_per_live_saved in 1
	
	gen vsl = 7.4*1000000*1.216545 //https://www.epa.gov/environmental-economics/mortality-risk-valuation EPA amount time inflation factor. 
	
	gen roi_app = (vsl/app_per_live_saved)
	gen roi_pay = (vsl/pay_per_live_saved)
	
	list roi_app roi_pay in 1

	/* - 2603 saved lives 
			- 1040 white lives and 1730 black lives 
			- 2770 if you add these up
		- 593 treatments so 4.7 lives saved per treatment 
		- $19,109.74 appropriated per life saved
		- $17,092 saved per life saved 

		- ROI from app is 471
		- ROI from pay is 526
	*/
	
******************************************************************************************************************************************	
// The intervention was also particularly effective in reducing Black infant mortality, resulting in a mortality rate decrease approximately
// three times greater than that observed for White infants (a reduction of 12 vs. 4 deaths per 1,000 births), and narrowing the Black-White infant 
// mortality gap by one-third.	
******************************************************************************************************************************************
	
******************************************************************************************************************************************
// [p. 1] By the end of 1942, the Endowment had appropriated over...
******************************************************************************************************************************************

// Load capital appropriations 
use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta" if statefip == 37 & year <= 1942, clear

// Merge in inflation factor
fmerge m:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) keep(3) nogen

gen long capp_all_adj = capp_all*inv_inflation_factor

gcollapse (sum) capp_all_adj capp_all

sum capp_all, d
di %12.0fc r(mean)

sum capp_all_adj , d format
di %12.0fc r(mean)

******************************************************************************************************************************************
// Do we know how many counties went from 0 to 1 hospital?
******************************************************************************************************************************************

// Load county-level first-stage hospitals data 
use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

* Between 1922-1926: 44 counties never had a hospital and 56 had at least one hospital in one year.
* Of the 44 counties, 12 had a hospital in at least one year 1927-42.

// Flag counties that never had any hospitals 1922-1926
egen max_pre = max(year >= 1922 & year <= 1926 & tot_hospitals > 0), by(fips)

// Flag counties that ever had a hospital 1927-1942
egen max_post = max(year >= 1927 & year <= 1942 & tot_hospitals > 0), by(fips)

// How many counties went from 0 to 1?
gunique fips if max_pre == 0
gunique fips if max_pre == 1
gunique fips if max_pre == 0 & max_post == 1
gunique fips if max_post == 1


******************************************************************************************************************************************
// Decline in infant deaths per 1,000 births from day 1 to months 2 to 12
******************************************************************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(capp_all) time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

gen mort_day_2to30 = mort_month_1 - mort_day_0

sum mort_day_0
sum mort_day_2to30
sum mort_month_2to12

collapse (sum) mort_day_0 mort_day_2to30 mort_month_2to12 births_pub, by(year)

gen deaths_per_day_24hrs = mort_day_0
gen deaths_per_day_m1 = mort_day_2to30/29
gen deaths_per_day_m2to12 = mort_month_2to12/(365*11/12)

sum deaths_per_day_24hrs deaths_per_day_m1 deaths_per_day_m2to12

gen imr_24hrs = deaths_per_day_24hrs*1000/births_pub
gen imr_m1 = deaths_per_day_m1*1000/births_pub
gen imr_m2to12 = deaths_per_day_m2to12*1000/births_pub

sum imr_24hrs imr_m1 imr_m2to12

gen imr_ratio = imr_m1/imr_m2to12
sum imr_ratio

******************************************************************************************************************************************
// Appendix on NC death certificates - which observations get dropped from main sample
******************************************************************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(capp_all) time(year) location(fips)

local min_year 	1922
local max_year 		1942

local suffix "pub"
local mort "mort"

* Birth are never less than deaths for pooled IMR or white IMR
count if !missing(`mort') & `mort' > births_`suffix' & year >= `min_year' & year <= `max_year'
count if !missing(`mort'_wt) & `mort'_wt > births_`suffix'_wt & year >= `min_year' & year <= `max_year'

* Births are sometimes less than deaths for black IMR
count if !missing(`mort'_bk) & `mort'_bk > births_`suffix'_bk & year >= `min_year' & year <= `max_year'
unique fips if !missing(`mort'_bk) & `mort'_bk > births_`suffix'_bk & year >= `min_year' & year <= `max_year'

* Deaths are sometimes zero

unique fips if !missing(`mort'_wt) & `mort'_wt == 0 & year >= `min_year' & year <= `max_year'
unique fips if !missing(`mort'_bk) & `mort'_bk == 0 & year >= `min_year' & year <= `max_year'

******************************************************************************************************************************************
// p. 9 Share of capital expenditures for mixed-race hospitals
******************************************************************************************************************************************

// Load free days data with hospital type
use hosp_* type institution using "$PROJ_PATH/analysis/processed/data/duke/labc_hospital_locations_cleaned.dta" if hosp_id != ., clear
desc, f

// Generate hospital type dummies
replace type = "White Only" if type == "White only"
replace type = "Tuberculosis Sanatoria" if type == "Sanatorium" | type == "TB"
replace type = "White and Colored" if type == "Mixed"
replace type = "Special Hospitals" if type == "Special" | regexm(institution,"Shriners")
tab type, m

gen hosp_colored = (type == "Colored Only")
gen hosp_mixed = (type == "White and Colored")
gen hosp_special = (type == "Special Hospitals")
gen hosp_tb = (type == "Tuberculosis Sanatoria")
gen hosp_white = (type == "White Only")

la var hosp_id "Unique hospital ID"
la var hosp_colored "=1 if colored only hospital"
la var hosp_mixed "=1 if mixed hospital"
la var hosp_special "=1 if specialty hospital"
la var hosp_tb "=1 if TB hospital"
la var hosp_white "=1 if white only hospital"
la var institution "Hospital name"

foreach var of varlist hosp_colored-hosp_white {
	gegen temp_`var' = max(`var'), by(hosp_id)
	replace `var' = temp_`var'
	drop temp_`var' 
}

keep hosp_*
gduplicates drop
gisid hosp_id 
gsort hosp_id 

tempfile hosp_type
save `hosp_type', replace

// Load capital expenditures data
use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta" if statefip == 37 & year >= 1927 & year <= 1942, clear
gsort hosp_id year

// Drop non-zero capital expenditures 
keep if capp_all > 0 | pay_all > 0

// Merge in hospital type from Duke free days data
merge m:1 hosp_id using `hosp_type'

// Keep only entries with capital expenditure and hospital type 
tab statefip _merge
keep if _merge == 3
drop _merge

tab hosp_white, m
tab hosp_mixed, m 
tab hosp_colored, m 

// Drop TB and speciality hospitals 
keep if hosp_white == 1 | hosp_mixed == 1 | hosp_colored == 1

// Code hospital as mixed if conflict
replace hosp_white = 0 if hosp_mixed == 1
replace hosp_colored = 0 if hosp_mixed == 1

assert hosp_white + hosp_mixed + hosp_colored == 1

// Create categorical variable for hospital type (necessary)
gen hosp_type = 0
replace hosp_type = 1 if hosp_white == 1
replace hosp_type = 2 if hosp_colored == 1
replace hosp_type = 3 if hosp_mixed == 1

label define hosp_lab 1 "White only" 2 "Black only" 3 "Mixed", replace
la val hosp_type hosp_lab

collapse (sum) capp_all pay_all, by(hosp_type)

egen tot_capp = total(capp_all)
egen tot_pay = total(pay_all)

gen share_capp = capp_all/tot_capp
gen share_pay = pay_all/tot_pay

list share_* hosp_type

* EOF
