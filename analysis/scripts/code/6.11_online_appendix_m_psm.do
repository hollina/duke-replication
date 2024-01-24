version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_psm.do
* PURPOSE: Run analysis for Appendix M - Propensity score matching: Alternative control group and falsification test
************/

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _) drop(*)"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"
local baseline_controls_int "c.percent_illit##i.race c.percent_black##i.race c.percent_other_race##i.race c.percent_urban##i.race c.retail_sales_per_capita##i.race c.chd_presence##i.race"	

// Panel start and end dates
local year_start 	1922
local year_end 		1940

// Duke treatment variable 
local treat 		"capp_all"

// List of Southern states 
global southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

// Set seed for reproducability
set seed 12345

// Set of variables used in propensity score match
local psm_controls pct_not_in_1930_u_1_b pct_not_in_1930_1_5_b pct_not_in_1930_u_1_w /// 
		 pct_not_in_1930_1_5_w ///
		 prop_beds non_prop_beds any_non_profit has_beds ///
		 chd_presence ///
		 percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita ///
		 pop_total		 

// Which range of propensity scores are we considering
local top_trim_list 900 750 500  

///////////////////////////////////////////////////////////////////////////////
// Determine share of counties treated by year 

// Duke treatment variable - Get duke ever treated
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

gen ones = 1
collapse (sum) ones, by(time_treated)
drop if missing(time_treated)

sort time_treated
gen rolling_sum = sum(ones)
sum ones 

gen share = rolling_sum/r(sum)

levelsof share
local share_list `r(levels)'

///////////////////////////////////////////////////////////////////////////////

// Get duke ever treated. 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

keep fips ever_treated
gduplicates drop 
gisid fips 

compress
tempfile duke_treat
save `duke_treat', replace 

///////////////////////////////////////////////////////////////////////////////
// Number and type of hospital beds

use "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta", clear

// Restrict to Southern states 
rename StateFIPS statefip 
keep if $southern_states

// Drop South Carolina 
drop if statefip == 45

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
replace county_nhgis = "SURRY" if county_nhgis == "SURREY" & state == "NORTH CAROLINA"

fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose assert(2 3) keep(3) keepusing(fips)

// Create an inidicator for each hospital with non-zero beds  
gen has_beds = 0 
replace has_beds = 1 if beds > 0 & !missing(beds)

gen prop_beds = 0 
replace prop_beds = proprietary*beds
gen non_prop_beds = 0 
replace non_prop_beds = (1-proprietary)*beds

// Collapse to create # of hospitals in each county-year (including non non-profit count)
gcollapse (sum) has_beds proprietary beds prop_beds non_prop_beds, by(fips year)

// Make indicator for any non-profit bed in county year
gen any_non_profit = 0
replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds
bysort fips: egen ever_non_profit = max(any_non_profit) // XXX Why is this defined over 1925 to 1942? Don't we want baseline characteristics here for psm?

keep if year == 1927
drop year

// Save
compress
tempfile hosp_beds
save `hosp_beds', replace

///////////////////////////////////////////////////////////////////////////////
// County health departments
use "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", clear 
keep if year == 1925
drop year

// drop SC 
drop if statefip == 45

// Save
compress
tempfile chd
save `chd', replace

///////////////////////////////////////////////////////////////////////////////
// Census characteristics
use  "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", clear
keep if year == 1920

// drop SC 
drop if statefip == 45

