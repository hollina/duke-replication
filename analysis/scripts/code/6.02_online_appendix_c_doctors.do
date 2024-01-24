version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_doctors.do
* PURPOSE: Run regressions for Online Appendix C - First stage results for doctors and other health care professionals
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

// Duke treatment type
local treat			"capp_all"

***********************************************************************************************
***** Table C1: Doctors first-stage results pooled and by race - Alternate specifications *****
***********************************************************************************************

local qual 			"2yr"
local stackMax 		3
local stackMin 		-3

eststo clear

local z = 1
foreach race in pooled black white {

	if "`race'" == "pooled" {
		local weightvar births_pub
		local race_suf ""
	}	
	if "`race'" == "white" {
		local weightvar births_pub_wt
		local race_suf "_white"
	}
	if "`race'" == "black" {
		local weightvar births_pub_bk
		local race_suf "_black"
	}
	
	foreach depvar in md`race_suf' md_good_`qual'`race_suf' md_bad_`qual'`race_suf' {
		
		eststo clear

		foreach suffix in noPC yesPC  {
						
			// Load data 
			use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear
			
			// Create separate time treated variable for Callaway-Sant'Anna
			gen time_treated_2 = time_treated
			replace time_treated_2 = 0 if missing(time_treated)
			
			// Drop counties ever with zero births by race
			egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
			if "`race'" == "white" | "`race'" == "black" {
				drop if ever_zero_births == 1
			}
			
			// Create doctors per 100,000 population
			capture drop rmd*
			
			* Get variable names that start with "md_".
			ds md_*
			local mdvars = r(varlist)

			* Exclude variable names that end with "_white" or "_black".
			ds *_white *_black, not
			local mdvars_notwhiteblack = r(varlist)

			* Intersect the two lists to get the final list of variable names.
			local pooled_vars : list mdvars & mdvars_notwhiteblack
			di "`pooled_vars'"
			
			foreach var of local pooled_vars { 

				gen r`var' = (`var'/births_pub)*1000
				la var r`var' "`: var label `var'' per 1000 births"

			}
			gen rmd = (md/births_pub)*1000
			la var rmd "Doctors per 1,000 births "

			ds md_*white, 
			local white_vars  `r(varlist)'
			
			foreach var of local white_vars { 
				
				gen r`var' = (`var'/births_pub_wt)*1000
				la var r`var' "`: var label `var'' per 1,000 white births"

			}
			
			ds md_*black, 
			local black_vars `r(varlist)'

			foreach var of local black_vars { 
				
				gen r`var' = (`var'/births_pub_bk)*1000
				la var r`var' "`: var label `var'' per 1,000 black births"

			}
			
			local suffix3 ""
			
			if substr("`depvar'", 1, 7) == "md_good" {
				local suffix3 "g"
			}
			if substr("`depvar'", 1, 6) == "md_bad" {
				local suffix3 "bad"
			}
			
			if "`suffix'" == "noPC" {
				local depvar_new `depvar'

			}
			if "`suffix'" == "yesPC" {
				local depvar_new r`depvar'
			}
			
			local lbl: var label `depvar_new'
			di "`lbl'"
			
			if `z' == 1 {
				local position top
			}
			if `z' > 1  {
				local position middle
			}
		
			if `z' == 9 {
				local position bottom
			}
			
			if "`depvar_new'" == "md" { 
				local table_lbl "\emph{A. Pooled} &&&&&&&& \\ \addlinespace\hspace{.5cm} All" 
			}
			if "`depvar_new'" == "md_good_2yr" { 
				local table_lbl "\addlinespace\hspace{.5cm} High quality" 
			}
			if "`depvar_new'" == "md_bad_2yr" { 
				local table_lbl "\addlinespace\hspace{.5cm} Low quality" 
			}
			if "`depvar_new'" == "md_black" { 
				local table_lbl "\emph{B. Black} &&&&&&&& \\ \addlinespace\hspace{.5cm} All" 
			}
			if "`depvar_new'" == "md_good_2yr_black" { 
				local table_lbl "\addlinespace\hspace{.5cm} High quality" 
			}
			if "`depvar_new'" == "md_bad_2yr_black" { 
				local table_lbl "\addlinespace\hspace{.5cm} Low quality" 
			}
			if "`depvar_new'" == "md_white" { 
				local table_lbl "\emph{C. White} &&&&&&&& \\ \addlinespace\hspace{.5cm} All" 
			}
			if "`depvar_new'" == "md_good_2yr_white" { 
				local table_lbl "\addlinespace\hspace{.5cm} High quality" 
			}
			if "`depvar_new'" == "md_bad_2yr_white" { 
				local table_lbl "\addlinespace\hspace{.5cm} Low quality" 
			}
			
			// TWFE OLS estimation

				*Estimation
				eststo p1_c1`suffix'`suffix3': reghdfe `depvar_new' 1.treated [aw = `weightvar'], absorb(fips amd_wave) vce(cluster fips)				
				csdid_estadd_level 1.treated, statname("md_efct_") 

			
			// eTWFE  

				*Estimation
				jwdid `depvar_new' [pw = `weightvar'], ivar(fips) tvar(amd_wave) gvar(time_treated_2)  
						
				*Aggregation
				eststo p1_c3`suffix'`suffix3': estat simple 
				csdid_estadd_level  "", statname("md_efct_")		

	
			// csdid of Callaway and Sant'Anna (2020)

				*Estimation
				csdid `depvar_new' [iw = `weightvar'], ivar(fips) time(amd_wave) gvar(time_treated_2) agg(event)

				*Aggregation
				eststo p1_c4`suffix'`suffix3': csdid_estat simple
				csdid_estadd_level "", statname("md_efct_")
				
				
			/////////////////////////////////////////////////////////////////////////////////
			// Balanced stacked 
						
			balanced_stacked, ///
				outcome(`depvar_new') ///
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
			
			*Estimation
			eststo p1_c2`suffix'`suffix3': reghdfe `depvar_new' 1.treated [aw = `weightvar'], absorb(fips##stackID amd_wave##stackID) vce(cluster fips)
			csdid_estadd_level 1.treated, statname("md_efct_") 

		}
		// Prepare table
		if "`position'" == "top" {

			local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} & \multicolumn{1}{c}{(8)} \\"
			local numbers_main2 "& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Stacked-TWFE} & \multicolumn{1}{c}{eTWFE} & \multicolumn{1}{c}{CS} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Stacked-TWFE} & \multicolumn{1}{c}{eTWFE} & \multicolumn{1}{c}{CS} \\"

			local y_1 `"\$Y^{R}_{ct} = \text{Doctors}$"'
			local y_2 "\$Y^{R}_{ct} = \text{Doctors per 1000 births}$"

			// Make top panel - Pooled - All 
			#delimit ;
			esttab p1_c1noPC`suffix3' p1_c2noPC`suffix3' p1_c3noPC`suffix3' p1_c4noPC`suffix3' p1_c1yesPC`suffix3' p1_c2yesPC`suffix3' p1_c3yesPC`suffix3' p1_c4yesPC`suffix3'
			 using "$PROJ_PATH/analysis/output/appendix/table_c1_county_level_doctors_robustness.tex", `booktabs_default_options' replace 
			mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
			posthead("`numbers_main' `numbers_main2'") 
		stats(md_efct_b md_efct_se, fmt(0 0) labels("`table_lbl'" "~") layout(@ @));
			#delimit cr
			
		}
			
		if "`position'" == "middle" & "`suffix3'" != "bad" {
				
			#delimit ;
			esttab p1_c1noPC`suffix3' p1_c2noPC`suffix3' p1_c3noPC`suffix3' p1_c4noPC`suffix3' p1_c1yesPC`suffix3' p1_c2yesPC`suffix3' p1_c3yesPC`suffix3' p1_c4yesPC`suffix3'
			 using "$PROJ_PATH/analysis/output/appendix/table_c1_county_level_doctors_robustness.tex", `booktabs_default_options' append 
		stats(md_efct_b md_efct_se, fmt(0 0 ) labels("`table_lbl'" "~") layout(@ @));
		#delimit cr

		}

		if "`position'" == "middle" & "`suffix3'" == "bad" {
			
			#delimit ;
			esttab p1_c1noPC`suffix3' p1_c2noPC`suffix3' p1_c3noPC`suffix3' p1_c4noPC`suffix3' p1_c1yesPC`suffix3' p1_c2yesPC`suffix3' p1_c3yesPC`suffix3' p1_c4yesPC`suffix3'
			 using "$PROJ_PATH/analysis/output/appendix/table_c1_county_level_doctors_robustness.tex", `booktabs_default_options' append 
			stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations")	layout(@ @ "\multicolumn{1}{c}{@}"));
			#delimit cr

		}

		if "`position'" == "bottom" {
				
			#delimit ;
			esttab p1_c1noPC`suffix3' p1_c2noPC`suffix3' p1_c3noPC`suffix3' p1_c4noPC`suffix3' p1_c1yesPC`suffix3' p1_c2yesPC`suffix3' p1_c3yesPC`suffix3' p1_c4yesPC`suffix3'
			 using "$PROJ_PATH/analysis/output/appendix/table_c1_county_level_doctors_robustness.tex", `booktabs_default_options' append 
			stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
			postfoot("\midrule 
				County FE  			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
				AMD Wave FE 		& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
				Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
				Controls 			& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\");
			#delimit cr
			
		}
	
		local z = `z' + 1
		
	}
}


************************************************************************************************************
***** Tables C2 and C3: Doctors first-stage results pooled and by race - Alternate measures of quality *****
************************************************************************************************************

foreach qual in 2yr ama approve close {
	
	foreach race in pooled black white {
						
		if "`race'" == "pooled" {
			local race_suf ""
			local weightvar births_pub
		}					
		
		if "`race'" == "white" {
			local race_suf "_white"
			local weightvar births_pub_wt
		}
		
		if "`race'" == "black" {
			local race_suf "_black"
			local weightvar births_pub_bk
		}
				
		foreach depvar in md_good_`qual'`race_suf' md_bad_`qual'`race_suf' {
			
			foreach suffix in noPC yesPC  {

				// Open dataset
				use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear
			
				// In specifications by race, drop counties ever with zero race-specific births
				egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
				if "`race'" == "white" | "`race'" == "black" {
					drop if ever_zero_births == 1
				}
				
				// Create separate time treated variable for Mundlak estimator 
				gen time_treated_2 = time_treated
				replace time_treated_2 = 0 if missing(time_treated)
	
				// Create doctors per 100,000 population
				capture drop rmd*
				
				* Get variable names that start with "md_"
				ds md_*
				local mdvars = r(varlist)

				* Exclude variable names that end with "_white" or "_black"
				ds *_white *_black, not
				local mdvars_notwhiteblack = r(varlist)

				* Intersect the two lists to get the final list of variable names
				local pooled_vars : list mdvars & mdvars_notwhiteblack
				di "`pooled_vars'"

				foreach var of local pooled_vars { 

					gen r`var' = (`var'/births_pub)*1000
					la var r`var' "`: var label `var'' per 1000 births"

				}
				
				gen rmd = (md/births_pub)*1000
				la var rmd "Doctors per 1,000 births "

				ds md_*white, 
				local white_vars  `r(varlist)'
				
				foreach var of local white_vars { 
					
					gen r`var' = (`var'/births_pub_wt)*1000
					la var r`var' "`: var label `var'' per 1,000 white births"

				}
				
				ds md_*black, 
				local black_vars `r(varlist)'

				foreach var of local black_vars { 
					
					gen r`var' = (`var'/births_pub_bk)*1000
					la var r`var' "`: var label `var'' per 1,000 black births"

				}
													
				local suffix3 ""
				if substr("`depvar'", 1, 7) == "md_good" {
					local suffix3 "g"
				}
				if substr("`depvar'", 1, 6) == "md_bad" {
					local suffix3 "bad"
				}
					
				if "`suffix'" == "noPC" {
					local depvar_new `depvar'
				}
				if "`suffix'" == "yesPC" {
						local depvar_new r`depvar'
				}	
			
				////////////////////////////////////////////////////////////////////////
				// Doctors	- County level					
				local lbl: var label `depvar_new'
				di "`lbl'"
						
				// TWFE OLS estimation

					*Estimation
					eststo p_`race'_`suffix'_`qual'_`suffix3': reghdfe `depvar_new' 1.treated `baseline_controls' [aw = `weightvar'], absorb(fips amd_wave) vce(cluster fips)	
					csdid_estadd_level 1.treated, statname("md_efct_") 
						
			}
		}
	}
}


// Prepare tables
local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} \\"

local y_1 `"\$Y^{R}_{ct} = \text{Doctors}$"'
local y_2 "\$Y^{R}_{ct} = \text{Doctors per 1000 births}$"

// High quality table 

// Make top panel - Pooled - top row - 2-year requirement
local lbl: var label md_good_2yr
di "`lbl'"
#delimit ;
esttab p_pooled_noPC_2yr_g p_pooled_yesPC_2yr_g
 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'") 
stats(md_efct_b md_efct_se, fmt(0 0) labels("\emph{A. Pooled - High Quality} && \\ \addlinespace\hspace{.5cm} `lbl'" "~" )	layout(@ @));
#delimit cr

// Make top panel - Pooled - middle rows - AMA and existing/approved
foreach qual in ama approve {
	
	local lbl: var label md_good_`qual'
	di "`lbl'"
	#delimit ;
	esttab p_pooled_noPC_`qual'_g p_pooled_yesPC_`qual'_g
	 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se, fmt(0 0 ) labels("\hspace{.5cm}`lbl'" "~" )	layout(@ @));
	#delimit cr	
	
}		

// Make top panel - Pooled - bottom row - closure 
foreach qual in close {
	local lbl: var label md_good_`qual'
	di "`lbl'"
	#delimit ;
	esttab p_pooled_noPC_`qual'_g p_pooled_yesPC_`qual'_g
	 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("\hspace{.5cm}`lbl'" "~" "\addlinespace\hspace{.5cm} Observations")	layout(@ @));
	#delimit cr	
}		
		
// Make middle/bottom panels - Black/White - Good 
foreach race in black white {
	
	if "`race'" == "white" {
		local tblLBL "C. White"
	}
	if "`race'" == "black" {
		local tblLBL "B. Black"
	}
						
	local lbl: var label md_good_2yr
	di "`lbl'"
	#delimit ;
	esttab p_`race'_noPC_2yr_g p_`race'_yesPC_2yr_g
	 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se, fmt(0 0) labels("\emph{`tblLBL' - High Quality} && \\ \addlinespace\hspace{.5cm} `lbl'" "~" )	layout(@ @));
	#delimit cr

	foreach qual in ama approve {
		local lbl: var label md_good_`qual'
		di "`lbl'"
			#delimit ;
		esttab p_`race'_noPC_`qual'_g p_`race'_yesPC_`qual'_g
		 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' append 
		stats(md_efct_b md_efct_se, fmt(0 0 ) labels("\hspace{.5cm}`lbl'" "~" )	layout(@ @));
		#delimit cr	
	}
	
	foreach qual in close {
		local lbl: var label md_good_`qual'
		di "`lbl'"
			#delimit ;
		esttab p_`race'_noPC_`qual'_g p_`race'_yesPC_`qual'_g
		 using "$PROJ_PATH/analysis/output/appendix/table_c2_county_level_doctors_alt_qual_high.tex", `booktabs_default_options' append 
		stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("\hspace{.5cm}`lbl'" "~" "\addlinespace\hspace{.5cm} Observations")	layout(@ @));
		#delimit cr	
	}		
	
}
		
// Low quality table 
		
// Make top panel - Pooled - top row - 2-year requirement
local lbl: var label md_bad_2yr
di "`lbl'"
#delimit ;
esttab p_pooled_noPC_2yr_bad p_pooled_yesPC_2yr_bad
 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' replace 
mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("`numbers_main'") 
stats(md_efct_b md_efct_se, fmt(0 0) labels("\emph{A. Pooled - Low Quality} && \\ \addlinespace\hspace{.5cm} `lbl'" "~" )	layout(@ @));
#delimit cr

// Make top panel - Pooled - middle rows - AMA and existing/approved
foreach qual in ama approve {
	local lbl: var label md_bad_`qual'
	di "`lbl'"
		#delimit ;
	esttab p_pooled_noPC_`qual'_bad p_pooled_yesPC_`qual'_bad
	 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se, fmt(0 0 ) labels("\hspace{.5cm}`lbl'" "~" )	layout(@ @));
	#delimit cr	
}

// Make top panel - Pooled - bottom row - closure 
foreach qual in close {
	local lbl: var label md_bad_`qual'
	di "`lbl'"
		#delimit ;
	esttab p_pooled_noPC_`qual'_bad p_pooled_yesPC_`qual'_bad
	 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("\hspace{.5cm}`lbl'" "~" "\addlinespace\hspace{.5cm} Observations")	layout(@ @));
	#delimit cr	
}		
		
