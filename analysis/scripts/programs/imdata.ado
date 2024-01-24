/**** Script: imdata.ado
	* Purpose: 
	*	- corrects observations for which deaths > births --> replaces births with deaths
	*	- constructs infant mortality rates as deaths*1000/births
	*	- constructs log(imr)
	*	- defines racial gap in imr
	*	- generates weights for WLS
	* 	- creates variable labels
*/

cap program drop imdata
program define imdata
	
	syntax, mort(string) suffix(string) 
	
	qui {
		
		// Ensure that births >= deaths. If births 
		
		* Figure out range of non-missing years for births variable
		sum year if !missing(births_`suffix'), d
		local b_min = r(min)
		local b_max = r(max)
		
		* Figure out range of non-missing years for mortality variable
		sum year if !missing(`mort'), d
		local d_min = r(min)
		local d_max = r(max)
		
		* Take min/max
		local min_year = max(`b_min', `d_min')
		local max_year = min(`b_max', `d_max')
		
		replace births_`suffix' = `mort' if !missing(`mort') & `mort' > births_`suffix' & year >= `min_year' & year <= `max_year'
		
		if "`suffix'" != "occ" {
			replace births_`suffix'_bk = `mort'_bk if !missing(`mort'_bk) & `mort'_bk > births_`suffix'_bk & year >= `min_year' & year <= `max_year'
			replace births_`suffix'_wt = `mort'_wt if !missing(`mort'_wt) & `mort'_wt > births_`suffix'_wt & year >= `min_year' & year <= `max_year'
		}
		
		// Pooled infant mortality variables
		
		* IMR - deaths*1000/births
		gen imr_`suffix' = `mort'*1000/births_`suffix'
		
		* log IMR
		gen ln_imr_`suffix' = ln(imr_`suffix')
	
		* log (IMR+1)
		gen ln_imr_p1_`suffix' = ln(imr_`suffix' + 1)
		
		// Labels
		la var imr_`suffix' "Pooled infant mortality rate per 1,000 live births"
		la var ln_imr_`suffix' "Log of pooled infant mortality rate per 1,000 live births"
		la var ln_imr_p1_`suffix' "Log of pooled infant mortality rate per 1,000 live births, plus 1"

		// Measures by race - not for publish births
		
		if "`suffix'" != "occ" {
		
			// IMR by race - black
			gen imr_`suffix'_bk = `mort'_bk*1000/births_`suffix'_bk
			gen ln_imr_`suffix'_bk = ln(imr_`suffix'_bk)
			gen ln_imr_p1_`suffix'_bk = ln(imr_`suffix'_bk + 1)
			
			// IMR by race - white
			gen imr_`suffix'_wt = `mort'_wt*1000/births_`suffix'_wt
			gen ln_imr_`suffix'_wt = ln(imr_`suffix'_wt)
			gen ln_imr_p1_`suffix'_wt = ln(imr_`suffix'_wt + 1)

			// Label variables
			la var imr_`suffix'_wt "White infant mortality rate per 1,000 live births"
			la var imr_`suffix'_bk "Black infant mortality rate per 1,000 live births"
		
			la var ln_imr_`suffix'_wt "Log of White infant mortality rate per 1,000 live births"
			la var ln_imr_`suffix'_bk "Log of Black infant mortality rate per 1,000 live births"

			la var ln_imr_p1_`suffix'_wt "Log of White infant mortality rate per 1,000 live births, plus 1"
			la var ln_imr_p1_`suffix'_bk "Log of Black infant mortality rate per 1,000 live births, plus 1"

			// Create flag counties if black/white births/deaths ever missing/equal to zero
			*gen zero_births = (births_`suffix'_bk == 0 | births_`suffix'_wt == 0)
			*gen zero_births_deaths = (mort_bk == 0 | mort_wt == 0 | births_`suffix'_bk == 0 | births_`suffix'_wt == 0)
			*gegen ever_zero_births = max(births_`suffix'_bk == 0 | births_`suffix'_wt == 0), by(fips)
			*gegen ever_zero_births_deaths = max(mort_bk == 0 | mort_wt == 0 | births_`suffix'_bk == 0 | births_`suffix'_wt == 0), by(fips)
			
		}
	
	}

end
