version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_es_diagnostics.do
* PURPOSE: Run analysis for Appendix I - Event study diagnostics
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

********************************************************************
***** Table I1: Goodman-Bacon (2021a) decomposition diagnostic *****
********************************************************************

local race_group pooled black white

foreach race in `race_group' {

	if "`race'" == "pooled" {
		local race_ind ""
		local panel "a"
	}
	if "`race'" == "black" {
		local race_ind "_bk"
		local panel "b"
	}
	if "`race'" == "white" {
		local race_ind "_wt"
		local panel "c"
	}
		
	// Short-run mortality outcomes
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate DiD treatment variable
	duketreat, treatvar(`treat') time(year) location(fips)

	// Generate infant mortality outcomes 
	imdata, mort(mort) suffix(pub)

	// Flag counties with infant deaths ever equal to zero 
	gegen ever_zero_births = max(births_pub`race_ind' == 0), by(fips)

	// Flag counties with infant deaths ever equal to zero 
	gegen ever_zero_deaths = max(mort`race_ind' == 0), by(fips)
	
	keep if ever_zero_births == 0 & ever_zero_deaths == 0

	save "$PROJ_PATH/analysis/processed/data/R/input/bacon_input.dta", replace


	***** Run Bacon decomposition code in R *****

	shell $RSCRIPT_PATH "$PROJ_PATH/analysis/scripts/code/6.08.1_bacon_decomp.R" `year_start' `year_end' ln_imr_pub`race_ind'
	
	* Get number of comparisons from R output

	use "$PROJ_PATH/analysis/processed/data/R/output/bacon_out.dta", clear

	rename _all, lower

	count if type == "Treated vs Untreated"
	local n_u = r(N)
	count if type == "Earlier vs Later Treated"
	local n_e = r(N)
	count if type == "Later vs Earlier Treated"
	local n_l = r(N)

	local big_n = `n_u' + `n_e' + `n_l'

	* Bacon decomposition in Stata
	
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

	// Generate DiD treatment variable
	duketreat, treatvar(`treat') time(year) location(fips)

	// Generate infant mortality outcomes 
	imdata, mort(mort) suffix(pub)

	// Flag counties with infant deaths ever equal to zero 
	gegen ever_zero_births = max(births_pub`race_ind' == 0), by(fips)

	// Flag counties with infant deaths ever equal to zero 
	gegen ever_zero_deaths = max(imr_pub`race_ind' == 0), by(fips)
	
	keep if ever_zero_births == 0 & ever_zero_deaths == 0	

	xtset fips year
	xtreg ln_imr_pub`race_ind' treated i.year, fe vce(cluster fips)

	if "`race'" != "pooled" {
		local legend "legend(off)"
	} 
	else {
			local legend `"legend(pos(6) col(3) size(medium) label(1 `"Early treat vs. late control"') label(2 `"Late treat vs. early control"')  label(3 `"Treated vs. never treated"'))"'

	}
	
	bacondecomp ln_imr_pub`race_ind' treated, ddetail stub(bacon_) ///
		msizes(6 6 6) gropt(xtitle(, size(8)) ytitle(,size(8)) xlab(, nogrid valuelabel labsize(8) angle(0)) ylab(, nogrid labsize(8) angle(0) format(%03.2f)) xsize(8) `legend' graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white))

	*graph export "$PROJ_PATH/analysis/output/appendix/figure_i1`panel'_bacon_decomp_diagnostic`race_ind'.png", as(png) height(2400) replace
	graph export "$PROJ_PATH/analysis/output/appendix/figure_i1`panel'_bacon_decomp_diagnostic`race_ind'.pdf", replace

	* Create summary table
	 
	// Effect
	sum bacon_B  [aw = bacon_S]
	local avg_dd =  string(r(mean),"%9.3f")
	
	sum bacon_B  [aw = bacon_S] if bacon_cgroup == 2 
	local dd_avg_e = string(r(mean),"%9.3f")
	
	sum bacon_B  [aw = bacon_S] if bacon_cgroup == 1
	local dd_avg_l = string(r(mean),"%9.3f")
	
	sum bacon_B  [aw = bacon_S] if bacon_cgroup == 4
	local dd_avg_u = string(r(mean),"%9.3f")
	
	collapse (count) N = bacon_B (sum) bacon_S , by(bacon_cgroup)

	sum bacon_S
	gen weights = bacon_S/r(sum)
	
	// Weights
	sum weights if bacon_cgroup == 2
	local wt_sum_e = string(r(mean),"%9.3f")
	
	sum weights if bacon_cgroup == 1
	local wt_sum_l = string(r(mean),"%9.3f")
	
	sum weights if bacon_cgroup == 4
	local wt_sum_u = string(r(mean),"%9.3f")
	
	sum weights
	local big_wt =  string(r(sum),"%9.3f")
	
	// Count
	sum N if bacon_cgroup == 2
	local n_e = string(r(mean),"%9.0f")
	
	sum N if bacon_cgroup == 1
	local n_l = string(r(mean),"%9.0f")
	
	sum N if bacon_cgroup == 4
	local n_u = string(r(mean),"%9.0f")
	
	sum N
	local big_n =  string(r(sum),"%9.0f")


	if "`race'" == "pooled" {
		capture file close myfile
		file open myfile using "$PROJ_PATH/analysis/output/appendix/table_i1_bacon_summary.tex", write text replace 
		file write myfile "\multirow{2}{*}{Type of DD comparison} & \multicolumn{1}{c}{Average} & \multicolumn{1}{c}{Number of 2x2} & \multicolumn{1}{c}{Total} \\" _n
		file write myfile "& \multicolumn{1}{c}{Estimate} & \multicolumn{1}{c}{Comparisons} & \multicolumn{1}{c}{Weight} \\" _n
	}
	file write myfile "\midrule" _n
	file write myfile "\addlinespace" _n
	
	if "`race'" == "pooled" {
		file write myfile "\multicolumn{4}{l}{\textit{A. Pooled infant mortality rate}} \\" _n
	}
	if "`race'" == "black" {
		file write myfile "\multicolumn{4}{l}{\textit{B. Black infant mortality rate}} \\" _n
	}
	if "`race'" == "white" {
		file write myfile "\multicolumn{4}{l}{\textit{C. White infant mortality rate}} \\" _n
	}
	file write myfile "\addlinespace" _n
	file write myfile "\multicolumn{1}{l}{Earlier Treated vs. Later Treated Controls} & `dd_avg_e' & \multicolumn{1}{c}{`n_e'} & `wt_sum_e' \\" _n
	file write myfile "\multicolumn{1}{l}{Later Treated vs. Earlier Treated Controls} & `dd_avg_l' & \multicolumn{1}{c}{`n_l'} & `wt_sum_l' \\" _n
	file write myfile "\multicolumn{1}{l}{Treated vs. Untreated Controls} & `dd_avg_u' & \multicolumn{1}{c}{`n_u'} & `wt_sum_u' \\" _n
	file write myfile "\midrule" _n
	file write myfile "\multicolumn{1}{l}{Average DD estimate} & `avg_dd' & \multicolumn{1}{c}{`big_n'} & `big_wt' \\" _n
	
	if "`race'" == "white" file close myfile
	
}


*********************************************************************************************
***** Figure I2: Number of treated counties by event-time period
*********************************************************************************************

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

// Generate DiD treatment variable
duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)

// Generate event time variable 
gen event_time = year - time_treated 
sum event_time 

local event_min = r(min)
local event_max = r(max)

create_treated_bins, ///
	low_event_cap(`event_min') ///
	high_event_cap(`event_max') ///
	y_var("imr_pub") ///
	output_file_name("$PROJ_PATH/analysis/output/appendix/figure_i2_event_study_n_treated_units") ///
	time_variable(year) ///
	id_variable(fips) 

	
disp "DateTime: $S_DATE $S_TIME"

* EOF
