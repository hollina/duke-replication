/**** Script: imdata.ado
	* Purpose: 
	*	- corrects observations for which deaths > births --> replaces births with deaths
	*	- constructs later-life mortality rates as deaths*1000/births
	*	- constructs log(llmr)
	*	- defines racial gap in llmr
	*	- generates weights for WLS
	* 	- creates variable labels
*/

cap program drop llmdata
program define llmdata
	
	syntax, mort(string) scaleby(string) suffix(string)
	
	qui {
		
		if "`scaleby'" == "births" & "`suffix'" == "" {
			di "If scaling dep var by births you need to specify the suffix option"
			exit
		}
		
		// Ensure that births >= deaths.
		
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
		
		// Ensure that population >= deaths 
		replace population = `mort' if !missing(`mort') & `mort' > population
		
		// Later-life mortality variables
		
		if "`scaleby'" == "population" {
			local multiplier = 100000
			local denom "`scaleby'"
		}
		else if "`scaleby'" == "births" {
			local multiplier = 1000
			local denom "`scaleby'_`suffix'"
		}
		
		gen llmr_`scaleby' = `mort'*`multiplier'/`denom'
		
		* log LLMR
		gen ln_llmr_`scaleby' = ln(llmr_`scaleby')
	
		* log (LLMR+1)
		gen ln_llmr_p1_`scaleby' = ln(llmr_`scaleby' + 1)
		
		// Labels
		
		if "`scaleby'" == "population" {
			local rate "100,000 population"
		}
		else if "`scaleby'" == "births" {
			local rate "1,000 live births"
			
		}
		la var llmr_`scaleby' "Pooled later-life mortality rate per `rate'''"
		la var ln_llmr_`scaleby' "Log of pooled later-life mortality rate per `rate'"
		la var ln_llmr_p1_`scaleby' "Log of pooled later-life mortality rate per `rate', plus 1"

		// Flag counties if births/deaths ever missing/equal to zero
		*gen zero_births = (births_`suffix' == 0)
		*gen zero_births_deaths = (`mort' == 0 | births_`suffix' == 0)
		*gegen ever_zero_births = max(births_`suffix' == 0), by(fips)
		*gegen ever_zero_births_deaths = max(`mort' == 0 | births_`suffix' == 0), by(fips)
		
		// Flag county if population ever missing/equal to zero 
		*gen zero_pop = (population == 0)
		*gegen ever_zero_pop = max(population == 0), by(fips)

	}

end
