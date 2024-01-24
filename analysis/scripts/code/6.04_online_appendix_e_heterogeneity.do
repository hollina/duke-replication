version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_heterogeneity.do
* PURPOSE: Run analysis for Appendix E - Duke funding: Heterogeneity by project type
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

***********************************************************************
***** Table E1: Appropriation and payment details by project type *****
***********************************************************************

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
gcollapse (sum) capp_* pay_*, by(app_id) labelformat(#sourcelabel#)
	
// All projects
label variable capp_all "\hspace{0.5cm} Appropriations, millions"
label variable pay_all "\hspace{0.5cm} Payments, millions"

estpost summarize capp_all if capp_all > 0 
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", replace ///
	cells("mean(fmt(%20.2f) label(\multicolumn{1}{c}{Mean} )) sd(fmt(%20.2f) label(\multicolumn{1}{c}{S.D.}) ) min(fmt(%20.2f) label(\multicolumn{1}{c}{Min.}) ) max(fmt(%20.2f) label(\multicolumn{1}{c}{Max.})) count(fmt(%3.0f) label(\multicolumn{1}{c}{N}))  ") ///
	nomtitle nonum label f alignment(S S) booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) ///
	refcat(capp_all "\emph{All projects}" capp_all, nolabel)

estpost tabstat pay_all if capp_all > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
		
		
// All projects, excluding homes for nurses
label variable capp_ex_nurse "\hspace{0.5cm} Appropriations, millions"
label variable pay_ex_nurse "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_ex_nurse if capp_ex_nurse > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_ex_nurse "\addlinespace \emph{All projects, excluding homes for nurses}" capp_ex_nurse, nolabel)

estpost tabstat pay_ex_nurse if capp_ex_nurse > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
	
	
// New hospitals/plants
label variable capp_new_hosp "\hspace{0.5cm} Appropriations, millions"
label variable pay_new_hosp "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_new_hosp if capp_new_hosp > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_new_hosp "\addlinespace \emph{New hospitals or plants}" capp_new_hosp, nolabel)
	
estpost tabstat pay_new_hosp if capp_new_hosp > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
	
	
// Additions
label variable capp_addition "\hspace{0.5cm} Appropriations, millions"
label variable pay_addition "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_addition if capp_addition > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_addition "\addlinespace \emph{Additions}" capp_addition, nolabel)

estpost tabstat pay_addition if capp_addition > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise		
		
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
	
	
// Equipment
label variable capp_equipment "\hspace{0.5cm} Appropriations, millions"
label variable pay_equipment "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_equipment if capp_equipment > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_equipment "\addlinespace \emph{Equipment}" capp_equipment, nolabel)

estpost tabstat pay_equipment if capp_equipment > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
	


// Purchase existing facilities
label variable capp_purchase "\hspace{0.5cm} Appropriations, millions"
label variable pay_purchase "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_purchase if capp_purchase > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_purchase "\addlinespace \emph{Purchases of existing facilities}" capp_purchase, nolabel)

estpost tabstat pay_purchase if capp_purchase > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline
	
	
// Homes for nurses
label variable capp_nurse_homes "\hspace{0.5cm} Appropriations, millions"
label variable pay_nurse_homes "\hspace{0.5cm} Payments, millions"

estpost tabstat capp_nurse_homes if capp_nurse_homes > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise
	
	esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(capp_nurse_homes "\addlinespace \emph{Homes for nurses}" capp_nurse_homes, nolabel)

estpost tabstat pay_nurse_homes if capp_nurse_homes > 0, ///
	statistics(mean sd min max N) columns(statistics) listwise

esttab . using "$PROJ_PATH/analysis/output/appendix/table_e1_het_summary.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
		nomtitle ///
		nonum ///
		label ///
		f ///
		alignment(S S) ///
		collabels(none) ///
		booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) mlabels(none)  noline


////////////////////////////////////////////////////////////////////////////////////////////////////
// Figure E1: Share of appropriations receiving first payment by years since appropriation
////////////////////////////////////////////////////////////////////////////////////////////////////

// Load cleaned capital appropriations data 
use "$PROJ_PATH/analysis/processed/data/duke/capital_expenditures/capital_appropriations_1927_1962.dta", clear

// Get first year of appropriation 
egen app_year = min(year), by(app_id)

// Restrict to appropriations made during main sample period
keep if statefip == 37 & app_year <= 1942

// Ensure nothing missing 
recode capp_all pay_all (mis = 0)

// Get first year of payment 
egen first_payment = min(year) if pay_all > 0, by(app_id)
egen pay_year = min(first_payment), by(app_id)

