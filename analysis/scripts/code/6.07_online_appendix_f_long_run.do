version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_long_run.do
* PURPOSE: Run analysis for Appendix Section F
************/
// clear memory
clear all 
* User switches

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"


global southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"



*************************************************************************************************
***** Table F1: Long-run mortality with rates
*************************************************************************************************

// Control variables
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"

local baseline_controls "c.percent_illit c.percent_black c.percent_other_race c.percent_urban c.retail_sales_per_capita i.chd_presence"
local race_baseline_controls "c.percent_illit##i.race c.percent_black##i.race c.percent_other_race##i.race c.percent_urban##i.race c.retail_sales_per_capita##i.race i.chd_presence##i.race"


////////////////////////////////////////////////////////////////////////////////
// Panel A: Pooled 

use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear


// Fixed effects 
local fixed_effects "i.age##i.fips i.age##i.year"
local race_int_fixed_effects "i.age##i.fips##i.race i.age##i.year##i.race"

////////////////////////////////////////////////////////////////////////////////
// Program Run

// Generate long-run mortality outcomes + generate weights 

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
	

		// Column 4 - Poisson lldr - no controls - no weights
		eststo p1_c4: ppmlhdfe lldr b0.treated, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 5 - Poisson lldr - no controls -  weights
		eststo p1_c5: ppmlhdfe lldr b0.treated [pw = births_pub], absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 6 - Poisson lldr - controls -  weights
		eststo p1_c6: ppmlhdfe lldr b0.treated  [pw = births_pub], absorb("`fixed_effects'  `int_baseline_controls'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

// By race
		
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta", clear


// Flag counties with births or population ever equal to zero
egen ever_zero_births = max(births_pub == 0), by(fips)
egen ever_zero_pop = max(population == 0), by(fips)



// Generate long-run mortality outcomes + generate weights 
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
	

		// Column 4 - Poisson lldr - no controls - no weights
		eststo p2_c4: ppmlhdfe lldr b0.treated if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 5 - Poisson lldr - no controls -  weights
		eststo p2_c5: ppmlhdfe lldr b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 6 - Poisson lldr - controls -  weights
		eststo p2_c6: ppmlhdfe lldr b0.treated  [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'  `int_baseline_controls'") vce(cluster fips)
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
	

		// Column 4 - Poisson lldr - no controls - no weights
		eststo p3_c4: ppmlhdfe lldr b0.treated if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 5 - Poisson lldr - no controls -  weights
		eststo p3_c5: ppmlhdfe lldr b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 6 - Poisson lldr - controls -  weights
		eststo p3_c6: ppmlhdfe lldr b0.treated  [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'  `int_baseline_controls'") vce(cluster fips)
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
			

		// Column 4 - Poisson lldr - no controls - no weights
		eststo p4_c4: ppmlhdfe lldr b0.treated##i.race if ever_zero_births == 0 , absorb("`race_int_fixed_effects'") vce(cluster fips)
		test _b[1.treated#2.race] = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
			
		// Column 5 - Poisson lldr - no controls -  weights
		eststo p4_c5: ppmlhdfe lldr b0.treated##i.race [pw = births_pub] if ever_zero_births == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
		test _b[1.treated#2.race] = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
			
		// Column 6 - Poisson lldr - controls -  weights
		eststo p4_c6: ppmlhdfe lldr b0.treated##i.race `race_int_baseline_controls' [pw = births_pub] if ever_zero_births == 0, absorb("`race_int_fixed_effects'  ") vce(cluster fips)
		test _b[1.treated#2.race] = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
////////////////////////////////////////////////////////////////////////////////
// With rates

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Long-run deaths}$"'
local y_2 "\$Y^{R}_{ct} = \text{Long-run mortality rate}$"

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c4 p1_c5 p1_c6 
 using "$PROJ_PATH/analysis/output/appendix/table_F1_later_life_mortality_with_rates.tex", `booktabs_default_options' replace 
 mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled long-run deaths or long-run mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c4 p2_c5 p2_c6 
 using "$PROJ_PATH/analysis/output/appendix/table_F1_later_life_mortality_with_rates.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black long-run deaths or long-run mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 p3_c4 p3_c5 p3_c6 
 using "$PROJ_PATH/analysis/output/appendix/table_F1_later_life_mortality_with_rates.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White long-run deaths or long-run mortality rate} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 p4_c4 p4_c5 p4_c6
 using "$PROJ_PATH/analysis/output/appendix/table_F1_later_life_mortality_with_rates.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth X Age FE 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth X Age FE 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\   
	Weights 						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\");
#delimit cr

*************************************************************************************************
***** Table F2: Collapsed long-run mortality  -
*************************************************************************************************

version 15
disp "DateTime: $S_DATE $S_TIME"

// clear memory
clear all 

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables

local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita i.chd_presence"
local race_baseline_controls "c.percent_illit##i.race c.percent_black##i.race c.percent_other_race##i.race c.percent_urban##i.race c.retail_sales_per_capita##i.race i.chd_presence##i.race"

// Panel A: Pooled 

// Panel start and end dates
local year_start 	1932
local year_end 		1941

// Long-run mortality restrictions
local age_lb 		56
local age_ub		64

// Fixed effects 
local fixed_effects "i.fips i.year"
local race_int_fixed_effects "i.fips##i.race i.year##i.race"

////////////////////////////////////////////////////////////////////////////////
// Collapsed 
// Open dataset
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear
replace population = 0 if year != `year_start'

collapse ///
	(sum) deaths births_pub population ///
	(mean) capp_all  treated time_treated ///
	percent_illit percent_black percent_other_race percent_urban ///
	retail_sales_per_capita chd_presence ///
	, by(year fips)
sort fips year

count 
 
bysort fips: gen temp_pop = sum(population)
replace population = temp_pop 
gen lldr = (deaths/population)*100000

		/////////////////////////////////////
	// Now with "years of treatment" 
	gen treatment_begins_at_age = .
	replace treatment_begins_at_age = time_treated - year if !missing(time_treated)
	replace treatment_begins_at_age = 0 if treatment_begins_at_age < 0 & !missing(treatment_begins_at_age)
	
	// Simpler to understand treatment
	gen treated_0_1 = 0
	replace treated_0_1 = 1 if treatment_begins_at_age <= 1
	
	gen treated_2_3 = 0
	replace treated_2_3 = 1 if treatment_begins_at_age <= 3
	
	gen treated_4_5 = 0
	replace treated_4_5 = 1 if treatment_begins_at_age <= 5
	
	gen treated_6_up = 0
	replace treated_6_up = 1 if treatment_begins_at_age > 5

////////////////////////////////////////////////////////////////////////////////
// Run

// Generate long-run mortality outcomes + generate weights 

	* Binary treatment 
		// Column 1 - Poisson deaths - no controls - no weights
		eststo p1_c1: ppmlhdfe deaths b0.treated, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

		// Column 2 - Poisson deaths - no controls -  weights
		eststo p1_c2: ppmlhdfe deaths b0.treated [pw = births_pub], absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 3 - Poisson deaths - controls -  weights
		eststo p1_c3: ppmlhdfe deaths b0.treated `baseline_controls' [pw = births_pub], absorb("`fixed_effects'  ") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
		
		
////////////////////////////////////////////////////////////////////////////////	
// By race
		
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta", clear

egen ever_zero_births = max(births_pub == 0), by(fips)

replace population = 0 if year != `year_start'

collapse ///
	(sum) deaths births_pub population ever_zero_births ///
	(mean) capp_all  treated time_treated ///
	percent_illit percent_black percent_other_race percent_urban ///
	retail_sales_per_capita chd_presence ///
	, by(year fips race)
sort fips year

count 
 
bysort fips: gen temp_pop = sum(population)
replace population = temp_pop 
gen lldr = (deaths/population)*100000

		/////////////////////////////////////
	// Now with "years of treatment" 
	gen treatment_begins_at_age = .
	replace treatment_begins_at_age = time_treated - year if !missing(time_treated)
	replace treatment_begins_at_age = 0 if treatment_begins_at_age < 0 & !missing(treatment_begins_at_age)
	
	// Simpler to understand treatment
	gen treated_0_1 = 0
	replace treated_0_1 = 1 if treatment_begins_at_age <= 1
	
	gen treated_2_3 = 0
	replace treated_2_3 = 1 if treatment_begins_at_age <= 3
	
	gen treated_4_5 = 0
	replace treated_4_5 = 1 if treatment_begins_at_age <= 5
	
	gen treated_6_up = 0
	replace treated_6_up = 1 if treatment_begins_at_age > 5


// Generate long-run mortality outcomes + generate weights 
	* Black Binary treatment 
		// Column 1 - Poisson deaths - no controls - no weights
		eststo p2_c1: ppmlhdfe deaths b0.treated if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 2 - Poisson deaths - no controls -  weights
		eststo p2_c2: ppmlhdfe deaths b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 3 - Poisson deaths - controls -  weights
		eststo p2_c3: ppmlhdfe deaths b0.treated `baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 2, absorb("`fixed_effects' ") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	

	* White Binary treatment 
		// Column 1 - Poisson deaths - no controls - no weights
		eststo p3_c1: ppmlhdfe deaths b0.treated if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 2 - Poisson deaths - no controls -  weights
		eststo p3_c2: ppmlhdfe deaths b0.treated [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
		lincomestadd2a  100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
	
		// Column 3 - Poisson deaths - controls -  weights
		eststo p3_c3: ppmlhdfe deaths b0.treated  `baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 1, absorb("`fixed_effects'") vce(cluster fips)
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
		eststo p4_c3: ppmlhdfe deaths b0.treated##i.race  `race_baseline_controls' [pw = births_pub] if ever_zero_births == 0, absorb("`race_int_fixed_effects'  ") vce(cluster fips)
		test _b[1.treated#2.race] = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value' 
			

local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Long-run deaths}$"'

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_F2_later_life_mortality_collapsed.tex", `booktabs_default_options' replace 
 mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_F2_later_life_mortality_collapsed.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_F2_later_life_mortality_collapsed.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White long-run deaths} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_F2_later_life_mortality_collapsed.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\ 
	Year of birth 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\   
	Weights 						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\
	Controls						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes}  \\");
#delimit cr

*************************************************************************************************
***** Table F3: Long-run mortality add other southern states
*************************************************************************************************


// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Panel start and end dates
local first_year_numident 1988
local year_start 1932
local year_end 1941
local age_lb 56
local age_ub 64
local first_cohort 1932
local fixed_effects "i.age##i.fips i.age##i.year"
local race_int_fixed_effects "i.age##i.fips##i.race i.age##i.year##i.race"
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"
global southern_states 	"inlist(str_st_fips, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

////////////////////////////////////////////////////////////////////////////////
// By Pooled
use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_pooled.dta", clear
append using  "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta"

// Drop south carolina
gen str_fips = string(fips)
gen str_st_fips = substr(str_fips,1,2)
destring str_st_fips, replace
tab str_st_fips 
drop if str_st_fips  == 45
keep if $southern_states
drop str_st_fips str_fips



// Flag counties with births or population ever equal to zero
egen ever_zero_births = max(births_pub == 0), by(fips)
egen ever_zero_pop = max(population == 0), by(fips)

gen drop = 0 
replace drop = 1 if statefip == 37 & ever_treated == 0

gen drop_inculde_no_np = 0 
replace drop_inculde_no_np = 1 if drop == 1
replace drop_inculde_no_np = 1 if statefip != 37  & ever_non_profit == 0

// Pooled 

eststo p1_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p1_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p1_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


////////////////////////////////////////////////////////////////////////////////
// By race
use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race.dta", clear
append using  "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta"

// Drop south carolina
gen str_fips = string(fips)
gen str_st_fips = substr(str_fips,1,2)
destring str_st_fips, replace
tab str_st_fips 
drop if str_st_fips  == 45
keep if $southern_states

drop str_st_fips str_fips


// Flag counties with births or population ever equal to zero
egen ever_zero_births = max(births_pub == 0), by(fips)
egen ever_zero_pop = max(population == 0), by(fips)

gen drop = 0 
replace drop = 1 if statefip == 37 & ever_treated == 0

gen drop_inculde_no_np = 0 
replace drop_inculde_no_np = 1 if drop == 1
replace drop_inculde_no_np = 1 if statefip != 37  & ever_non_profit == 0

// Black 

eststo p2_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 2 , absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p2_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 2 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p2_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 2 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

// White 

eststo p3_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 1 , absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p3_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 1 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p3_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & race == 1 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

// Interaction 

eststo p4_c1: ppmlhdfe deaths b0.treated##i.race  `race_int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 , absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'

eststo p4_c2: ppmlhdfe deaths b0.treated##ib1.race  `race_int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & drop == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'

eststo p4_c3: ppmlhdfe deaths b0.treated##ib1.race  `race_int_baseline_controls' [pw = births_pub] if ever_zero_births == 0 & drop_inculde_no_np == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'
		
		

///////////////////////////////////////////////////////////////////////////////
// Combined table 

// Load short-run estimates. 
forvalues i = 1(1)4 {
	forvalues j = 1(1)3 {
		est use "$PROJ_PATH/analysis/processed/temp/cc_sr_p`i'_c`j'"
		eststo  cc_sr_p`i'_c`j'
	}
}
// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 "\$Y^{R}_{ct} = \text{Infant mortality rate}$"
local y_2 "\$Y^{R}_{ct} = \text{Long-run deaths}$"
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Make top panel - Pooled
#delimit ;
esttab cc_sr_p1_c1 cc_sr_p1_c2 cc_sr_p1_c3 p1_c1 p1_c2 p1_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F3_combined_mortality_clean_controls.tex", `booktabs_default_options' replace 
 mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab  cc_sr_p2_c1 cc_sr_p2_c2 cc_sr_p2_c3 p2_c1 p2_c2 p2_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F3_combined_mortality_clean_controls.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab cc_sr_p3_c1 cc_sr_p3_c2 cc_sr_p3_c3 p3_c1 p3_c2 p3_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F3_combined_mortality_clean_controls.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab cc_sr_p4_c1 cc_sr_p4_c2 cc_sr_p4_c3 p4_c1 p4_c2 p4_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F3_combined_mortality_clean_controls.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth FE 				 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\ 
	County of birth X Age  FE 				 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth   FE 			 	 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\   
	Year of birth  X Age FE 			 	  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\   
	Weights 								 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls								 & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} \\
	Exclude untreated NC 					&\multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  &\multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Exclude without non-profit hosp.		& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} \\");
#delimit cr

// Delete short-run estimates. 
forvalues i = 1(1)4 {
	forvalues j = 1(1)3 {
		rm "$PROJ_PATH/analysis/processed/temp/cc_sr_p`i'_c`j'.ster"
	}
}
*************************************************************************************************
***** Table F4: Long-run mortality, include South Carolina
*************************************************************************************************
clear all

* User switches

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Panel start and end dates
local first_year_numident 1988
local year_start 1932
local year_end 1941
local age_lb 56
local age_ub 64
local first_cohort 1932
local fixed_effects "i.age##i.fips i.age##i.year"
local race_int_fixed_effects "i.age##i.fips##i.race i.age##i.year##i.race"
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"
global southern_states_with_sc 	"inlist(str_st_fips, 1, 5, 12, 13, 21, 22, 28, 37, 45, 47, 48, 51, 54)"


////////////////////////////////////////////////////////////////////////////////
// By Pooled
use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_pooled.dta", clear
append using  "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled_nc_sc.dta"
gen str_fips = string(fips)
gen str_st_fips = substr(str_fips,1,2)
destring str_st_fips, replace
keep if $southern_states_with_sc


levelsof fips if ever_treated == 1


// Flag counties with births or population ever equal to zero
egen ever_zero_pop = max(population == 0), by(fips)

gen treated_state = 0
replace treated_state = 1 if statefip == 37 | statefip == 45

gen drop = 0 
replace drop = 1 if treated_state == 1 & ever_treated == 0 

gen drop_inculde_no_np = 0 
replace drop_inculde_no_np = 1 if drop == 1
replace drop_inculde_no_np = 1 if treated_state != 1  & ever_non_profit == 0

// Pooled 
eststo p1_ca1: ppmlhdfe deaths b0.treated if ever_zero_pop == 0 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p1_ca2: ppmlhdfe deaths b0.treated [pw = population] if ever_zero_pop == 0 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p1_ca3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p1_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p1_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p1_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")




////////////////////////////////////////////////////////////////////////////////
// By race
use "$PROJ_PATH/analysis/processed/data/south_gompertz_event_study_input_by_race.dta", clear
append using  "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race_nc_sc.dta"
gen str_fips = string(fips)
gen str_st_fips = substr(str_fips,1,2)
destring str_st_fips, replace
keep if $southern_states_with_sc


// Flag counties with births or population ever equal to zero
egen ever_zero_pop = max(population == 0), by(fips)
gen treated_state = 0
replace treated_state = 1 if statefip == 37 | statefip == 45

gen drop = 0 
replace drop = 1 if treated_state == 1 & ever_treated == 0 

gen drop_inculde_no_np = 0 
replace drop_inculde_no_np = 1 if drop == 1
replace drop_inculde_no_np = 1 if treated_state != 1  & ever_non_profit == 0

// Black 

eststo p2_ca1: ppmlhdfe deaths b0.treated  if ever_zero_pop == 0 & race == 2 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p2_ca2: ppmlhdfe deaths b0.treated  [pw = population] if ever_zero_pop == 0 & race == 2 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p2_ca3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 2  & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p2_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 2 , absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p2_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 2 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p2_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 2 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

// White 
eststo p3_ca1: ppmlhdfe deaths b0.treated  if ever_zero_pop == 0 & race == 1 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p3_ca2: ppmlhdfe deaths b0.treated  [pw = population] if ever_zero_pop == 0 & race == 1 & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p3_ca3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 1  & treated_state == 1, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p3_c1: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 1 , absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p3_c2: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 1 & drop == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")


eststo p3_c3: ppmlhdfe deaths b0.treated `int_baseline_controls' [pw = population] if ever_zero_pop == 0 & race == 1 & drop_inculde_no_np == 0, absorb("`fixed_effects'") vce(cluster fips)
lincomestadd2a  100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("pct_efct_")

// Interaction 

eststo p4_ca1: ppmlhdfe deaths b0.treated##i.race  if ever_zero_pop == 0   & treated_state == 1, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'
		
eststo p4_ca2: ppmlhdfe deaths b0.treated##i.race  [pw = population] if ever_zero_pop == 0  & treated_state == 1, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'
		
eststo p4_ca3: ppmlhdfe deaths b0.treated##i.race `race_int_baseline_controls' [pw = population] if ever_zero_pop == 0  & treated_state == 1, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'

eststo p4_c1: ppmlhdfe deaths b0.treated##i.race  `race_int_baseline_controls' [pw = population] if ever_zero_pop == 0 , absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'

eststo p4_c2: ppmlhdfe deaths b0.treated##ib1.race  `race_int_baseline_controls' [pw = population] if ever_zero_pop == 0 & drop == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'

eststo p4_c3: ppmlhdfe deaths b0.treated##ib1.race  `race_int_baseline_controls' [pw = population] if ever_zero_pop == 0 & drop_inculde_no_np == 0, absorb("`race_int_fixed_effects'") vce(cluster fips)
	testnl exp(_b[1.treated#2.race]) - 1 = 0
		local  int_p_value = r(p) 
		estadd scalar int_p_value = `int_p_value'
		
		
///////////////////////////////////////////////////////////////////////////////
// Combined table 

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 "Only data from North and South Carolina"
local y_2 "Add data from other southern states"
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Make top panel - Pooled
#delimit ;
esttab p1_ca1 p1_ca2 p1_ca3 p1_c1 p1_c2 p1_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F4_later_life_mortality_add_south_carolina.tex", `booktabs_default_options' replace 
 mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab  p2_ca1 p2_ca2 p2_ca3 p2_c1 p2_c2 p2_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F4_later_life_mortality_add_south_carolina.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_ca1 p3_ca2 p3_ca3 p3_c1 p3_c2 p3_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F4_later_life_mortality_add_south_carolina.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_ca1 p4_ca2 p4_ca3 p4_c1 p4_c2 p4_c3
 using "$PROJ_PATH/analysis/output/appendix/table_F4_later_life_mortality_add_south_carolina.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth X Age  FE 				 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth  X Age FE 			 	 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\   
	Weights 								 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls								 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} \\
	Include non-Carolina 					 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} &\multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Exclude untreated Carolina 					 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} &\multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Exclude without non-profit hosp.		  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} \\");