// Save
compress
tempfile census
save `census', replace
		
///////////////////////////////////////////////////////////////////////////////
// Uniform measure of infant/child mortality
	
// Loop over each range
foreach top_trim in `top_trim_list' {
	
	// Find analogous "bottom" part of the distribution
	local bottom_trim = 1000 - `top_trim'

	use "$PROJ_PATH/analysis/processed/data/ipums/childhood_survival.dta", clear 

	// drop SC 
	drop if statefip == 45

	merge 1:1 fips using `hosp_beds', nogen 
	merge 1:1 fips using `chd', assert(2 3) nogen
	merge 1:1 fips using `census', assert(1 3) keep(3) nogen
	merge 1:1 fips using `duke_treat', assert(1 3) nogen

	replace has_beds = 0 if missing(has_beds)
	replace proprietary = 0 if missing(proprietary)
	replace prop_beds = 0 if missing(prop_beds)
	replace non_prop_beds = 0 if missing(non_prop_beds)
	replace any_non_profit = 0 if missing(any_non_profit)
	replace beds = 0 if missing(beds)
	replace ever_non_profit = 0 if missing(ever_non_profit)

	ds pct* n_*
	foreach var in `r(varlist)' {
		replace `var' = 0 if missing(`var')
	}
	replace chd_presence = 0 if missing(chd_presence)

	replace ever_treated = 0 if missing(ever_treated)	
		
	// Make indicator for "control" counties in N.C.
	gen drop = 0 
	replace drop = 1 if statefip == 37 & ever_treated == 0

	gen drop_include_no_np = 0 
	replace drop_include_no_np = 1 if drop == 1
	replace drop_include_no_np = 1 if statefip != 37 & ever_non_profit == 0

	///////////////////////////////////////////////////////////////////////////////
	// Simple logit
	// Create ATTxPop weights
	
		// Pooled
		logit ever_treated ///
				 `psm_controls' [pw = n_1920_u_1] if statefip == 37
				
			predict p_hat
			
		_pctile p_hat, nq(1000)
		gen out_of_state_fake_treat = .
		replace out_of_state_fake_treat = 1 if p_hat >= r(r`top_trim') & statefip != 37
		replace out_of_state_fake_treat = 0 if p_hat < r(r`bottom_trim') & statefip != 37
		drop if missing(out_of_state_fake_treat)
		
	keep fips out_of_state_fake_treat
	compress
	save "$PROJ_PATH/analysis/processed/temp/fake_treat.dta", replace 

	*********************************************************************
	// Set up infant mortality analysis
	*********************************************************************
	
	use "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta", clear
	assert !missing(statefip)
	keep if $southern_states

	// Drop SC or NC
	drop if statefip == 45 | statefip == 37
		
	//  Make indicatory for "control" counties in N.C.
	gen ever_treated = 0
	gen drop = 0 
	replace drop = 1 if statefip == 37 & ever_treated == 0

	gen drop_include_no_np = 0 
	replace drop_include_no_np = 1 if drop == 1
	replace drop_include_no_np = 1 if statefip != 37  & ever_non_profit == 0

	fmerge m:1 fips using "$PROJ_PATH/analysis/processed/temp/fake_treat.dta", keep(3) nogen


	// Fake treatment drawing with replacement from actual treatment years. 
		* Define your macros with the elements and their probabilities
	gen random_draw = runiform()


	// Simple fake treatment
	bysort fips: egen max_random_draw2 = max(random_draw)
	gen treatment_begins = 0
	replace treatment_begins = 1 if max_random_draw2 == random_draw
	bysort fips: gen fake_treatment = sum(treatment_begins)
	replace fake_treatment = 1 if fake_treatment > 1 & !missing(fake_treatment)
	replace fake_treatment = 0 if out_of_state_fake_treat == 0
	

	// Create fake treatment with same roll out as main treatment 
	bysort fips: replace random_draw = random_draw[1]
	replace random_draw = . if out_of_state_fake_treat == 0
	gen fake_year_treated = .

	// Assign year of treatment using share of actually treated counties in each year
	local y = 1927
	foreach x in `share_list' {
		replace fake_year_treated = `y' if random_draw <= `x' & out_of_state_fake_treat == 1 & missing(fake_year_treated)

		local y = `y' + 1
	}
	gen fake_treatment2 = .
	replace fake_treatment2 = 0 if !missing(out_of_state_fake_treat)
	replace fake_treatment2 = 1 if out_of_state_fake_treat == 1 & year >= fake_year_treated & !missing(fake_year_treated)

	save "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes_psm.dta", replace
	
	if `top_trim' == 900 {
		local column_n = 1
		local column_n2 = 2
	} 
	if `top_trim' == 750 {
		local column_n = 3
		local column_n2 = 4
	} 
	if `top_trim' == 500 {
		local column_n = 5
		local column_n2 = 6
	} 
	
	imppml_pvalue_no_int, y_stub(imr_) suffix(pub) t(fake_treatment) controls(`baseline_controls') wgt(births) a(fips year) column(`column_n') pooled  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_psm_") 
	imppml_pvalue_no_int, y_stub(imr_) suffix(pub) t(fake_treatment2) controls(`baseline_controls') wgt(births) a(fips year) column(`column_n2') pooled  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_psm_") 

	imppml_pvalue_no_int, y_stub(imr_) suffix(pub) t(fake_treatment) wgt(births) controls(`baseline_controls') a(fips year) column(`column_n')  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_psm_") 
	imppml_pvalue_no_int, y_stub(imr_) suffix(pub) t(fake_treatment2) wgt(births) controls(`baseline_controls') a(fips year) column(`column_n2')  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_psm_") 
	


	// Infant mortality rate by year and race
	local race_group pooled white black

	foreach race in `race_group' {
		if "`race'" == "pooled" {
			local race_ind ""
		}
		if "`race'" == "white" {
			local race_ind "_wt"
		}
		if "`race'" == "black" {
			local race_ind "_bk"
		}
			
		use "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes_psm.dta", clear
		
		// Drop untreated NC counties
		keep if drop == 0 
		
		// Generate infant mortality outcomes + generate weights 
		gcollapse (mean) imr_pub`race_ind' [aweight = births_pub`race_ind'], by(year out_of_state_fake_treat) 
		tempfile dta`race_ind'
		save  `dta`race_ind''
			
	}

	use `dta', clear 
	merge 1:1 year out_of_state_fake_treat using `dta_bk', assert(3) nogen
	merge 1:1 year out_of_state_fake_treat using `dta_wt', assert(3) nogen
	 
	*********************************************************************************
	// Appendix Figure M1: Compare infant mortality in non-Carolina counties 	*****
	//	that look the most like treated NC counties to infant mortality in 		*****
	//	non-Carolina counties that look the least like like treated NC counties *****
	*********************************************************************************
	
	
	// Infant mortality rate by year and race - Full figure
	local fig_width 7

	if `bottom_trim' == 100 {
		local percent_label "10%"
		local panel "a"
	}
	if `bottom_trim' == 250 {
		local percent_label "25%"
		local panel "b"
	}
	if `bottom_trim' == 500 {
		local percent_label "50%"
		local panel "c"
	}
	// Compare non-Carolina counties that look the most like treated NC counties to those that look the least like like treated NC counties propensity score match to treated NC counties
	
	// For plot, only show balanced years
	keep if year >= 1930
	
	* Pooled
	twoway connected imr_pub year if out_of_state_fake_treat == 0, lw(1.5) lcolor("black") lp(longdash) msymbol(none)  ///
		|| connected imr_pub year if out_of_state_fake_treat == 1,  lw(1.5) lcolor("orange") lp(shortdash)  msymbol(none) ///
					xlab(1930(2)1940, nogrid valuelabel labsize(7) angle(0)) ///
					ylab(0(50)200, nogrid labsize(7) angle(0) format(%3.0f)) ///
					xtitle("Year", size(7) height(7)) ///
					ytitle("") ///
					subtitle("Pooled infant mortality rate per 1,000 live births", size(5) pos(11)) ///
					xsize(`fig_width') ///
					legend(pos(5) col(2) ring(0) label(1 "Bottom `percent_label'") label(2 "Top  `percent_label'") size(7)) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
					title("{bf:Comapre top `percent_label' to bottom `percent_label' }", size(6) pos(11))
					
	graph export "$PROJ_PATH/analysis/output/appendix/figure_m1`panel'1_psm_top`bottom_trim'pct_fake_treat_clean_cntrls_pooled_imr_by_treatment_over_time.pdf",  replace

	
	* Black 
	twoway connected imr_pub_bk year if out_of_state_fake_treat == 0, lw(1.5) lcolor("black") lp(longdash) msymbol(none)  ///
		|| connected imr_pub_bk year if out_of_state_fake_treat == 1,  lw(1.5) lcolor("orange") lp(shortdash)  msymbol(none) ///
					xlab(1930(2)1940, nogrid valuelabel labsize(6) angle(0)) ///
					ylab(0(50)200, nogrid labsize(5) angle(0) format(%3.0f)) ///
					xtitle("Year", size(7) height(7)) ///
					ytitle("") ///
					subtitle("Black infant mortality rate per 1,000 live births", size(5) pos(11)) ///
					xsize(`fig_width') ///
					legend(pos(5) col(2) ring(0) label(1 "Bottom `percent_label'") label(2 "Top  `percent_label'") size(6)) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
			
	graph export "$PROJ_PATH/analysis/output/appendix/figure_m1`panel'2_psm_top`bottom_trim'pct_fake_treat_clean_cntrls_black_imr_by_treatment_over_time.pdf", replace

	
	* White 
	twoway connected imr_pub_wt year if out_of_state_fake_treat == 0, lw(1.5) lcolor("black") lp(longdash) msymbol(none)  ///
		|| connected imr_pub_wt year if out_of_state_fake_treat == 1,  lw(1.5) lcolor("orange") lp(shortdash)  msymbol(none) ///
					xlab(1930(2)1940, nogrid valuelabel labsize(7) angle(0)) ///
					ylab(0(50)200, nogrid labsize(7) angle(0) format(%3.0f)) ///
					xtitle("Year", size(7) height(7)) ///
					ytitle("") ///
					subtitle("White infant mortality rate per 1,000 live births", size(5) pos(11)) ///
					xsize(`fig_width') ///
					legend(pos(5) col(2) ring(0) label(1 "Bottom `percent_label'") label(2 "Top  `percent_label'") size(7)) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 

	graph export "$PROJ_PATH/analysis/output/appendix/figure_m1`panel'3_psm_top`bottom_trim'pct_fake_treat_clean_cntrls_white_imr_by_treatment_over_time.pdf", replace

}

*********************************************************************************
// Appendix Table M1: Compare infant mortality in non-Carolina counties 	*****
//	that look the most like treated NC counties to infant mortality in 		*****
//	non-Carolina counties that look the least like like treated NC counties *****
*********************************************************************************

clear 

// Load short-run estimates
forvalues i = 1(1)3 {
	forvalues j = 1(1)6 {
		est use "$PROJ_PATH/analysis/processed/temp/cc_sr_psm_p`i'_c`j'"
		eststo  cc_sr_psm_p`i'_c`j'
	}
}

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

local y_1 "10\%"
local y_2 "25\%"
local y_2 "50\%"

// Make top panel - Pooled
#delimit ;
esttab cc_sr_psm_p1_c1 cc_sr_psm_p1_c2 cc_sr_psm_p1_c3 cc_sr_psm_p1_c4 cc_sr_psm_p1_c5 cc_sr_psm_p1_c6
 using "$PROJ_PATH/analysis/output/appendix/table_m1_imr_poisson_clean_cntrls_psm.tex", `booktabs_default_options' replace 
  mgroups("Top 10\% vs bottom 10\%" "Top 25\% vs bottom 25\%" "Top 50\% vs bottom 50\%", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab cc_sr_psm_p2_c1 cc_sr_psm_p2_c2 cc_sr_psm_p2_c3 cc_sr_psm_p2_c4 cc_sr_psm_p2_c5 cc_sr_psm_p2_c6
 using "$PROJ_PATH/analysis/output/appendix/table_m1_imr_poisson_clean_cntrls_psm.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab cc_sr_psm_p3_c1 cc_sr_psm_p3_c2 cc_sr_psm_p3_c3 cc_sr_psm_p3_c4 cc_sr_psm_p3_c5 cc_sr_psm_p3_c6
 using "$PROJ_PATH/analysis/output/appendix/table_m1_imr_poisson_clean_cntrls_psm.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule 
	County of birth FE 						 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\ 
	Year of birth FE 			 			 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\   
	Weights 								 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls								 & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}  \\
	Exclude NC 					 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\
	Pseudo-treatment begins in random year 				 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  \\
	Pseudo-treatment begins in years that match actual roll-out					 & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  \\");
#delimit cr

//  Clean up
erase "$PROJ_PATH/analysis/processed/temp/clean_control_outcomes_psm.dta"

// Remove temp files
forvalues i = 1(1)3 {
	forvalues j = 1(1)6 {
		rm "$PROJ_PATH/analysis/processed/temp/cc_sr_psm_p`i'_c`j'.ster"
	}
}

rm "$PROJ_PATH/analysis/processed/temp/fake_treat.dta"




*****************************************************************************
* Now only keep those control counties that look like Duke counties based on PSM
******************************************************************************

* User switches

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _) drop(*)"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"
local baseline_controls_int "c.percent_illit##i.race c.percent_black##i.race c.percent_other_race##i.race c.percent_urban##i.race c.retail_sales_per_capita##i.race  c.chd_presence##i.race"	

