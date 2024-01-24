version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_non_nc.do
* PURPOSE: Run analysis for Appendix J - Instrumental variables, Alternate samples and non-Carolina control counties
************/

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
local year_end 		1942

// Event study endpoints
local graphMax 6
local graphMin -6

global southern_states 	"inlist(statefip, 1, 5, 12, 13, 21, 22, 28, 37, 47, 48, 51, 54)"

***************************************************************************************************
// Specification chart: Robustness to using non-North Carolina counties as untreated controls *****
***************************************************************************************************

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

// Panel A - Pooled

// Column 1 - Poisson IMR - + additional control counties
imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls')  wgt(births) a(fips year) column(1) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add southern counties")

// Column 2 - Poisson IMR - drop NC 
imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls') restrict("drop == 0") wgt(births) a(fips year) column(2) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add S. counties + drop untreated NC")

// Column 3 - Poisson IMR - drop NC and counties without NP hosp - weights
imppml, y_stub(imr_) suffix(pub) t(treated)  controls(`baseline_controls') restrict("drop_inculde_no_np == 0") wgt(births) a(fips year) column(3) pooled save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add S. counties w/hosp + drop untreat")



// Panels B to D - By Race and Fully Interacted

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

// Column 1 - Poisson IMR - + additional control counties
imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births)  controls(`baseline_controls') restrict("ever_zero_births == 0") a(fips year) column(1)  save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add southern counties")

// Column 2 - Poisson IMR - drop NC 
imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births)  controls(`baseline_controls') restrict("ever_zero_births == 0 & drop == 0") a(fips year) column(2) save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add S. counties + drop untreated NC")


// Column 3 - Poisson IMR - drop NC and counties without NP hosp - weights
imppml, y_stub(imr_) suffix(pub) t(treated) wgt(births) controls(`baseline_controls')  restrict("ever_zero_births == 0 & drop_inculde_no_np == 0") a(fips year) column(3) save_path("$PROJ_PATH/analysis/processed/temp") save_prefix("cc_sr_") ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, clean control, Add S. counties w/hosp + drop untreat")
			

*********************************************************************************************************************
// Figure J1 - Figure J1. Infant mortality by year: Ever-treated NC vs. other Duke-ineligible Southern counties *****
*********************************************************************************************************************

local year_start 	1922 
local year_end 		1942
local treat 		"capp_all"

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

ppmlhdfe imr_pub b0.treated  [pw = births_pub], ///
	absorb(fips year) vce(cluster fips)  
	
gen ever_non_profit = 0 
replace ever_non_profit = 1 if ever_treated == 1

// Append southern states
append using "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta"
drop if year == 1921

//  Make indicatory for "control" counties in N.C.
gen drop = 0 
replace drop = 1 if statefip == 37 & ever_treated == 0

gen drop_include_no_np = 0 
replace drop_include_no_np = 1 if drop == 1
replace drop_include_no_np = 1 if statefip != 37  & ever_non_profit == 0

gen bw_imr_gap = (imr_pub_bk-imr_pub_wt)

gen group = . 
replace group = 1 if ever_treated == 1
replace group = 2 if ever_treated == 0 & statefip == 37
replace group = 3 if statefip != 37 
tab statefip 

drop if year > 1940
tab statefip 

preserve

	collapse (mean) imr_pub_bk [aw = births_pub_bk], by(year group) 
	keep if year >= 1925 & year <= 1940
	
	twoway ///
		|| connected imr_pub_bk year if group == 1, msymbol(none) lw(1.0) col("230 65 115") msymbol(none) lp(solid)  ///
		|| connected imr_pub_bk year if group == 3, msymbol(none) lw(.5) col("black") msymbol(none) lp(dashed) ///
			legend(off) ///
			xtitle("Year", size(5) height(7)) ///
			ytitle("", size(5)) ///
			subtitle("Black infant mortality rate, treated NC vs non-NC", size(5) pos(11)) ///
			xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			xlab(1925(5)1940, nogrid valuelabel labsize(5) angle(0)) ///
					ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///
					xtitle("Year", size(5) height(7)) ///
					title("{bf:Black infant mortality by year comparing ever-treated NC}" "{bf:   to Duke-ineligible other southern counties}", size(6) pos(11)) ///
									subtitle("Infant deaths per 1,000 live births", size(5) pos(11)) ///
					text(95 1930 "Ever-treated (in NC)", size(large)) ///
					text(130 1936.2 "Other southern counties", size(large)) ///
					text(123 1936.2 "ineligible for Duke funding", size(large)) 
					
	*graph export "$PROJ_PATH/analysis/output/appendix/figure_j1a_imr_treated_vs_southern_bk.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_j1a_imr_treated_vs_southern_bk.pdf", replace

restore


preserve

	collapse (mean) imr_pub_wt [aw = births_pub_wt], by(year group) 
	keep if year >= 1925 & year <= 1940

	twoway ///
		|| connected imr_pub_wt year if group == 1, msymbol(none) lw(1.0) col("230 65 115") msymbol(none) lp(solid)  ///
		|| connected imr_pub_wt year if group == 3, msymbol(none) lw(.5) col("black") msymbol(none) lp(dashed) ///
			legend(off) ///
			xtitle("Year", size(5) height(7)) ///
			ytitle("", size(5)) ///
			subtitle("White infant mortality rate, treated NC vs non-NC", size(5) pos(11)) ///
			xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			xlab(1925(5)1940, nogrid valuelabel labsize(5) angle(0)) ///
					ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///
					xtitle("Year", size(5) height(7)) ///
					title("{bf:White infant mortality by year comparing ever-treated NC}" "{bf:   to Duke-ineligible other southern counties}", size(6) pos(11)) ///
									subtitle("Infant deaths per 1,000 live births", size(5) pos(11)) ///
					text(45 1933 "Ever-treated (in NC)", size(large)) ///
					text(79 1933.5 "Other southern counties", size(large)) ///
					text(76 1933.5 "ineligible for Duke funding", size(large)) 

	*graph export "$PROJ_PATH/analysis/output/appendix/figure_j1b_imr_treated_vs_southern_wt.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_j1b_imr_treated_vs_southern_wt.pdf", replace

restore

***********************************************************************************************************************
// Figure J2 - Event studies: Replacing untreated North Carolina counties with other ineligible Southern counties *****
***********************************************************************************************************************

local depvar_stub	imr_pub
local weight_stub	births_pub

foreach race in pooled black white {
			
	if "`race'" == "pooled" {
		local race_suf ""
		local panel "a"
	}	
	if "`race'" == "white" {
		local race_suf "_wt"
		local panel "b"
	}
	if "`race'" == "black" {
		local race_suf "_bk"
		local panel "c"
	}
	
	local depvar 	`depvar_stub'`race_suf'	
	local weightvar `weight_stub'`race_suf'

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
				
	local lbl: var label `depvar'
	di "`lbl'"

	// Drop counties ever with zero births by race
	egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
	
	if "`race'" == "white" | "`race'" == "black" {
		drop if ever_zero_births == 1
	}
	
	// Create separate version of treatment for Callaway-Sant'Anna with untreated coded to 0
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
		
	ppmlhdfe `depvar' b0.treated  [pw = `weightvar']  , ///
	absorb(fips year) vce(cluster fips)  
	
	ppmlhdfe `depvar' b0.treated  [pw = `weightvar']  if drop == 0, ///
	absorb(fips year) vce(cluster fips)  
	
	ppmlhdfe `depvar' b0.treated  [pw = `weightvar']  if drop_inculde_no_np == 0, ///
	absorb(fips year) vce(cluster fips)   
	

	// gen event-time (adoption_date = treatment adoption date)
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
			xlab(-6(1)6 ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%3.2f)) ///		
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(off) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/appendix/figure_j2`panel'_es_other_southern_states_imr_`race'.png", replace
		graph export "$PROJ_PATH/analysis/output/appendix/figure_j2`panel'_es_other_southern_states_imr_`race'.pdf", replace 
	
}

// Remove temp files
/* forvalues i = 1(1)4 {
	forvalues j = 1(1)3 {
		rm "$PROJ_PATH/analysis/processed/temp/cc_sr_p`i'_c`j'.ster"
	}
} */

disp "DateTime: $S_DATE $S_TIME"

* EOF