// Make middle/bottom panels - Black/White - Bad 
foreach race in black white {
	
	if "`race'" == "white" {
		local tblLBL "C. White"
	}
	
	if "`race'" == "black" {
		local tblLBL "B. Black"
	}
						
	local lbl: var label md_bad_2yr
	di "`lbl'"
	#delimit ;
	esttab p_`race'_noPC_2yr_bad p_`race'_yesPC_2yr_bad
	 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' append 
	stats(md_efct_b md_efct_se, fmt(0 0) labels("\emph{`tblLBL' - Low Quality} && \\ \addlinespace\hspace{.5cm} `lbl'" "~" )	layout(@ @));
	#delimit cr

	foreach qual in ama approve {
		local lbl: var label md_bad_`qual'
		di "`lbl'"
			#delimit ;
		esttab p_`race'_noPC_`qual'_bad p_`race'_yesPC_`qual'_bad
		 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' append 
		stats(md_efct_b md_efct_se, fmt(0 0 ) labels("\hspace{.5cm}`lbl'" "~" )	layout(@ @));
		#delimit cr	
	}		
	
	foreach qual in close {
		local lbl: var label md_bad_`qual'
		di "`lbl'"
		#delimit ;
		esttab p_`race'_noPC_`qual'_bad p_`race'_yesPC_`qual'_bad
		 using "$PROJ_PATH/analysis/output/appendix/table_c3_county_level_doctors_alt_qual_low.tex", `booktabs_default_options' append 
		stats(md_efct_b md_efct_se N, fmt(0 0 %9.0fc) labels("\hspace{.5cm}`lbl'" "~" "\addlinespace\hspace{.5cm} Observations")	layout(@ @));
		#delimit cr	
	}		
	
}


