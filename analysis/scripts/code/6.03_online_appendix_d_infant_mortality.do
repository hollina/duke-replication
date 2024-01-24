version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_infant_mortality.do
* PURPOSE: Run analysis for Appendix D - Infant mortality: Additional results
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

************************************************************************************
***** Table D1: Robustness of infant mortality results to alternate estimators *****
************************************************************************************
eststo clear

local stackMin		-6
local stackMax		6
local depvar_stub	imr_pub
local weight_stub	births_pub

foreach race in pooled black white {
	
	eststo clear
	
	if "`race'" == "pooled" {
		local race_suf ""
	}	
	if "`race'" == "white" {
		local race_suf "_wt"
	}
	if "`race'" == "black" {
		local race_suf "_bk"
	}

	local weightvar `weight_stub'`race_suf'

	foreach suffix in noPC yesPC  {
		
		// Load county-level infant mortality data 
		use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

		// Generate infant mortality outcomes + generate weights 
		imdata, mort(mort) suffix(pub)
			
		// Drop counties ever with zero births by race
		egen ever_zero_births = max(births_pub_bk == 0 | births_pub_wt == 0), by(fips)
		
		if "`race'" == "white" | "`race'" == "black" {
			drop if ever_zero_births == 1
		}		
		
		// Set local for dependent variable 
		if "`suffix'" == "noPC" {
			local depvar mort`race_suf'	
		}
		if "`suffix'" == "yesPC" {
			local depvar imr_pub`race_suf'
		}
		
		local lbl: var label `depvar'
		di "`lbl'"
		
		// Add Duke treatment 
		duketreat, treatvar(`treat') time(year) location(fips)
		
		// Create separate time treated variable for Callaway-Sant'Anna
		gen time_treated_2 = time_treated
		replace time_treated_2 = 0 if missing(time_treated)
		
		if "`race'" == "pooled" {
			local position top
		}
		else if "`race'" == "black" {
			local position middle
		}
		else {
			local position bottom
		}
		
		if "`race'" == "pooled" { 
			local table_lbl "\emph{A. Pooled} &&&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
		}
		if "`race'" == "black" { 
			local table_lbl "\emph{B. Black} &&&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
		}
		if "`race'" == "white" { 
			local table_lbl "\emph{C. White} &&&&&&&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
		}
		
		// Options for store group
		if "`race'" == "pooled" { 
			local store_group_stub "pool" 
		}
		else {
			local store_group_stub "`race'"
		}
		
		if "`suffix'" == "noPC" {
			local store_depvar 	"death_count"
		}
		else if "`suffix'" == "yesPC" {
			local store_depvar "death_rate"
		}
		else {
			di "Dependent variable is not specified for store_options."
			exit
		}
		
		// Poisson estimation

			*Estimation
			eststo p1_c1`suffix': ppmlhdfe `depvar' 1.treated [pw = `weightvar'], absorb(fips year) cluster(fips) sep(fe)
			lincomestadd2a 100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") 
			
		// eTWFE  

			*Estimation
			jwdid `depvar' [pw = `weightvar'], ivar(fips) tvar(year) gvar(time_treated_2) method(poisson)
					
			*Aggregation
			eststo p1_c3`suffix': estat simple 
			if "`suffix'" == "noPC" {
				csdid_estadd_level  "", statname("pct_efct_")
			}
			else {
				csdid_estadd_level  "", statname("pct_efct_") ///	
				store ///
				store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
				store_options("sr, mundlak poisson, `store_depvar', Ycounty, Yyear, Ncontrols, Yweights") ///
				store_group("`store_group_stub'")	
			}
			
		// TWFE OLS estimation

			*Estimation
			eststo p1_c4`suffix': reghdfe `depvar' 1.treated [aw = `weightvar'], absorb(fips year) vce(cluster fips)	
			
			* Save untreated mean 
			sum `depvar' if treated == 0 [aw = `weightvar']
			local mean_untr_imr = r(mean)
			
			if "`suffix'" == "noPC" {
				lincomestadd2a 100*(_b[1.treated]/`mean_untr_imr'), comtype(lincom) statname("pct_efct_")
			}
			else {
				lincomestadd2a 100*(_b[1.treated]/`mean_untr_imr'), comtype(lincom) statname("pct_efct_") ///
				store ///
				store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
				store_options("sr, ols, `store_depvar', Ycounty, Yyear, Ncontrols, Yweights") ///
				store_group("`store_group_stub'")				
			}
			
		/////////////////////////////////////////////////////////////////////////////////
		// Balanced stacked 
					
		balanced_stacked, ///
			outcome(`depvar') ///
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
			eststo p1_c2`suffix': ppmlhdfe `depvar' 1.treated [pw = `weightvar'], absorb(fips##stackID year##stackID) cluster(fips) sep(fe)
			
			if "`suffix'" == "noPC" {
				lincomestadd2a 100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_")
			}
			else {
				lincomestadd2a 100*(exp(_b[1.treated])-1), comtype(nlcom) statname("pct_efct_") ///
				store ///
				store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
				store_options("sr, stacked poisson, `store_depvar', Ycounty, Yyear, Ncontrols, Yweights") ///
				store_group("`store_group_stub'")	
			}
	}
	
	// Prepare table
	if "`position'" == "top" {

		local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} & \multicolumn{1}{c}{(8)} \\"
		local numbers_main2 "& \multicolumn{1}{c}{Poisson} & \multicolumn{1}{c}{Stacked-Poisson} & \multicolumn{1}{c}{eTWFE-Poisson} & \multicolumn{1}{c}{Callaway Sant'Anna} & \multicolumn{1}{c}{Poisson} & \multicolumn{1}{c}{Stacked-Poisson} & \multicolumn{1}{c}{eTWFE-Poisson} & \multicolumn{1}{c}{Callaway Sant'Anna} \\"

		local y_1 `"\$Y^{R}_{ct} = \text{Infant deaths}$"'
		local y_2 "\$Y^{R}_{ct} = \text{Infant mortality rate}$"

		// Make top panel - Pooled - All 
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_d1_infant_mortality_robustness.tex", `booktabs_default_options' replace 
		mgroups("`macval(y_1)'" "`macval(y_2)'", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		posthead("`numbers_main' `numbers_main2'") 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
		#delimit cr
		
	}
		
	if "`position'" == "middle" {
			
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_d1_infant_mortality_robustness.tex", `booktabs_default_options' append 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
		#delimit cr

	}

	if "`position'" == "bottom" {
			
		#delimit ;
		esttab p1_c1noPC p1_c2noPC p1_c3noPC p1_c4noPC p1_c1yesPC p1_c2yesPC p1_c3yesPC p1_c4yesPC
		 using "$PROJ_PATH/analysis/output/appendix/table_d1_infant_mortality_robustness.tex", `booktabs_default_options' append 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
		postfoot("\midrule 
			County FE  			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
			Year FE 		& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Controls 			& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No}  & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\");
		#delimit cr
		
	}

}



*********************************************************************************
***** Table D2: Robustness of infant mortality results to log specification *****
*********************************************************************************
eststo clear

local stackMin		-6
local stackMax		6
local depvar_stub	ln_imr_pub
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

	local weightvar `weight_stub'`race_suf'
		
	// Load county-level infant mortality data 
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate infant mortality outcomes + generate weights 
	imdata, mort(mort) suffix(pub)		
	
	// Set local for dependent variable 
	local depvar `depvar_stub'`race_suf'
	
	local lbl: var label `depvar'
	di "`lbl'"
	
	// Add Duke treatment 
	duketreat, treatvar(`treat') time(year) location(fips)
	
	// Create separate time treated variable for Callaway-Sant'Anna
	gen time_treated_2 = time_treated
	replace time_treated_2 = 0 if missing(time_treated)
	
	if "`race'" == "pooled" {
		local position top
	}
	else if "`race'" == "black" {
		local position middle
	}
	else {
		local position bottom
	}
	
	if "`race'" == "pooled" { 
		local table_lbl "\emph{A. Pooled} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
	}
	if "`race'" == "black" { 
		local table_lbl "\emph{B. Black} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
	}
	if "`race'" == "white" { 
		local table_lbl "\emph{C. White} &&& \\ \addlinespace\hspace{.5cm} Percent effect from Duke (=1)" 
	}
	
	// Options for store group
	if "`race'" == "pooled" { 
		local store_group_stub "pool" 
	}
	else {
		local store_group_stub "`race'"
	}
	
	// TWFE OLS estimation

		*Estimation
		eststo p1_c1: reghdfe `depvar' 1.treated [aw = `weightvar'], absorb(fips year) vce(cluster fips)	
		csdid_estadd_level 1.treated, statname("pct_efct_") logs

	// eTWFE  

		*Estimation
		jwdid `depvar' [pw = `weightvar'], ivar(fips) tvar(year) gvar(time_treated_2) 
				
		*Aggregation
		eststo p1_c3: estat simple 
		csdid_estadd_level "", statname("pct_efct_") logs ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
			store_options("sr, mundlak, ln_death_rate, Ycounty, Yyear, Ncontrols, Yweights") ///
			store_group("`store_group_stub'")	
		
		
	// csdid of Callaway and Sant'Anna (2020)

		*Estimation
		csdid `depvar' [iw = `weightvar'], ivar(fips) time(year) gvar(time_treated_2) agg(event)

		*Aggregation
		eststo p1_c4: csdid_estat simple
		csdid_estadd_level "", statname("pct_efct_") logs ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
			store_options("sr, Callaway and Sant'Anna (2020), ln_death_rate, Ycounty, Yyear, Ncontrols, Yweights") ///
			store_group("`store_group_stub'")		
		
	/////////////////////////////////////////////////////////////////////////////////
	// Balanced stacked 
				
	balanced_stacked, ///
		outcome(`depvar') ///
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
	eststo p1_c2: reghdfe `depvar' 1.treated [aw = `weightvar'], absorb(fips##stackID year##stackID) vce(cluster fips) 
	csdid_estadd_level 1.treated, statname("pct_efct_") logs ///
			store ///
			store_filename("$PROJ_PATH/analysis/output/sr_output_vary_spec.txt") ///
			store_options("sr, stacked, ln_death_rate, Ycounty, Yyear, Ncontrols, Yweights") ///
			store_group("`store_group_stub'")
			
	// Prepare table
	if "`position'" == "top" {

		local numbers_main "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\"
		local numbers_main2 "& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Stacked-TWFE} & \multicolumn{1}{c}{eTWFE} & \multicolumn{1}{c}{CS} \\"

		local y_1 `"\$Y^{R}_{ct} = ln(\text{Infant mortality rate})$"'

		// Make top panel - Pooled - All 
		#delimit ;
		esttab p1_c1 p1_c2 p1_c3 p1_c4
		 using "$PROJ_PATH/analysis/output/appendix/table_d2_infant_mortality_log_specs.tex", `booktabs_default_options' replace 
		mgroups("`macval(y_1)'", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		posthead("`numbers_main' `numbers_main2'") 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
		#delimit cr
		
	}
		
	if "`position'" == "middle" {
			
		#delimit ;
		esttab p1_c1 p1_c2 p1_c3 p1_c4
		 using "$PROJ_PATH/analysis/output/appendix/table_d2_infant_mortality_log_specs.tex", `booktabs_default_options' append 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"));
		#delimit cr

	}

	if "`position'" == "bottom" {
			
		#delimit ;
		esttab p1_c1 p1_c2 p1_c3 p1_c4
		 using "$PROJ_PATH/analysis/output/appendix/table_d2_infant_mortality_log_specs.tex", `booktabs_default_options' append 
		stats(pct_efct_b pct_efct_se N, fmt(0 0 %9.0fc) labels("`table_lbl'" "~" "\addlinespace\hspace{.5cm} Observations") layout(@ @ "\multicolumn{1}{c}{@}"))
		postfoot("\midrule 
			County FE  			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}	& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\ 
			Year FE 		& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Weights 			& \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes}  & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{Yes} \\
			Controls 			& \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} \\");
		#delimit cr
		
	}

}



*********************************************************************************************************
***** Figure D1: Stacked event studies for infant mortality - vary window and add/drop controls *********
*********************************************************************************************************

local depvar		imr_pub
local weightvar		births_pub
local race 			pooled 

// Interact controls with stack ID variable 
local baseline_controls_int "stackID##c.percent_illit stackID##c.percent_black stackID##c.percent_other_race stackID##c.percent_urban stackID##c.retail_sales_per_capita stackID#chd_presence"

// Set the number of pre and post periods to include in each stack
local kappa_list 	"3 4 5 6"  

foreach n_pre in `kappa_list' {
	
	local stackMax 		`n_pre'
	local stackMin 		-`n_pre'
	
	foreach cntrl_type in no yes {
		
		if "`cntrl_type'" == "no" {
			local panel "a"
		}
		if "`cntrl_type'" == "yes" {
			local panel "b"
		}
	
		// Load county-level infant mortality data 
		use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

		// Generate infant mortality outcomes + generate weights 
		imdata, mort(mort) suffix(pub)
			
		// Add Duke treatment 
		duketreat, treatvar(`treat') time(year) location(fips)

		// Include controls?
		
		if "`cntrl_type'" == "yes" {
			local stacked_controls `baseline_controls_int'
		}
		else {
			local stacked_controls ""
		}

		/////////////////////////////////////////////////////////////////////////////////
		// Balanced stacked 
				
		balanced_stacked, ///
			outcome(`depvar') ///
			treated(treated) ///
			timeTreated(time_treated) ///
			timeID(year) ///
			groupID(fips) ///
			k_pre(`stackMin') ///
			k_post(`stackMax') ///
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
					`stacked_controls' ///
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
		
		replace b = 0 if missing(b) & order == -1

		////////////////////////////////////////////////////////////////////////////////
		// Figure 
		
		gen new_id = 0 
		replace new_id = 1 if method == "stacked"
		 
		keep if order >= `stackMin'
		keep if order <= `stackMax'
		gsort order
		order order



		local gphMax 6
		local gphMin -6

		local low_label_cap_graph `gphMin'
		local high_label_cap_graph `gphMax'
		sum order 
		local low_event_cap_graph = r(min) - .01
		di "`low_event_cap_graph'"
		local high_event_cap_graph = r(max) + .01
		di "`high_event_cap_graph'"
		
		keep if order >= `low_event_cap_graph' & order < `high_event_cap_graph'

		// Plot estimates
		twoway ///
			|| rarea ll ul order if new_id == 1,  fcol(gs14) lcol(white) msize(3) /// estimates
			|| connected b order if new_id == 1,  lw(1.1) col(white) msize(7) msymbol(s) lp(solid)   /// highlighting
			|| connected b order if new_id == 1,  lw(0.6) col("230 65 115") msize(5) msymbol(s) lp(solid)  /// connect estimates
			|| scatteri 0 `low_label_cap_graph' 0 `high_label_cap_graph', recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
				xlab(`low_label_cap_graph'(1)`high_label_cap_graph' ///
						, nogrid valuelabel labsize(5) angle(0)) ///
				ylab(-20(10)20, nogrid labsize(5) angle(0) format(%3.0f)) ///		
				xtitle("Years since first capital appropriation from Duke Endowment", size(5) height(7)) ///
				xline(-.5, lpattern(dash) lcolor(gs7) lwidth(1)) ///
				xsize(8) ///
				legend(off) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
			*graph export "$PROJ_PATH/analysis/output/appendix/figure_d1`panel'_event_study_pooled_imr_stacked_poisson_kappa_`n_pre'_controls_`cntrl_type'.png", replace
			graph export "$PROJ_PATH/analysis/output/appendix/figure_d1`panel'_event_study_pooled_imr_stacked_poisson_kappa_`n_pre'_controls_`cntrl_type'.pdf", replace 

	}
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
