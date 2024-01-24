version 15
disp "DateTime: $S_DATE $S_TIME"

***********
* SCRIPT: 6.xx_online_appendix_ri.do
* PURPOSE: Run analysis for Appendix K - Randomization of the treatment
* DEPENDENCIES:
	* imppml_regsave.ado
	* regsave 
	* temp_local/
	
************

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"

// Duke treatment variable 
local treat 		"capp_all"

// Panel start and end dates
local year_start 	1922
local year_end 		1942

// Randomination options 
local nrep 			10000
local seed 			12345

*****  Randomize set of treated counties - Infant mortality *****

local replace replace

// Short-run mortality outcomes
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Keep list of treated counties and first year of Duke treatment 

preserve 

	keep if time_treated != .
	keep time_treated fips 
	order time_treated fips 

	duplicates drop
	
	count
	local n_treated `r(N)'
	
	gsort time_treated fips
	drop fips

	gen row_id = _n

	tempfile treated_year_list
	save `treated_year_list', replace
	
restore

keep fips
duplicates drop
sort fips
count 

tempfile treated_cty_list
save `treated_cty_list', replace

set seed `seed'

forvalues i = 1(1)`nrep' {

	qui {
		
		// Randomly select counties for treatment 
		use fips using `treated_cty_list', clear
		sample `n_treated'
		count
		
		// Randomize sequence of treated counties
		generate randnum`i' = uniform()
		sort randnum`i'

		// Merge in sequence of treated years
		gen row_id = _n
		fmerge 1:1 row_id using `treated_year_list', keepusing(time_treated) nogen

		drop randnum`i' row_id
		rename time_treated year

		tempfile rand_treat
		save `rand_treat', replace

		// Short-run mortality outcomes
		use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

		// Merge in randomized treatment 
		merge 1:1 fips year using `rand_treat', assert(1 3) 

		gen rand_treat = 1 if _merge == 3
		drop _merge

		// Generate DiD treatment variable
		duketreat, treatvar(rand_treat) time(year) location(fips)

		// Generate infant mortality outcomes 
		imdata, mort(mort) suffix(pub)

		if `i' > 1 local replace_option append
		if `i' == 1 local replace_option replace

		// Poisson - no controls - weights
		imppml_regsave, y_stub(imr_) suffix(pub) t(treated) wgt(births) a(fips year) pooled  replace_option(`replace_option') reg_filename(ri_all_cty)

	}
	
}


// Save main estimates

// Short-run mortality outcomes
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(capp_all) time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

ppmlhdfe imr_pub b0.treated  [pw = births_pub], absorb(fips year) vce(cluster fips)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")

local b_main `e(pct_efct_b_num)'
local t_main `e(pct_efct_t_num)'

nlcom 100*(exp(_b[1.treated])-1)
return list 

mat t_b = r(b)
mat t_V = r(V)

local t_b = t_b[1,1]
local t_V = t_V[1,1]
local  p_value = 2*ttail(e(df),abs(`t_b'/sqrt(`t_V')))

if `p_value' < .01 {
	local p_value "< .01"

} 
else {
local p_value = round(`p_value', .01)
}

*****  Randomize set of treated counties - Infant mortality *****

use "$PROJ_PATH/analysis/processed/temp/ri_all_cty.dta", clear

sum b
local b_avg = r(mean)
sum t
local t_avg = r(mean)

// Plot b

local text_y1 7.5
local text_y2 7
local text_x1 -10
local text_x2 1
	
local text_x_p_ri 20
local text_x_p_reg 20

local text_y3 6
local text_y4 5.5
local text_y5 4.5
local text_y6 4

// RI p-value
gen abs_b = abs(b)
count 
local total = r(N)
qui
count if abs_b >= abs(`b_main') 
local larger_than = r(N)

local p_value_ri = `larger_than'/`total'

local p_value_str = round(`p_value_ri', .01)

if `p_value_str' < .01 {
	local p_value_str "< .01"

}

twoway ///
	(histogram b, percent fcolor(none) lcolor(black)), ///
	subtitle("{bf:Randomize set of treated counties (10,000 reps)}", position(11) justification(left) size(4)) ///
	xline(`b_main', lstyle(foreground) lpattern(dash) lcolor("230 65 115") lwidth(1.0)) ///
	text(`text_y1' `text_x1' "Main", place(w) color("230 65 115") size(5)) ///
	text(`text_y2' `text_x1' "estimate", place(w) color("230 65 115") size(5)) ///
	xline(`b_avg', lstyle(foreground) lpattern(dash) lcolor(navy) lwidth(1.0)) ///
	text(`text_y1' `text_x2' "Sample mean", place(e) color(navy) size(5)) ///
	text(`text_y3' `text_x_p_ri' "Randomization inference", place(c) color(black) size(4)) ///
	text(`text_y4' `text_x_p_ri' "p-value: `p_value_str'", place(c) color(black) size(4)) ///
	text(`text_y5' `text_x_p_reg' "Regression", place(c) color(black) size(4)) ///
	text(`text_y6' `text_x_p_reg' "p-value: `p_value'", place(c) color(black) size(4)) ///
	ylabel(, angle(0) nogrid labsize(5)) yscale(nofextend) ytitle("Density", size(5)) ///
	xlabel(-30(10)30, angle(0) nogrid labsize(5)) xscale(nofextend) xtitle("Coefficient on Duke exposure", size(5)) ///
	xsize(5) scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))
	
*graph export "$PROJ_PATH/analysis/output/appendix/figure_k1_ri_all_cty_b.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_k1_ri_all_cty_b.pdf", replace


rm "$PROJ_PATH/analysis/processed/temp/ri_all_cty.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
