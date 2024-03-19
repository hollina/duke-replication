version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_iv.do
* PURPOSE: Run analysis for Appendix Table J1 - Effect of Duke support on pooled infant mortality rate: Intensive margin instrumental variables estimates
************/


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

******************************************************************************
// Set-up IV
******************************************************************************

// Open AMA data
use  "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta" if year <= 1927, clear

// Restrict to North Carolina 
rename StateFIPS statefip 
keep if statefip == 37

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

merge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta",  assert(2 3) keep(3) keepusing(fips)

// Create an inidicator for each hospital with non-zero beds  
gen has_beds = 0 
replace has_beds = 1 if beds > 0 & !missing(beds)

// Collapse to create # of hospitals in each county-year (including non non-profit count)
gcollapse (sum) has_beds proprietary, by(statefip fips)

// Make indicator for any non-profit bed in county year
gen any_non_profit = 0
replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds

rename any_non_profit any_non_profit_1927
rename has_beds has_beds_1927
rename proprietary proprietary_1927

tempfile temp_hosp
save `temp_hosp', replace 

// Open returns data	
use "$PROJ_PATH/analysis/processed/intermediate/duke/returns_by_year.dta", clear

rename year_end year
merge 1:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) nogen

gen balance_adj = inv_inflation_factor*balance_net_of_corpus/1000000
gen dist_to_hosp_adj = inv_inflation_factor*distribution_to_hospitals/1000000

ipolate balance_adj year, gen(balance)
ipolate dist_to_hosp_adj year, gen(dist)

keep if year >= `year_start' & year <= `year_end'

keep year balance dist
gisid year
gsort year
gen c_balance = sum(balance)
gen c_dist = sum(dist)

tempfile temp_financials
save `temp_financials', replace 

// Infant mortality in short-run:  Set up infant mortality analysis - NC
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

// merge with returns 
merge m:1 year using "`temp_financials'", keep(1 3) nogen

replace c_balance = 0 if year == 1922
replace c_dist = 0 if year == 1922
replace c_balance = 0 if year == 1923
replace c_dist = 0 if year == 1923
replace c_balance = 0 if year == 1924
replace c_dist = 0 if year == 1924

//  Make indicatory for "control" counties in N.C.
merge m:1 fips using "`temp_hosp'", nogen

replace any_non_profit_1927 = 0 if missing(any_non_profit_1927)
replace has_beds_1927 = 0 if missing(has_beds_1927)
replace proprietary_1927 = 0 if missing(proprietary_1927)

// Generate infant mortality outcomes + generate weights 
replace mort = . if births_pub == 0

replace tot_pay_`treat_type'_adj = 0 if missing(tot_pay_`treat_type'_adj)
replace tot_capp_`treat_type'_adj = 0 if missing(tot_capp_`treat_type'_adj)

gen instrument = 0
replace instrument = c_balance/1000 if any_non_profit_1927 == 1

// Create dummy variables so I can use tf function later on
xi i.fips i.year

compress
save "$PROJ_PATH/analysis/processed/temp/iv_data.dta", replace
	
******************************************************************************
// Set-up IV for non-NC analysis
******************************************************************************

// Panel start and end dates
local sample_start 		1922
local sample_end 		1940

// Open AMA data
use  "$PROJ_PATH/analysis/raw/ama/aha_data_all_states.dta" if year <= 1927, clear

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

merge m:1 state county_nhgis using "$PROJ_PATH/analysis/processed/data/nhgis/nhgis_1900_1960_counties.dta",  assert(2 3) keep(3) keepusing(fips)

// Create an inidicator for each hospital with non-zero beds  
gen has_beds = 0 
replace has_beds = 1 if beds > 0 & !missing(beds)

// Collapse to create # of hospitals in each county-year (including non non-profit count)
gcollapse (sum) has_beds proprietary, by(statefip fips)

// Make indicator for any non-profit bed in county year
gen any_non_profit = 0
replace any_non_profit = 1 if has_beds > 0 & proprietary < has_beds

rename any_non_profit any_non_profit_1927
rename has_beds has_beds_1927
rename proprietary proprietary_1927