// Duke treatment variable 
local treat 		"capp_all"
local treat_type	"all"

// Panel start and end dates
local year_start 	1922
local year_end 		1940

global southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

// Set seed for reproducability
set seed 12345

// Set of variables used in propensity score match
local psm_controls pct_not_in_1930_u_1_b pct_not_in_1930_1_5_b pct_not_in_1930_u_1_w /// 
		 pct_not_in_1930_1_5_w ///
		 prop_beds non_prop_beds any_non_profit has_beds ///
		 chd_presence ///
		 percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita ///
		 pop_total		 

// Which range of propensity scores are we considering
local top_trim_list 900 750 500  

///////////////////////////////////////////////////////////////////////////////

// Get duke ever treated. 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

*di "Cumulative frequencies: `cum_prob_list'" // XXX Local not defined

keep fips ever_treated
gduplicates drop 
gisid fips 

compress
tempfile duke_treat
save `duke_treat', replace 



///////////////////////////////////////////////////////////////////////////////
// Number and type of hospital beds

use "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta", clear

// Restrict to Southern states 
rename StateFIPS statefip 
keep if $southern_states

// Drop South Carolina 
drop if statefip == 45

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
replace county_nhgis = "SURRY" if county_nhgis == "SURREY" & state == "NORTH CAROLINA"

fmerge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta", verbose assert(2 3) keep(3) keepusing(fips)

// Create an inidicator for each hospital with non-zero beds  
gen has_beds = 0 
replace has_beds = 1 if beds > 0 & !missing(beds)

gen prop_beds = 0 
replace prop_beds = proprietary*beds
gen non_prop_beds = 0 
replace non_prop_beds = (1-proprietary)*beds

// Collapse to create # of hospitals in each county-year (including non non-profit count)
gcollapse (sum) has_beds proprietary beds prop_beds non_prop_beds, by(fips year)

// Make indicator for any non-profit bed in county year
gen any_non_profit = 0
replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds
bysort fips: egen ever_non_profit = max(any_non_profit) // XXX Why is this defined over 1925 to 1942? Don't we want baseline characteristics here for psm?

keep if year == 1927
drop year

// Save
compress
tempfile hosp_beds
save `hosp_beds', replace