keep app_id app_year pay_year 
gduplicates drop

// Share received of payment
gen years_until_rec = pay_year - app_year
tab years_until_rec, m

replace years_until_rec = 2 if years_until_rec > 2 & !missing(years_until_rec)
replace years_until_rec = 4 if missing(years_until_rec)

gen count = 1 
gcollapse (sum) count, by(years_until_rec)
sum count 
gen share = count/r(sum)

replace share = share*100

gsort years_until_rec
gen rolling = sum(share)
gen str_amount = round(share, .1)

twoway ///
	|| bar share years_until_rec if years_until_rec < 4 , bcolor(gs7) ///
	|| bar share years_until_rec if years_until_rec == 4 , bcolor(gs3) ///
	|| scatter share years_until_rec, m(i) mlabel(str_amount) mlabposition(12) mlabsize(6) mlabcolor(black) ///
	xla(0 "0" 1 "1" 2 "2 to 4" 4 `" "Never receive" "payment" "', labsize(6) nogrid notick) ///
	yla(, angle(0) labsize(6) nogrid notick) ///
	xtitle("Years since first appropriation", size(6)) ///
	subtitle("Share of appropriations with first payment by" " ",  size(5) pos(11)) ///
	ytitle("") ///
	legend(off) ///
	xsize(8) ///
	graphregion(margin(r+5) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
	
graph export "$PROJ_PATH/analysis/output/appendix/figure_e1_share_rec_pay_by_years_since_app.pdf", replace


**********************************************************************************************
***** Create storage matrices
**********************************************************************************************
// Binary 
	// Each column is a subset, rows pooled
	mat bin_b = J(1,6,.) 
	mat bin_se = J(1,6,.) 
// Appropriations 
	// Each column is a subset, rows pooled
	mat app_b = J(1,6,.) 
	mat app_se = J(1,6,.) 
// Payments 
	// Each column is a subset, rows pooled
	mat pay_b = J(1,6,.) 
	mat pay_se = J(1,6,.)
	
*************************************************************************************************************************************
***** Figure E2: Heterogeneity in effects by funding type. Binary and then scaled by $ from Duke (appropriations and payments). *****
*************************************************************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

// Add Duke treatment 	
duketreat, treatvar(`treat') time(year) location(fips)

gen all_treat = treated
gen all_ever_treated = ever_treated

local j = 1

foreach z in all ex_nurse new_hosp addition equipment purchase { // nurse_homes
		
	capture drop post 
	capture drop time_treated 
	capture drop treated 
	capture drop ever_treated 
	
	// Generate DiD treatment variable
	duketreat, treatvar(capp_`z') time(year) location(fips)
	
	capture drop bad_include 
	gen bad_include = 0 
	replace bad_include = 1 if all_ever_treated == 1 & ever_treated == 0

	replace tot_pay_`z'_adj = 0 if missing(tot_pay_`z'_adj)
	replace tot_capp_`z'_adj = 0 if missing(tot_capp_`z'_adj)

	// Pooled
	local i = 1
	
	// Binary
	eststo pl_c0_`z': ppmlhdfe imr_pub 1.treated `baseline_controls' [pw = births_pub] if bad_include == 0, ///
		absorb(fips year) vce(cluster fips) 
	lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom_pois") statname("bin_pct_efct_")
	mat bin_b[`i', `j'] = e(bin_pct_efct_b_num)
	mat bin_se[`i', `j'] = e(bin_pct_efct_se_num)
	
	// Appropriations
	eststo pl_c1_`z': ppmlhdfe imr_pub tot_capp_`z'_adj `baseline_controls' [pw = births_pub] if bad_include == 0, ///
		absorb(fips year) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`z'_adj])-1), comtype("nlcom_pois") statname("app_pct_efct_")
	mat app_b[`i', `j'] = e(app_pct_efct_b_num)
	mat app_se[`i', `j'] = e(app_pct_efct_se_num)
	

	// Payments
	eststo pl_c2_`z': ppmlhdfe imr_pub tot_pay_`z'_adj `baseline_controls' [pw = births_pub] if bad_include == 0, ///
		absorb(fips year) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`z'_adj])-1), comtype("nlcom_pois") statname("pay_pct_efct_")
	mat pay_b[`i', `j'] = e(pay_pct_efct_b_num)
	mat pay_se[`i', `j'] = e(pay_pct_efct_se_num)
	
	local j = `j' + 1

}

// Coef. Plot
clear 

// Turn stored estimates into data in memory
svmat bin_b
svmat bin_se

svmat app_b
svmat app_se

svmat pay_b
svmat pay_se
  
// Add race indicator
gen race = 0
replace race = 1 in 1

// Reshape 
greshape long bin_b@ bin_se@ app_b@ app_se@ pay_b@ pay_se@, i(race) j(specification_type) 

// Create proper labels
gen race_label = ""
replace race_label = "Pooled" if race == 1
drop race

gen specification = ""
replace specification = "Base specification" if specification_type == 1
replace specification =  "Exclude homes for nurses" if specification_type == 2
replace specification =  "New hospitals/plants" if specification_type == 3
replace specification = "Additions" if specification_type == 4
replace specification = "Equipment" if specification_type == 5
replace specification = "Purchase of existing facility" if specification_type == 6

// Gen 95% CI
foreach x in bin app pay {
	gen `x'_low = `x'_b - 1.96*`x'_se
	gen `x'_high = `x'_b + 1.96*`x'_se
}

///////////////////////////////////////////////////////////////////
// Plots
* 7 `" "Homes for" "nurses" "'
// Binary
twoway ///
	|| rcap bin_low bin_high specification_type if race_label == "Pooled", lcol("230 65 115") lwidth(.75) msize(4) ///
	|| scatter bin_b specification_type if race_label == "Pooled", msymbol(O) msize(3.5) mcol("230 65 115") ///
	legend(off) ///
	ylab(-30(10)10, angle(0) nogrid notick labsize(5)) ///
	ytitle("") ///
	xlab(1 `" "Base" "specification" "' 2 `" "Exclude" "homes for nurses" "' 3 `" "New" "hospitals/plants" "' 4 `" "Additions" "'  5 `" "Equipment" "' 6 `" "Purchase of" "existing" "facility" "', ///
	nogrid notick labsize(4)) ///
	xtitle("") ///
	yline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(margin(r+5) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				title("{bf:Intent to treat (Duke = 1)}", size(7) pos(11)) ///
				subtitle("Pooled", size(5) pos(11)) 
		
*graph export "$PROJ_PATH/analysis/output/appendix/figure_e2a_bin_pooled.png", replace 
graph export "$PROJ_PATH/analysis/output/appendix/figure_e2a_bin_pooled.pdf", replace 


// Appropriations
twoway ///
	|| rcap app_low app_high specification_type if race_label == "Pooled", lcol("230 65 115") lwidth(.75) msize(4) ///
	|| scatter app_b specification_type if race_label == "Pooled", msymbol(O) msize(3.5) mcol("230 65 115") ///
	legend(off) ///
	ylab(-30(10)10, angle(0) nogrid notick labsize(5)) ///
	ytitle("") ///
	xlab(1 `" "Base" "specification" "' 2 `" "Exclude" "homes for nurses" "' 3 `" "New" "hospitals/plants" "' 4 `" "Additions" "'  5 `" "Equipment" "' 6 `" "Purchase of" "existing" "facility" "', ///
	nogrid notick labsize(4)) ///
	xtitle("") ///
	yline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(margin(r+5) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				title("{bf:Appropriations, effect of $1 million from Duke}", size(7) pos(11)) ///
				subtitle("Pooled", size(5) pos(11)) 

*graph export "$PROJ_PATH/analysis/output/appendix/figure_e2b_app_pooled.png", replace 
graph export "$PROJ_PATH/analysis/output/appendix/figure_e2b_app_pooled.pdf", replace 

	
// Payments
twoway ///
	|| rcap pay_low pay_high specification_type if race_label == "Pooled", lcol("230 65 115") lwidth(.75) msize(4) ///
	|| scatter pay_b specification_type if race_label == "Pooled", msymbol(O) msize(3.5) mcol("230 65 115") ///
	legend(off) ///
	ylab(-30(10)10, angle(0) nogrid notick labsize(5)) ///
	ytitle("") ///
	xlab(1 `" "Base" "specification" "' 2 `" "Exclude" "homes for nurses" "' 3 `" "New" "hospitals/plants" "' 4 `" "Additions" "'  5 `" "Equipment" "' 6 `" "Purchase of" "existing" "facility" "', ///
	nogrid notick labsize(4)) ///
	xtitle("") ///
	yline(0, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(margin(r+5) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				title("{bf:Payments, effect of $1 million from Duke}", size(7) pos(11)) ///
				subtitle("Pooled", size(5) pos(11)) 
				
*graph export "$PROJ_PATH/analysis/output/appendix/figure_e2c_pay_pooled.png", replace 
graph export "$PROJ_PATH/analysis/output/appendix/figure_e2c_pay_pooled.pdf", replace 


disp "DateTime: $S_DATE $S_TIME"

* EOF