tempfile temp_hosp
save `temp_hosp', replace 

// Open returns data	
use "$PROJ_PATH/analysis/processed/intermediate/duke/returns_by_year.dta", clear

rename year_end year
merge 1:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", assert(2 3) nogen

gen balance_adj = inv_inflation_factor*balance_net_of_corpus/1000000
gen dist_to_hosp_adj = inv_inflation_factor*distribution_to_hospitals/1000000

ipolate balance_adj year, gen(balance)
ipolate dist_to_hosp_adj year, gen(dist)

keep if year >= `year_start' & year <= `year_end'

keep year balance dist
gisid year
gsort year
gen c_balance = sum(balance)
gen c_dist = sum(dist)

tempfile temp_financials
save `temp_financials', replace 

// Infant mortality in short-run:  Set up infant mortality analysis - Non-NC
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)
replace mort = . if births_pub == 0

// Append southern states 
append using "$PROJ_PATH/analysis/processed/data/pvf/southern_infant_deaths.dta"

// Restrict to IV years 
keep if year >= `sample_start' & year <= `sample_end'

// merge with returns 
merge m:1 year using "`temp_financials'"

replace c_balance = 0 if year == 1922
replace c_dist = 0 if year == 1922
replace c_balance = 0 if year == 1923
replace c_dist = 0 if year == 1923
replace c_balance = 0 if year == 1924
replace c_dist = 0 if year == 1924

//  Make indicatory for "control" counties in N.C.
merge m:1 fips using "`temp_hosp'", nogen

replace any_non_profit_1927 = 0 if missing(any_non_profit_1927)
replace has_beds_1927 = 0 if missing(has_beds_1927)
replace proprietary_1927 = 0 if missing(proprietary_1927)

// Generate infant mortality outcomes + generate weights 
replace mort = . if births_pub == 0

replace tot_pay_`treat_type'_adj = 0 if missing(tot_pay_`treat_type'_adj)
replace tot_capp_`treat_type'_adj = 0 if missing(tot_capp_`treat_type'_adj)

gen instrument = 0
replace instrument = c_balance/1000 if any_non_profit_1927 == 1 & statefip == 37

keep if any_non_profit_1927 == 1

// Create dummy variables so I can use tf function later on
xi i.fips i.year

compress
save "$PROJ_PATH/analysis/processed/temp/iv_data_non_NC.dta", replace
	
******************************************************************************
// Pooled 
******************************************************************************

use "$PROJ_PATH/analysis/processed/temp/iv_data_non_NC.dta", clear

// Blank regression for spacing in esttab 
eststo blank: reg tot_pay_`treat_type'_adj births_pub
estadd local N = "", replace

// Relation of two on one another. 
eststo pl_c1: reghdfe tot_pay_`treat_type'_adj tot_capp_`treat_type'_adj `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips)
lincomestadd2a _b[tot_capp_`treat_type'_adj], comtype("nlcom") statname("app_pay_")  specName(pl_c1)
		
// Poisson
	// Appropriations
	eststo pl_c2: ppmlhdfe imr_pub tot_capp_`treat_type'_adj  `baseline_controls' [pw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom_pois") statname("pct_efct_") specName(pl_c2)

	// Payments
	eststo pl_c3: ppmlhdfe imr_pub tot_pay_`treat_type'_adj  `baseline_controls' [pw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom_pois") statname("pct_efct_")  specName(pl_c3)

// OLS with ln(x)
	// Appropriations
	eststo pl_c4: reghdfe ln_imr_pub tot_capp_`treat_type'_adj  `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c4)

	// Payments
	eststo pl_c5: reghdfe ln_imr_pub tot_pay_`treat_type'_adj  `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c5)

// Reduced form 
	// Appropriations
	eststo pl_c10: reghdfe  ln_imr_pub instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c10)
	test instrument

	// Payments
	eststo pl_c11: reghdfe  ln_imr_pub instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c11)
	test instrument
			

// First stage
	// Appropriations
	eststo pl_c6: reghdfe  tot_capp_`treat_type'_adj instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 1*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c6)
	test instrument

	// Payments
	eststo pl_c7: reghdfe  tot_pay_`treat_type'_adj instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 1*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c7)
	test instrument
			
