capture program drop csdid_estadd_level

program define csdid_estadd_level
syntax anything, statname(name) [format(string) omitstars store store_filename(string) store_options(string) store_group(string) logs]

	* Retrieve stored estimates from r(table)
	matrix r_table = r(table)
	
	if "`e(cmd)'" == "reghdfe"  {
		
		* Check if specified variable is included in regression
		local var_names: colnames r_table 
		local n_var : word count `var_names'
		
		local i = 0
		forvalues j = 1(1)`n_var' {
			capture assert "`: word `j' of `var_names''" == "`anything'"
			if _rc == 0 { 
				local i = `i' + 1 
			}
		}
		if `i' == 0 {
			di in red "The specified variable is not included in the model."
			exit
		}
		
	}
	
	if "`e(cmd)'" == "reghdfe" |   "`e(cmd)'" == "jwdid" {

		local b = r_table[rownumb(r_table,"b"),colnumb(r_table,"`anything'")]
		local se = r_table[rownumb(r_table,"se"),colnumb(r_table,"`anything'")]
		
		local b = `b'
		local se = `se'
		
		local t = r_table[rownumb(r_table,"t"),colnumb(r_table,"`anything'")]
		local pvalue = r_table[rownumb(r_table,"pvalue"),colnumb(r_table,"`anything'")]
		assert `pvalue' ~= .
			
	}
	if "`e(cmd)'" == "jwdid" {
				
		local b = r_table[rownumb(r_table,"b"),colnumb(r_table,"r2vs1._at")]
		local se = r_table[rownumb(r_table,"se"),colnumb(r_table,"r2vs1._at")]
		
				
		local b = `b'
		local se = `se'
		
		local t = r_table[rownumb(r_table,"z"),colnumb(r_table,"r2vs1._at")]
		local pvalue = r_table[rownumb(r_table,"pvalue"),colnumb(r_table,"r2vs1._at")]
		assert `pvalue' ~= .
	}
	
	if "`e(cmd)'" == "csdid" {
				
		local b = r_table[rownumb(r_table,"b"),colnumb(r_table,"ATT")]
		local se = r_table[rownumb(r_table,"se"),colnumb(r_table,"ATT")]
		
				
		local b = `b'
		local se = `se'
		
		local t = r_table[rownumb(r_table,"z"),colnumb(r_table,"ATT")]
		local pvalue = r_table[rownumb(r_table,"pvalue"),colnumb(r_table,"ATT")]
		assert `pvalue' ~= .
	}
	
	if "`format'" == "" {
		local format %04.2f
	}
	
	if "`logs'" != "" {
		local log_adjust "*100"
	}
	
	local b_est_store = `b'`log_adjust'
	local se_est_store = `se'`log_adjust'	
	local b_est : di `format' `b'
	local se_est : di `format' `se'
	local t_est : di `format' `t'
	local bnum = `b'
	local senum = `se'
	local tnum = `t'
	
	// Write to text file
	if "`store'"!="" {
		// Open file
		file open temp_handle using "`store_filename'", write append

		// Save estimate, N, and p-value
		file write temp_handle ///
				%100s "`store_options'" _tab ///
				%5s "`store_group'" _tab ///
				(`b_est_store') _tab ///
				(`se_est_store') _tab ///
				(`pvalue') _tab ///
				(e(N)) ///
				_n
		// Close file
		file close temp_handle
	}
		
	local stars ""
	if "`omitstars'" == "" {
		if `pvalue' < 0.10 local stars \sym{*}
		if `pvalue' < 0.05 local stars \sym{**}
		if `pvalue' < 0.01 local stars \sym{***}
	}

	local bstring `b_est'`stars'
	local sestring (`se_est')
	local tstring `t_est'

	estadd local `statname'b "`bstring'"
	estadd local `statname'se "`sestring'"
	estadd local `statname't "`tstring'"

	estadd scalar `statname'b_num = `bnum'
	estadd scalar `statname'se_num = `senum'
	estadd scalar `statname't_num = `tnum'


end
