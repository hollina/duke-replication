version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_hospitals.do
* PURPOSE: Run regressions for main tables and figures
************/

* Preamble: these two lines of code are included so scripts can be run individually (rather than called by 0_run_master.do)
adopath ++ "$PROJ_PATH/analysis/scripts/libraries/stata-18"
adopath ++ "$PROJ_PATH/analysis/scripts/programs"

************************
* User switches

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _) drop(*)"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"

// Panel start and end dates
local year_start 	1922
local year_end 		1942

// Duke treatment type
local treat			"capp_ex_nurse"

*****************************************************************************
***** Table B1: Hospital first-stage results - Alternate specifications *****
*****************************************************************************
eststo clear

local stackMin		-6
local stackMax		6
local weightvar  	births_pub

local z = 1
	
foreach depvar in i_tot_beds_aha i_likely_beds_aha i_prop_beds_aha tot_hospitals tot_hosp_likely tot_hosp_prop {
		
	eststo clear

	foreach suffix in noPC yesPC  {
		
		// Load county-level first-stage hospitals data 
		use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear
		// Remove AHA label 
			foreach var of varlist *aha* *hosp* {
				local variable_label : variable label `var'
				local variable_label : subinstr local variable_label ", AHA" ""
				label variable `var' "`variable_label'"

				local variable_label : variable label `var'
				local variable_label : subinstr local variable_label " in county" ""
				label variable `var' "`variable_label'"
			}
		// Add Duke treatment 
		if substr("`depvar'", 1, 8) == "tot_hosp" {
			duketreat, treatvar(`treat') time(year) location(fips)
		}
		else {
			duketreat, treatvar(capp_all) time(year) location(fips)
		}
		
		// Create separate time treated variable for Callaway-Sant'Anna
		gen time_treated_2 = time_treated
		replace time_treated_2 = 0 if missing(time_treated)
		
		if "`suffix'" == "noPC" {
			local depvar_new `depvar'
		}
		if "`suffix'" == "yesPC" {
			local depvar_new `depvar'_pc
		}
		
		local lbl: var label `depvar_new'
		di "`lbl'"
		
		if "`depvar_new'" == "i_tot_beds_aha_pc" {
			local position top
		}
		if "`depvar_new'" != "i_tot_beds_aha_pc" {
			if "`depvar_new'" != "tot_hosp_prop" {
				local position middle
			}
		}
		if `z' == 6 {
			local position bottom
		}
		
		if "`depvar_new'" == "i_tot_beds_aha_pc" { 
			local table_lbl "\emph{A. Beds (Duke treatment: All appropriations)} &&&&&&&& \\ \addlinespace\hspace{.5cm} Total" 
		}
		if "`depvar_new'" == "i_likely_beds_aha_pc" { 
			local table_lbl "\addlinespace\hspace{.5cm} Non-profit/church/public" 
		}
		if "`depvar_new'" == "i_prop_beds_aha_pc" { 
			local table_lbl "\addlinespace\hspace{.5cm} Proprietary" 
		}
		if "`depvar_new'" == "tot_hospitals_pc" { 
			local table_lbl "\emph{B. Hospitals (Duke treatment: Exclude homes for nurses)} &&&&&&&& \\ \addlinespace\hspace{.5cm} Total" 
		}
		if "`depvar_new'" == "tot_hosp_likely_pc" { 
			local table_lbl "\addlinespace\hspace{.5cm} Non-profit/church/public" 
		}
		if "`depvar_new'" == "tot_hosp_prop_pc" { 
			local table_lbl "\addlinespace\hspace{.5cm} Proprietary" 
		}
		
		// TWFE OLS estimation

			*Estimation
			eststo p1_c1`suffix': reghdfe `depvar_new' 1.treated [aw = `weightvar'], absorb(fips year) vce(cluster fips)				
			csdid_estadd_level 1.treated, statname("bed_efct_") 
		
		// eTWFE  

			*Estimation
			jwdid `depvar_new' [pw = `weightvar'], ivar(fips) tvar(year) gvar(time_treated_2)  
					
			*Aggregation
			eststo p1_c3`suffix': estat simple 
			csdid_estadd_level  "", statname("bed_efct_")		
			
		// csdid of Callaway and Sant'Anna (2020)

			*Estimation
			csdid `depvar_new' [iw = `weightvar'], ivar(fips) time(year) gvar(time_treated_2) agg(event)

			*Aggregation
			eststo p1_c4`suffix': csdid_estat simple
			csdid_estadd_level "", statname("bed_efct_")
			
		/////////////////////////////////////////////////////////////////////////////////
		// Balanced stacked 
					
		balanced_stacked, ///
			outcome(`depvar_new') ///
			treated(treated) ///
			timeTreated(time_treated) ///
			timeID(year) ///
			groupID(fips) ///
			k_pre(`stackMin') ///
			k_post(`stackMax') ///
			year_start_stack(`year_start') ///
			year_end_stack(`year_end') ///
			notYetTreated("FALSE") 
		
		gisid stackID fips year 
		gsort stackID fips year
		
		*Estimation
		eststo p1_c2`suffix': reghdfe `depvar_new' 1.treated [aw = `weightvar'], absorb(fips##stackID year##stackID) vce(cluster fips)
		csdid_estadd_level 1.treated, statname("bed_efct_") 

	}
	// Prepare table
	if "`position'" == "top" {

		local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} & \multicolumn{1}{c}{(8)} \\"
		local numbers_main2 "& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Stacked-TWFE} & \multicolumn{1}{c}{eTWFE} & \multicolumn{1}{c}{CS} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Stacked-TWFE} & \multicolumn{1}{c}{eTWFE} & \multicolumn{1}{c}{CS} \\"

		local y_1 `"\$Y^{R}_{ct} = \text{Beds or Hospitals}$"'
		local y_2 "\$Y^{R}_{ct} = \text{Beds or Hospitals per 1000 births}$"

		// Make top panel - Pooled - All 
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_b1_county_level_hospitals_robustness.tex", `booktabs_default_options' replace 
		mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		posthead("`numbers_main' `numbers_main2'") 
	stats(bed_efct_b bed_efct_se, fmt(0 0) labels("`table_lbl'" "~") layout(@ @));
		#delimit cr
		
	}
		
	if "`position'" == "middle" {
			
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_b1_county_level_hospitals_robustness.tex", `booktabs_default_options' append 
	stats(bed_efct_b bed_efct_se, fmt(0 0 ) labels("`table_lbl'" "~") layout(@ @));
	#delimit cr

	}

	if "`position'" == "bottom" {
			
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_b1_county_level_hospitals_robustness.tex", `booktabs_default_options' append 
		stats(bed_efct_b bed_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
		postfoot("\midrule 
			County FE  			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
			Year FE 		& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Controls 			& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\");
		#delimit cr
		
	}

	local z = `z' + 1
}

		
********************************************************************************************
***** Figure B1a: Descriptive plot of total hospitals by year and ever treated status ******
********************************************************************************************

local fig_width 	7
local weightvar  	births_pub

// Load county-level first-stage hospitals data 
use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

// Remove AHA label 
	foreach var of varlist *aha* *hosp*  {
		local variable_label : variable label `var'
		local variable_label : subinstr local variable_label ", AHA" ""
		label variable `var' "`variable_label'"

		local variable_label : variable label `var'
		local variable_label : subinstr local variable_label " in county" ""
		label variable `var' "`variable_label'"
	}
	
// Add Duke treatment 
duketreat, treatvar(`treat') time(year) location(fips)

keep tot_hospitals_pc tot_hosp_likely_pc tot_hosp_prop_pc `weightvar' ever_treated year 

foreach v of var * {
 	local l`v' : variable label `v'
	if `"`l`v''"' == "" {
 		local l`v' "`v'"
  	}
}

gcollapse (mean) tot_hospitals_pc tot_hosp_likely_pc tot_hosp_prop_pc [aw = `weightvar'], by(ever_treated year) 

 foreach v of var * {
 	label var `v' `"`l`v''"'
 }						
  
foreach depvar in tot_hospitals_pc tot_hosp_likely_pc tot_hosp_prop_pc { 

	local lbl: var label `depvar'
	di "`lbl'"
	
	if  "`depvar'" == "tot_hospitals_pc" {
		local label_1 "1.75"
		local label_2 "1.65"
		
		local label_3 "1.1"
		local label_4 "0.9"
		
		local label_fmt "%3.1f"	
		
		local title "total_hospitals"
		local row "1"

	}	

	if  "`depvar'" == "tot_hosp_likely_pc" {
		local label_1 "1.5"
		local label_2 "1.35"
		
		local label_3 ".75"
		local label_4 ".6"
		
		local label_fmt "%3.1f"		
		
		local title "likely_hospitals"
		local row "2"

	}	
		
	if  "`depvar'" == "tot_hosp_prop_pc" {
		local label_1 ".39"
		local label_2 ".36"
		
		local label_3 ".175"
		local label_4 ".1475"
		
		local label_fmt "%3.1f"		
		
		local title "private_hospitals"
		local row "3"

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
		
	*graph export "$PROJ_PATH/analysis/output/appendix/figure_b1a`row'_`title'_by_year.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_b1a`row'_`title'_by_year.pdf", replace
	
}

*********************************************************************
***** Figure B1b: First-stage event studies for total hospitals *****
*********************************************************************

local z = 1
local weightvar  births_pub

foreach depvar in tot_hospitals_pc tot_hosp_likely_pc tot_hosp_prop_pc { 
							
	// Load county-level first-stage hospitals data 
	use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear
	// Remove AHA label 
	foreach var of varlist *aha* *hosp*  {
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

		
	if  "`depvar'" == "tot_hospitals_pc" {

		local title "total_hospitals"
		local row "1"

	}	

	if  "`depvar'" == "tot_hosp_likely_pc" {	
		
		local title "likely_hospitals"
		local row "2"

	}	
		
	if  "`depvar'" == "tot_hosp_prop_pc" {
		
		local title "private_hospitals"
		local row "3"

	}
	
	keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

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
			xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
			xsize(8) ///
			legend(order(3 "TWFE" ///
						6 "Stacked-TWFE" 9 "eTWFE" 12 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		 subtitle("`lbl'", size(6) pos(11)) 
		 
		*graph export "$PROJ_PATH/analysis/output/appendix/figure_b1b`row'_`title'_first_stage.png", replace
		graph export "$PROJ_PATH/analysis/output/appendix/figure_b1b`row'_`title'_first_stage.pdf", replace 
	
}