version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_other_results.do
* PURPOSE: Run regressions for Appendix G - Other results
************/

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

// Duke treatment variable 
local treat 		"capp_all"

****************************************************************************
***** Specification chart: Robustness in dropping small counties - IMR *****
****************************************************************************

// Set seed in case there are ties in the ranking (, unique option solves ties "arbitrarily")
set seed 12345

// Rank counties by average birth size  
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

bysort fips: egen mean_births = mean(births_pub)
bysort fips: keep if _n == 1
egen rank_births = rank(mean_births), unique

keep fips rank_births
gsort rank_births

// Save file to be merged
tempfile county_size
save `county_size', replace
		
// Merge ranking onto data
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear
fmerge m:1 fips using `county_size', nogen

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

// Gradually drop more small counties 
forvalues x = 0(5)50 {
	
	keep if rank_births > `x'
	
	ppmlhdfe imr_pub b0.treated `baseline_controls' [pw = births_pub], absorb(fips year) cluster(fips)
	di "`e(cmdline)'"
	lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_") ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, drop smallest counties, `x'") ///
		store_group("pool")

}

*****************************************************************************************
// Appendix Table G1 - Balancing test: Effects of Duke support on control variables *****
*****************************************************************************************

// Load infant mortality data 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear
local balance_controls "percent_illit percent_black percent_urban retail_sales_per_capita chd_presence"

// Drop counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
drop if ever_zero_births != 0

// Label baseline_controls for table
label var percent_illit "\addlinespace\hspace{.5cm}\% Illiterate"
label var percent_black "\hspace{.5cm}\% Black"
label var percent_other_race "\hspace{.5cm}\% Other Race"
label var percent_urban "\hspace{.5cm}\% Urban"
label var retail_sales_per_capita "\hspace{.5cm} Retail sales per capita"
label var chd_presence "\hspace{.5cm} County health department present (=1)"

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Store the number of baseline_controls
local length_of_cov: list sizeof local(balance_controls)
di "`length_of_cov'"