///////////////////////////////////////////////////////////////////////////////
// County health departments
use "$PROJ_PATH/analysis/processed/data/chd/chd_operation_dates_panel.dta", clear 
keep if year == 1925
drop year

// drop SC 
drop if statefip == 45

// Save
compress
tempfile chd
save `chd', replace

///////////////////////////////////////////////////////////////////////////////
// Census characteristics
use  "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", clear
keep if year == 1920

// drop SC 
drop if statefip == 45

// Save
compress
tempfile census
save `census', replace
		
///////////////////////////////////////////////////////////////////////////////
// Uniform measure of infant/child mortality
	
// Loop over each range
foreach top_trim in `top_trim_list' {
    *local top_trim 500
	// Find analogous "bottom" part of the distribution
	local bottom_trim = 1000 - `top_trim'

	use "$PROJ_PATH/analysis/processed/data/ipums/childhood_survival.dta", clear 

	// drop SC 
	drop if statefip == 45

	merge 1:1 fips using `hosp_beds', nogen // XXX Shouldn't we drop _merge == 2? No child mortality data 
	merge 1:1 fips using `chd', assert(2 3) nogen
	merge 1:1 fips using `census', assert(1 3) keep(3) nogen
	merge 1:1 fips using `duke_treat', assert(1 3) nogen

	replace has_beds = 0 if missing(has_beds)
	replace proprietary = 0 if missing(proprietary)
	replace prop_beds = 0 if missing(prop_beds)
	replace non_prop_beds = 0 if missing(non_prop_beds)
	replace any_non_profit = 0 if missing(any_non_profit)
	replace beds = 0 if missing(beds)
	replace ever_non_profit = 0 if missing(ever_non_profit)

	ds pct* n_*
	foreach var in `r(varlist)' {
		replace `var' = 0 if missing(`var')
	}
	replace chd_presence = 0 if missing(chd_presence)

	replace ever_treated = 0 if missing(ever_treated)	
		
	//  Make indicatory for "control" counties in N.C.
	gen drop = 0 
	replace drop = 1 if statefip == 37 & ever_treated == 0

	gen drop_include_no_np = 0 
	replace drop_include_no_np = 1 if drop == 1
	replace drop_include_no_np = 1 if statefip != 37 & ever_non_profit == 0

	///////////////////////////////////////////////////////////////////////////////
	// Simple logit
	// Create ATTxPop weights
		// Pooled
		logit ever_treated ///
				 `psm_controls' [pw = n_1920_u_1] if statefip == 37
				
			predict p_hat
			
		_pctile p_hat, nq(1000)
		gen out_of_state_fake_treat = .
		replace out_of_state_fake_treat = 1 if p_hat >= r(r`top_trim') & statefip != 37
		replace out_of_state_fake_treat = 0 if p_hat < r(r`bottom_trim') & statefip != 37
		drop if missing(out_of_state_fake_treat)
		keep if out_of_state_fake_treat == 1
	keep fips out_of_state_fake_treat
	compress
	save "$PROJ_PATH/analysis/processed/temp/fake_treat_`top_trim'.dta", replace 

}
// Short run
foreach top_trim in `top_trim_list' {
	local bottom_trim = 1000 - `top_trim'

    ******************************************************************************
    // Robustness to using non-North Carolina counties as untreated controls *****
    ******************************************************************************

    // Short-run: Set up infant mortality analysis 
    use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

    // Generate DiD treatment variable
    duketreat, treatvar(`treat') time(year) location(fips)

    // Generate infant mortality outcomes + generate weights 
    imdata, mort(mort) suffix(pub)
    replace mort = . if births_pub == 0

    // Append southern states 
    append using "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta"
    merge m:1 fips using "$PROJ_PATH/analysis/processed/temp/fake_treat_`top_trim'.dta", keep(1 3) nogen
    keep if statefip == 37 | out_of_state_fake_treat == 1

    // Restrict to IV years 
    keep if year >= `year_start' & year <= 1940

    //  Make indicator for "control" counties in N.C.
    gen drop = 0 
    replace drop = 1 if statefip == 37 & ever_treated == 0

    gen drop_inculde_no_np = 0 
    replace drop_inculde_no_np = 1 if drop == 1
    replace drop_inculde_no_np = 1 if statefip != 37  & ever_non_profit == 0

    // Panel A - Pooled

    // Column 1 - Poisson IMR - + additional control counties
    imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls')  wgt(births) a(fips year) column(1) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 

    // Column 2 - Poisson IMR - drop NC 
    imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls') restrict("drop == 0") wgt(births) a(fips year) column(2) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 
                
    // Column 3 - Poisson IMR - drop NC and counties without NP hosp - weights
    imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls') restrict("drop_inculde_no_np == 0") wgt(births) a(fips year) column(3) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 
                


    // Panels B to D - By Race and Fully Interacted

    // Flag counties with black or white births ever equal to zero
    egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

    // Column 1 - Poisson IMR - + additional control counties
    imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births)  controls(`baseline_controls') restrict("ever_zero_births == 0") a(fips year) column(1)  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 

    // Column 2 - Poisson IMR - drop NC 
    imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births)  controls(`baseline_controls') restrict("ever_zero_births == 0 & drop == 0") a(fips year) column(2) save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 

    // Column 3 - Poisson IMR - drop NC and counties without NP hosp - weights
    imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births) controls(`baseline_controls')  restrict("ever_zero_births == 0 & drop_inculde_no_np == 0") a(fips year) column(3) save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("psm_`top_trim'_cc_sr_") 
    

}

