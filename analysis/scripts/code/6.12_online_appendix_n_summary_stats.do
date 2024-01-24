version 15
disp "DateTime: $S_DATE $S_TIME"

/***********
* SCRIPT: 6.xx_online_appendix_summary_stats.do
* PURPOSE: Produce summary statistics tables for Appendix N. 
************/

// Settings for figures
graph set window fontface "Roboto Light"
graph set ps fontface "Roboto Light"
graph set eps fontface "Roboto Light"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.2f) se(%12.2f) collabels(none) f gaps label mlabels(none) nolines nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01) substitute(\_ _)"

// Control variables
local baseline_controls "percent_illit percent_black percent_other_race percent_urban retail_sales_per_capita chd_presence"

// Duke treatment variable 
local treat 		"capp_all"

// Panel start and end dates
local year_start 	1922
local year_end 		1942
local lr_year_end 	1941

// Later-life mortality restrictions
local age_lb 		56
local age_ub		64
local first_cohort	1932

////////////////////////////////////////////////////////////////////////////////
// Table N1: Treatment 
////////////////////////////////////////////////////////////////////////////////

use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear
	
// Merge in inflation factor
fmerge m:1 year using "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta"
drop if _merge == 2
drop _merge 

// Generate DiD treatment variable
replace capp_all = 0 if missing(capp_all)
replace pay_all = 0 if missing(pay_all)
replace capp_all = capp_all*inv_inflation_factor/1000000
replace pay_all = pay_all*inv_inflation_factor/1000000
replace capp_all = 0 if missing(capp_all)
replace pay_all = 0 if missing(pay_all)