************************************************************************
***** Table C4: Doctors first-stage results pooled - Other metrics *****
************************************************************************

use "$PROJ_PATH/analysis/processed/data/amd_physicians/amd_physicians_with_med_school_quality.dta", clear 

// Create binary variable that takes the value 1 if `raw_med_school` contains the phrase "N.C."
gen nc_med_school = regexm(raw_med_school,"N\.C\.")

// Gen age
gen age = year - birth_year + 1

// Create counts of young doctors and recently trained doctors.
gen young = . 
replace young = 0 if age > 39 & !missing(age)
replace young = 1 if age <= 39 & !missing(age) 

gen post_flex_lic = . 
replace post_flex_lic = 1 if license_year1 > 1910 & !missing(license_year1)
replace post_flex_lic = 0 if license_year1 <= 1910 & !missing(license_year1)

gen pre_flex_lic = . 
replace pre_flex_lic = 1 if license_year1 <= 1910 & !missing(license_year1)
replace pre_flex_lic = 0 if license_year1 > 1910 & !missing(license_year1)

sumup age, by(md_good_2yr)

// Create local macro of the things i want to collapse over
local md_list ///
 young  ///
 post_flex_lic pre_flex_lic ///
 md_surgeon md_specialist ///
 ama_fellow ama_member nc_med_school 