// Get the standard deviations
mean `balance_controls'
estat sd
matrix csd = r(sd)'
eststo csd 
mat list csd

// Make a place to store the coefficients
matrix define meanDiff_betas = J(`length_of_cov', 1, .)
matrix define meanDiff_betas_se = J(`length_of_cov', 1, .)
matrix define meanDiff_betas_p = J(`length_of_cov', 1, .)
matrix define meanDiff_betas_N = J(`length_of_cov', 1, .)

// Now get regression adjusted mean differences
local count = 0

foreach y of local balance_controls {
	local count = `count' + 1
	
	ppmlhdfe `y' b0.treated  [pw = births_pub], ///
	absorb(fips year ) vce(cluster fips)  
	
	nlcom 100*(exp(_b[1.treated])-1)
	mat b = r(b)
	mat V = r(V)

	scalar b = b[1,1]
	matrix meanDiff_betas[`count',1] = b 
	scalar se_v2 = sqrt(V[1,1])
	matrix meanDiff_betas_se[`count',1] = se_v2

	scalar p_val = 2*ttail(`e(df)',abs(b/se_v2))
	matrix meanDiff_betas_p[`count',1] = p_val
	
	matrix meanDiff_betas_N[`count',1] = `e(N)'

	// Round estimates to whatever place we need
	scalar rm_rounded_estimate = round(b,.01)
	local rm_rounded_estimate : di %3.2f rm_rounded_estimate
	scalar rm_string_estimate = "`rm_rounded_estimate'"

	// Round standard errors
	scalar rm_rounded_se = round(se_v2,.01)
	local rm_rounded_se : di %3.2f rm_rounded_se
	scalar rm_string_se = "("+"`rm_rounded_se'"+")"

	// Add stars for significance 
	if p_val <= .01	{
		scalar rm_string_estimate = rm_string_estimate + "\nlsym{3}"
	}	

	if p_val>.01 & p_val<=.05 {
		scalar rm_string_estimate = rm_string_estimate + "\nlsym{2}"
	}

	if  p_val>.05 & p_val<=.1 {
		scalar rm_string_estimate = rm_string_estimate + "\nlsym{1}"
	}
	
	else {
		scalar rm_string_estimate = rm_string_estimate 
	}			
			
	// Add the results
	estadd local rm_b_str =rm_string_estimate
	estadd local rm_se_str =rm_string_se	
	
	est sto m1_`y'


}

// Check to see if it worked
matrix list meanDiff_betas
matrix list meanDiff_betas_se
matrix list meanDiff_betas_p
matrix list meanDiff_betas_N

local count = 0
foreach y of local balance_controls {
	local count = `count' + 1
	
	ppmlhdfe `y' b0.treated  [pw = births_pub], ///
	absorb(fips year ) vce(cluster fips)  	
	
	// Calculate Cohen's d diff
	scalar cohen_d = meanDiff_betas[`count',1] / csd[`count',1]
	scalar cohen_d_rounded_estimate = round(cohen_d,.01)
	local cohen_d_rounded_estimate : di %3.2f cohen_d_rounded_estimate
	scalar cohen_d_string_estimate = "`cohen_d_rounded_estimate'"
	estadd local rm_b_str =cohen_d_string_estimate

	est sto m2_`y'

}

// Check to see if it worked
matrix list meanDiff_betas
matrix list meanDiff_betas_se
matrix list meanDiff_betas_p
matrix list meanDiff_betas_N

// Compute Cohen's D and store it in a matrix
matrix cohensD = J(`length_of_cov', 1, .)
forvalues j = 1(1)`length_of_cov'{
	matrix cohensD[`j', 1] = meanDiff_betas[`j',1] / csd[`j',1]
}
matrix list cohensD

// Store the cohen's D as a model
matrix d = cohensD'
matrix colnames d = `balance_controls'
ereturn post d
eststo d

// Store the coeffients as a model
matrix beta = meanDiff_betas'
matrix colnames beta = `balance_controls'
ereturn post beta
eststo beta

// Store the se as a model
matrix se = meanDiff_betas_se'
matrix colnames se = `balance_controls'
ereturn post se
eststo se

// Store the p_val as a model
matrix p_val = meanDiff_betas_p'
matrix colnames p_val = `balance_controls'
ereturn post p_val
eststo p_val

// Store the N as a model 
matrix bigN = meanDiff_betas_N'
matrix colnames bigN = `balance_controls'
ereturn post bigN
eststo bigN

// Load data
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)

// Regress Duke on baseline_controls
reghdfe treated `balance_controls' [aw = births_pub], absorb(fips year) vce(cluster fips)  

test percent_illit = percent_black = percent_urban = retail_sales_per_capita = chd_presence = 0
return list
estadd scalar joint_p = r(p) : p_val 

// Label balance_controls for table
label var percent_illit "\addlinespace\hspace{.5cm}\% Illiterate"
label var percent_black "\hspace{.5cm}\% Black"
label var percent_other_race "\hspace{.5cm}\% Other Race"
label var percent_urban "\hspace{.5cm}\% Urban"
label var retail_sales_per_capita "\hspace{.5cm} Retail sales per capita"
label var chd_presence "\hspace{.5cm} County health department present (=1)"

// Make table
esttab beta p_val using "$PROJ_PATH/analysis/output/appendix/table_g1_covariance_balance_test.tex" ///
		,star(* 0.10 ** 0.05 *** .01)  ///
		se ///
		b(%9.2f) ///
		booktabs ///
		f ///
		replace  ///
		mtitles("Mean \% difference" "p-value") ///
		label /// 
		noobs ///
		posthead("\midrule\addlinespace\emph{A. Pei et al. (2019) balancing test} && \\") ///
		prefoot("") /// 
		stats(joint_p, fmt(%9.3f) labels("\emph{B. F-Test for joint significance of controls} && \\ \addlinespace\hspace{.5cm} p-value") layout("\multicolumn{1}{c}{@}"))
		
		
**********************************************************************************************************
// Appendix Table G2 - Extensive margin intent-to-treat effect of Duke support on maternal mortality *****
**********************************************************************************************************

// Load data
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Start in 1932 since first year when MMR by residence is reported 
keep if year >= 1932 

// Generate maternal mortality variables
// gen maternal_deaths = mmr*births_pub
// gen maternal_deaths_res = mmr_res*births_pub

gen mmr = maternal_deaths*1000/pop_fem 
gen mmr_res = maternal_deaths_res*1000/pop_fem 

// Panel A - By place of death

// First. Poisson, without accounting for population. 
eststo p1_c1: ppmlhdfe maternal_deaths b0.treated, absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p1_c2: ppmlhdfe maternal_deaths b0.treated [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p1_c3: ppmlhdfe maternal_deaths b0.treated `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
	
// First. Poisson, without accounting for population. 
eststo p1_c1a: ppmlhdfe mmr b0.treated, absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Second. Poisson, with weights
eststo p1_c2a: ppmlhdfe mmr b0.treated [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p1_c3a: ppmlhdfe mmr b0.treated `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	

// Panel B - By place of residence

// First. Poisson, without accounting for population. 
eststo p2_c1: ppmlhdfe maternal_deaths_res b0.treated, absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p2_c2: ppmlhdfe maternal_deaths_res b0.treated [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p2_c3: ppmlhdfe maternal_deaths_res b0.treated `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// First. Poisson, without accounting for population. 
eststo p2_c1a: ppmlhdfe mmr_res b0.treated, absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p2_c2a: ppmlhdfe mmr_res b0.treated [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p2_c3a: ppmlhdfe mmr_res b0.treated `baseline_controls' [pw = births_pub], absorb(fips year) vce(cluster fips) sep(fe)
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")


// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
local titles "& \multicolumn{3}{c}{\shortstack{Number of Deaths}} & \multicolumn{3}{c}{\shortstack{Death rate per 1,000 women}}  \\"
local midrule "\cmidrule(lr){2-4}\cmidrule(lr){5-7}"

// Make top panel - Maternal mortality rate by place of occurrence
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c1a p1_c2a p1_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g2_maternal_mortality_diff_specs.tex", `booktabs_default_options' replace 
posthead("`titles' `midrule' `numbers_main' ")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Maternal mortality} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Maternal mortality race by place of residence
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c1a p2_c2a p2_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g2_maternal_mortality_diff_specs.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Maternal mortality, resident} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule 
	County of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}\\ 
	Year of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}\\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}\\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}\\");