duketreat, treatvar(`treat') time(year) location(fips)

// Generate infant mortality outcomes 
imdata, mort(mort) suffix(pub)
	
label variable treated "\hspace{0.5cm} County-year treatment status (=1)"
label variable capp_all "\hspace{0.5cm} Appropriations, millions"
label variable pay_all "\hspace{0.5cm} Payments, millions"

label variable births_pub "\hspace{0.75cm} Births" 
label variable births_pub_wt "\hspace{0.75cm} Births" 
label variable births_pub_bk "\hspace{0.75cm} Births" 

label variable mort "\hspace{0.75cm} Infant deaths" 
label variable mort_bk "\hspace{0.75cm} Infant deaths" 
label variable mort_wt "\hspace{0.75cm} Infant deaths" 

label variable imr_pub "\hspace{0.75cm} Infant deaths per 1,000 births" 
label variable imr_pub_bk "\hspace{0.75cm} Infant deaths per 1,000 births" 
label variable imr_pub_wt "\hspace{0.75cm} Infant deaths per 1,000 births" 
	sum treated capp_all pay_all
	
// Summarize things that are neither rates nor counts from simple IMR stuff 
estpost summarize  ///
	treated capp_all pay_all 

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", replace ///
	cells("mean(fmt(%20.2f) label(\multicolumn{1}{c}{Mean} )) sd(fmt(%20.2f) label(\multicolumn{1}{c}{S.D.}) ) min(fmt(%20.2f) label(\multicolumn{1}{c}{Min.}) ) max(fmt(%20.2f) label(\multicolumn{1}{c}{Max.})) count(fmt(%3.0f) label(\multicolumn{1}{c}{N}))  ") ///
	nomtitle nonum label f alignment(S S) booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) ///
	refcat(treated "\emph{Short-run treatment and mortality}" treated, nolabel)

estpost summarize  ///
	mort imr_pub births_pub

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline	///
	refcat(mort "\addlinespace \hspace{0.25cm} \emph{Pooled}" mort, nolabel)

estpost summarize  ///
	mort_bk imr_pub_bk births_pub_bk

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline	///
	refcat(mort_bk "\addlinespace \hspace{0.25cm} \emph{Black}" mort_bk, nolabel)
estpost summarize  ///
	mort_wt imr_pub_wt births_pub_wt

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline	///
	refcat(mort_wt "\addlinespace \hspace{0.25cm} \emph{White}" mort_wt, nolabel)

	
////////////////////////////////////////////////////////////////////////////////
// Long run

// Look at county-year population now 
	// Pooled
		use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_pooled.dta", clear
		drop if yodssn > 2005
		capture drop year
		rename yobssn year
		keep if age >= `age_lb'
		keep if age <= `age_ub'
		keep if year >= `first_cohort'
		drop if year > `lr_year_end'
		replace capp_all = 0 if missing(capp_all)

	// Assign treatment
	capture drop treated 
	capture drop first_exp_year
	capture drop ever_treated
	capture drop post
	capture drop time_treated
	duketreat, treatvar(`treat') time(year) location(fips)
	label variable treated "\hspace{0.5cm} County-birth-year treatment status (=1)"
	label variable deaths "\hspace{0.75cm} Deaths in follow-up year"
	label variable population "\hspace{0.75cm} Population alive in follow-up year"

	estpost summarize  ///
		treated

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline	///
	refcat(treated "\addlinespace \emph{Long-run treatment and mortality}" treated, nolabel)

	estpost summarize  ///
		deaths 

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline	///
	refcat(deaths "\addlinespace \hspace{0.25cm}  \emph{Pooled}" deaths, nolabel)


	// By Race
		use "$PROJ_PATH/analysis/processed/data/gompertz_event_study_input_by_race.dta", clear
		
	label variable deaths "\hspace{0.75cm} Deaths in follow-up year"
	label variable population "\hspace{0.75cm} Population alive in follow-up year"

	estpost summarize  ///
		deaths  if race == 2

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(deaths "\addlinespace \hspace{0.25cm}  \emph{Black}" deaths, nolabel)

	estpost summarize  ///
		deaths  if race == 1

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(deaths "\addlinespace \hspace{0.25cm}  \emph{White}" deaths, nolabel)



///////////////////////////////////////////////////////////////////////////////////
// Sulfa 
	use "$PROJ_PATH/analysis/processed/data/nc_vital_stats/shift_share_pneumonia_mortality_22to26.dta", clear
label var base_pneumonia_22to26 "\hspace{0.75cm} Average pooled pneumonia mortality rate, 1922 to 1926"

estpost summarize  ///
	base_pneumonia_22to26

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(base_pneumonia_22to26 "\addlinespace \emph{Sulfa-specification}" base_pneumonia_22to26, nolabel)


///////////////////////////////////////////////////////////////////////////////////
// Controls
	use "$PROJ_PATH/analysis/processed/data/nc_deaths_event_study_input.dta" if statefip == 37 & year >= `year_start' & year <= `year_end', clear

label var percent_illit "\hspace{0.75cm} \% illiterate"
label var percent_black "\hspace{0.75cm} \%  population Black"
label var percent_other_race "\hspace{0.75cm}  \% population other race"
label var percent_urban "\hspace{0.75cm}  \% population urban"
label var retail_sales_per_capita "\hspace{0.75cm} Retail sales per capita"
label var chd_presence "\hspace{0.75cm} County health department present (=1)"

estpost summarize  ///
	`baseline_controls'

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n1_summary_treatment_mortality.tex", append ///
cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
				nomtitle ///
				nonum ///
				label ///
				f ///
				alignment(S S) ///
				collabels(none) ///
				booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
			noobs substitute(\_ _) mlabels(none)  noline ///
	refcat(percent_illit "\addlinespace \emph{Controls}" percent_illit, nolabel)
 
///////////////////////////////////////////////////////////////////////////////////
// Table N2: First stage 
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Hospitals 
	use "$PROJ_PATH/analysis/processed/data/hospitals_county_level_first_stage_data.dta", clear

	// Total Beds and hospitals 
	label variable i_tot_beds_aha "\hspace{0.75cm} Beds" 
	label variable i_tot_beds_aha_pc "\hspace{0.75cm} Beds per 1,000 births" 
	label variable tot_hospitals "\addlinespace \hspace{0.75cm} Hospitals" 
	label variable tot_hospitals_pc "\hspace{0.75cm} Hospitals per 1,000 births" 
		estpost summarize  ///
			i_tot_beds_aha i_tot_beds_aha_pc tot_hospitals tot_hospitals_pc

esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", replace ///
	cells("mean(fmt(%20.2f) label(\multicolumn{1}{c}{Mean} )) sd(fmt(%20.2f) label(\multicolumn{1}{c}{S.D.}) ) min(fmt(%20.2f) label(\multicolumn{1}{c}{Min.}) ) max(fmt(%20.2f) label(\multicolumn{1}{c}{Max.})) count(fmt(%3.0f) label(\multicolumn{1}{c}{N}))  ") ///
	nomtitle nonum label f alignment(S S) booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
	noobs substitute(\_ _) ///
		refcat(i_tot_beds_aha "\addlinespace\emph{Short-run hospital data} &&&&& \\ \addlinespace \hspace{0.25cm}  \emph{Total}" i_tot_beds_aha, nolabel)

	label variable i_likely_beds_aha "\hspace{0.75cm} Beds" 
	label variable i_likely_beds_aha_pc "\hspace{0.75cm} Beds per 1,000 births" 
	label variable tot_hosp_likely "\addlinespace \hspace{0.75cm} Hospitals" 
	label variable tot_hosp_likely_pc "\hspace{0.75cm} Hospitals per 1,000 births" 
		estpost summarize  ///
			i_likely_beds_aha i_likely_beds_aha_pc tot_hosp_likely tot_hosp_likely_pc

	esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
					nomtitle ///
					nonum ///
					label ///
					f ///
					alignment(S S) ///
					collabels(none) ///
					booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
				noobs substitute(\_ _) mlabels(none)  noline ///
		refcat(i_likely_beds_aha "\addlinespace \hspace{0.25cm}  \emph{Non-profit/Public/Church}" i_likely_beds_aha, nolabel)

	label variable i_prop_beds_aha "\hspace{0.75cm} Beds" 
	label variable i_prop_beds_aha_pc "\hspace{0.75cm} Beds per 1,000 births" 
	label variable tot_hosp_prop "\addlinespace \hspace{0.75cm} Hospitals" 
	label variable tot_hosp_prop_pc "\hspace{0.75cm} Hospitals per 1,000 births" 
		estpost summarize  ///
			i_prop_beds_aha i_prop_beds_aha_pc tot_hosp_prop tot_hosp_prop_pc

	esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
					nomtitle ///
					nonum ///
					label ///
					f ///
					alignment(S S) ///
					collabels(none) ///
					booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
				noobs substitute(\_ _) mlabels(none)  noline ///
		refcat(i_prop_beds_aha "\addlinespace \hspace{0.25cm}  \emph{Proprietary}" i_prop_beds_aha, nolabel)
		

///////////////////////////////////////////////////////////////////////////////////
// Doctors 
	local qual "2yr"
	local good_var good_`qual'
	local bad_var bad_`qual'
	local suffix "_`qual'_as_quality"
	local depvar md

	// Load data 
	use "$PROJ_PATH/analysis/processed/data/amd_county-by-year_binned_panel.dta", clear


	// Total Beds and hospitals 
	label variable md "\hspace{0.75cm} Doctors" 
	label variable rmd "\hspace{0.75cm} Doctors per 1,000 births" 

	label variable md_good_2yr "\addlinespace \hspace{0.75cm} High-quality doctors" 
	label variable rmd_good_2yr "\hspace{0.75cm} High-quality doctors per 1,000 births" 

	label variable md_bad_2yr "\addlinespace \hspace{0.75cm} Low-quality doctors" 
	label variable rmd_bad_2yr "\hspace{0.75cm} Low-quality doctors per 1,000 births" 

	foreach race in black white {
		label variable md_`race' "\hspace{0.75cm} Doctors" 
		label variable rmd_`race' "\hspace{0.75cm} Doctors per 1,000 births" 

		label variable md_good_2yr_`race' "\addlinespace \hspace{0.75cm} High-quality doctors" 
		label variable rmd_good_2yr_`race' "\hspace{0.75cm} High-quality doctors per 1,000 births" 

		label variable md_bad_2yr_`race' "\addlinespace \hspace{0.75cm} Low-quality doctors" 
		label variable rmd_bad_2yr_`race' "\hspace{0.75cm} Low-quality doctors per 1,000 births" 
	}


		estpost summarize  ///
			md rmd md_good_2yr rmd_good_2yr md_bad_2yr rmd_bad_2yr

	esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
					nomtitle ///
					nonum ///
					label ///
					f ///
					alignment(S S) ///
					collabels(none) ///
					booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
				noobs substitute(\_ _) mlabels(none)  noline ///
		refcat(md "\addlinespace\emph{Short-run doctor data} &&&&& \\ \addlinespace \hspace{0.25cm}  \emph{Pooled}" md, nolabel)
	label variable md "\hspace{0.75cm} Doctors" 
	label variable rmd "\hspace{0.75cm} Doctors per 1,000 births" 

	label variable md_good_2yr "\addlinespace \hspace{0.75cm} High-quality doctors" 
	label variable rmd_good_2yr "\hspace{0.75cm} High-quality doctors per 1,000 births" 

	label variable md_bad_2yr "\addlinespace \hspace{0.75cm} Low-quality doctors" 
	label variable rmd_bad_2yr "\hspace{0.75cm} Low-quality doctors per 1,000 births" 
	
// Black
		estpost summarize  ///
			md_black rmd_black md_good_2yr_black rmd_good_2yr_black md_bad_2yr_black rmd_bad_2yr_black

	esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
					nomtitle ///
					nonum ///
					label ///
					f ///
					alignment(S S) ///
					collabels(none) ///
					booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
				noobs substitute(\_ _) mlabels(none)  noline ///
		refcat(md_black "\addlinespace \hspace{0.25cm}  \emph{Black}" md_black, nolabel)
		
// White
		estpost summarize  ///
			md_white rmd_white md_good_2yr_white rmd_good_2yr_white md_bad_2yr_white rmd_bad_2yr_white

	esttab . using "$PROJ_PATH/analysis/output/appendix/table_n2_summary_first_stage.tex", append ///
	cells("mean(fmt(%20.2f)) sd(fmt(%20.2f)) min(fmt(%20.2f)) max(fmt(%20.2f)) count(fmt(%3.0f))  ") ///
					nomtitle ///
					nonum ///
					label ///
					f ///
					alignment(S S) ///
					collabels(none) ///
					booktabs nomtitles b(%20.2f) se(%20.2f) eqlabels(none) eform  ///
				noobs substitute(\_ _) mlabels(none)  noline ///
		refcat(md_white "\addlinespace \hspace{0.25cm}  \emph{White}" md_white, nolabel)

		
disp "DateTime: $S_DATE $S_TIME"

* EOF