sumup `md_list', by(year)

// Create AMD Wave
gen amd_wave = . 
	replace amd_wave = 1 if year > 1919 & year <= 1921
	replace amd_wave = 2 if year > 1921 & year <= 1923
	replace amd_wave = 3 if year > 1923 & year <= 1925
	replace amd_wave = 4 if year > 1925 & year <= 1927
	replace amd_wave = 5 if year > 1927 & year <= 1929
	replace amd_wave = 6 if year > 1929 & year <= 1931
	replace amd_wave = 7 if year > 1931 & year <= 1934
	replace amd_wave = 8 if year > 1934 & year <= 1936
	replace amd_wave = 9 if year > 1936 & year <= 1938
	replace amd_wave = 10 if year > 1938 & year <= 1940
	replace amd_wave = 11 if year > 1940 & year <= 1942

// Collapse the `md_list' local macro by statefip countyicp fips state county_nhgis gisjoin amd_wave year, creating mean, median, p25, p75, min, max, and n
foreach v in `md_list' {
	local l "`l' (sum) sum_`v'=`v'  (mean) mean_`v'=`v' (median) median_`v'=`v' (p25) p25_`v'=`v' (p95) p95_`v'=`v' (max) max_`v'=`v' (count) n_`v' = `v'"
}

	collapse ///
		`l' ///
	, by(statefip countyicp fips state county_nhgis gisjoin amd_wave year)