clear 
// Long Run
local top_trim_list 900 750 500  

foreach top_trim in `top_trim_list' {
	if `top_trim' == 900 {
		local table_num 2
	}
	if `top_trim' == 750 {
		local table_num 3
	}
	if `top_trim' == 500 {
		local table_num 4
	}
   * local top_trim 900
   
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
	local bottom_trim = 1000 - `top_trim'

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

    merge m:1 fips using "$PROJ_PATH/analysis/processed/temp/fake_treat_`top_trim'.dta", keep(1 3) nogen
    keep if str_st_fips == 37 | out_of_state_fake_treat == 1
    
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

    merge m:1 fips using "$PROJ_PATH/analysis/processed/temp/fake_treat_`top_trim'.dta", keep(1 3) nogen
    keep if str_st_fips == 37 | out_of_state_fake_treat == 1
    
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
            est use "$PROJ_PATH/analysis/processed/temp/psm_`top_trim'_cc_sr_p`i'_c`j'"
            eststo  cc_sr_p`i'_c`j'
        }
    }

    if `bottom_trim' == 100 {
		local percent_label "10\%"
	}
	if `bottom_trim' == 250 {
		local percent_label "25\%"
	}
	if `bottom_trim' == 500 {
		local percent_label "50\%"
	}

    // Prepare table
    local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

    local y_1 "\$Y^{R}_{ct} = \text{Infant mortality rate}$"
    local y_2 "\$Y^{R}_{ct} = \text{Long-run deaths}$"
    local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

    // Make top panel - Pooled
    #delimit ;
    esttab cc_sr_p1_c1 cc_sr_p1_c2 cc_sr_p1_c3 p1_c1 p1_c2 p1_c3
    using "$PROJ_PATH/analysis/output/appendix/table_m`table_num'_combined_mortality_poisson_clean_controls_psm_`top_trim'.tex", `booktabs_default_options' replace 
    mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    posthead("`numbers_main'")
    stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
    #delimit cr

    // Make 2nd panel - Black
    #delimit ;
    esttab  cc_sr_p2_c1 cc_sr_p2_c2 cc_sr_p2_c3 p2_c1 p2_c2 p2_c3
    using "$PROJ_PATH/analysis/output/appendix/table_m`table_num'_combined_mortality_poisson_clean_controls_psm_`top_trim'.tex", `booktabs_default_options' append
    stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
    #delimit cr

    // Make 3rd panel - White
    #delimit ;
    esttab cc_sr_p3_c1 cc_sr_p3_c2 cc_sr_p3_c3 p3_c1 p3_c2 p3_c3
    using "$PROJ_PATH/analysis/output/appendix/table_m`table_num'_combined_mortality_poisson_clean_controls_psm_`top_trim'.tex", `booktabs_default_options' append
    stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
    #delimit cr

    // Make bottom panel - Fully interacted
    #delimit ;
    esttab cc_sr_p4_c1 cc_sr_p4_c2 cc_sr_p4_c3 p4_c1 p4_c2 p4_c3
    using "$PROJ_PATH/analysis/output/appendix/table_m`table_num'_combined_mortality_poisson_clean_controls_psm_`top_trim'.tex", `booktabs_default_options' append
    stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
    postfoot("\midrule 
        County of birth FE 				 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\ 
        County of birth X Age  FE 				 & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
        Year of birth   FE 			 	 & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\   
        Year of birth  X Age FE 			 	  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\   
        Weights 								 & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
        Controls								 & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes}   & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} \\
        Exclude untreated NC 					&\multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  &\multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
        Exclude without non-profit hosp.		& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} \\
        PSM percentile cutoff for including other southern counties		& \multicolumn{1}{c}{`percent_label'}  & \multicolumn{1}{c}{`percent_label'} & \multicolumn{1}{c}{`percent_label'}  & \multicolumn{1}{c}{`percent_label'}  & \multicolumn{1}{c}{`percent_label'} & \multicolumn{1}{c}{`percent_label'} \\");
    #delimit cr


}
// Move this to psm
local top_trim_list 900 750 500  
foreach top_trim in `top_trim_list' {
	cap rm "$PROJ_PATH/analysis/processed/temp/fake_treat_`top_trim'.dta"
}

* EOF 