// 2SLS
	// Appropriations
	eststo pl_c8: ivreghdfe ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument)  [aw = births_pub], ///
		absorb(fips year ) cluster(fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c8)

		// AR Confidence set
		weakiv ivreg2 ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local ar_cs = e(ar_cset)
		local lower = 100*(exp(real(substr("`ar_cs'", strrpos("`ar_cs'", ",") + 1,  strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ll : di %04.2f `lower'
		local higher = 100*(exp(real(substr("`ar_cs'", 2, strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ul : di %04.2f `higher'
		local ar_p = e(ar_p)
		local stars ""
			if `ar_p' < 0.10 local stars \sym{*}
			if `ar_p' < 0.05 local stars \sym{**}
			if `ar_p' < 0.01 local stars \sym{***}
		local space ""
			if `ar_p' < 0.10 local space ~
			if `ar_p' < 0.05 local space ~~
			if `ar_p' < 0.01 local space ~~~

		local ar_string `space'[`ar_ul', `ar_ll']`stars'
		estadd local ar_ci "`ar_string'": pl_c8

		// tF ratio
		tf ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local tf_lower = 100*(exp(real(e(tF_LB_05)))-1)
		local tf_ll : di %04.2f `tf_lower'
		local tf_higher = 100*(exp(real(e(tF_UB_05)))-1)
		local tf_ul : di %04.2f `tf_higher'
		local tf_p = 2*ttail(99, abs(real(e(beta_hat)))/real(e(tF_se_beta_hat_05)))
		local tf_stars ""
			if `tf_p' < 0.10 local tf_stars \sym{*}
			if `tf_p' < 0.05 local tf_stars \sym{**}
			if `tf_p' < 0.01 local tf_stars \sym{***}

		local tf_space ""
			if `tf_p' < 0.10 local tf_space ~
			if `tf_p' < 0.05 local tf_space ~~
			if `tf_p' < 0.01 local tf_space ~~~

		local tf_string `tf_space'[`tf_ll', `tf_ul']`tf_stars'
		estadd local tf_ci "`tf_string'": pl_c8


	// Payments
	eststo pl_c9: ivreghdfe ln_imr_pub   `baseline_controls' (tot_pay_`treat_type'_adj=instrument)  [aw = births_pub], ///
		absorb(fips year ) cluster(fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_") specName(pl_c9)

		weakiv ivreg2 ln_imr_pub `baseline_controls'  (tot_pay_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local ar_cs = e(ar_cset)
		local lower = 100*(exp(real(substr("`ar_cs'", strrpos("`ar_cs'", ",") + 1,  strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ll : di %04.2f `lower'
		local higher = 100*(exp(real(substr("`ar_cs'", 2, strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ul : di %04.2f `higher'
		local ar_p = e(ar_p)
		local stars ""
			if `ar_p' < 0.10 local stars \sym{*}
			if `ar_p' < 0.05 local stars \sym{**}
			if `ar_p' < 0.01 local stars \sym{***}

		local space ""
			if `ar_p' < 0.10 local space ~
			if `ar_p' < 0.05 local space ~~
			if `ar_p' < 0.01 local space ~~~

		local ar_string `space'[`ar_ul', `ar_ll']`stars'
		estadd local ar_ci "`ar_string'": pl_c9

	// tF ratio
		tf ln_imr_pub `baseline_controls'  (tot_pay_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local tf_lower = 100*(exp(real(e(tF_LB_05)))-1)
		local tf_ll : di %04.2f `tf_lower'
		local tf_higher = 100*(exp(real(e(tF_UB_05)))-1)
		local tf_ul : di %04.2f `tf_higher'
		local tf_p = 2*ttail(99, abs(real(e(beta_hat)))/real(e(tF_se_beta_hat_05)))
		local tf_stars ""
			if `tf_p' < 0.10 local tf_stars \sym{*}
			if `tf_p' < 0.05 local tf_stars \sym{**}
			if `tf_p' < 0.01 local tf_stars \sym{***}
		local tf_space ""
			if `tf_p' < 0.10 local tf_space ~
			if `tf_p' < 0.05 local tf_space ~~
			if `tf_p' < 0.01 local tf_space ~~~

		local tf_string `tf_space'[`tf_ll', `tf_ul']`tf_stars'
		estadd local tf_ci "`tf_string'": pl_c9

///////////////////////////////////////////////////////////////////////////////
// Export

   // Formation
   	local y_0 `"\$ Y^{R}_{ct} $:~~~~~"'
   	local y_1 `"IMR"'
   	local y_2 `"ln(IMR)"'
	local y_3 `"Appropriations"'
	local y_4 `"Payments"'
	local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{~} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} & \multicolumn{1}{c}{(8)} & \multicolumn{1}{c}{(9)} & \multicolumn{1}{c}{(10)}  \\ "
	local titles_main2 "\multicolumn{1}{r}{Specification:~~~~~ } & \multicolumn{1}{c}{\shortstack{Poisson}} & \multicolumn{1}{c}{\shortstack{OLS}} & \multicolumn{1}{c}{\shortstack{First stage}} & \multicolumn{1}{c}{\shortstack{Reduced form}}  & \multicolumn{1}{c}{IV} & \multicolumn{1}{c}{\hspace{.5in}~}  & \multicolumn{1}{c}{\shortstack{Poisson}} &\multicolumn{1}{c}{\shortstack{OLS}} &\multicolumn{1}{c}{\shortstack{First stage}} & \multicolumn{1}{c}{\shortstack{Reduced form}}  & \multicolumn{1}{c}{IV} \\"
	local titles_main3 "\multicolumn{1}{r}{`y_0'} & \multicolumn{1}{c}{`y_1'} & \multicolumn{1}{c}{`y_2'} & \multicolumn{1}{c}{`y_3'} & \multicolumn{1}{c}{`y_2'}  & \multicolumn{1}{c}{`y_2'} & \multicolumn{1}{c}{\hspace{.5in}~}  & \multicolumn{1}{c}{`y_1'} & \multicolumn{1}{c}{`y_2'} & \multicolumn{1}{c}{`y_4'} & \multicolumn{1}{c}{`y_2'}  & \multicolumn{1}{c}{`y_2'} \\"
	local midrules "&\multicolumn{5}{c}{Appropriations}                               &\multicolumn{1}{c}{} &\multicolumn{5}{c}{Payments}                                     \\\cmidrule(lr){2-6}\cmidrule(lr){8-12}"
	
	// Make top panel
	esttab  pl_c2 pl_c4 pl_c6 pl_c10 pl_c8  blank pl_c3 pl_c5 pl_c7  pl_c11 pl_c9 ///
	  using "$PROJ_PATH/analysis/output/appendix/table_j1_iv_pooled_imr_intensive.tex", `booktabs_default_options' replace ///
	  posthead("`midrules' `titles_main2' `numbers_main' `titles_main3' ") ///
	  stats(pct_efct_b pct_efct_se ar_ci tf_ci first_stage_b first_stage_se   N, fmt(0 0 0 0 0 0 %9.0fc) labels("\midrule \emph{A. Southern counties with non-profit hospital (1922-1940)} &&&&&&&&& \\ \addlinespace\addlinespace\hspace{.5cm}  Percent effect from \\$1 million of Duke support" "~" "\hspace{1cm}  Anderson-Rubin 95\% Confidence Set" "\hspace{1cm}  tF 95\% Confidence Interval" "\addlinespace\addlinespace\hspace{.5cm} (Endowment returns, billions) X 1(Non-profit hospital before Duke)" "~" "\addlinespace\addlinespace\hspace{.5cm} Observations") layout(@ @  @ @ "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"))


//////////////////////////////////////////////////////////////////////////////////
// Pooled 
//////////////////////////////////////////////////////////////////////////////////

use "$PROJ_PATH/analysis/processed/temp/iv_data.dta", clear

// Blank regression for spacing in esttab 
eststo blank: reg tot_pay_`treat_type'_adj births_pub
estadd local N = "", replace

//////////////////////////////////////////////////////////////////////////////////
// Pooled 
//////////////////////////////////////////////////////////////////////////////////

// Relation of two on one another. 
eststo pl_c1: reghdfe tot_pay_`treat_type'_adj tot_capp_`treat_type'_adj `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips)
lincomestadd2a _b[tot_capp_`treat_type'_adj], comtype("nlcom") statname("app_pay_")  specName(pl_c1)
		
// Poisson
	// Appropriations
	eststo pl_c2: ppmlhdfe imr_pub tot_capp_`treat_type'_adj  `baseline_controls' [pw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom_pois") statname("pct_efct_") specName(pl_c2)

	// Payments
	eststo pl_c3: ppmlhdfe imr_pub tot_pay_`treat_type'_adj  `baseline_controls' [pw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom_pois") statname("pct_efct_")  specName(pl_c3)

// OLS with ln(x)
	// Appropriations
	eststo pl_c4: reghdfe ln_imr_pub tot_capp_`treat_type'_adj  `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c4)

	// Payments
	eststo pl_c5: reghdfe ln_imr_pub tot_pay_`treat_type'_adj  `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c5)

// Reduced form 
	// Appropriations
	eststo pl_c10: reghdfe  ln_imr_pub instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c10)
	test instrument

	// Payments
	eststo pl_c11: reghdfe  ln_imr_pub instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 100*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c11)
	test instrument
			

// First stage
	// Appropriations
	eststo pl_c6: reghdfe  tot_capp_`treat_type'_adj instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 1*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c6)
	test instrument

	// Payments
	eststo pl_c7: reghdfe  tot_pay_`treat_type'_adj instrument `baseline_controls' [aw = births_pub], ///
		absorb(fips year ) vce(cluster fips)  
	lincomestadd2a 1*(exp(_b[instrument])-1), comtype("nlcom") statname("first_stage_")  specName(pl_c7)
	test instrument
			
// 2SLS
	// Appropriations
	eststo pl_c8: ivreghdfe ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument)  [aw = births_pub], ///
		absorb(fips year ) cluster(fips)  
	lincomestadd2a 100*(exp(_b[tot_capp_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_")  specName(pl_c8)

		// AR Confidence set
		weakiv ivreg2 ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local ar_cs = e(ar_cset)
		local lower = 100*(exp(real(substr("`ar_cs'", strrpos("`ar_cs'", ",") + 1,  strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ll : di %04.2f `lower'
		local higher = 100*(exp(real(substr("`ar_cs'", 2, strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ul : di %04.2f `higher'
		local ar_p = e(ar_p)
		local stars ""
			if `ar_p' < 0.10 local stars \sym{*}
			if `ar_p' < 0.05 local stars \sym{**}
			if `ar_p' < 0.01 local stars \sym{***}
		local space ""
			if `ar_p' < 0.10 local space ~
			if `ar_p' < 0.05 local space ~~
			if `ar_p' < 0.01 local space ~~~

		local ar_string `space'[`ar_ul', `ar_ll']`stars'
		estadd local ar_ci "`ar_string'": pl_c8

		// tF ratio
		tf ln_imr_pub `baseline_controls'  (tot_capp_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local tf_lower = 100*(exp(real(e(tF_LB_05)))-1)
		local tf_ll : di %04.2f `tf_lower'
		local tf_higher = 100*(exp(real(e(tF_UB_05)))-1)
		local tf_ul : di %04.2f `tf_higher'
		local tf_p = 2*ttail(99, abs(real(e(beta_hat)))/real(e(tF_se_beta_hat_05)))
		local tf_stars ""
			if `tf_p' < 0.10 local tf_stars \sym{*}
			if `tf_p' < 0.05 local tf_stars \sym{**}
			if `tf_p' < 0.01 local tf_stars \sym{***}

		local tf_space ""
			if `tf_p' < 0.10 local tf_space ~
			if `tf_p' < 0.05 local tf_space ~~
			if `tf_p' < 0.01 local tf_space ~~~

		local tf_string `tf_space'[`tf_ll', `tf_ul']`tf_stars'
		estadd local tf_ci "`tf_string'": pl_c8


	// Payments
	eststo pl_c9: ivreghdfe ln_imr_pub   `baseline_controls' (tot_pay_`treat_type'_adj=instrument)  [aw = births_pub], ///
		absorb(fips year ) cluster(fips)  
	lincomestadd2a 100*(exp(_b[tot_pay_`treat_type'_adj])-1), comtype("nlcom") statname("pct_efct_") specName(pl_c9)

		weakiv ivreg2 ln_imr_pub `baseline_controls'  (tot_pay_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local ar_cs = e(ar_cset)
		local lower = 100*(exp(real(substr("`ar_cs'", strrpos("`ar_cs'", ",") + 1,  strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ll : di %04.2f `lower'
		local higher = 100*(exp(real(substr("`ar_cs'", 2, strrpos("`ar_cs'", ",")-2)))-1)
		local ar_ul : di %04.2f `higher'
		local ar_p = e(ar_p)
		local stars ""
			if `ar_p' < 0.10 local stars \sym{*}
			if `ar_p' < 0.05 local stars \sym{**}
			if `ar_p' < 0.01 local stars \sym{***}

		local space ""
			if `ar_p' < 0.10 local space ~
			if `ar_p' < 0.05 local space ~~
			if `ar_p' < 0.01 local space ~~~

		local ar_string `space'[`ar_ul', `ar_ll']`stars'
		estadd local ar_ci "`ar_string'": pl_c9

	// tF ratio
		tf ln_imr_pub `baseline_controls'  (tot_pay_`treat_type'_adj=instrument) _I*  [aw = births_pub], ///
		cluster(fips)
		local tf_lower = 100*(exp(real(e(tF_LB_05)))-1)
		local tf_ll : di %04.2f `tf_lower'
		local tf_higher = 100*(exp(real(e(tF_UB_05)))-1)
		local tf_ul : di %04.2f `tf_higher'
		local tf_p = 2*ttail(99, abs(real(e(beta_hat)))/real(e(tF_se_beta_hat_05)))
		local tf_stars ""
			if `tf_p' < 0.10 local tf_stars \sym{*}
			if `tf_p' < 0.05 local tf_stars \sym{**}
			if `tf_p' < 0.01 local tf_stars \sym{***}
		local tf_space ""
			if `tf_p' < 0.10 local tf_space ~
			if `tf_p' < 0.05 local tf_space ~~
			if `tf_p' < 0.01 local tf_space ~~~

		local tf_string `tf_space'[`tf_ll', `tf_ul']`tf_stars'
		estadd local tf_ci "`tf_string'": pl_c9

///////////////////////////////////////////////////////////////////////////////
// Export

 	// Add to top panel
	esttab  pl_c2 pl_c4 pl_c6 pl_c10 pl_c8  blank pl_c3 pl_c5 pl_c7  pl_c11 pl_c9 ///
	  using "$PROJ_PATH/analysis/output/appendix/table_j1_iv_pooled_imr_intensive.tex", `booktabs_default_options' append ///
	  stats(pct_efct_b pct_efct_se ar_ci tf_ci first_stage_b first_stage_se   N, fmt(0 0 0 0 0 0 %9.0fc) labels("\midrule \emph{B. All NC counties (1922-1940)} &&&&&&&&& \\ \addlinespace\addlinespace\hspace{.5cm}  Percent effect from \\$1 million of Duke support" "~" "\hspace{1cm}  Anderson-Rubin 95\% Confidence Set" "\hspace{1cm}  tF 95\% Confidence Interval" "\addlinespace\addlinespace\hspace{.5cm} (Endowment returns, billions) X 1(Non-profit hospital before Duke)" "~" "\addlinespace\addlinespace\hspace{.5cm} Observations") layout(@ @  @ @ "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"))
	  
rm "$PROJ_PATH/analysis/processed/temp/iv_data.dta"
rm "$PROJ_PATH/analysis/processed/temp/iv_data_non_NC.dta"

cap rm "$PROJ_PATH/IV_CriticalValues_matrix_95.mmat"
cap rm "$PROJ_PATH/IV_CriticalValues_matrix_99.mmat"


local top_trim_list 900 750 500  
foreach top_trim in `top_trim_list' {	
	forvalues x = 1(1)4 {
		forvalues y = 1(1)3 {
			cap rm "$PROJ_PATH/analysis/processed/temp/psm_`top_trim'_cc_sr_p`x'_c`y'.ster"
		}
	}
}


disp "DateTime: $S_DATE $S_TIME"

* EOF
