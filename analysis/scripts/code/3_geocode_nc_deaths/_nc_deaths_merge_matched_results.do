merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bcntry_matched.dta", keep(1 3) nogen

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_comma.dta", keep(1 3) nogen
merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_matched_space.dta", keep(1 3) nogen
replace bstate = bstate_sp if (bstate == 99 | bstate == .) & bstate_sp != 99 & bstate_sp != 99
drop bstate_sp
gen st_mq = 1 if bstate != 99
merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bstate_cross_match.dta", keep(1 3) nogen
replace bstate = bstate_jw if (bstate == 99 | bstate == .) & bstate_jw != 99 & bstate_jw != 99
replace st_mq = jw_st if st_mq == . & jw_st != .
drop bstate_jw jw_st

forvalues n = 1(1)6 {
	gen bctyfips`n' = .
	gen mq`n' = .
	gen bcity`n' = ""
	gen cty_match`n' = 0
}
merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_match_comma.dta", keep(1 3) nogen keepusing(bctyfips)
replace bctyfips1 = bctyfips if bctyfips == .
drop bctyfips
merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/cty_exact_match_space.dta", keep(1 3) nogen keepusing(bctyfips_sp)
replace bctyfips1 = bctyfips_sp if bctyfips1 == . & bctyfips_sp != .
replace bctyfips2 = bctyfips_sp if bctyfips1 != bctyfips_sp & bctyfips_sp != .
drop bctyfips_sp
replace cty_match1 = 1 if bctyfips1 != .
replace cty_match2 = 1 if bctyfips2 != .

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/location_exact_match_comma.dta", keep(1 3) nogen
replace bctyfips1 = bctyfips_loc if bctyfips1 == . & bctyfips_loc != .
replace bcity1 = bcity if bctyfips1 == bctyfips_loc
replace bctyfips2 = bctyfips_loc if bctyfips_loc != bctyfips1 & bctyfips_loc != . & bctyfips2 == .
replace bcity2 = bcity if bctyfips2 == bctyfips_loc
replace bctyfips3 = bctyfips_loc if bctyfips_loc != bctyfips1 & bctyfips_loc != bctyfips2 & bctyfips_loc != . 
replace bcity3 = bcity if bctyfips3 == bctyfips_loc
drop bcity bctyfips_loc
merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/location_exact_match_space.dta", keep(1 3) nogen
replace bctyfips1 = bctyfips_loc_sp if bctyfips1 == . & bctyfips_loc_sp != .
replace bcity1 = bcity_sp if bctyfips1 == bctyfips_loc_sp
replace bctyfips2 = bctyfips_loc_sp if bctyfips_loc_sp != bctyfips1 & bctyfips_loc_sp != . & bctyfips2 == .
replace bcity2 = bcity_sp if bctyfips2 == bctyfips_loc_sp
replace bctyfips3 = bctyfips_loc_sp if bctyfips_loc_sp != bctyfips1 & bctyfips_loc_sp != bctyfips2 & bctyfips_loc_sp != . 
replace bcity3 = bcity_sp if bctyfips3 == bctyfips_loc_sp
drop bcity_sp bctyfips_loc_sp