#delimit cr


*************************************************************************************************
// Appendix Table G3 - Extensive margin intent-to-treat effect of Duke support on fertility *****
*************************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate fertility (births per 1,000 women)
gen tfr = births_pub*1000/pop_fem

// Labels
la var tfr "Pooled total fertility rate per 1,000 population"

// tfr by race - black
gen tfr_bk = births_pub_bk*1000/pop_fem_bk

// tfr by race - white
gen tfr_wt = births_pub_wt*1000/pop_fem_wt

// Label variables
la var tfr_wt "White total fertility rate per 1,000 population"
la var tfr_bk "Black total fertility rate per 1,000 population"

// Flag counties with black or white population ever equal to zero
egen ever_zero_pop_fem = max(pop_fem_bk == 0 | pop_fem_wt == 0), by(fips)
tab ever_zero_pop_fem



// Panel A - Pooled

// First. Poisson, without accounting for population. 
eststo p1_c1: ppmlhdfe births_pub b0.treated, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p1_c2: ppmlhdfe births_pub b0.treated [pw = pop_fem], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p1_c3: ppmlhdfe births_pub b0.treated `baseline_controls' [pw = pop_fem], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
	
// First. Poisson, without accounting for population. 
eststo p1_c1a: ppmlhdfe tfr b0.treated, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p1_c2a: ppmlhdfe tfr b0.treated [pw = pop_fem], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p1_c3a: ppmlhdfe tfr b0.treated `baseline_controls' [pw = pop_fem], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	

// Panel B - Black fertility rate

