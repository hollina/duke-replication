version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 5_figures.do
* PURPOSE: Run regressions for main figures
************/

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"

// Duke treatment variable 
local treat 		"capp_all"

// Panel start and end dates
local year_start 	1922
local year_end 		1942
	
************************************************************
***** Figure 1a: Fraction of counties supported by Duke ***** 
************************************************************

clear
local N = 1962 - 1920 + 1
set obs `N'

gen year = _n + 1919
assert year >= 1920 & year <= 1962

tempfile years
save `years', replace

use fips statefip using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_interpolated_pop_1900-1962.dta", clear

gduplicates drop
count if statefip == 37 
assert r(N) == 100

drop if missing(statefip)
cross using `years'

fmerge 1:1 fips year using "$PROJ_PATH/analysis/processed/data/duke/duke_county-year-panel_1925-1962.dta", ///
	keep(1 3) ///
	keepusing(`treat') /// 
	nogen 

xtset fips year
tab year

keep if statefip == 37 & year >= `year_start' & year <= `year_end'

// Generate variables for event study timing
duketreat, treatvar(`treat') time(year) location(fips) 

egen N_treated = total(treated), by(year)

keep year N_treated
duplicates drop

gen fraction_counties = N_treated/100

twoway connected fraction_counties year, lw(1.0) col("230 65 115") msymbol(none) lp(solid) /// 
		xlab(1922(5)1942, nogrid labsize(5) angle(0)) ///
		ylab(0(0.1)0.5, nogrid labs(5) angle(0) format(%03.1f)) ///
		legend(off) ///
		xtitle("Year", size(5) height(7)) ///
		ytitle("", size(5)) ///
		subtitle("Share of counties ever having received capital appropriation from Duke Endowment", size(4) pos(11)) ///
		xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
		
*graph export "$PROJ_PATH/analysis/output/main/figure_1a_share_counties_treated.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_1a_share_counties_treated.pdf",  replace


********************************************************************************************************
***** Figure 1c: Descriptive plot of infant mortality rates by year and race ****************************
********************************************************************************************************

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
		
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate infant mortality outcomes + generate weights 
	imdata, mort(mort) suffix(pub)

	collapse (mean) imr_pub`race_ind' [aweight = births_pub`race_ind'], by(year) 
	tempfile dta`race_ind'
	save  `dta`race_ind''
		
}

use `dta', clear 
merge 1:1 year using `dta_bk', assert(3) nogen
merge 1:1 year using `dta_wt', assert(3) nogen