#delimit cr

*************************************************************************************************
***** Figure F1: Life expectancy at birth and numident restrictions
*************************************************************************************************

cd "$PROJ_PATH"

//////////////////////////////////////////////////////////
// Redo life expectancy at birth with x-axis
// Import excel
import excel "analysis/raw/cdc-wonder/imr-and-life-expectancy-by-year.xlsx", ///
	sheet("Sheet1") cellrange(A1:E19) firstrow clear

insobs 3, before(1)
replace year = 1922 in 1
replace year = 1932 in 2
replace year = 1941 in 3

gen min_age_numident = 1988 - year
gen max_age_numident = 2005 - year

gen max_included_age = 64
gen min_included_age = 56

replace min_age_numident = 0 if min_age_numident < 0
*replace min_age_numident = 84 if min_age_numident > 84
replace max_age_numident = 0 if max_age_numident < 0
*replace max_age_numident = 84 if max_age_numident > 84

sort year 
*     || rarea min_included_age max_included_age year if year <= 1941 & year >= 1932, fcolor("74 120 169") lcolor(gs8) lpattern(l) lwidth(.5) ///

twoway ///
    || scatteri 80 1932 80 1941, recast(area) lcol(gs8) lp(l) lwidth(0.5)   fcolor(blue%50) /// Birth year cohort
    || rarea min_age_numident max_age_numident year if year <= 2020 & min_age_numident <= 80 & max_age_numident >=25, fcolor(gs13%50) lcolor(gs8) lpattern(l) lwidth(.5) ///
	|| connected le_white year if year <= 2020,  lcolor(black)  lpattern(l) lwidth(1) msymbol(none) ///
	|| connected le_black year if year <= 2020,  lcolor(black)  lpattern("-") lwidth(.5)  msymbol(none) ///
    || scatteri 65 1840 65 2020, recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// Age 65 line 
    || pcarrowi 46 1975 42 1966, lcolor(black) msize(3) mcolor(black) ///
    || pcarrowi 9 1950 12 1941.5, lcolor(black) msize(3) mcolor(black) ///
    ylab(0(20)80, nogrid notick labsize(6) ) ///
	xlab(1840(40)2020, nogrid notick labsize(6) ) ///
	ytitle("", size(7)) ///
	xtitle("Birth year", size(7)) ///
	legend(off) ///
	xscale(range(1840 2020))	///
		xsize(8) ///
		graphregion( fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				subtitle("Life expectancy at birth", size(5) pos(11)) ///	
				title("Life expectancy at birth is below age 65 for those" "born before 1940", size(7) pos(11)) ///	
		text(27 1870 "Black", place(s) size(6)) ///
		text(45.5 1865 "White", place(nw) size(6)) ///
        text(70 1840 "Age 65", place(e) size(4)) ///
        text(9.5 1949.5 "Birth years in", place(e) size(4)) ///
        text(2.5 1949.5 "preferred specification", place(e) size(4)) ///
        text(47 1975 "Available follow-up years", place(e) size(4)) ///
        text(40 1975 "from Numident", place(e) size(4)) 
        
		graph export "$PROJ_PATH/analysis/output/appendix/figure_F1_life_exp_at_birth_with_numident_restrictions.pdf", replace

*************************************************************************************************
***** Figures F2 and F3: Long-run event-study and composition of treated units in event-time
*************************************************************************************************

version 15
disp "DateTime: $S_DATE $S_TIME"

// clear memory
clear all 



// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"

//////////////////////////////////////////////////////////////////////////////
// Pooled 

// Create first year treated

use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear

gen time_treated_2 = time_treated
replace time_treated_2 = 0 if missing(time_treated)
				

// Graph min and max 
local gphMin -6
local gphMax 6
local ref_time = -6

// Panel start and end dates
local year_start 	1932
local year_end 		1941

// Later-life mortality restrictions
local age_lb 		56
local age_ub		64
local ref_time = -6




sort fips year yodssn 
order fips year yodssn ever_treated capp_all 

					local weightvar births_pub
					capture drop event_time_bacon
					gen event_time_bacon = year - time_treated
					
		// Determine number of unique "event times"		
	capture drop x_value 
	capture drop y_value 
	
	gen x_value = .
	gen y_value = . 
	egen id_cy = group(fips year)
	local order_index = 1
	forvalues i = -8(1)10 {
		di "`i'"
		replace x_value = `i' in `order_index'
		unique id_cy if event_time_bacon == `i'
		replace y_value = `r(N)' in  `order_index'
		
		local order_index = `order_index' + 1
	}
	
	graph bar (sum) y_value, over(x_value) /// 
		b1title("Years since first capital appropriation from Duke Endowment relative to birth year", size(4) height(7)) ///
		ytitle("") ///
		subtitle("Number of observations in event time")

				 
			*graph export "$PROJ_PATH/analysis/output/appendix/unbalanced_event_time_long_run.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_F3_unbalanced_event_time_long_run.pdf", replace 

										order event_time_bacon
					levelsof(event_time_bacon) if !missing(deaths), matrow(event_time_names)	
					mat list event_time_names
									
						local unique_event_times = r(r)
						di `unique_event_times'
						

						local ref_event_time = `ref_time'
						capture drop event_time_names1
						
						recode event_time_bacon (.=`ref_event_time')
						*ensure that "xi" omits -1
						char event_time_bacon[omit] `ref_event_time'

						xi i.event_time_bacon, pref(_T)
						order fips year yodssn ever_treated capp_all  event_time_bacon

						ppmlhdfe deaths ///
									_T* ///
									[pw = `weightvar'] ///
									, absorb(i.age##i.fips i.age##i.year) vce(cluster fips)	
									
				levelsof(event_time_bacon) if  !missing(deaths) , local(event_time_names_with_ref)
				
				// Extract position of reference year
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
				
		
						levelsof(event_time_bacon) if event_time_bacon != `ref_event_time' & !missing(deaths) , matrow(event_time_names_without_ref) // Original line in Alex's code 
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
						mat ppmle_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
						mat list ppmle_results
						
						
											
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
						*di `time_b4_ref_event_time'
						capture drop event_time_names_wo_ref_capped1
						
						// Find out order of event time in the post-period is right after reference event-time
						capture drop event_time_names_without_ref1
						svmat event_time_names_without_ref
						preserve 
							*drop if event_time_names_without_ref1 < 0
							*drop if event_time_names_without_ref1 > 10
							egen time_after_ref_event_time = min(event_time_names_without_ref1) if event_time_names_without_ref1 >= 0
							gen temp_order = _n if !missing(event_time_names_without_ref1)
							sum temp_order if time_after_ref_event_time == event_time_names_without_ref1
							local time_after_ref_event_time = r(mean)
							
							sum temp_order
							local max_pos = r(max)
						restore
						*di `time_after_ref_event_time'
						*di `max_pos'
						capture drop event_time_names_wo_ref_capped1		
						

						// Add row where reference group should be
						mat ppmle_results = ppmle_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ ppmle_results[`time_after_ref_event_time'..`max_pos',.]
						mat list ppmle_results
										
					
						// Clean up. 
						capture drop event_time_bacon
						capture drop _T*
						capture drop event_time_names_without_ref1
						
			
		clear
		tempfile ppmle_results
		svmat ppmle_results
		rename ppmle_results1 order
		rename ppmle_results2 b
		rename ppmle_results3 ll
		rename ppmle_results4 ul
		gen method = "ppmle"

		save "`ppmle_results'"
		


		replace b = 0 if missing(b) & order == -1

		////////////////////////////////////////////////////////////////////////////////
		// Figure 
		gen new_id = 0 
		replace new_id = 1 if method == "ppmle"
	
		gen modified_event_time = order 
		 
		keep if order >= `gphMin'
		keep if order <= `gphMax'
		sort modified_event_time
		order modified_event_time
		
		local mn = `gphMin' -  1
		local mx = `gphMax' + 1
		local low_event_cap_graph `mn'
		local high_event_cap_graph `mx'

		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'
		keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

		// Plot estimates - For slides without title
		twoway ///
			|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
			|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
			|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
			|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			|| pcarrowi 10 5.25 1 5.05 (0) , mcolor(black) lcolor(black) ///
			|| pcarrowi 12 -.45 6 -.75 (0) , mcolor(black) lcolor(black) ///
			|| pcarrowi -20 -5.75 -12 -5.25 (0) , mcolor(black) lcolor(black) ///
				text(20 5.25 "Appropriation five", place(0)) ///
				text(16 5.25 "years before", place(0)) ///
				text(12 5.25 "birth", place(0)) ///
				text(23 -.5 "Appropriation", place(0)) ///
				text(19 -.5 "in first year", place(0)) ///
				text(15 -.5 "of life", place(0)) ///
				text(-22 -6.05 "Appropriation", place(0)) ///
				text(-26 -6.05 "at age five", place(0)) ///
				xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
						, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(, labsize(5)) ///
				xtitle("Years since first capital appropriation from Duke Endowment relative to birth year", size(4) height(7)) ///
				xsize(8) ///
				legend(off) ///
			    xline(.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			 subtitle("Effect of duke appropriation on long-run mortality by year" " ", size(5) pos(11)) 
			 
			*graph export "$PROJ_PATH/analysis/output/appendix/figure_xx_`depvar_new'_long_run_first_stage_`gphMax'.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_F2_long_run_unbalanced_event_study.pdf", replace 

*************************************************************************************************
***** Figure F4: Long-run event-study, extended time
*************************************************************************************************

version 15
disp "DateTime: $S_DATE $S_TIME"

// clear memory
clear all 

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"

//////////////////////////////////////////////////////////////////////////////
// Pooled 

// Create first year treated

use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear

gen time_treated_2 = time_treated
replace time_treated_2 = 0 if missing(time_treated)
				

// Graph min and max 
local gphMin -6
local gphMax 10
local ref_time = -6

// Panel start and end dates
local year_start 	1932
local year_end 		1941

// Later-life mortality restrictions
local age_lb 		56
local age_ub		64

sort fips year yodssn 
order fips year yodssn ever_treated capp_all 

					local weightvar births_pub

					capture drop event_time_bacon
					gen event_time_bacon = year - time_treated
					


										order event_time_bacon
					levelsof(event_time_bacon) if !missing(deaths), matrow(event_time_names)	
					mat list event_time_names
									
						local unique_event_times = r(r)
						di `unique_event_times'
						

						local ref_event_time = `ref_time'
						capture drop event_time_names1
						
						recode event_time_bacon (.=`ref_event_time')
						*ensure that "xi" omits -1
						char event_time_bacon[omit] `ref_event_time'

						xi i.event_time_bacon, pref(_T)
						order fips year yodssn ever_treated capp_all  event_time_bacon

						ppmlhdfe deaths ///
									_T* ///
									[pw = `weightvar'] ///
									, absorb(i.age##i.fips i.age##i.year) vce(cluster fips)	
									
				levelsof(event_time_bacon) if  !missing(deaths) , local(event_time_names_with_ref)
				
				// Extract position of reference year
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
				
		
						levelsof(event_time_bacon) if event_time_bacon != `ref_event_time' & !missing(deaths) , matrow(event_time_names_without_ref) // Original line in Alex's code 
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
						mat ppmle_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
						mat list ppmle_results
						
						
											
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
						*di `time_b4_ref_event_time'
						capture drop event_time_names_wo_ref_capped1
						
						// Find out order of event time in the post-period is right after reference event-time
						capture drop event_time_names_without_ref1
						svmat event_time_names_without_ref
						preserve 
							*drop if event_time_names_without_ref1 < 0
							*drop if event_time_names_without_ref1 > 10
							egen time_after_ref_event_time = min(event_time_names_without_ref1) if event_time_names_without_ref1 >= 0
							gen temp_order = _n if !missing(event_time_names_without_ref1)
							sum temp_order if time_after_ref_event_time == event_time_names_without_ref1
							local time_after_ref_event_time = r(mean)
							
							sum temp_order
							local max_pos = r(max)
						restore
						*di `time_after_ref_event_time'
						*di `max_pos'
						capture drop event_time_names_wo_ref_capped1		
						

						// Add row where reference group should be
						mat ppmle_results = ppmle_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ ppmle_results[`time_after_ref_event_time'..`max_pos',.]
						mat list ppmle_results
										
					
						// Clean up. 
						capture drop event_time_bacon
						capture drop _T*
						capture drop event_time_names_without_ref1
						
			
		clear
		tempfile ppmle_results
		svmat ppmle_results
		rename ppmle_results1 order
		rename ppmle_results2 b
		rename ppmle_results3 ll
		rename ppmle_results4 ul
		gen method = "ppmle"

		save "`ppmle_results'"
		


		replace b = 0 if missing(b) & order == -1

		////////////////////////////////////////////////////////////////////////////////
		// Figure 
		gen new_id = 0 
		replace new_id = 1 if method == "ppmle"
	
		gen modified_event_time = order 
		 
		keep if order >= `gphMin'
		keep if order <= `gphMax'
		sort modified_event_time
		order modified_event_time
		
		local mn = `gphMin' -  1
		local mx = `gphMax' + 1
		local low_event_cap_graph `mn'
		local high_event_cap_graph `mx'

		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'
		keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

		// Plot estimates - For slides without title
		twoway ///
			|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
			|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
			|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
			|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			|| pcarrowi 10 5.25 1 5.05 (0) , mcolor(black) lcolor(black) ///
			|| pcarrowi 12 -.45 6 -.75 (0) , mcolor(black) lcolor(black) ///
			|| pcarrowi -20 -5.75 -12 -5.25 (0) , mcolor(black) lcolor(black) ///
				text(20 5.25 "Appropriation five", place(0)) ///
				text(16 5.25 "years before", place(0)) ///
				text(12 5.25 "birth", place(0)) ///
				text(23 -.5 "Appropriation", place(0)) ///
				text(19 -.5 "in first year", place(0)) ///
				text(15 -.5 "of life", place(0)) ///
				text(-22 -6.05 "Appropriation", place(0)) ///
				text(-26 -6.05 "at age five", place(0)) ///
				xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
						, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(, labsize(5)) ///
				xtitle("Years since first capital appropriation from Duke Endowment relative to birth year", size(4) height(7)) ///
				xsize(8) ///
				legend(off) ///
			    xline(.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			 subtitle("Effect of duke appropriation on long-run mortality by year" " ", size(5) pos(11)) 
			 
			*graph export "$PROJ_PATH/analysis/output/appendix/figure_xx_`depvar_new'_long_run_first_stage_`gphMax'.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_F4_long_run_unbalanced_event_study_extended.pdf", replace 

*************************************************************************************************
***** Figure F5: Long-run event-study, balanced event-time
*************************************************************************************************
///////////////////////////////version 15
disp "DateTime: $S_DATE $S_TIME"

// clear memory
clear all 



// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables
local int_baseline_controls "i.age##c.percent_illit i.age##c.percent_black i.age##c.percent_other_race i.age##c.percent_urban i.age##c.retail_sales_per_capita i.age##i.chd_presence"
local race_int_baseline_controls "i.age##c.percent_illit##i.race i.age##c.percent_black##i.race i.age##c.percent_other_race##i.race i.age##c.percent_urban##i.race i.age##c.retail_sales_per_capita##i.race i.age##i.chd_presence##i.race"

//////////////////////////////////////////////////////////////////////////////
// Pooled 

// Create first year treated

use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear

gen time_treated_2 = time_treated
replace time_treated_2 = 0 if missing(time_treated)
				

// Graph min and max 
local gphMin -2
local gphMax 6
local ref_time = -2

// Panel start and end dates
local year_start 	1932
local year_end 		1941

// Later-life mortality restrictions
local age_lb 		56
local age_ub		64



///////////////////////////////////////////////////////////////////////////////////////////////
// Number treated by event-time

///////////////////////////////////////////////////////////////////////////////////////////////
// Pooled
use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear

gen time_treated_2 = time_treated
replace time_treated_2 = 0 if missing(time_treated)
				

keep if year >= `year_start' & year <= `year_end'

// Cohort restrictions
keep if age >= `age_lb' & age <= `age_ub'


sort fips year yodssn 
order fips year yodssn ever_treated capp_all 

					local weightvar births_pub
					local depvar_new deaths

					capture drop event_time_bacon
					gen event_time_bacon = year - time_treated
	
	tab event_time_bacon
		
	
	gen neg_6 = 0
	replace neg_6 =1 if event_time_bacon == -2
	gen pos_6 = 0
	replace pos_6 =1 if event_time_bacon == 6
	bysort fips age: egen has_neg_6 = max(neg_6)
	bysort fips age: egen has_pos_6 = max(pos_6)
	
	
	keep if has_neg_6 ==1 & has_pos_6 ==1 | missing(event_time_bacon)
	
	
		// Determine number of unique "event times"		
	capture drop x_value 
	capture drop y_value 
	
	gen x_value = .
	gen y_value = . 
	egen id_cy = group(fips year)
	local order_index = 1
	forvalues i = -3(1)7 {
		di "`i'"
		replace x_value = `i' in `order_index'
		unique id_cy if event_time_bacon == `i'
		replace y_value = `r(N)' in  `order_index'
		
		local order_index = `order_index' + 1
	}
	
	graph bar (sum) y_value, over(x_value) /// 
		b1title("Years since first capital appropriation from Duke Endowment relative to birth year", size(4) height(7)) ///
		ytitle("") ///
		subtitle("Number of observations in event time")

				 
			*graph export "$PROJ_PATH/analysis/output/appendix/balanced_event_time_long_run.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_F5_bot_balanced_event_time_long_run.pdf", replace 
	
										order event_time_bacon
					levelsof(event_time_bacon) if !missing(deaths), matrow(event_time_names)	
					mat list event_time_names
									
						local unique_event_times = r(r)
						di `unique_event_times'
						

						local ref_event_time = `ref_time'
						capture drop event_time_names1
						
						recode event_time_bacon (.=`ref_event_time')
						*ensure that "xi" omits -1
						char event_time_bacon[omit] `ref_event_time'

						xi i.event_time_bacon, pref(_T)
						order fips year yodssn ever_treated capp_all  event_time_bacon

						ppmlhdfe deaths ///
									_T* ///
									[pw = `weightvar'] ///
									, absorb(i.age##i.fips i.age##i.year) vce(cluster fips)	
									
				levelsof(event_time_bacon) if  !missing(deaths) , local(event_time_names_with_ref)
				
				// Extract position of reference year
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
				
		
						levelsof(event_time_bacon) if event_time_bacon != `ref_event_time' & !missing(deaths) , matrow(event_time_names_without_ref) // Original line in Alex's code 
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
						mat ppmle_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
						mat list ppmle_results
						
						
											
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
						*di `time_b4_ref_event_time'
						capture drop event_time_names_wo_ref_capped1
						
						// Find out order of event time in the post-period is right after reference event-time
						capture drop event_time_names_without_ref1
						svmat event_time_names_without_ref
						preserve 
							*drop if event_time_names_without_ref1 < 0
							*drop if event_time_names_without_ref1 > 10
							egen time_after_ref_event_time = min(event_time_names_without_ref1) if event_time_names_without_ref1 >= 0
							gen temp_order = _n if !missing(event_time_names_without_ref1)
							sum temp_order if time_after_ref_event_time == event_time_names_without_ref1
							local time_after_ref_event_time = r(mean)
							
							sum temp_order
							local max_pos = r(max)
						restore
						*di `time_after_ref_event_time'
						*di `max_pos'
						capture drop event_time_names_wo_ref_capped1		
						

						// Add row where reference group should be
						mat ppmle_results = ppmle_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ ppmle_results[`time_after_ref_event_time'..`max_pos',.]
						mat list ppmle_results
										
					
						// Clean up. 
						capture drop event_time_bacon
						capture drop _T*
						capture drop event_time_names_without_ref1
						
			
		clear
		tempfile ppmle_results
		svmat ppmle_results
		rename ppmle_results1 order
		rename ppmle_results2 b
		rename ppmle_results3 ll
		rename ppmle_results4 ul
		gen method = "ppmle"

		save "`ppmle_results'"
		


		replace b = 0 if missing(b) & order == -1

		////////////////////////////////////////////////////////////////////////////////
		// Figure 
		gen new_id = 0 
		replace new_id = 1 if method == "ppmle"
	
		gen modified_event_time = order 
		 
		keep if order >= `gphMin'
		keep if order <= `gphMax'
		sort modified_event_time
		order modified_event_time
		
		local mn = `gphMin' -  1
		local mx = `gphMax' + 1
		local low_event_cap_graph `mn'
		local high_event_cap_graph `mx'

		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'
		keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

		// Plot estimates - For slides without title
		twoway ///
			|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
			|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
			|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
			|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			|| pcarrowi 10 5.25 1 5.05 (0) , mcolor(black) lcolor(black) ///
			|| pcarrowi 12 -.45 6 -.75 (0) , mcolor(black) lcolor(black) ///
				text(20 5.25 "Appropriation five", place(0)) ///
				text(16 5.25 "years before", place(0)) ///
				text(12 5.25 "birth", place(0)) ///
				text(23 -.5 "Appropriation", place(0)) ///
				text(19 -.5 "in first year", place(0)) ///
				text(15 -.5 "of life", place(0)) ///
				xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
						, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(, labsize(5)) ///
				xtitle("Years since first capital appropriation from Duke Endowment relative to birth year", size(4) height(7)) ///
				xsize(8) ///
				legend(off) ///
			    xline(.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			 subtitle("Effect of duke appropriation on Pooled long-run mortality by year" " ", size(5) pos(11)) 
			 
			graph export "$PROJ_PATH/analysis/output/appendix/figure_F5_balanced_event_study.pdf", replace 