// Drop if missing amd_wave
drop if missing(amd_wave)

// Merge with regular doctor data 
merge 1:1 fips amd_wave using "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Counts / Doctors per birth 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Table options
local booktabs_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Duke treatment variable 
local treat 		"capp_all"
local stat 			sum
local i = 1

local md_count_list  ///
 	md_surgeon md_specialist ///
 	ama_fellow ama_member nc_med_school ///
	young post_flex_lic pre_flex_lic

foreach depvar in `md_count_list' {
	gen `stat'_`depvar'_pc  = (`stat'_`depvar' / births_pub)*1000

	// Column 1 - Docs - no controls - no weights
	eststo p`i'_c1 :reghdfe `stat'_`depvar' b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Docs - no controls - weights
	eststo p`i'_c2 :reghdfe `stat'_`depvar' b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 3 - Docs - county-level controls - weights
	eststo p`i'_c3 :reghdfe `stat'_`depvar' b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 1 - Docs - no controls - no weights
	eststo p`i'_c4 :reghdfe `stat'_`depvar'_pc b0.treated, absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 2 - Docs - no controls - weights
	eststo p`i'_c5 :reghdfe `stat'_`depvar'_pc b0.treated [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	// Column 3 - Docs - county-level controls - weights
	eststo p`i'_c6 :reghdfe `stat'_`depvar'_pc b0.treated `baseline_controls' [aw = births_pub], absorb(fips amd_wave) vce(cluster fips)
	di "`e(cmdline)'"

	local i = `i' + 1

}

	// Prepare table
	local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"

	local y_1 `"\$Y^{R}_{ct} = \text{Doctors}$"'
	local y_2 "\$Y^{R}_{ct} = \text{Doctors per 1,000 births}$"

	// Make top panel - Doctors - All
	#delimit ;
	esttab p1_c1 p1_c2 p1_c3 p1_c4 p1_c5 p1_c6
	using "$PROJ_PATH/analysis/output/appendix/table_c4_county_level_doctors_other_metrics.tex", `booktabs_options' replace 
	mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
	posthead("`numbers_main' \midrule") 
	keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} Surgeons") ;
	#delimit cr

	local i = 2
	local md_count_list2  ///
 	md_specialist ///
 	ama_fellow ama_member  ///
	nc_med_school young post_flex_lic

	foreach depvar in `md_count_list2' {
		if "`depvar'" == "license_year1" {
			local lbl "License Year"
		}
		if "`depvar'" == "md_surgeon" {
			local lbl "Surgeons"	
		}
		if "`depvar'" == "md_specialist" {
			local lbl "Specialists"
		}
		if "`depvar'" == "ama_fellow" {
			local lbl "AMA Fellows"
		}
		if "`depvar'" == "ama_member" {
			local lbl "AMA Members"
		}
		if "`depvar'" == "young" {
			local lbl "Doctors under 40"
		}
		if "`depvar'" == "nc_med_school" {
			local lbl "Doctors from N.C. medical school"
		}
		if "`depvar'" == "post_flex_lic" {
			local lbl "Doctors licensed after Flexner report"
		}
		
		
	// Append middle part of table 
	#delimit ;
	esttab p`i'_c1 p`i'_c2 p`i'_c3 p`i'_c4 p`i'_c5 p`i'_c6
	using "$PROJ_PATH/analysis/output/appendix/table_c4_county_level_doctors_other_metrics.tex", `booktabs_options' append 
	keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} `lbl'") ;
	#delimit cr

			local i = `i' + 1
	}


local depvar pre_flex_lic
		if "`depvar'" == "pre_flex_lic" {
			local lbl "Doctors licensed before Flexner report"
		}
	#delimit ;
	esttab p`i'_c1 p`i'_c2 p`i'_c3 p`i'_c4 p`i'_c5 p`i'_c6
	using "$PROJ_PATH/analysis/output/appendix/table_c4_county_level_doctors_other_metrics.tex", `booktabs_options' append 
	keep(1.treated) coeflabels(1.treated "\addlinespace\hspace{.5cm} `lbl'")
	stats(N, fmt(%9.0fc) labels("\addlinespace\hspace{.5cm} Observations") layout("\multicolumn{1}{c}{@}"))
	postfoot("\midrule 
	County FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\ 
	AMD Wave FE 	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  \\
	Weights 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
	Controls 			& \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{Yes}  \\");
	#delimit cr


	
***********************************************************************************
***** Figure C1a: Descriptive plot of doctors by year and ever treated status *****
***********************************************************************************

// Doctors by year and ever treated status

local fig_width 	7
local qual 			2yr

// Black 
local race_group 	black 
local race_suf 		"_black"
local weightvar 	births_pub_bk
local lbl 			"Black "
local labels 		"0(1)5"

// Load data 
use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

keep  rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf'  `weightvar' calendar_year ever_treated
gcollapse (mean) rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' [aweight = `weightvar'], by(calendar_year ever_treated) 

