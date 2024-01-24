capture program drop lincomestadd2a
program define lincomestadd2a
syntax anything, statname(name) comtype(string) [format(string) omitstars specName(string) store store_filename(string) store_options(string) store_group(string)]

if "specName" != "" {
	local specAddition ": `specName'"
}

capture which estadd
if _rc {
	di "You need to install estadd/estout first: ssc install estout."
	exit 199
}

if "`comtype'" == "lincom" {
	lincom `anything'
	local pvalue = 2*ttail(r(df), abs(r(estimate)/r(se)))
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}

	local b_est_store `r(estimate)'
	local se_store `r(se)'
	local b_est : di `format' `r(estimate)'
	local se : di `format' `r(se)'
	local t : di `format' `r(estimate)'/`r(se)'
	local bnum = `r(estimate)'
	local senum = `r(se)'
	local tnum = `r(estimate)'/`r(se)'
	

}

if "`comtype'" == "nlcom" {

	// Residual degrees of freedom stored differently in reghdfe vs. ppmlfe
	if "`e(cmd)'" == "ppmlhdfe" {
		local residual_df "`e(df)'"
	}
	else if "`e(cmd)'" == "reghdfe" | "`e(cmd)'" == "ivreghdfe" {
		local residual_df "`e(df_r)'"
	}
	else {
		di "The command `e(cmd)' is unsupported with suboption nlcom."
		exit
	}
	
	nlcom `anything'
	mat b_est = r(b)
	mat V_est = r(V)

	scalar b_est = b_est[1,1]
	local b_est = b_est
	scalar se_v2 = sqrt(V_est[1,1])
	local se_v2 = se_v2
	local  pvalue = 2*ttail(`residual_df',abs(`b_est'/`se_v2'))
	
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}
	
	local b_est_store = `b_est'
	local se_store = `se_v2'	
	local b_est : di `format' `b_est'
	local se : di `format' `se_v2'
	local t : di `format' `b_est'/`se_v2'
	local bnum = `b_est'
	local senum = `se_v2'
	local tnum = `b_est'/`se_v2'
}


if "`comtype'" == "nlcom_pois" {
	nlcom `anything'
	mat b_est = r(b)
	mat V_est = r(V)

	scalar b_est = b_est[1,1]
	local b_est = b_est
	scalar se_v2 = sqrt(V_est[1,1])
	local se_v2 = se_v2
	local  pvalue = 2*ttail(`e(df)',abs(`b_est'/`se_v2'))
	
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}
	
	local b_est_store = `b_est'
	local se_store = `se_v2'
	local b_est : di `format' `b_est'
	local se : di `format' `se_v2'
	local t : di `format' `b_est'/`se_v2'
	local bnum = `b_est'
	local senum = `se_v2'
	local tnum = `b_est'/`se_v2'
}

	// Write to text file
	if "`store'"!="" {
		// Open file
		file open temp_handle using "`store_filename'", write append

		// Save estimate, N, and p-value
		file write temp_handle ///
				%100s "`store_options'" _tab ///
				%5s "`store_group'" _tab ///
				(`b_est_store') _tab ///
				(`se_store') _tab ///
				(`pvalue') _tab ///
				(e(N)) ///
				_n
		// Close file
		file close temp_handle
	}
	
	// Add stars
	local stars ""
	if "`omitstars'" == "" {
		if `pvalue' < 0.10 local stars \sym{*}
		if `pvalue' < 0.05 local stars \sym{**}
		if `pvalue' < 0.01 local stars \sym{***}
	}
	
	// Create string versions of everything
	local bstring `b_est'`stars'
	local sestring (`se')
	local tstring `t'

	estadd local `statname'b "`bstring'"`specAddition'
	estadd local `statname'se "`sestring'"`specAddition'
	estadd local `statname't "`tstring'"`specAddition'

	estadd scalar `statname'b_num = `bnum'`specAddition'
	estadd scalar `statname'se_num = `senum'`specAddition'
	estadd scalar `statname't_num = `tnum'`specAddition'

end