// First. Poisson, without accounting for population. 
eststo p2_c1: ppmlhdfe births_pub_bk b0.treated if ever_zero_pop_fem == 0, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p2_c2: ppmlhdfe births_pub_bk b0.treated if ever_zero_pop_fem == 0 [pw = pop_fem_bk], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p2_c3: ppmlhdfe births_pub_bk b0.treated `baseline_controls' if ever_zero_pop_fem == 0 [pw = pop_fem_bk], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	

eststo p2_c1a: ppmlhdfe tfr_bk b0.treated if ever_zero_pop_fem == 0, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
eststo p2_c2a: ppmlhdfe tfr_bk b0.treated if ever_zero_pop_fem == 0 [pw = pop_fem_bk], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

eststo p2_c3a: ppmlhdfe tfr_bk b0.treated `baseline_controls' if ever_zero_pop_fem == 0 [pw = pop_fem_bk], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	

// Panel C - White fertility rate

// First. Poisson, without accounting for population. 
eststo p3_c1: ppmlhdfe births_pub_wt b0.treated if ever_zero_pop_fem == 0, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
// Second. Poisson, with weights
eststo p3_c2: ppmlhdfe births_pub_wt b0.treated if ever_zero_pop_fem == 0 [pw = pop_fem_wt], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

// Third. Poisson, with weights and controls. 
eststo p3_c3: ppmlhdfe births_pub_wt b0.treated `baseline_controls' if ever_zero_pop_fem == 0 [pw = pop_fem_wt], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
eststo p3_c1a: ppmlhdfe tfr_wt b0.treated if ever_zero_pop_fem == 0, absorb(fips year) vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
	
eststo p3_c2a: ppmlhdfe tfr_wt b0.treated if ever_zero_pop_fem == 0 [pw = pop_fem_wt], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

eststo p3_c3a: ppmlhdfe tfr_wt b0.treated `baseline_controls' if ever_zero_pop_fem == 0 [pw = pop_fem_wt], absorb(fips year) vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")

keep if ever_zero_pop_fem == 0

// Reshape dataset to do analysis by race
keep tfr_* pop_fem_* births_pub_* treated fips year `baseline_controls'
greshape long tfr_@ pop_fem_@ births_pub_@, i(fips year) j(race_str) string

	gen race = . 
	replace race = 1 if race_str == "wt"
	replace race = 2 if race_str == "bk"

	drop race_str

	local absorb "fips year"

	// Interact variables to be absorbed with race
	local n_absorb : word count `absorb'

	forvalues j = 1(1)`n_absorb' {
		
		local temp_absorb "`temp_absorb' `: word `j' of `absorb''##i.race"
	}
	
	local absorb "`temp_absorb'"
			
	// Create list of controls interacted with race
	local n_controls : word count `baseline_controls'
	
	forvalues j = 1(1)`n_controls' {
	
		// Check if control is binary
		capture assert missing(`: word `j' of `baseline_controls'') | inlist(`: word `j' of `baseline_controls'', 0, 1)
		
		if _rc == 0 {
			local prefix ""
		}
		else {
			local prefix "#c."
		}
	
		local interacted_controls "`interacted_controls' i.race#`prefix'`: word `j' of `baseline_controls''"
	}

// Estimate mortality rate for the untreated
sum tfr_ if treated == 0 & race == 2 [aw = pop_fem_]
local mean_untr_bk = r(mean)

sum tfr_ if treated == 0 [aw = pop_fem_]
local mean_untr = r(mean)

// Panel D - Pooled, Fully Interacted

// First. Poisson, without accounting for population. 
eststo p4_c1: ppmlhdfe births_pub_ b0.treated##i.race, absorb(`absorb' `interacted_controls') vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'

// Second. Poisson, with weights
eststo p4_c2: ppmlhdfe births_pub_ b0.treated##i.race [pw = pop_fem_], absorb(`absorb' `interacted_controls') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'

// Third. Poisson, with weights and controls. 
eststo p4_c3: ppmlhdfe births_pub_ b0.treated##i.race [pw = pop_fem_], absorb(`absorb' `interacted_controls') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'
	
eststo p4_c1a: ppmlhdfe tfr_ b0.treated##i.race, absorb(`absorb' `interacted_controls') vce(cluster fips) 
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'
	
eststo p4_c2a: ppmlhdfe tfr_ b0.treated##i.race [pw = pop_fem_], absorb(`absorb' `interacted_controls') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'
	