// Infant mortality rate by year and race - Full figure
twoway connected imr_pub year, lw(.75) lcolor("black") lp(longdash) msymbol(none) ///
	|| connected imr_pub_wt year, lw(1) lcolor("black") lp(line) msymbol(none)   ///
	|| connected imr_pub_bk year,  lw(.75) lcolor(gs13) lp(shortdash)  msymbol(none)  ///
				xlab(1922(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xtitle("Year", size(5) height(7)) ///
				subtitle("Infant deaths per 1,000 live births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(8) ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(70 1936 "Black", size(large)) ///
				text(43 1933 "White", size(large)) ///
				text(77 1923 "Pooled", size(large)) 
				
*graph export "$PROJ_PATH/analysis/output/main/figure_1c_infant_morality_by_race_over_time.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_1c_infant_morality_by_race_over_time.pdf", replace


********************************************************************************************************
***** Figure 1b and 1d: Maps ***************************************************************************
********************************************************************************************************

// Maps
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate variables for event study timing and set up event study specification
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)

// Generate first treated year
egen first_year = min(time_treated), by(fips)

// Generate percent change in IMR
egen imr_`year_start' = max((year == `year_start')*imr_pub), by(fips)
egen imr_`year_end' = max((year == `year_end')*imr_pub), by(fips)

gen pct_change_imr = (imr_`year_end' - imr_`year_start')*100/imr_`year_start'

gen spending_pc = (tot_capp_all_adj*1000000)/pop_total 

keep statefip fips year percent_urban base_pneumonia_22to26 first_year pct_change_imr spending_pc

rename base_pneumonia_22to26 base_pneumonia

tab first_year, m
tab first_year

gen duke_cat = 0
replace duke_cat = 1 if first_year >= 1939 & first_year <= 1942
replace duke_cat = 2 if first_year >= 1934 & first_year <= 1938
replace duke_cat = 3 if first_year >= 1930 & first_year <= 1933
replace duke_cat = 4 if first_year >= 1929 & first_year <= 1929
replace duke_cat = 5 if first_year >= 1927 & first_year <= 1928

gen duke_cat_label = ""
replace duke_cat_label = "No Duke" if duke_cat == 0
replace duke_cat_label = "1939-1942" if duke_cat == 1
replace duke_cat_label = "1934-1938" if duke_cat == 2
replace duke_cat_label = "1930-1933" if duke_cat == 3
replace duke_cat_label = "1929" if duke_cat == 4
replace duke_cat_label = "1927-1928" if duke_cat == 5

save "$PROJ_PATH/analysis/processed/data/R/input/map_input.dta", replace

// Run code to create maps in R
cd "$PROJ_PATH"
shell $R_PATH --vanilla <"$PROJ_PATH/analysis/scripts/code/5_maps.R"	


**********************************************************************************************************************
***** Row 1 of Figures 2a, 2b, and 2c: Descriptive plot of hospital beds by year and ever treated status *************
**********************************************************************************************************************

local fig_width 	7
local weightvar  	births_pub

// Load county-level first-stage hospitals data 
use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

// Remove AHA label 
foreach var of varlist *aha* {
	local variable_label : variable label `var'
	local variable_label : subinstr local variable_label ", AHA" ""
	label variable `var' "`variable_label'"

	local variable_label : variable label `var'
	local variable_label : subinstr local variable_label " in county" ""
	label variable `var' "`variable_label'"
}
// Add Duke treatment 
duketreat, treatvar(`treat') time(year) location(fips)

keep i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc `weightvar' ever_treated year 

foreach v of var * {
	local l`v' : variable label `v'
	if `"`l`v''"' == "" {
		local l`v' "`v'"
	}
}

gcollapse (mean) i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc  [aw = `weightvar'], by(ever_treated year) 

 foreach v of var * {
	label var `v' `"`l`v''"'
 }						
  
foreach depvar in i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc { 

	local lbl: var label `depvar'
	di "`lbl'"

	if "`depvar'" == "i_tot_beds_aha_pc"  {
		local label_1 "90"
		local label_2 "80"
		
		local label_3 "40"
		local label_4 "30"
		
		local label_fmt "%3.0f"		
		
		local panel "a"
		local title "total_beds"

	}
	
	if  "`depvar'" == "i_likely_beds_aha_pc"  {
		local label_1 "73"
		local label_2 "63"
		
		local label_3 "33"
		local label_4 "23"
		
		local label_fmt "%3.0f"		
		
		local panel "b"
		local title "likely_beds"

	}
	
	if  "`depvar'" == "i_prop_beds_aha_pc"  {
		local label_1 "13.5"
		local label_2 "12.5"
		
		local label_3 "7.5"
		local label_4 "6.5"
		
		local label_fmt "%3.0f"		
		
		local panel "c"
		local title "private_beds"

	}		
	twoway ///
		|| connected `depvar' year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
		|| connected `depvar' year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
					xlab(1922(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
					xtitle("Year", size(5) height(7)) ///
					ytitle("") ///
					subtitle("`lbl'", size(5) pos(11)) ///
					xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
					xsize(`fig_width') ///
					legend(off) ///
					ylab(, nogrid labsize(5) angle(0) format(`label_fmt')) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)  ///
					text(`label_1' 1922 "Ever treated", size(large) placement(right)) text(`label_2' 1922 "by 1942", size(large) placement(right)) ///
					text(`label_3' 1922 "Never treated", size(large) placement(right)) text(`label_4' 1922 "up to 1942", size(large) placement(right))
		
	*graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'1_`title'_by_year.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'1_`title'_by_year.pdf", replace
	
}

*********************************************************************************************************************
***** Row 2 of Figures 2a, 2b, and 2c: Descriptive plot of hospital beds by event-time for ever treated *************
*********************************************************************************************************************

local fig_width		7
local gphMax		5
local weightvar		births_pub

// Load county-level first-stage hospitals data 
use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

// Remove , AHA label
foreach var of varlist *aha* {
	local variable_label : variable label `var'
	local variable_label : subinstr local variable_label ", AHA" ""
	label variable `var' "`variable_label'"

	local variable_label : variable label `var'
	local variable_label : subinstr local variable_label " in county" ""
	label variable `var' "`variable_label'"
}
// Add Duke treatment 
duketreat, treatvar(`treat') time(year) location(fips)
keep if ever_treated == 1

gen event_time = year - time_treated
bysort fips: egen min_event_time = min(event_time)
bysort fips: egen max_event_time = max(event_time)
	
foreach depvar in i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc { 
	gen temp_yb_size = `depvar' if event_time == -1 & !missing(event_time)
	bysort fips: egen yb_size = max(temp_yb_size)
	replace `depvar' = `depvar'/yb_size
	drop yb_size temp_yb_size
}

keep i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc `weightvar' event_time   

foreach v of var * {
	local l`v' : variable label `v'
	if `"`l`v''"' == "" {
		local l`v' "`v'"
	}
}

gcollapse (mean) i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc [aw = `weightvar'], by(event_time) 

foreach v of var * {
	label var `v' `"`l`v''"'
}
		
foreach depvar in i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc { 
	
	local lbl: var label `depvar'
	di "`lbl'"
	local labels "0(0.5)2"
	
	if "`depvar'" == "i_tot_beds_aha_pc" { // "`depvar'" == "i_tot_beds_aha" | 
		local labels ".5(0.25)1.25"
		local panel "a"
		local title "total_beds"
	}
	if "`depvar'" == "i_likely_beds_aha_pc" { 
		local panel "b"
		local title "likely_beds"
	}
	if "`depvar'" == "i_prop_beds_aha_pc" { 
		local panel "c"
		local title "private_beds"		
	}
	
	twoway ///
		|| connected `depvar' event_time if event_time <= -.5 & event_time >= -6 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
			|| lfit  `depvar' event_time if event_time <= -.5 & event_time >= -6 ,color(black) range(-6 6) lcolor("black") lp(dash) ///
		|| connected  `depvar' event_time if event_time >= -.5 & event_time <= 6, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
					xlab(-6(1)6, nogrid valuelabel labsize(5) angle(0)) ///
					xtitle("Years since capital appropriation", size(5) height(7)) ///
					ytitle("") ///
					subtitle("`lbl' relative to t=-1", size(5) pos(11)) ///
					xline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
					xsize(`fig_width') ///
					legend(off) ///
					ylab(`labels', nogrid labsize(5) angle(0) format(%3.2f)) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
		
	*graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'2_`title'_by_event_time.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'2_`title'_by_event_time.pdf", replace
	
}

************************************************************************************************
***** Row 3 of Figures 2a, 2b, and 2c: First-stage event studies for hospital beds *************
************************************************************************************************

local z = 1
local weightvar births_pub

foreach depvar in i_tot_beds_aha_pc i_likely_beds_aha_pc i_prop_beds_aha_pc { 
							
	// Load county-level first-stage hospitals data 
	use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear
	
	// Remove , AHA label
	foreach var of varlist *aha* {
		local variable_label : variable label `var'
		local variable_label : subinstr local variable_label ", AHA" ""
		label variable `var' "`variable_label'"

		local variable_label : variable label `var'
		local variable_label : subinstr local variable_label " in county" ""
		label variable `var' "`variable_label'"
	}

	local lbl: var label `depvar'
	di "`lbl'"
	
	// Add Duke treatment 
	duketreat, treatvar(`treat') time(year) location(fips)

	// Create separate version of treatment for Callaway-Sant'Anna with untreated coded to 0
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
		
	
	// TWFE OLS estimation
	
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
	
	reghdfe `depvar' ///
				_T* ///
				[aw = `weightvar'] ///
				, absorb(fips year) vce(cluster fips)	
				
	mat b = e(b)'
	mat list b 
	mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
	mat list b

	mata st_matrix("ll", (st_matrix("e(b)"))'- invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
	mat list ll
	mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
	mat list ll
	
	mata st_matrix("ul", (st_matrix("e(b)"))'+ invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
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
	mat twfe_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list twfe_results
								
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
	mat twfe_results = twfe_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ twfe_results[`time_after_ref_event_time'..`max_pos',.]
	mat list twfe_results
							
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1
				
	// csdid of Callaway and Sant'Anna

	*Estimation
	csdid `depvar' [iw = `weightvar'], ivar(fips) time(year) gvar(time_treated_2) agg(event)
	
	*Aggregation
	csdid_estat event
	
	* Store event-study info
	local evlist = subinstr("`:colname r(table)'","T","",.)
	local evlist = subinstr("`evlist'","m","-",.)
	local evlist = subinstr("`evlist'","p","+",.)
	 
	matrix mm = r(table)'
	matrix mm=mm[3...,....]
	
	tsvmat mm, name(cs_b cs_se cs_z cs_p cs_ll cs_ul)
	qui:gen cs_order =.
	local k = 0
	foreach i of local evlist {
		if !inlist("`i'","Pre_avg","Post_avg")  {
			local k = `k'+1
			qui:replace cs_order =`i' in `k'
		} 	
	}
	mkmat cs_order cs_b cs_se cs_z cs_p cs_ll cs_ul, matrix(cs_results) nomissing

	mat list cs_results

	// eTWFE - Column 2 - Beds - no controls - weights 
	jwdid `depvar' [pw = `weightvar'], ivar(fips) tvar(year) gvar(time_treated_2)  
	
	*Aggregation
	estat event 
	return list 
	 
	mat b =  r(table)'
	mat list b 
	 
	local coln:rowname b

	local coln= subinstr("`coln'","r2vs1._at@","",.)
	local coln= subinstr("`coln'","bn","",.)
	local coln= subinstr("`coln'",".__event__","",.)
	di "`coln'"
	
	foreach i of local coln {
		local ll:label (__event__) `i'
		local lcoln `lcoln' `ll'
	}
	di "`lcoln'"

	tsvmat b, name(etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul)
	qui: gen etwfe_order = .
	local k = 1
	foreach i of local lcoln {
		qui: replace etwfe_order =`i' in `k'
		local k = `k' + 1
		di "`i'"

	}
	
	mkmat etwfe_order etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul, matrix(etwfe_results) nomissing
			
	/////////////////////////////////////////////////////////////////////////////////
	// Balanced stacked 
			
	balanced_stacked, ///
		outcome(`depvar') ///
		treated(treated) ///
		timeTreated(time_treated) ///
		timeID(year) ///
		groupID(fips) ///
		k_pre(-6) ///
		k_post(6) ///
		year_start_stack(1922) ///
		year_end_stack(1942) ///
		notYetTreated("FALSE") 
	
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
	
	reghdfe `depvar' ///
				_T* ///
				[aw = `weightvar'] ///
				, absorb(fips##stackID year##stackID) vce(cluster fips)	
				
	mat b = e(b)'
	mat list b 
	mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
	mat list b

	mata st_matrix("ll", (st_matrix("e(b)"))'- invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
	mat list ll
	mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
	mat list ll
	
	mata st_matrix("ul", (st_matrix("e(b)"))'+ invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
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
	mat stacked_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list stacked_results
				
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
	mat stacked_results = stacked_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ stacked_results[`time_after_ref_event_time'..`max_pos',.]
	mat list stacked_results
										
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1			
					
	////////////////////////////////////////////////////////////////////////////////

	clear 

	tempfile stacked_results
	svmat stacked_results
	rename stacked_results1 order
	rename stacked_results2 b
	rename stacked_results3 ll
	rename stacked_results4 ul
	gen method = "stacked"
	save "`stacked_results'"

	clear
	tempfile twfe_results
	svmat twfe_results
	rename twfe_results1 order
	rename twfe_results2 b
	rename twfe_results3 ll
	rename twfe_results4 ul
	gen method = "twfe"

	save "`twfe_results'"

	clear
	tempfile cs_results
	svmat cs_results, names(col)
	rename cs_b b
	rename cs_ll ll
	rename cs_ul ul
	gen method = "cs"
	rename cs_order order

	save "`cs_results'"

	clear 
	tempfile etwfe_results
	svmat etwfe_results, names(col)
	gen method = "etwfe"
	rename etwfe_b b
	rename etwfe_ll ll
	rename etwfe_ul ul
	rename  etwfe_order order

	append using "`stacked_results'"
	append using "`cs_results'"
	append using "`twfe_results'"

	replace b = 0 if missing(b) & order == -1

	////////////////////////////////////////////////////////////////////////////////
	// Figure 
	
	gen new_id = 0 
	replace new_id = 1 if method == "twfe"
	replace new_id = 2 if method == "stacked"
	replace new_id = 3 if method == "etwfe"
	replace new_id = 4 if method == "cs"

	gen modified_event_time = order + ((new_id - 1) / (6) ) - ((3 - 1) / (6) )
	 
	keep if order >= -6
	keep if order <= 6
	sort modified_event_time
	order modified_event_time

	local gphMax 		6
	local gphMin 		-6
	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	di "`high_event_cap_graph'"


	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

	// Labels for figure output file 
	if "`depvar'" == "i_tot_beds_aha_pc" { 
		local panel "a"
		local title "total_beds"
	}
	if "`depvar'" == "i_likely_beds_aha_pc" { 
		local panel "b"
		local title "likely_beds"
	}
	if "`depvar'" == "i_prop_beds_aha_pc" { 
		local panel "c"
		local title "private_beds"		
	}	

	// Plot estimates
	twoway ///
		|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
		|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
		|| rcap ll ul modified_event_time if  new_id == 2, fcol("black") lcol("black") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 2,  col(white) msize(3) msymbol(d)  /// highlighting
		|| scatter b modified_event_time if  new_id == 2,  col("black") msize(2) msymbol(d) /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 3, fcol("vermillion") lcol("vermillion") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 3,  col(white) msize(3) msymbol(t)  /// highlighting
		|| scatter b modified_event_time if  new_id == 3,  col("vermillion") msize(2) msymbol(t)  /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 4, fcol("sea") lcol("sea") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 4,  col(white) msize(3) msymbol(c)  /// highlighting
		|| scatter b modified_event_time if  new_id == 4,  col("sea") msize(2) msymbol(c)  /// connect estimates
		|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%3.2f)) ///		
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(order(3 "TWFE" ///
						6 "Stacked-TWFE" 9 "eTWFE" 12 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'3_`title'_first_stage.png", replace
		graph export "$PROJ_PATH/analysis/output/main/figure_2`panel'3_`title'_first_stage.pdf", replace 
	
}

********************************************************************************************************
***** Row 1 of Figures 3a, 3b, and 3c: Descriptive plot of doctors by year and ever treated status *****
********************************************************************************************************

// Doctors by year and ever treated status
local fig_width 	7
local qual 			2yr
local race_group 	pooled 
local weightvar 	births_pub
local lbl 			""
local race_suf 		""
local el 			""
local labels 		"0(20)80"
local labels_low	"0(15)35"
local labels_mid	"0(20)40"

// Load data 
use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

keep rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' `weightvar' calendar_year ever_treated 
gcollapse (mean) rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf'  [aweight = `weightvar'], by(calendar_year ever_treated) 


* Pooled - All doctors
twoway ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of `lbl'doctors per 1,000 births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_mid', nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(36 1922 "Ever treated", size(large) placement(right)) text(33 1922 "by 1942", size(large) placement(right)) ///
				text(18 1922 "Never treated", size(large) placement(right)) text(15 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/main/figure_3a1_`race_group'_rMD_by_treat_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3a1_`race_group'_rMD_by_treat_status.pdf", replace


* Pooled - High Quality doctors
twoway ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of high quality `lbl'doctors per 1,000 births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_low', nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(23 1936 "Ever treated", size(large) placement(right)) text(21 1936 "by 1942", size(large) placement(right)) ///
				text(8 1937.5 "Never treated", size(large) placement(right)) text(6 1937.5 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/main/figure_3b1_`race_group'_rMD_good_by_treat_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3b1_`race_group'_rMD_good_by_treat_status.pdf", replace

* Pooled - Low Quality doctors
twoway ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of low quality `lbl'doctors per 1,000 births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_low', nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(33 1922 "Ever treated", size(large) placement(right)) text(31 1922 "by 1942", size(large) placement(right)) ///
				text(15 1922 "Never treated", size(large) placement(right)) text(13 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/main/figure_3c1_`race_group'_rMD_bad_by_treat_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3c1_`race_group'_rMD_bad_by_treat_status.pdf", replace


********************************************************************************************************
***** Row 2 of Figures 3a, 3b, and 3c: Descriptive plot of doctors by event-time for ever treated  *****
********************************************************************************************************

local fig_width 		7
local qual 				2yr
local race_group 		pooled 
local el 				""
local race_suf 			""
local weightvar 		births_pub
local lbl 				""
local labels_high 		"0(.5)4"
local labels_not_high 	".5(.25)1.25"
local labels_low 		".75(.25)1.25"

// Load data 
use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear
keep if ever_treated == 1

gen event_time = amd_wave - time_treated

gen temp_yb_size = rmd`race_suf' if event_time == -1 & !missing(event_time)
bysort fips: egen yb_size = max(temp_yb_size)
replace rmd`race_suf' = rmd`race_suf'/yb_size
drop yb_size temp_yb_size

gen temp_yb_size = rmd_good_`qual'`race_suf' if event_time == -1 & !missing(event_time)
bysort fips: egen yb_size = max(temp_yb_size)
replace rmd_good_`qual'`race_suf' = rmd_good_`qual'`race_suf'/yb_size
drop yb_size temp_yb_size

gen temp_yb_size = rmd_bad_`qual'`race_suf' if event_time == -1 & !missing(event_time)
bysort fips: egen yb_size = max(temp_yb_size)
replace rmd_bad_`qual'`race_suf' = rmd_bad_`qual'`race_suf'/yb_size
drop yb_size temp_yb_size
	
keep rmd`race_suf'  rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' `weightvar' event_time 
	
gcollapse (mean) rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' [aw = `weightvar'], by(event_time) 


* Pooled - All doctors
twoway ///
	|| connected rmd`race_suf' event_time if event_time <= -.5 & event_time >= -5 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit   rmd`race_suf' event_time if event_time <= -.5 & event_time >= -5 ,color(black) range(-5 5) lcolor("black") lp(dash) ///
	|| connected  rmd`race_suf' event_time if event_time >= -.5 & event_time <= 5, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-5(1)5, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("AMD waves since capital appropriation", size(5) height(7)) ///
				ytitle("") ///
				subtitle("`lbl'Doctors in county per 1,000 births relative to t=-1", size(5) pos(11)) ///
				xline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_low', nogrid labsize(5) angle(0) format(%3.2f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 	

*graph export "$PROJ_PATH/analysis/output/main/figure_3a2_`race_group'_rMD_by_event_time.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3a2_`race_group'_rMD_by_event_time.pdf", replace


* Pooled - High Quality doctors
twoway ///
	|| connected rmd_good_2yr`race_suf' event_time if event_time <= -.5 & event_time >= -5 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit   rmd_good_2yr`race_suf' event_time if event_time <= -.5 & event_time >= -5 ,color(black) range(-5 5) lcolor("black") lp(dash) ///
	|| connected  rmd_good_2yr`race_suf' event_time if event_time >= -.5 & event_time <= 5, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-5(1)5, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("AMD waves since capital appropriation", size(5) height(7)) ///
				ytitle("") ///
				subtitle("High quality `lbl'doctors in county per 1,000 births relative to t=-1", size(5) pos(11)) ///
				xline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_high', nogrid labsize(5) angle(0) format(%3.2f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
	
*graph export "$PROJ_PATH/analysis/output/main/figure_3b2_`race_group'_rMD_good_by_event_time.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3b2_`race_group'_rMD_good_by_event_time.pdf", replace


* Pooled - Low Quality doctors
twoway ///
	|| connected rmd_bad_2yr`race_suf' event_time if event_time <= -.5 & event_time >= -5 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit   rmd_bad_2yr`race_suf' event_time if event_time <= -.5 & event_time >= -5 ,color(black) range(-5 5) lcolor("black") lp(dash) ///
	|| connected  rmd_bad_2yr`race_suf' event_time if event_time >= -.5 & event_time <= 5, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-5(1)5, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("AMD waves since capital appropriation", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Low quality `lbl'doctors per 1,000 births in county relative to t=-1", size(5) pos(11)) ///
				xline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels_not_high', nogrid labsize(5) angle(0) format(%3.2f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 	

*graph export "$PROJ_PATH/analysis/output/main/figure_3c2_`race_group'_rMD_bad_by_event_time.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_3c2_`race_group'_rMD_bad_by_event_time.pdf", replace



**********************************************************************************
***** Row 3 of Figures 3a, 3b, and 3c: First-stage event studies for doctors *****
**********************************************************************************

local stackMax 		3
local stackMin 		-3
local gphMax 		5
local gphMin 		-5
local qual		 	2yr 
local race_group	pooled
local el 			""
local race_suf 		""
local weightvar 	births_pub

	foreach depvar in rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' { 
	*local  depvar md`race_suf'
	eststo clear

	// Load data 
	use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
						
	local lbl: var label `depvar'
	di "`lbl'"
							
	// TWFE OLS estimation
					
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = amd_wave - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
		
		reghdfe `depvar' ///
					_T* ///
					[aw = `weightvar'] ///
					, absorb(fips amd_wave) vce(cluster fips)	
					
		mat b = e(b)'
		mat list b 
		mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
		mat list b

		mata st_matrix("ll", (st_matrix("e(b)"))'- invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
		mat list ll
		mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
		mat list ll
		
		mata st_matrix("ul", (st_matrix("e(b)"))'+ invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
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
	mat twfe_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list twfe_results
							
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
	mat twfe_results = twfe_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ twfe_results[`time_after_ref_event_time'..`max_pos',.]
	mat list twfe_results
						
	// Clean up 
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1
			
			
	// csdid of Callaway and Sant'Anna (2020) 

	*Estimation
	csdid `depvar' [iw = `weightvar'], ivar(fips) time(amd_wave) gvar(time_treated_2) agg(event)

	*Aggregation
	csdid_estat event

	* Store event-study info
	local evlist = subinstr("`:colname r(table)'","T","",.)
	local evlist = subinstr("`evlist'","m","-",.)
	local evlist = subinstr("`evlist'","p","+",.)
	 
	matrix mm = r(table)'
	matrix mm=mm[3...,....]

	tsvmat mm, name(cs_b cs_se cs_z cs_p cs_ll cs_ul)
	qui:gen cs_order =.
	local k = 0
	foreach i of local evlist {
		if !inlist("`i'","Pre_avg","Post_avg")  {
			local k = `k'+1
			qui:replace cs_order =`i' in `k'
		} 	
	}
	mkmat cs_order cs_b cs_se cs_z cs_p cs_ll cs_ul, matrix(cs_results) nomissing

	mat list cs_results


	// eTWFE - no controls - weights 
	jwdid `depvar' [pw = `weightvar'], ivar(fips) tvar(amd_wave) gvar(time_treated_2)  

	*Aggregation
	estat event 
	return list 
	 
	mat b =  r(table)'
	mat list b 
	 
	local coln:rowname b

	local coln= subinstr("`coln'","r2vs1._at@","",.)
	local coln= subinstr("`coln'","bn","",.)
	local coln= subinstr("`coln'",".__event__","",.)
	di "`coln'"

	foreach i of local coln {
		local ll:label (__event__) `i'
		local lcoln `lcoln' `ll'
	}
	di "`lcoln'"

	tsvmat b, name(etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul)
	qui:gen etwfe_order =.
	local k = 1
	foreach i of local lcoln {
		qui:replace etwfe_order =`i' in `k'
		local k = `k'+1
		di "`i'"
	}
	mkmat etwfe_order etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul, matrix(etwfe_results) nomissing
						
				
	/////////////////////////////////////////////////////////////////////////////////
	// Balanced stacked 
		
	balanced_stacked, ///
		outcome(`depvar') ///
		treated(treated) ///
		timeTreated(time_treated) ///
		timeID(amd_wave) ///
		groupID(fips) ///
		k_pre(`stackMin') ///
		k_post(`stackMax') ///
		year_start_stack(1) ///
		year_end_stack(11) ///
		notYetTreated("FALSE") 
			
	gisid stackID fips amd_wave
	gsort stackID fips amd_wave
	order stackID fips amd_wave 
			
	* gen event-time (adoption_date = treatment adoption date)
	capture drop event_time_bacon
	gen event_time_bacon = amd_wave - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
		
		reghdfe `depvar' ///
					_T* ///
					[aw = `weightvar'] ///
					, absorb(fips##stackID amd_wave##stackID) vce(cluster fips)	
					
		mat b = e(b)'
		mat list b 
		mata st_matrix("b",select(st_matrix("b"),st_matrix("b")[.,1]:!=0))
		mat list b

		mata st_matrix("ll", (st_matrix("e(b)"))'- invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
		mat list ll
		mata st_matrix("ll",select(st_matrix("ll"),st_matrix("ll")[.,1]:!=0))
		mat list ll
		
		mata st_matrix("ul", (st_matrix("e(b)"))'+ invt(st_numscalar("e(df_r)"), 0.975)*sqrt(diagonal(st_matrix("e(V)"))))
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
	mat stacked_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list stacked_results
																	
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
	mat stacked_results = stacked_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ stacked_results[`time_after_ref_event_time'..`max_pos',.]
	mat list stacked_results
								
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1			
									
	////////////////////////////////////////////////////////////////////////////////
	clear 

	tempfile stacked_results
	svmat stacked_results
	rename stacked_results1 order
	rename stacked_results2 b
	rename stacked_results3 ll
	rename stacked_results4 ul
	gen method = "stacked"
	save "`stacked_results'"

	clear
	tempfile twfe_results
	svmat twfe_results
	rename twfe_results1 order
	rename twfe_results2 b
	rename twfe_results3 ll
	rename twfe_results4 ul
	gen method = "twfe"

	save "`twfe_results'"

	clear
	tempfile cs_results
	svmat cs_results, names(col)
	rename cs_b b
	rename cs_ll ll
	rename cs_ul ul
	gen method = "cs"
	rename cs_order order

	save "`cs_results'"

	clear 
	tempfile etwfe_results
	svmat etwfe_results, names(col)
	gen method = "etwfe"
	rename etwfe_b b
	rename etwfe_ll ll
	rename etwfe_ul ul
	rename  etwfe_order order

	append using "`stacked_results'"
	append using "`cs_results'"
	append using "`twfe_results'"

	replace b = 0 if missing(b) & order == -1

	////////////////////////////////////////////////////////////////////////////////
	// Figure 
	gen new_id = 0 
	replace new_id = 1 if method == "twfe"
	replace new_id = 2 if method == "stacked"
	replace new_id = 3 if method == "etwfe"
	replace new_id = 4 if method == "cs"

	gen modified_event_time = order + ((new_id - 1) / (6) ) - ((3 - 1) / (6) )
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	
	keep if order >= `gphMin'
	keep if order <= `gphMax'
	sort modified_event_time
	order modified_event_time

	local mn = `gphMin' -  1
	local mx = `gphMax' + 1

	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

	if "`depvar'" == "rmd" {
		local panel "a"
		local title "rMD"
	}
	if "`depvar'" == "rmd_good_2yr" {
		local panel "b"
		local title "rMD_good"
	}
	if "`depvar'" == "rmd_bad_2yr" {
		local panel "c"
		local title "rMD_bad"
	}	
	
	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	di "`high_event_cap_graph'"

	// Plot estimates
	twoway ///
		|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
		|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
		|| rcap ll ul modified_event_time if  new_id == 2, fcol("black") lcol("black") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 2,  col(white) msize(3) msymbol(d)  /// highlighting
		|| scatter b modified_event_time if  new_id == 2,  col("black") msize(2) msymbol(d) /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 3, fcol("vermillion") lcol("vermillion") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 3,  col(white) msize(3) msymbol(t)  /// highlighting
		|| scatter b modified_event_time if  new_id == 3,  col("vermillion") msize(2) msymbol(t)  /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 4, fcol("sea") lcol("sea") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 4,  col(white) msize(3) msymbol(c)  /// highlighting
		|| scatter b modified_event_time if  new_id == 4,  col("sea") msize(2) msymbol(c)  /// connect estimates
		|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///		
			xtitle("AMD waves since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(order(3 "TWFE" ///
						6 "Stacked-TWFE" 9 "eTWFE" 12 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(5) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/main/figure_3`panel'3_`race_group'_`title'_first_stage.png", replace
		graph export "$PROJ_PATH/analysis/output/main/figure_3`panel'3_`race_group'_`title'_first_stage.pdf", replace 
	
}

***********************************************************************************************************************
***** Row 1 of Figures 4a, 4b, and 4c: Descriptive plot of infant mortality rates by year and ever treated status *****
***********************************************************************************************************************

local fig_width 7

// Infant mortality rate by year and ever treated status
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
		
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate infant mortality outcomes + generate weights 
	imdata, mort(mort) suffix(pub)
	
	// Generate Duke treatment variables
	duketreat, treatvar(`treat') time(year) location(fips) 

	collapse (mean) imr_pub`race_ind' [aweight = births_pub`race_ind'], by(year ever_treated) 
	tempfile dta`race_ind'
	save  `dta`race_ind''
		
}

use `dta', clear 
merge 1:1 year ever_treated using `dta_bk', assert(3) nogen
merge 1:1 year ever_treated using `dta_wt', assert(3) nogen

// Infant mortality rate by year and ever treated status - Full figure

* Pooled
twoway connected imr_pub year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected imr_pub year if ever_treated == 1, lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1922(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(30(20)120, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Pooled infant mortality rate per 1,000 live births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(86 1922.2 "Ever treated", size(large) placement(right)) text(80 1922.2 "by 1942", size(large) placement(right)) ///
				text(62 1922.2 "Never treated", size(large) placement(right)) text(56 1922.2 "up to 1942", size(large) placement(right))
	
*graph export "$PROJ_PATH/analysis/output/main/figure_4a1_imr_by_treatment_status_pooled.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4a1_imr_by_treatment_status_pooled.pdf", replace

* Black
twoway connected imr_pub_bk year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected imr_pub_bk year if ever_treated == 1, lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1922(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(30(20)120, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Black infant mortality rate per 1,000 live births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(97 1922.2 "Ever treated", size(large) placement(right)) text(91 1922.2 "by 1942", size(large) placement(right)) ///
				text(75 1922.2 "Never treated", size(large) placement(right)) text(69 1922.2 "up to 1942", size(large) placement(right))
		
*graph export "$PROJ_PATH/analysis/output/main/figure_4b1_imr_by_treatment_status_black.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4b1_imr_by_treatment_status_black.pdf", replace

* White
twoway connected imr_pub_wt year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected imr_pub_wt year if ever_treated == 1, lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1922(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(30(20)120, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("White infant mortality rate per 1,000 live births", size(5) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(75 1922.2 "Ever treated", size(large) placement(right)) text(69 1922.2 "by 1942", size(large) placement(right)) ///
				text(54 1922.2 "Never treated", size(large) placement(right)) text(48 1922.2 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/main/figure_4c1_imr_by_treatment_status_white.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4c1_imr_by_treatment_status_white.pdf", replace


********************************************************************************************************
***** Row 2 of Figures 4a, 4b, and 4c: Descriptive plot of infant mortality rates by event time *******************************
********************************************************************************************************

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
		
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate infant mortality outcomes + generate weights 
	imdata, mort(mort) suffix(pub)

	// Generate variables for event study timing and set up event study specification
	duketreat, treatvar(`treat') time(year) location(fips)

	// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
	tab time_treated, m

	// store largest leads and lags
	capture drop event_time
	gen event_time = year - time_treated
	tab event_time, m
		
	gcollapse (mean) imr_pub`race_ind' [aweight = births_pub`race_ind'], by(event_time) 
	
	tempfile dta`race_ind'
	save  `dta`race_ind'', replace
			
}

use `dta', clear 
fmerge 1:1 event_time using `dta_bk', assert(3) nogen
fmerge 1:1 event_time using `dta_wt', assert(3) nogen

* Pooled IMR
twoway ///
	|| connected imr_pub event_time if event_time <= -.5 & event_time >= -6 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit  imr_pub event_time if event_time <= -.5 & event_time >= -6 ,color(black) range(-6 6) lcolor("black") lp(dash) ///
	|| connected imr_pub event_time if event_time >= -.5 & event_time <= 6, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-6(1)6, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(40(10)110, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xline(-0.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xtitle("Years since first capital appropriation from Duke Endowment ", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Pooled infant mortality rate per 1,000 live births in counties treated by 1942", size(4) pos(11)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)

*graph export "$PROJ_PATH/analysis/output/main/figure_4a2_imr_by_event_time_pooled.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4a2_imr_by_event_time_pooled.pdf",  replace

* Black IMR
twoway ///
	|| connected imr_pub_bk event_time if event_time <= -.5 & event_time >= -6 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit  imr_pub_bk event_time if event_time <= -.5 & event_time >= -6 ,color(black) range(-6 6) lcolor("black") lp(dash) ///
	|| connected imr_pub_bk event_time if event_time >= -.5 & event_time <= 6, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-6(1)6, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(40(10)110, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xline(-0.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Black infant mortality rate per 1,000 live births in counties treated by 1942", size(4) pos(11)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
*graph export "$PROJ_PATH/analysis/output/main/figure_4b2_imr_by_event_time_black.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4b2_imr_by_event_time_black.pdf",  replace

* White IMR
twoway ///
	|| connected imr_pub_wt event_time if event_time <= -.5 & event_time >= -6 , lw(.75) lcolor("230 65 115") lp(line) msymbol(none)  ///
	|| lfit  imr_pub_wt event_time if event_time <= -.5 & event_time >= -6 ,color(black) range(-6 6) lcolor("black") lp(dash) ///
	|| connected imr_pub_wt event_time if event_time >= -.5 & event_time <= 6, lw(.75) lcolor("230 65 115") lp(longdash) msymbol(none) ///
				xlab(-6(1)6, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(40(10)110, nogrid labsize(5) angle(0) format(%3.0f)) ///
				xline(-0.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
				ytitle("") ///
				subtitle("White infant mortality rate per 1,000 live births in counties treated by 1942", size(4) pos(11)) ///
				xsize(`fig_width') ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)

*graph export "$PROJ_PATH/analysis/output/main/figure_4c2_imr_by_event_time_white.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/main/figure_4c2_imr_by_event_time_white.pdf", replace



*******************************************************************************
***** Row 3 of Figures 4a, 4b, and 4c: Event studies for infant mortality *****
*******************************************************************************

local depvar_stub	imr_pub
local weight_stub	births_pub

foreach race in pooled black white {
			
	if "`race'" == "pooled" {
		local race_suf ""
	}	
	if "`race'" == "white" {
		local race_suf "_wt"
	}
	if "`race'" == "black" {
		local race_suf "_bk"
	}
	
	local depvar 	`depvar_stub'`race_suf'	
	local weightvar `weight_stub'`race_suf'

	// Load county-level infant mortality data 
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate infant mortality outcomes + generate weights 
	imdata, mort(mort) suffix(pub)
		
	local lbl: var label `depvar'
	di "`lbl'"
	
	// Add Duke treatment 
	duketreat, treatvar(`treat') time(year) location(fips)

	// Drop counties ever with zero births by race
	egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
	
	if "`race'" == "white" | "`race'" == "black" {
		drop if ever_zero_births == 1
	}
	
	// Create separate version of treatment for Callaway-Sant'Anna with untreated coded to 0
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
		
	
	// Poisson estimation
	
	* gen event-time (adoption_date = treatment adoption date)
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
				[pw = `weightvar'] ///
				, absorb(fips year) cluster(fips) sep(fe)	
	
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
	
	
					
	// csdid of Callaway and Sant'Anna

	preserve 
	
	* Drop zeroes since we will use logs
		keep if `depvar' != 0

		*Estimation
		csdid ln_`depvar' [iw = `weightvar'], ivar(fips) time(year) gvar(time_treated_2) agg(event)
		
		*Aggregation
		csdid_estat event
		
		* Store event-study info
		local evlist = subinstr("`:colname r(table)'","T","",.)
		local evlist = subinstr("`evlist'","m","-",.)
		local evlist = subinstr("`evlist'","p","+",.)
		 
		matrix mm = r(table)'
		matrix mm=mm[3...,....]
		
		tsvmat mm, name(cs_b cs_se cs_z cs_p cs_ll cs_ul)
		qui:gen cs_order =.
		local k = 0
		foreach i of local evlist {
			if !inlist("`i'","Pre_avg","Post_avg")  {
				local k = `k'+1
				qui:replace cs_order =`i' in `k'
			} 	
		}
		mkmat cs_order cs_b cs_se cs_z cs_p cs_ll cs_ul, matrix(cs_results) nomissing

		mat list cs_results
	
	restore
	

	// eTWFE 
	jwdid `depvar' [pw = `weightvar'], ivar(fips) tvar(year) gvar(time_treated_2) method(poisson)
	
	*Aggregation
	estat event 
	return list 
	 
	mat b =  r(table)'
	mat list b 
	 
	local coln:rowname b

	local coln= subinstr("`coln'","r2vs1._at@","",.)
	local coln= subinstr("`coln'","bn","",.)
	local coln= subinstr("`coln'",".__event__","",.)
	di "`coln'"
	
	foreach i of local coln {
		local ll:label (__event__) `i'
		local lcoln `lcoln' `ll'
	}
	di "`lcoln'"

	tsvmat b, name(etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul)
	qui: gen etwfe_order = .
	local k = 1
	foreach i of local lcoln {
		qui: replace etwfe_order =`i' in `k'
		local k = `k' + 1
		di "`i'"

	}
	
	mkmat etwfe_order etwfe_b etwfe_se etwfe_z etwfe_p etwfe_ll etwfe_ul, matrix(etwfe_results) nomissing
			
	/////////////////////////////////////////////////////////////////////////////////
	// Balanced stacked 
			
	balanced_stacked, ///
		outcome(`depvar') ///
		treated(treated) ///
		timeTreated(time_treated) ///
		timeID(year) ///
		groupID(fips) ///
		k_pre(-6) ///
		k_post(6) ///
		year_start_stack(`year_start') ///
		year_end_stack(`year_end') ///
		notYetTreated("FALSE") 
	
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = year - time_treated
	levelsof(event_time_bacon) if !missing(`depvar'), matrow(event_time_names)	
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
				[pw = `weightvar'] ///
				, absorb(fips##stackID year##stackID) cluster(fips) sep(fe)	
				
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
	mat stacked_results =  event_time_names_without_ref, b[1..`max_pos',.], ll[1..`max_pos',.], ul[1..`max_pos',.]
	mat list stacked_results
				
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
	mat stacked_results = stacked_results[1..`time_b4_ref_event_time',.] \ `ref_event_time', 0, 0, 0 \ stacked_results[`time_after_ref_event_time'..`max_pos',.]
	mat list stacked_results
										
	// Clean up
	capture drop event_time_bacon
	capture drop _T*
	capture drop event_time_names_without_ref1			
					
	////////////////////////////////////////////////////////////////////////////////

	clear 

	tempfile stacked_results
	svmat stacked_results
	rename stacked_results1 order
	rename stacked_results2 b
	rename stacked_results3 ll
	rename stacked_results4 ul
	gen method = "stacked"
	save "`stacked_results'"

	clear
	tempfile ppml_results
	svmat ppml_results
	rename ppml_results1 order
	rename ppml_results2 b
	rename ppml_results3 ll
	rename ppml_results4 ul
	gen method = "poisson"

	save "`ppml_results'"

	clear
	tempfile cs_results
	svmat cs_results, names(col)
	rename cs_b b
	rename cs_ll ll
	rename cs_ul ul
	gen method = "cs"
	rename cs_order order

	save "`cs_results'"

	clear 
	tempfile etwfe_results
	svmat etwfe_results, names(col)
	gen method = "etwfe"
	rename etwfe_b b
	rename etwfe_ll ll
	rename etwfe_ul ul
	rename  etwfe_order order

	append using "`stacked_results'"
	append using "`cs_results'"
	append using "`ppml_results'"

	replace b = 0 if missing(b) & order == -1

	////////////////////////////////////////////////////////////////////////////////
	// Figure 
	
	gen new_id = 0 
	replace new_id = 1 if method == "poisson"
	replace new_id = 2 if method == "stacked"
	replace new_id = 3 if method == "etwfe"
	replace new_id = 4 if method == "cs"

	gen modified_event_time = order + ((new_id - 1) / (6) ) - ((3 - 1) / (6) )
	 
	keep if order >= -6
	keep if order <= 6
	sort modified_event_time
	order modified_event_time

	local gphMax 		6
	local gphMin 		-6
	local low_label_cap_graph `gphMin'
	local high_label_cap_graph `gphMax'
	sum modified_event_time 
	local low_event_cap_graph = r(min) - .01
	di "`low_event_cap_graph'"
	local high_event_cap_graph = r(max) + .01
	di "`high_event_cap_graph'"

	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'
	
	// Scale CS coefficients by 100
	replace ll = ll*100 if method == "cs"
	replace ul = ul*100 if method == "cs"
	replace b = b*100 if method == "cs"
	
	local depvar_title imr
	
	if "`race'" == "pooled" {
		local panel "a"
	}
	if "`race'" == "black" {
		local panel "b"
	}
	if "`race'" == "white" {
		local panel "c"
	}
	
	// Plot estimates
	twoway ///
		|| rcap ll ul modified_event_time if  new_id == 1, fcol("230 65 115") lcol("230 65 115") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 1,  col(white) msize(3) msymbol(s)  /// highlighting
		|| scatter b modified_event_time if  new_id == 1,  col("230 65 115") msize(2) msymbol(s)  /// connect estimates
		|| rcap ll ul modified_event_time if  new_id == 2, fcol("black") lcol("black") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 2,  col(white) msize(3) msymbol(d)  /// highlighting
		|| scatter b modified_event_time if  new_id == 2,  col("black") msize(2) msymbol(d) /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 3, fcol("vermillion") lcol("vermillion") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 3,  col(white) msize(3) msymbol(t)  /// highlighting
		|| scatter b modified_event_time if  new_id == 3,  col("vermillion") msize(2) msymbol(t)  /// connect estimates
			|| rcap ll ul modified_event_time if  new_id == 4, fcol("sea") lcol("sea") msize(2) /// estimates
		|| scatter b modified_event_time if  new_id == 4,  col(white) msize(3) msymbol(c)  /// highlighting
		|| scatter b modified_event_time if  new_id == 4,  col("sea") msize(2) msymbol(c)  /// connect estimates
		|| scatteri 0 `low_event_cap_graph' 0 `high_event_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
					, nogrid valuelabel labsize(5) angle(0)) ///
			ylab(-40(20)20, nogrid labsize(5) angle(0) format(%3.2f)) ///		
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(order(3 "Poisson" ///
						6 "Stacked-Poisson" 9 "eTWFE" 12 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/main/figure_4`panel'3_`depvar_title'_event_study_`race'.png", replace
		graph export "$PROJ_PATH/analysis/output/main/figure_4`panel'3_`depvar_title'_event_study_`race'.pdf", replace 
	
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