replace mq1 = 1 if bctyfips1 != .
replace mq2 = 1 if bctyfips2 != .
replace mq3 = 1 if bctyfips3 != .

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bcty_cross_match.dta", keep(1 3) nogen keepusing(bctyfips_jw jw*)
replace bctyfips1 = bctyfips_jw if bctyfips1 == . & bctyfips_jw != .
replace mq1 = jw_bcty if bctyfips1 == bctyfips_jw & mq1 == .
replace cty_match1 = 1 if bctyfips1 == . & bctyfips_jw != .
replace bctyfips2 = bctyfips_jw if bctyfips1 != bctyfips_jw & bctyfips_jw != . & bctyfips2 == .
replace mq2 = jw_bcty if bctyfips2 == bctyfips_jw & mq2 == .
replace cty_match2 = 1 if bctyfips1 != bctyfips_jw & bctyfips_jw != . & bctyfips2 == .
replace bctyfips3 = bctyfips_jw if bctyfips1 != bctyfips_jw & bctyfips2 != bctyfips_jw & bctyfips_jw != . & bctyfips3 == .
replace mq3 = jw_bcty if bctyfips3 == bctyfips_jw & mq3 == .
replace cty_match3 = 1 if bctyfips1 != bctyfips_jw & bctyfips2 != bctyfips_jw & bctyfips_jw != . & bctyfips3 == .
drop bctyfips_jw jw_bcty

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/bloc_cross_match.dta", keep(1 3) nogen keepusing(bctyfips_loc_jw bcity_jw jw*)
replace bctyfips1 = bctyfips_loc_jw if bctyfips1 == . & bctyfips_loc_jw != .
replace bcity1 = bcity_jw if bctyfips1 == bctyfips_loc_jw
replace mq1 = jw_bp if bctyfips1 == bctyfips_loc_jw & mq1 == .
replace bctyfips2 = bctyfips_loc_jw if bctyfips1 != bctyfips_loc_jw & bctyfips_loc_jw != . & bctyfips2 == .
replace bcity2 = bcity_jw if bctyfips2 == bctyfips_loc_jw
replace mq2 = jw_bp if bctyfips2 == bctyfips_loc_jw & mq2 == .
replace bctyfips3 = bctyfips_loc_jw if bctyfips1 != bctyfips_loc_jw & bctyfips2 != bctyfips_loc_jw & bctyfips_loc_jw != . & bctyfips3 == .
replace bcity3 = bcity_jw if bctyfips3 == bctyfips_loc_jw
replace mq3 = jw_bp if bctyfips3 == bctyfips_loc_jw & mq3 == .
replace bctyfips4 = bctyfips_loc_jw if bctyfips1 != bctyfips_loc_jw & bctyfips2 != bctyfips_loc_jw & bctyfips3 != bctyfips_loc_jw & bctyfips_loc_jw != . & bctyfips4 == .
replace bcity4 = bcity_jw if bctyfips4 == bctyfips_loc_jw
replace mq4 = jw_bp if bctyfips4 == bctyfips_loc_jw & mq4 == .
drop bctyfips_loc_jw jw_bp bcity_jw

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/btown_cross_match.dta", keep(1 3) nogen
replace bctyfips1 = bctyfips_uc if bctyfips1 == . & bctyfips_uc != .
replace bcity1 = btown if bctyfips1 == bctyfips_uc
replace mq1 = jw_uc if bctyfips1 == bctyfips_uc & mq1 == .
replace bctyfips2 = bctyfips_uc if bctyfips1 != bctyfips_uc & bctyfips_uc != . & bctyfips2 == .
replace bcity2 = btown if bctyfips2 == bctyfips_uc
replace mq2 = jw_uc if bctyfips2 == bctyfips_uc & mq2 == .
replace bctyfips3 = bctyfips_uc if bctyfips1 != bctyfips_uc & bctyfips2 != bctyfips_uc & bctyfips_uc != . & bctyfips3 == .
replace bcity3 = btown if bctyfips3 == bctyfips_uc
replace mq3 = jw_uc if bctyfips3 == bctyfips_uc & mq3 == .
replace bctyfips4 = bctyfips_uc if bctyfips1 != bctyfips_uc & bctyfips2 != bctyfips_uc & bctyfips3 != bctyfips_uc & bctyfips_uc != . & bctyfips4 == .
replace bcity4 = btown if bctyfips4 == bctyfips_uc
replace mq4 = jw_uc if bctyfips4 == bctyfips_uc & mq4 == .
drop bctyfips_uc jw_uc btown

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/gnis_cross_match.dta", keep(1 3) nogen
replace bctyfips1 = bctyfips_gnis if bctyfips1 == . & bctyfips_gnis != .
replace bcity1 = bcity_gnis if bctyfips1 == bctyfips_gnis
replace mq1 = jw_gnis if bctyfips1 == bctyfips_gnis & mq1 == .
replace bctyfips2 = bctyfips_gnis if bctyfips1 != bctyfips_gnis & bctyfips_gnis != . & bctyfips2 == .
replace bcity2 = bcity_gnis if bctyfips2 == bctyfips_gnis
replace mq2 = jw_gnis if bctyfips2 == bctyfips_gnis & mq2 == .
replace bctyfips3 = bctyfips_gnis if bctyfips1 != bctyfips_gnis & bctyfips2 != bctyfips_gnis & bctyfips_gnis != . & bctyfips3 == .
replace bcity3 = bcity_gnis if bctyfips3 == bctyfips_gnis
replace mq3 = jw_gnis if bctyfips3 == bctyfips_gnis & mq3 == .
replace bctyfips4 = bctyfips_gnis if bctyfips1 != bctyfips_gnis & bctyfips2 != bctyfips_gnis & bctyfips3 != bctyfips_gnis & bctyfips_gnis != . & bctyfips4 == .
replace bcity4 = bcity_gnis if bctyfips4 == bctyfips_gnis
replace mq4 = jw_gnis if bctyfips4 == bctyfips_gnis & mq4 == .
replace bctyfips5 = bctyfips_gnis if bctyfips1 != bctyfips_gnis & bctyfips2 != bctyfips_gnis & bctyfips3 != bctyfips_gnis & bctyfips4 != bctyfips_gnis & bctyfips_gnis != . & bctyfips5 == .
replace bcity5 = bcity_gnis if bctyfips5 == bctyfips_gnis
replace mq5 = jw_gnis if bctyfips5 == bctyfips_gnis & mq5 == .
drop bctyfips_gnis jw_gnis bcity_gnis