eststo p4_c3a: ppmlhdfe tfr_ b0.treated##i.race [pw = pop_fem_], absorb(`absorb' `interacted_controls') vce(cluster fips)  
lincomestadd2a 100*(exp(_b[1.treated])-1), comtype("nlcom") statname("pct_efct_")
lincomestadd2a 100*(exp(_b[1.treated#2.race])-1), comtype("nlcom") statname("int_pct_efct_")
	testnl   exp(_b[1.treated#2.race])-1 = 0
	local  int_p_value = r(p) 
	estadd scalar int_p_value = `int_p_value'


// Prepare table
local numbers_main_long "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"
local midrule "\cmidrule(lr){2-4}\cmidrule(lr){5-7}"
local titles "& \multicolumn{3}{c}{\shortstack{Number of Births}} & \multicolumn{3}{c}{\shortstack{Births per 1,000 women}}  \\"

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c1a p1_c2a p1_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g3_short_run_fertility_diff_specs.tex", `booktabs_default_options' replace 
posthead("`titles' `midrule' `numbers_main_long' ")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled births} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c1 p2_c2a p2_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g3_short_run_fertility_diff_specs.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black births} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 p3_c1a p3_c2a p3_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g3_short_run_fertility_diff_specs.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White births} &&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 p4_c1a p4_c2a p4_c3a
 using "$PROJ_PATH/analysis/output/appendix/table_g3_short_run_fertility_diff_specs.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\ 
	Year of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes}& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes}  \\");
#delimit cr


*************************************************************************************************
***** Appendix Table G5: Effect of Duke support on infant mortality rate by timing of death *****
*************************************************************************************************

// Make list of birth types
local imr_list "day_0 day_1to365 week_2to52 month_2to12"
tokenize `imr_list'

// Panel A - Pooled 
forvalues i = 1(1)4 {
	
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate DiD treatment variable
	duketreat, treatvar(`treat') time(year) location(fips)
	
	// Generate infant mortality outcomes 
	imdata, mort(mort_``i'') suffix(pub)
	
	// Get death type
	if `i' == 1 {
		local lbl "Include only deaths in first 24 hours"
	}
	if `i' == 2 {
		local lbl "Exclude deaths in first 24 hours"
	}
	if `i' == 3 {
		local lbl "Exclude deaths in first week"
	}
	if `i' == 4 {
		local lbl "Exclude deaths in first month"
	}
	// Poisson - controls - weights - drop counties ever with zero births
	imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a("fips year") column(`i') pooled ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, timing of death, `lbl'")
			
}

// Panel B to D - By race and fully interacted  
forvalues i = 1(1)4 {
	
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear
	
	// Generate DiD treatment variable
	duketreat, treatvar(`treat') time(year) location(fips)
	
	// Generate infant mortality outcomes 
	imdata, mort(mort_``i'') suffix(pub)
	
	// Flag counties with black or white births ever equal to zero
	gegen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

	// Flag counties that always have zero black deaths
	gegen max_deaths_bk = max(imr_pub_bk), by(fips)
	
	// Get death type
	if `i' == 1 {
		local lbl "Include only deaths in first 24 hours"
	}
	if `i' == 2 {
		local lbl "Exclude deaths in first 24 hours"
	}
	if `i' == 3 {
		local lbl "Exclude deaths in first week"
	}
	if `i' == 4 {
		local lbl "Exclude deaths in first month"
	}
	// Poisson - controls - weights - drop counties ever with zero births
	imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0 & max_deaths_bk != 0") a("fips year") column(`i')  ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, timing of death, `lbl'")

}

