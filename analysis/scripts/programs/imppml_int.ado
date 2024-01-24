/**** Script: imppml.ado 
	* Purpose: 
	*	- Runs ppmlhdfe regressions
*/

cap program drop imppml_int
program define imppml_int
	
	syntax, y_stub(string) suffix(string) Treated(string) Absorb(string) [pooled controls(string) wgt(string) restrict(string) stacked(string) COLumn(string)]
	
	// Options for eststo 
	
	if "`column'" != "" {
		
		local eststo_prefix_pooled 		"eststo p1_c`column': "
		local eststo_prefix_black  		"eststo p2_c`column': "
		local eststo_prefix_white  		"eststo p3_c`column': "
		local eststo_prefix_interact	"eststo p4_c`column': "
		
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
	
	local scaled_coef "_b[`treated']"
	local comtype "nlcom"
	
	if "`pooled'" != "" {
	
		// Pooled IMR 
		`eststo_prefix_pooled' ppmlhdfe `depvar_pooled' `treated' `controls' `reg_wgt_pooled' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		lincomestadd2a  100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_")
	}
	
	else {
		
		// Black IMR 
		`eststo_prefix_black' ppmlhdfe `depvar_black' `treated' `controls' `reg_wgt_bk' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		lincomestadd2a 100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_")
		
		// White IMR 
		`eststo_prefix_white' ppmlhdfe `depvar_white' `treated' `controls' `reg_wgt_wt' `if', absorb(`absorb' `stacked_controls') vce(cluster fips)
		di "`e(cmdline)'"
		lincomestadd2a 100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_")
		
		// Fully interacted
		preserve
			
			// Drop if restriction
			
			if "`restrict'" != "" {
				keep `if'
			}
			
			// Reshape dataset to do analysis by race
			keep `depvar_white' `depvar_black' `wgt_bk' `wgt_wt' `treated' `controls' `baseline_controls_for_stacked' `absorb_vars' `stacked'
			greshape long `depvar_pooled'_@ `wgt_pooled'_@, i(`absorb_vars' `stacked') j(race_str) string

			local depvar_interact "`depvar_pooled'_"
			
			if "`wgt'" != "" {
				local reg_wgt_interact "[pw = `wgt_pooled'_]"
			}

			gen race = . 
			replace race = 1 if race_str == "wt"
			replace race = 2 if race_str == "bk"

			drop race_str
				
			// Interact variables to be absorbed with race
		
			local n_absorb : word count `absorb'
		
			forvalues j = 1(1)`n_absorb' {
				
				local temp_absorb "`temp_absorb' `: word `j' of `absorb''##i.race"
			}
			
			local absorb "`temp_absorb'"
		
			// If running stacked, replace interacted controls with baseline controls
			
			if "`stacked'" != "" {
				local stack_hash "`stacked'#"
				local controls "`baseline_controls_for_stacked'"
			}
			
			// Create list of controls interacted with race
						
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
				
					local interacted_controls "`interacted_controls' `stack_hash'race#`prefix'`: word `j' of `controls''"
				}
			}
			
			// Store lincom scaled coefficient and interacted coefficient
			
			local scaled_coef "_b[`treated']"
			local int_scaled_coef "_b[2.race#c.`treated']"
			local comtype "nlcom"
						
			// Fully interacted - Racial IMR gap
			
			`eststo_prefix_interact' ppmlhdfe `depvar_interact' i.race##c.`treated' `reg_wgt_interact', absorb(`absorb' `interacted_controls') vce(cluster fips)
			di "`e(cmdline)'"
			lincomestadd2a 100*(`scaled_coef'), comtype(`comtype') statname("pct_efct_")
			lincomestadd2a 100*(`int_scaled_coef'), comtype(`comtype') statname("int_pct_efct_")
		
		restore
	
	}
	
end