merge m:1 bpl using "$PROJ_PATH/analysis/processed/temp/birth_death_match.dta", keep(1 3) nogen
replace bctyfips1 = bctyfips_dp if bctyfips1 == . & bctyfips_dp != .
replace bcity1 = bcity_dp if bctyfips1 == bctyfips_dp & bcity1 == "" & bcity_dp != ""
replace mq1 = jw_dp if bctyfips1 == bctyfips_dp & mq1 == .
replace cty_match1 = 1 if bctyfips1 == . & bctyfips_dp != . & cty_match_dp == 1
replace bctyfips2 = bctyfips_dp if bctyfips1 != bctyfips_dp & bctyfips_dp != . & bctyfips2 == .
replace bcity2 = bcity_dp if bctyfips2 == bctyfips_dp & bcity2 == "" & bcity_dp != ""
replace mq2 = jw_dp if bctyfips2 == bctyfips_dp & mq2 == .
replace cty_match2 = 1 if bctyfips1 != bctyfips_dp & bctyfips_dp != . & bctyfips2 == . & cty_match_dp == 1
replace bctyfips3 = bctyfips_dp if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips_dp != . & bctyfips3 == .
replace bcity3 = bcity_dp if bctyfips3 == bctyfips_dp & bcity3 == "" & bcity_dp != ""
replace mq3 = jw_dp if bctyfips3 == bctyfips_dp & mq3 == .
replace cty_match3 = 1 if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips_dp != . & bctyfips3 == . & cty_match_dp == 1
replace bctyfips4 = bctyfips_dp if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips_dp != . & bctyfips4 == .
replace bcity4 = bcity_dp if bctyfips4 == bctyfips_dp & bcity4 == "" & bcity_dp != ""
replace mq4 = jw_dp if bctyfips4 == bctyfips_dp & mq4 == .
replace cty_match4 = 1 if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips_dp != . & bctyfips4 == . & cty_match_dp == 1
replace bctyfips5 = bctyfips_dp if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips4 != bctyfips_dp & bctyfips_dp != . & bctyfips5 == .
replace bcity5 = bcity_dp if bctyfips5 == bctyfips_dp & bcity5 == "" & bcity_dp != ""
replace mq5 = jw_dp if bctyfips5 == bctyfips_dp & mq5 == .
replace cty_match5 = 1 if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips4 != bctyfips_dp & bctyfips_dp != . & bctyfips5 == . & cty_match_dp == 1
replace bctyfips6 = bctyfips_dp if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips4 != bctyfips_dp & bctyfips5 != bctyfips_dp & bctyfips_dp != . & bctyfips6 == .
replace bcity6 = bcity_dp if bctyfips6 == bctyfips_dp & bcity6 == "" & bcity_dp != ""
replace mq6 = jw_dp if bctyfips6 == bctyfips_dp & mq6 == .
replace cty_match6 = 1 if bctyfips1 != bctyfips_dp & bctyfips2 != bctyfips_dp & bctyfips3 != bctyfips_dp & bctyfips4 != bctyfips_dp & bctyfips5 != bctyfips_dp & bctyfips_dp != . & bctyfips6 == . & cty_match_dp == 1
drop bctyfips_dp jw_dp bcity_dp cty_match_dp