// Prepare table
local mgroup2 "&\multicolumn{1}{c}{Deaths on:}&\multicolumn{3}{c}{Excluding those who died in the first:} \\ "
local mgroup3 "&\multicolumn{1}{c}{day 0}&\multicolumn{1}{c}{day}&\multicolumn{1}{c}{week}&\multicolumn{1}{c}{month} \\"
local numbers "\cmidrule(lr){2-2}\cmidrule(lr){3-5} & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\ "

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c4
 using "$PROJ_PATH/analysis/output/appendix/table_g4_infant_mortality_poisson_by_timing.tex", `booktabs_default_options' replace 
posthead("`mgroup2'" "`mgroup3'" "`numbers'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled infant mortality rate} &&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c4
 using "$PROJ_PATH/analysis/output/appendix/table_g4_infant_mortality_poisson_by_timing.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black infant mortality rate} &&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 p3_c4
 using "$PROJ_PATH/analysis/output/appendix/table_g4_infant_mortality_poisson_by_timing.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White infant mortality rate} &&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 p4_c4 
 using "$PROJ_PATH/analysis/output/appendix/table_g4_infant_mortality_poisson_by_timing.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Controls 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\");
#delimit cr


********************************************************************************************
***** Specification chart: Loop through shortening/lengthening start/end year of panel *****
********************************************************************************************

// Changing start year of panel
local first_year	1917
local last_year		1926

// Loop through start year of panel 

forvalues year_i = `first_year'(1)`last_year' {

	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_i' & year <= `year_end', clear

	// Generate variables for event study timing and set up event study specification
	duketreat, treatvar(`treat') time(year) location(fips)
	
	// Generate infant mortality outcomes 
	imdata, mort(mort) suffix(occ)

	// Poisson - controls - weights
	imppml, y_stub(imr_) suffix(occ) t(treated) controls(`baseline_controls') wgt(births) a(fips year) pooled ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, start year, `year_i'")
	
}

// Changing end year of panel
local first_year	1936
local last_year		1962

// Loop through end year of panel 
forvalues year_i = `first_year'(1)`last_year' {

	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_i', clear

	// Generate variables for event study timing and set up event study specification
	duketreat, treatvar(`treat') time(year) location(fips)

	// Generate infant mortality outcomes 
	imdata, mort(mort) suffix(occ)

	// Poisson - controls - weights
	imppml, y_stub(imr_) suffix(occ) t(treated) controls(`baseline_controls') wgt(births) a(fips year) pooled ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
			store_options("sr, end year, `year_i'")

}


***************************************************************************************************************
***** Appendix Table G5: Effects of Duke support: Robustness to including stillbirths and unnamed infants *****
***************************************************************************************************************

// Panel A - Pooled

// Column 1 - Add back reported still births 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_excl_nonam) suffix(pub)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(1) pooled  ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Add stillbirths− 1932+")


// Column 2 - Add back infant deaths with no names only after 1932
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
replace mort = mort + no_name if year > 1932
imdata, mort(mort) suffix(pub)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(2) pooled  ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Add stillbirths and unnamed− 1932+")


// Column 3 - Add back infant deaths with no names all years
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_excl_still) suffix(pub)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(3) pooled  ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Add unnamed− all years")


// Column 4 - Add back infant deaths with no names + still borns
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_all) suffix(pub)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(4) pooled ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Add stillbirths and unnamed− all years")


// Column 5 - Only no name deaths
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(no_name) suffix(pub)
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(5) pooled ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Include only unnamed− all years")


// Column 6 - Only no name deaths up to 1932
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= 1932, clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(no_name) suffix(pub)
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(6) pooled  ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Include only unnamed− 1926−1932")



// Only stillborn deaths
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= 1932, clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(still) suffix(pub)

// Only stillborn deaths
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) a(fips year) column(7) pooled ///
		store ///
		store_filename("$PROJ_PATH/analysis/output/sr_output_vary_samp.txt") ///
		store_options("sr, stillborn, Include only stillbirths− 1926−1932")




// Panels B to D - Separately by race and fully interacted

// Column 1 - Add back infant deaths with no names
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_excl_still) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(1) 


// Column 2 - Add back infant deaths with no names only after 1932
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
replace mort = mort + no_name if year > 1932
imdata, mort(mort) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(2)
 

// Column 3 - Add back reported still births 
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_excl_nonam) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(3)


// Column 4 - Add back infant deaths with no names + still borns
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort_all) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(4) 


// Column 5 - Only no name deaths
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(no_name) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(5)


// Column 6 - Only no name deaths up to 1932
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= 1932, clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(no_name) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0") a(fips year) column(6)


