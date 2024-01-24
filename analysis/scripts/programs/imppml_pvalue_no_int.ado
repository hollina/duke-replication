/**** Script: imppml_pvalue_no_int.ado 
	* Purpose: 
	*	- Runs ppmlhdfe regressions
*/

cap program drop imppml_pvalue_no_int
program define imppml_pvalue_no_int
	
	syntax, y_stub(string) suffix(string) Treated(string) Absorb(string) [pooled controls(string) wgt(string) restrict(string) stacked(string) COLumn(string) save_path(string) save_prefix(string)  store store_filename(string) store_options(string)]
	
	// Options for eststo 
	
	if "`column'" != "" {
		
		local eststo_prefix_pooled 		"eststo p1_c`column': "
		local eststo_prefix_black  		"eststo p2_c`column': "
		local eststo_prefix_white  		"eststo p3_c`column': "

		if "`save_path" != "" {
			local estsave_pooled 		"est save `save_path'/`save_prefix'p1_c`column', replace"
			local estsave_black  		"est save `save_path'/`save_prefix'p2_c`column', replace"
			local estsave_white  		"est save `save_path'/`save_prefix'p3_c`column', replace"
		}
		
	}	
	
	// Preserve absorbing variables for reshape below
	local absorb_vars "`absorb'"
			
	// Options for stacked regression
	
	if "`stacked'" != "" {
	
		// Create locals for interactions of absorb terms with stack ID
		local hash_stack "##`stacked'"
		
		// Interact variables to be absorbed with stack IDs
		
		local n_absorb : word count `absorb'
		
		forvalues j = 1(1)`n_absorb' {
			
			local temp_absorb "`temp_absorb' `: word `j' of `absorb''`hash_stack'"
		}
		
		local absorb "`temp_absorb'"
		
		// Preserve baseline controls for use later in fully interacted specification
		local baseline_controls_for_stacked "`controls'"	
		
		// Create list of controls interacted with stack ID
					
		if "`controls'" != "" {
		
			local n_controls : word count `controls'
			
			forvalues j = 1(1)`n_controls' {
			
				// Check if control is binary
				
				capture assert missing(`: word `j' of `controls'') | inlist(`: word `j' of `controls'', 0, 1)
				
				if _rc == 0 {
					local prefix ""
				}
				else {
					local prefix "#c."
				}
			
				local stacked_controls "`stacked_controls' `stacked'#`prefix'`: word `j' of `controls''"
			}
			
			local controls ""
		}
				
	}
	
	// Options for dependent variable
		* When variable stub is mort - we use mortality counts as y
		* When variable stub is imr - y is the mortality rate
	
	if substr("`y_stub'",1,4) == "mort" {
		
		local depvar_pooled "`y_stub'"
		local depvar_black "`y_stub'_bk"
		local depvar_white "`y_stub'_wt"
	}
	else {
	
		local depvar_pooled "`y_stub'`suffix'"
		local depvar_black "`y_stub'`suffix'_bk"
		local depvar_white "`y_stub'`suffix'_wt"
	}
	
	// Options for weights:
	* (1) birth cohort size for unit of observation (county by year)
	* none

	local wgt_pooled "births_`suffix'"
	local wgt_bk "births_`suffix'_bk"
	local wgt_wt "births_`suffix'_wt"
		
	if "`wgt'" != "" {

		local reg_wgt_pooled "[pw = `wgt_pooled']"
		local reg_wgt_bk "[pw = `wgt_bk']"
		local reg_wgt_wt "[pw = `wgt_wt']"	
	}
	else {

		local reg_wgt_pooled ""
		local reg_wgt_bk ""
		local reg_wgt_wt ""
	}	
	
	if "`restrict'" != "" {
		local if "if `restrict'"
	}
	
	local scaled_coef "exp(_b[1.`treated'])-1"
	local comtype "nlcom"
	
	if "`pooled'" != "" {
	
		// Pooled IMR 
		`eststo_prefix_pooled' ppmlhdfe `depvar_pooled' b0.`treated' `controls' `reg_wgt_pooled' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		// Store coef. 
		if "`store'"!="" {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") ///
			store store_filename("`store_filename'") store_options("`store_options'") store_group("pool")
		} 
		else {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") 
		}
		if "`save_path'" != "" {
			`estsave_pooled'
		}
		
	}
	
	else {
		
		// Black IMR 
		`eststo_prefix_black' ppmlhdfe `depvar_black' b0.`treated' `controls' `reg_wgt_bk' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		// Store coef. 
		if "`store'"!="" {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") ///
			store store_filename("`store_filename'") store_options("`store_options'") store_group("black")
		} 
		else {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") 
		}		
		if "`save_path'" != "" {
			`estsave_black'
		}
		// White IMR 
		`eststo_prefix_white' ppmlhdfe `depvar_white' b0.`treated' `controls' `reg_wgt_wt' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		// Store coef. 
		if "`store'"!="" {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") ///
			store store_filename("`store_filename'") store_options("`store_options'") store_group("white")
		} 
		else {
			lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_") 
		}		
		if "`save_path'" != "" {
			`estsave_white'
		}		
	
	}
	
end
