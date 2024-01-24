capture program drop balanced_stacked
program define balanced_stacked

version 15

syntax, ///
	outcome(varname) ///
	treated(varname) ///
	timeTreated(varname) ///
	timeID(varname) ///
	groupID(varname) ///
	k_pre(integer) ///
	k_post(integer) ///
	year_start_stack(integer) ///
	year_end_stack(integer) ///
	notYetTreated(string) 

	// Assert 
	if `k_pre' >= 0 | `k_post' <= 0 {
		di "k_pre must be a negative integer and k_post must be a positive integer"
	}

	* Step 1: Define an event window
		* This is done using k_pre, k_post, year_start_stack, and year_end_stack above
		* k_pre = -6
		* k_post = 6
		* year_start_stack = 1922
		* year_end_stack = 1942
		* get(groupID)

	* Step 2. Enumerate Sub-Experiments

	// Only keep sub experiments if stack window fully contained within sample window 
	levelsof `timeTreated' if `timeTreated' >= `year_start_stack' - `k_pre' &  `timeTreated' <= `year_end_stack' - `k_post'
	local sub_experiments_to_keep = r(levels)

	// Keep treated observations and never treated observations (and possibly not-yet-treated observations)
	foreach stackYear in `sub_experiments_to_keep' {
		
		preserve
		
			gen keep_obs = 0 
			
			// Treated
			replace keep_obs = 1 if `timeTreated' == `stackYear'  & `timeID' >= (`stackYear' + `k_pre') & `timeID' <= (`stackYear' + `k_post')

			// Never treated
			replace keep_obs = 1 if missing(`timeTreated') & `timeID' >= (`stackYear' + `k_pre') & `timeID' <= (`stackYear' + `k_post')

			// Not yet treated 
			 if ("`notYetTreated'" == "TRUE") {
			 	
				// If unit is treated beyond stack window, recode as not treated 
				replace time_treated = . if `timeTreated' > (`stackYear' + `k_post')
				
				// Not yet treated 
				replace keep_obs = 1 if missing(`timeTreated') & `timeID' >= (`stackYear' + `k_pre') & `timeID' <= (`stackYear' + `k_post')
			
			 }
			 
			// Keep only those observations selected 
			keep if keep_obs == 1
			drop keep_obs 
			
			// Keep only groups present in each year 
			bysort `groupID': gen count = _N
			keep if count == `k_post' - `k_pre' + 1
			drop count 
			  
			 // Add stack-id
			 gen stackID =  `stackYear'
				
			 // Tempfile
			 tempfile stack`stackYear'
			 save "`stack`stackYear''"
	 
		 // Restore
		 restore
	}

	// Append stacks 
	clear
	foreach stackYear in `sub_experiments_to_keep' {
		append using "`stack`stackYear''"
	}

	// Drop any stacks in which there is no control group
	gen temp_ever_treated = 0
	replace temp_ever_treated = 1 if !missing(`timeTreated')
	bysort stackID: egen any_treated = max(temp_ever_treated)
	drop if any_treated == 0
	drop any_treated temp_ever_treated

	order stackID `groupID' `timeID'
	gsort stackID `groupID' `timeID'

end 