// Column 7 - Only stillborn deaths
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= 1932, clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(still) suffix(pub)

// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)

// Flag counties with black or white deaths always equal to zero
egen always_zero_deaths_bk = min(still_bk == 0), by(fips)
egen always_zero_deaths_wt = min(still_wt == 0), by(fips)
egen always_zero_deaths = max(always_zero_deaths_bk == 1 | always_zero_deaths_wt == 1), by(fips)

// Only stillborn deaths
imppml, y_stub(imr_) suffix(pub) t(treated) controls(`baseline_controls') wgt(births) restrict("ever_zero_births == 0 & always_zero_deaths == 0") a(fips year) column(7)


// Prepare table
local mgroup2 "&\multicolumn{4}{c}{Adding to the main sample:}&\multicolumn{3}{c}{Including only:} \\ "
local mgroup3 "&\multicolumn{1}{c}{Stillborn}&\multicolumn{1}{c}{Unnamed}&\multicolumn{1}{c}{Unnamed}&\multicolumn{1}{c}{\shortstack{Stillborn + \\ Unnamed}}&\multicolumn{1}{c}{Unnamed}&\multicolumn{1}{c}{Unnamed}&\multicolumn{1}{c}{Stillborn} \\"
local mgroup4 "\cmidrule(lr){2-5}\cmidrule(lr){6-8} &\multicolumn{2}{c}{1922-32}&\multicolumn{3}{c}{All years}&\multicolumn{2}{c}{1922-32} \\"
local numbers "\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-8} & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} \\ "

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 p1_c4 p1_c5 p1_c6 p1_c7
 using "$PROJ_PATH/analysis/output/appendix/table_g5_stillborn_unnamed_infants.tex", `booktabs_default_options' replace 
posthead("`mgroup2'" "`mgroup3'" "`mgroup4'" "`numbers'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\midrule \emph{A. Pooled infant mortality rate} &&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 p2_c4 p2_c5 p2_c6 p2_c7
 using "$PROJ_PATH/analysis/output/appendix/table_g5_stillborn_unnamed_infants.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{B. Black infant mortality rate} &&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3 p3_c4 p3_c5 p3_c6 p3_c7
 using "$PROJ_PATH/analysis/output/appendix/table_g5_stillborn_unnamed_infants.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("\emph{C. White infant mortality rate} &&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr

// Make bottom panel - Fully interacted
#delimit ;
esttab p4_c1 p4_c2 p4_c3 p4_c4 p4_c5 p4_c6 p4_c7 
 using "$PROJ_PATH/analysis/output/appendix/table_g5_stillborn_unnamed_infants.tex", `booktabs_default_options' append
stats(int_p_value, fmt(%09.2f) labels("\addlinespace\hspace{.5cm} P-value for difference by race") layout(@))
postfoot("\midrule 
	County of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Controls 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\");
#delimit cr



*****************************************************************************************************************
***** Appendix Table G6 - Effects of sulfa drugs on infant mortality: Shift-share difference-in-differences *****
*****************************************************************************************************************

// Generate upper and lower quartile values of baseline pneumonia

use "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", clear

sum base_pneumonia_22to26, d

local pneumonia_p75 = r(p75)
local pneumonia_p25 = r(p25)
local pneumonia_iqr = `pneumonia_p75' - `pneumonia_p25'

di "IQR: `pneumonia_iqr'"
	

// Short-run infant mortality outcomes
use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes + generate weights 
imdata, mort(mort) suffix(pub)

// Generate sulfa x Duke treated x post shift share interaction terms
gen post_sulfa = (year >= 1937)
gen post_sulfa_shift_share = post_sulfa*base_pneumonia_22to26

gen treated_post_sulfa = treated*post_sulfa
gen treated_shift_share = treated*base_pneumonia_22to26
gen treated_post_shift_share = treated*post_sulfa*base_pneumonia_22to26

la var post_sulfa "=1 if sulfa (1937 onward)"
la var treated "$\text{Duke}_{ct}\;\;(\delta_0)$"
la var treated_post_sulfa "$\text{Duke}_{ct}\times\text{Sulfa}_{t}\;\;(\delta_1)$"
la var treated_shift_share "$\text{Duke}_{ct}\times\text{Pre-pneumonia}_{c}\;\;(\delta_2)$"
la var post_sulfa_shift_share "$\text{Sulfa}_{t}\times\text{Pre-pneumonia}_{c}\;\;(\delta_3)$"
la var treated_post_shift_share "$\text{Duke}_{ct}\times\text{Sulfa}_t\times\text{Pre-pneumonia}_c\;\;(\delta_4)$"

// Panel A: Pooled

// Poisson - no controls - no weights
ppmlhdfe imr_pub ///
	post_sulfa_shift_share, ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p1_c1

// Poisson - no controls - weights
ppmlhdfe imr_pub ///
	post_sulfa_shift_share ///
	[pw = births_pub], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p1_c2

// Poisson - controls - weights
ppmlhdfe imr_pub ///
	post_sulfa_shift_share ///
	`baseline_controls' [pw = births_pub], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p1_c3

// Prepare table
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\"

// Make top panel - Pooled
#delimit ;
esttab p1_c1 p1_c2 p1_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_g6_sulfa_dd_poisson.tex", `booktabs_default_options' replace 
posthead("`numbers_main'")
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels(`"\midrule \emph{A. Pooled infant mortality rate} &&& \\ \addlinespace\hspace{.5cm} Percent effect from $\text{Pneumonia}_{IQR}\times\text{Post sulfa}$"' "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr


// Flag counties with black or white births ever equal to zero
egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)


// Panel B: Black 

// Poisson - no controls - no weights
ppmlhdfe imr_pub_bk ///
	post_sulfa_shift_share ///
	if ever_zero_births == 0, ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p2_c1

// Poisson - no controls - weights
ppmlhdfe imr_pub_bk ///
	post_sulfa_shift_share ///
	if ever_zero_births == 0 ///
	[pw = births_pub_bk], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p2_c2

// Poisson - controls - weights
ppmlhdfe imr_pub_bk ///
	post_sulfa_shift_share ///
	`baseline_controls' if ever_zero_births == 0 ///
	[pw = births_pub_bk], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p2_c3

// Make 2nd panel - Black
#delimit ;
esttab p2_c1 p2_c2 p2_c3 
 using "$PROJ_PATH/analysis/output/appendix/table_g6_sulfa_dd_poisson.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels(`"\emph{B. Black infant mortality rate} &&& \\ \addlinespace\hspace{.5cm} Percent effect from $\text{Pneumonia}_{IQR}\times\text{Post sulfa}$"' "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
#delimit cr



// Panel C: White

// Poisson - no controls - no weights
ppmlhdfe imr_pub_wt ///
	post_sulfa_shift_share ///
	if ever_zero_births == 0, ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p3_c1

// Poisson - no controls - weights
ppmlhdfe imr_pub_wt ///
	post_sulfa_shift_share ///
	if ever_zero_births == 0 ///
	[pw = births_pub_wt], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p3_c2

// Poisson - controls - weights
ppmlhdfe imr_pub_wt ///
	post_sulfa_shift_share ///
	`baseline_controls' if ever_zero_births == 0 ///
	[pw = births_pub_wt], ///
	absorb(fips year) vce(cluster fips)  
	
lincomestadd2a 100*(exp(`pneumonia_iqr'*_b[post_sulfa_shift_share])-1), comtype("nlcom_pois") statname("pct_efct_")

eststo p3_c3



// Make 3rd panel - White
#delimit ;
esttab p3_c1 p3_c2 p3_c3
 using "$PROJ_PATH/analysis/output/appendix/table_g6_sulfa_dd_poisson.tex", `booktabs_default_options' append
stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels(`"\emph{C. White infant mortality rate} &&& \\ \addlinespace\hspace{.5cm} Percent effect from $\text{Pneumonia}_{IQR}\times\text{Post sulfa}$"' "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule 
	County of birth FE 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
	Year of birth FE 				& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\  
	Controls						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} \\  
	Weights 						& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\");
#delimit cr



disp "DateTime: $S_DATE $S_TIME"

* EOF 