* Black - All doctors
twoway ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(0(2)10, nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(7 1922 "Ever treated", size(large) placement(right)) text(6. 1922 "by 1942", size(large) placement(right)) ///
				text(2 1922 "Never treated", size(large) placement(right)) text(1. 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a1_`race_group'_rMD_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a1_`race_group'_rMD_by_treatment_status.pdf", replace


* Black - High Quality doctors
twoway ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of high quality `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(`labels', nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(3.75 1937 "Ever treated", size(large) placement(right)) text(3.25 1937 "by 1942", size(large) placement(right)) ///
				text(1.5 1935 "Never treated", size(large) placement(right)) text(1 1935 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a2_`race_group'_rMD_good_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a2_`race_group'_rMD_good_by_treatment_status.pdf", replace


* Black - Low Quality doctors
twoway ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of low quality `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(0(2)8, nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(6 1922 "Ever treated", size(large) placement(right)) text(5.5 1922 "by 1942", size(large) placement(right)) ///
				text(2 1922 "Never treated", size(large) placement(right)) text(1.5 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a3_`race_group'_rMD_bad_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c1a3_`race_group'_rMD_bad_by_treatment_status.pdf", replace



// White
local race_group 	white 
local race_suf 		"_white"
local weightvar 	births_pub_wt
local lbl 			"White "
local labels 		"0(20)80"

// Load data 
use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

keep rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf'  `weightvar' calendar_year ever_treated
gcollapse (mean) rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' [aweight = `weightvar'], by(calendar_year ever_treated) 
	
* White - All doctors
twoway ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(0(10)50, nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(50 1922 "Ever treated", size(large) placement(right)) text(45 1922 "by 1942", size(large) placement(right)) ///
				text(27 1922 "Never treated", size(large) placement(right)) text(22 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a1_`race_group'_rMD_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a1_`race_group'_rMD_by_treatment_status.pdf", replace


* White - High Quality doctors
twoway ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_good_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of high quality `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(0(10)30, nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(30 1937 "Ever treated", size(large) placement(right)) text(27 1937 "by 1942", size(large) placement(right)) ///
				text(10 1937.5 "Never treated", size(large) placement(right)) text(7 1937.5 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a2_`race_group'_rMD_good_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a2_`race_group'_rMD_good_by_treatment_status.pdf", replace


* White - Low Quality doctors
twoway ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none)  ///
	|| connected rmd_bad_2yr`race_suf' calendar_year if ever_treated == 1,  lw(1) lcolor("230 65 115") lp(line)  msymbol(none) ///
				xlab(1921(5)1942, nogrid valuelabel labsize(5) angle(0)) ///
				xtitle("Year", size(5) height(7)) ///
				ytitle("") ///
				subtitle("Average number of low quality `lbl'doctors per 1,000 births", size(4) pos(11)) ///
				xline(1927, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(`fig_width') ///
				legend(off) ///
				ylab(0(15)45, nogrid labsize(5) angle(0) format(%3.0f)) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
				text(44 1922 "Ever treated", size(large) placement(right)) text(40 1922 "by 1942", size(large) placement(right)) ///
				text(24 1922 "Never treated", size(large) placement(right)) text(20 1922 "up to 1942", size(large) placement(right))

*graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a3_`race_group'_rMD_bad_by_treatment_status.png", as(png) height(2400) replace
graph export "$PROJ_PATH/analysis/output/appendix/figure_c2a3_`race_group'_rMD_bad_by_treatment_status.pdf", replace
	

***************************************************************************
***** Figure C1 and C2 panel B: First-stage event studies for doctors *****
***************************************************************************

local stackMax 		3
local stackMin 		-3
local gphMax 		5
local gphMin 		-5
local qual		 	2yr 

foreach race in black white {
	
	if "`race'" == "white" {
		local race_suf "_white"
		local weightvar births_pub_wt
		local figno "2"
	}
	if "`race'" == "black" {
		local race_suf "_black"
		local weightvar births_pub_bk
		local figno "1"
	}
								
	foreach depvar in rmd`race_suf' rmd_good_`qual'`race_suf' rmd_bad_`qual'`race_suf' {
		eststo clear

		// Load data 
		use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear

		// Drop counties that ever have zero births 
		egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
		drop if ever_zero_births == 1
			
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
		 
		keep if order >= `gphMin'
		keep if order <= `gphMax'
		sort modified_event_time
		order modified_event_time
		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'



		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'
		sum modified_event_time 
		local low_event_cap_graph = r(min) - .01
		di "`low_event_cap_graph'"
		local high_event_cap_graph = r(max) + .01
		di "`high_event_cap_graph'"

		keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'
		
		if "`depvar'" == "rmd`race_suf'" {
			local depvar_stub "all`race_suf'"
			local row "1"
		} 
		if "`depvar'" == "rmd_good_`qual'`race_suf'" {
			local depvar_stub "good`race_suf'"
			local row "2"
		} 
		if "`depvar'" == "rmd_bad_`qual'`race_suf'" {
			local depvar_stub "bad`race_suf'"
			local row "3"
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
				ylab(, nogrid labsize(5) angle(0) format(%3.0f)) ///		
				xtitle("AMD waves since first capital appropriation from Duke Endowment", size(5) height(7)) ///
				xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(8) ///
				legend(order(3 "TWFE" ///
							6 "Stacked-TWFE" 9 "eTWFE" 12 "Callaway Sant'Anna") rows(1) position(6) region(style(none))) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
			 subtitle("`lbl'", size(4) pos(11)) 
			 
			*graph export "$PROJ_PATH/analysis/output/appendix/figure_c`figno'b`row'_`depvar_stub'_doctors_first_stage.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_c`figno'b`row'_`depvar_stub'_doctors_first_stage.pdf", replace 
		
	}	
}


*****************************************************************
// Figure C3: Employment of other health care professionals *****
*****************************************************************

local medical_professionals "nurse hosp_attendant hosp_clerical"

// Descriptives
	
// Hospital staff in census 
use "$PROJ_PATH/analysis/processed/data/ipums_doctors_nurses_hospital_staff.dta", clear

collapse (mean) `medical_professionals', by(year ever_treated)

la var nurse "Nurses"
la var hosp_attendant "Number of Employees in Medical Industry, Attendant"
la var hosp_clerical "Number of Employees in Medical Industry, Clerical"

foreach occ of local medical_professionals {

	sum `occ' if ever_treated == 1
	local max_t = r(max)
	
	sum `occ' if ever_treated == 0
	local max_c = r(max)
	
	local max_y = max(`max_t',`max_c') 
	
	local y_text_t = `max_y'*0.8
	local y_text_c = `max_y'*0.2
	
	label define year_lab 1 "1910" 2 "1920" 3 "1930" 4 "1940", replace
	la val year year_lab
	
	if "`occ'" == "nurse" {
		local row "1"
	}
	if "`occ'" == "hosp_attendant" {
		local row "2"
	}
	if "`occ'" == "hosp_clerical" {
		local row "3"
	}
	
	twoway connected `occ' year if year >= 2 & ever_treated == 0, lw(1) lcolor("black") lp(longdash) msymbol(S) msize(3) mcolor("black") ///
		|| connected `occ' year if year >= 2 & ever_treated == 1,  lw(1) lcolor("230 65 115") lp(shortdash)  msymbol(O) msize(3) mcolor("230 65 115") ///
					xlab(2(1)4, nogrid valuelabel labsize(5) angle(0)) ///
					ylab(, nogrid labsize(5) angle(0) `fmt') ///
					yscale(range(0 `max_y')) ///
					xtitle("Year", size(5) height(7)) ///
					xline(2.7, lpattern(dash) lcolor(gs7) lwidth(1)) ///
					ytitle("") ///
					subtitle("`: var label `occ''", size(5) pos(11)) ///
					xsize(7) ///
					legend(off) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
					text(`y_text_c' 2.8 "Never treated", size(large) placement(right)) ///
					text(`y_text_t' 2.8 "Ever treated", size(large) placement(right))
					
	*graph export "$PROJ_PATH/analysis/output/appendix/figure_c3a`row'_med_profs_by_treatment_status_`occ'.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_c3a`row'_med_profs_by_treatment_status_`occ'.pdf", replace
	
}

// Event studies 

// Variables
local unit_id 		"fips"
local clustervar	"fips" 		
local aw			""
local iw			""

// Hospital staff in census 
use "$PROJ_PATH/analysis/processed/data/ipums_doctors_nurses_hospital_staff.dta", clear

local varcount: word count `medical_professionals'
di "`varcount'"
tokenize `medical_professionals'

forvalues i = 1(1)`varcount' {
	local y_var = "``i''"

	// Hospital staff in census 
	use "$PROJ_PATH/analysis/processed/data/ipums_doctors_nurses_hospital_staff.dta" if calendar_year >= 1920, clear

	la var nurse "Nurses"
	la var hosp_attendant "Number of Employees in Medical Industry, Attendant"
	la var hosp_clerical "Number of Employees in Medical Industry, Clerical"

	// store largest leads and lags
	gen event_time_bacon = year - time_treated

	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	// csdid of Callaway and Sant'Anna (2020)
	gen gvar = cond(time_treated > 0 & !missing(time_treated), time_treated, 0) // group variable as required for the csdid command
	tab gvar, m

	csdid `y_var' `iw', ivar(`unit_id') time(year) gvar(gvar) agg(event)
	
	matrix cs_b = e(b)
	matrix cs_v = e(V)

	// TWFE OLS estimation
	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event
	
	reghdfe `y_var' F*event L*event `aw', absorb(`unit_id' year) vce(cluster `unit_id')
	
	estimates store ols
	
	if "`y_var'" == "nurse" {
		local row "1"
	}
	if "`y_var'" == "hosp_attendant" {
		local row "2"
	}
	if "`y_var'" == "hosp_clerical" {
		local row "3"
	}
	
	// Plot 
	event_plot cs_b#cs_v ols, ///
		stub_lag(Tp# L#event) stub_lead(Tm# F#event) ///
		plottype(scatter) ciplottype(rcap) ///
		together trimlead(2) trimlag(1) noautolegend ///
		graph_opt( ///
			subtitle("`: var label `y_var''", size(6) pos(11)) ///
			xtitle("Census wave since first capital appropriation", size(6) height(7)) ///
			ytitle("Average causal effect", size(6)) ///
			xlabel(-2(1)1, nogrid notick  labsize(6)) xscale(extend) xsize(8) ///
			ylab(, labsize(6) angle(0) format(%03.1f) nogrid notick) yscale(extend) ///
			legend(order(1 "Callaway-Sant'Anna" ///
					3 "TWFE OLS") rows(1) position(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
		) ///
		lag_opt1(msymbol(O) color(cranberry) msize(4)) lag_ci_opt1(color(cranberry) msize(5)  lw(.75)) ///
		lag_opt2(msymbol(D) color(navy) msize(4)) lag_ci_opt2(color(navy) msize(5)  lw(.75)) 

	*graph export "$PROJ_PATH/analysis/output/appendix/figure_c3b`row'_event_study_hosp_staff_``i''.png", replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_c3b`row'_event_study_hosp_staff_``i''.pdf", replace
	
}


disp "DateTime: $S_DATE $S_TIME"

* EOF 