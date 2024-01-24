version 15
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 1_process_raw_data.do
* PURPOSE: imports the raw data and saves it in Stata readable format
************

************
* Code begins
************

// User switches for each section of code
local icpsr				1
local nhgis				1
local hospitals 		1
local duke				1
local chd 				1
local vital_stats 		1
local amd_physicians	1
local amd_med_schools	1 
local southern_deaths	1
local nc_pop			1
local gnis				1
local south_pop			1
local numident			1

// Save archived version of intermediate files 
local update 			0

***********************************
// Process ICPSR county codes *****
***********************************

if `icpsr' {
	
	// Source for ICPSR county codes: https://usa.ipums.org/usa/volii/ICPSR.shtml
	import excel using "$PROJ_PATH/analysis/raw/icpsr/icpsrcnt.xls", firstrow case(lower) cellrange(A1:E3261) clear
	drop if state == ""
	compress
	save "$PROJ_PATH/analysis/processed/intermediate/icpsr/icpsr_county_codes_uncleaned.dta", replace
}

********************************
// Process raw NHGIS files *****
********************************

if `nhgis' {

	// Extract 1900 to 1960 NHGIS county boundary files (2000 TL)
	forvalues y = 1900(10)1960 {
			
		// Clear previous instances of running shp2dta
		local filelist : dir "$PROJ_PATH/analysis/raw/nhgis/nhgis0033_shapefile_tl2000_us_county_`y'" files "*", respectcase
		foreach file in `filelist' {
			cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'/`file'"
		}
		cap mkdir "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'"
		
		// Copy raw files NHGIS shapefiles to intermediate folder 
		foreach file in `filelist' {
			cp "$PROJ_PATH/analysis/raw/nhgis/nhgis0033_shapefile_tl2000_us_county_`y'/`file'" "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'/`file'"
		}
		
		cd "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'"
		cap rm "nhgis_`y'_db.dta"
		cap rm "nhgis_`y'_coord.dta"
		shp2dta using US_county_`y', database(nhgis_`y'_db) coordinates(nhgis_`y'_coord) genid(nhgis_id)
		cp "nhgis_`y'_db.dta" "$PROJ_PATH/analysis/processed/intermediate/nhgis/nhgis_`y'_db.dta", replace
		*cp "nhgis_`y'_coord.dta" "$PROJ_PATH/analysis/processed/intermediate/nhgis/nhgis_`y'_coord.dta", replace
		rm "nhgis_`y'_db.dta"
		rm "nhgis_`y'_coord.dta"
		
		// Clear previous instances of running shp2dta
		local filelist : dir "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'" files "*", respectcase
		foreach file in `filelist' {
			cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'/`file'"
		}
		cd "$PROJ_PATH"
		rmdir "$PROJ_PATH/analysis/processed/temp/nhgis0033_shapefile_tl2000_us_county_`y'"
	
	}
	
	********************************
	// Load raw NHGIS table ********
	********************************

	// 1900
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  aym001    159-167  ///
	  double  ayt001    168-176  ///
	  double  ayt002    177-185  ///
	  double  azf001    186-194  ///
	  double  azf002    195-203  ///
	  double  azf003    204-212  ///
	  double  azf004    213-221  ///
	  double  az3001    222-230  ///
	  double  az3002    231-239  ///
	  double  az3003    240-248  ///
	  double  az3004    249-257  ///
	  double  ays001    258-266  ///
	  double  ays002    267-275  ///
	  double  ays003    276-284  ///
	  double  ays004    285-293  ///
	  double  ays005    294-302  ///
	  double  aza001    303-317  ///
	  double  aza002    318-332  ///
	  double  azc001    333-347  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds31_1900_county.dat", clear

	format aym001   %9.0f
	format ayt001   %9.0f
	format ayt002   %9.0f
	format azf001   %9.0f
	format azf002   %9.0f
	format azf003   %9.0f
	format azf004   %9.0f
	format az3001   %9.0f
	format az3002   %9.0f
	format az3003   %9.0f
	format az3004   %9.0f
	format ays001   %9.0f
	format ays002   %9.0f
	format ays003   %9.0f
	format ays004   %9.0f
	format ays005   %9.0f
	format aza001   %15.0f
	format aza002   %15.0f
	format azc001   %15.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var aym001   `"Total"'
	label var ayt001   `"Urban"'
	label var ayt002   `"Rural"'
	label var azf001   `"Native-born >> Male"'
	label var azf002   `"Native-born >> Female"'
	label var azf003   `"Foreign-born >> Male"'
	label var azf004   `"Foreign-born >> Female"'
	label var az3001   `"Other Colored >> Male"'
	label var az3002   `"Other Colored >> Female"'
	label var az3003   `"Negro >> Male"'
	label var az3004   `"Negro >> Female"'
	label var ays001   `"White: Native-born of native parentage"'
	label var ays002   `"White: Native-born of foreign parentage"'
	label var ays003   `"White: Foreign-born"'
	label var ays004   `"Colored, including Negro"'
	label var ays005   `"Negro"'
	label var aza001   `"Wages in manufacturing >> Male"'
	label var aza002   `"Wages in manufacturing >> Female"'
	label var azc001   `"Wages in manufacturing"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds31_1900_county.dta", replace
	 
	// 1910
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  a3y001    159-167  ///
	  double  a3y002    168-176  ///
	  double  a36001    177-185  ///
	  double  a43001    186-194  ///
	  double  a43002    195-203  ///
	  double  a3z001    204-212  ///
	  double  a3z002    213-221  ///
	  double  a30001    222-230  ///
	  double  a30002    231-239  ///
	  double  a30003    240-248  ///
	  double  a30004    249-257  ///
	  double  a38001    258-266  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds37_1910_county.dat", clear
	 
	format a3y001   %9.0f
	format a3y002   %9.0f
	format a36001   %9.0f
	format a43001   %9.0f
	format a43002   %9.0f
	format a3z001   %9.0f
	format a3z002   %9.0f
	format a30001   %9.0f
	format a30002   %9.0f
	format a30003   %9.0f
	format a30004   %9.0f
	format a38001   %9.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var a3y001   `"1910"'
	label var a3y002   `"1900"'
	label var a36001   `"Total"'
	label var a43001   `"Urban (populations residing in places of 2,500 or more persons)"'
	label var a43002   `"Rural (populations residing in remainder of county/state)"'
	label var a3z001   `"Male"'
	label var a3z002   `"Female"'
	label var a30001   `"White >> Male"'
	label var a30002   `"White >> Female"'
	label var a30003   `"Negro >> Male"'
	label var a30004   `"Negro >> Female"'
	label var a38001   `"Total"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds37_1910_county.dta", replace

	// 1920 
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  a7l001    159-167  ///
	  double  a7t001    168-176  ///
	  double  a7t002    177-185  ///
	  double  a8b001    186-194  ///
	  double  a8b002    195-203  ///
	  double  a8l001    204-212  ///
	  double  a8l002    213-221  ///
	  double  a8l003    222-230  ///
	  double  a8l004    231-239  ///
	  double  a8l005    240-248  ///
	  double  a8l006    249-257  ///
	  double  a7u001    258-266  ///
	  double  a78001    267-281  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds43_1920_county.dat", clear

	format a7l001   %9.0f
	format a7t001   %9.0f
	format a7t002   %9.0f
	format a8b001   %9.0f
	format a8b002   %9.0f
	format a8l001   %9.0f
	format a8l002   %9.0f
	format a8l003   %9.0f
	format a8l004   %9.0f
	format a8l005   %9.0f
	format a8l006   %9.0f
	format a7u001   %9.0f
	format a78001   %15.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var a7l001   `"Total"'
	label var a7t001   `"Urban"'
	label var a7t002   `"Rural"'
	label var a8b001   `"Male"'
	label var a8b002   `"Female"'
	label var a8l001   `"White: Native-born >> Male"'
	label var a8l002   `"White: Native-born >> Female"'
	label var a8l003   `"White: Foreign-born >> Male"'
	label var a8l004   `"White: Foreign-born >> Female"'
	label var a8l005   `"Negro >> Male"'
	label var a8l006   `"Negro >> Female"'
	label var a7u001   `"Total"'
	label var a78001   `"Wages of wage earners"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds43_1920_county.dta", replace

	// 1930 
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  bdp001    159-167  ///
	  double  bdx001    168-176  ///
	  double  beg001    177-185  ///
	  double  beg002    186-194  ///
	  double  bep001    195-203  ///
	  double  bep002    204-212  ///
	  double  bep003    213-221  ///
	  double  bep004    222-230  ///
	  double  bep005    231-239  ///
	  double  bep006    240-248  ///
	  double  bdv001    249-257  ///
	  double  beb001    258-272  ///
	  double  bet001    273-284  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds54_1930_county.dat", clear

	format bdp001   %9.0f
	format bdx001   %9.0f
	format beg001   %9.0f
	format beg002   %9.0f
	format bep001   %9.0f
	format bep002   %9.0f
	format bep003   %9.0f
	format bep004   %9.0f
	format bep005   %9.0f
	format bep006   %9.0f
	format bdv001   %9.0f
	format beb001   %15.0f
	format bet001   %15.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var bdp001   `"Total"'
	label var bdx001   `"Total"'
	label var beg001   `"Male"'
	label var beg002   `"Female"'
	label var bep001   `"White: Native-born >> Male"'
	label var bep002   `"White: Native-born >> Female"'
	label var bep003   `"White: Foreign-born >> Male"'
	label var bep004   `"White: Foreign-born >> Female"'
	label var bep005   `"Negro >> Male"'
	label var bep006   `"Negro >> Female"'
	label var bdv001   `"Total"'
	label var beb001   `"Annual wages in manufacturing, 1929"'
	label var bet001   `"Net sales of retail distribution stores, 1929"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds54_1930_county.dta", replace

	// 1940
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  bv7001    159-167  ///
	  double  bw1001    168-176  ///
	  double  bxn001    177-185  ///
	  double  bxn002    186-194  ///
	  double  bya001    195-203  ///
	  double  bya002    204-212  ///
	  double  bya003    213-221  ///
	  double  bya004    222-230  ///
	  double  bw2001    231-245  ///
	  double  bxh001    246-257  ///
	  double  bxh002    258-269  ///
	  double  bxh003    270-281  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds78_1940_county.dat", clear

	format bv7001   %9.0f
	format bw1001   %9.0f
	format bxn001   %9.0f
	format bxn002   %9.0f
	format bya001   %9.0f
	format bya002   %9.0f
	format bya003   %9.0f
	format bya004   %9.0f
	format bw2001   %15.0f
	format bxh001   %15.0f
	format bxh002   %15.0f
	format bxh003   %15.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var bv7001   `"Total"'
	label var bw1001   `"Total"'
	label var bxn001   `"Male"'
	label var bxn002   `"Female"'
	label var bya001   `"White: Native-born"'
	label var bya002   `"White: Foreign-born"'
	label var bya003   `"Negro"'
	label var bya004   `"Other"'
	label var bw2001   `"Wages paid in manufacturing, 1939"'
	label var bxh001   `"Sales, 1939 >> Retail stores"'
	label var bxh002   `"Sales, 1939 >> Wholesale business establishments"'
	label var bxh003   `"Sales, 1939 >> Service establishments"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds78_1940_county.dta", replace

	// 1950
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  b18001    159-167  ///
	  double  b2j001    168-176  ///
	  double  b3e001    177-185  ///
	  double  b3e002    186-194  ///
	  double  b3p001    195-203  ///
	  double  b3p002    204-212  ///
	  double  b3p003    213-221  ///
	  double  b3p004    222-230  ///
	  double  b3p005    231-239  ///
	  double  b3p006    240-248  ///
	  double  b3p007    249-257  ///
	  double  b3p008    258-266  ///
	  using "$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds84_1950_county.dat", clear

	format b18001   %9.0f
	format b2j001   %9.0f
	format b3e001   %9.0f
	format b3e002   %9.0f
	format b3p001   %9.0f
	format b3p002   %9.0f
	format b3p003   %9.0f
	format b3p004   %9.0f
	format b3p005   %9.0f
	format b3p006   %9.0f
	format b3p007   %9.0f
	format b3p008   %9.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var b18001   `"Total"'
	label var b2j001   `"Total"'
	label var b3e001   `"Male"'
	label var b3e002   `"Female"'
	label var b3p001   `"Male >> White: Native-born"'
	label var b3p002   `"Male >> White: Foreign-born"'
	label var b3p003   `"Male >> Negro"'
	label var b3p004   `"Male >> Other"'
	label var b3p005   `"Female >> White: Native-born"'
	label var b3p006   `"Female >> White: Foreign-born"'
	label var b3p007   `"Female >> Negro"'
	label var b3p008   `"Female >> Other"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds84_1950_county.dta", replace

	// 1960 
	quietly infix                ///
	  str     year      1-4      ///
	  str     state     5-28     ///
	  str     statea    29-31    ///
	  str     county    32-88    ///
	  str     countya   89-92    ///
	  str     areaname  93-158   ///
	  double  b5o001    159-167  ///
	  double  b5r001    168-176  ///
	  double  b5r002    177-185  ///
	  double  b5s001    186-194  ///
	  double  b5s002    195-203  ///
	  double  b5s003    204-212  ///
	  double  b5s004    213-221  ///
	  double  b5s005    222-230  ///
	  double  b5s006    231-239  ///
	  double  b5s007    240-248  ///
	  double  b5s008    249-257  ///
	  double  b5s009    258-266  ///
	  double  b5s010    267-275  ///
	  double  b5s011    276-284  ///
	  double  b5s012    285-293  ///
	  double  b5s013    294-302  ///
	  double  b5s014    303-311  ///
	  using `"$PROJ_PATH/analysis/raw/nhgis/tables/nhgis0029_ds91_1960_county.dat"', clear

	format b5o001   %9.0f
	format b5r001   %9.0f
	format b5r002   %9.0f
	format b5s001   %9.0f
	format b5s002   %9.0f
	format b5s003   %9.0f
	format b5s004   %9.0f
	format b5s005   %9.0f
	format b5s006   %9.0f
	format b5s007   %9.0f
	format b5s008   %9.0f
	format b5s009   %9.0f
	format b5s010   %9.0f	
	format b5s011   %9.0f
	format b5s012   %9.0f
	format b5s013   %9.0f
	format b5s014   %9.0f

	label var year     `"Data File Year"'
	label var state    `"State Name"'
	label var statea   `"State Code"'
	label var county   `"County Name"'
	label var countya  `"County Code"'
	label var areaname `"Area name"'
	label var b5o001   `"Total"'
	label var b5r001   `"Male"'
	label var b5r002   `"Female"'
	label var b5s001   `"Male >> White"'
	label var b5s002   `"Male >> Negro"'
	label var b5s003   `"Male >> Indian"'
	label var b5s004   `"Male >> Japanese"'
	label var b5s005   `"Male >> Chinese"'
	label var b5s006   `"Male >> Filipino"'
	label var b5s007   `"Male >> Other races"'
	label var b5s008   `"Female >> White"'
	label var b5s009   `"Female >> Negro"'
	label var b5s010   `"Female >> Indian"'
	label var b5s011   `"Female >> Japanese"'
	label var b5s012   `"Female >> Chinese"'
	label var b5s013   `"Female >> Filipino"'
	label var b5s014   `"Female >> Other races"'

	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/ds91_1960_county.dta", replace
	
// 	// Create stata version of crosswalk
// 	import delimited "$PROJ_PATH/analysis/raw/nhgis/crosswalk/eglp_county_crosswalk_endyr_2010.csv", clear
// 	drop icpsrst_2010 icpsrcty_2010
// 	save "$PROJ_PATH/analysis/processed/intermediate/nhgis/eglp_county_crosswalk_endyr_2010.dta", replace 
		
}

**************************************************************
// Process raw hospital files from AMD, AMD, and Pollitt *****
**************************************************************

if `hospitals' {

	foreach y of numlist 1921 1926 1928/1951 { 
		import excel using "$PROJ_PATH/analysis/raw/ama/Final_AMA_Hospitals_`y'.xlsx", clear firstrow case(lower)
		capture tostring averagebedsinuse, replace
		capture tostring beds, replace
		capture tostring notes, replace
		
		gen Year = `y'
		tempfile carohosp`y'
		save `carohosp`y'', replace
	}
	clear
	foreach y of numlist 1921 1926 1928/1951 {
		append using `carohosp`y''
	}
	
	// Fix error in 1940 AMA
	replace beds = "2324" if beds == "23241" & pdfno == 41 & Year == 1940

	save "$PROJ_PATH/analysis/processed/intermediate/ama/ama_carolina_hospitals_uncleaned.dta", replace

	// Load internship data
	import excel using "$PROJ_PATH/analysis/raw/ama/Internships.xlsx", sheet("Sheet1") clear
	*compress
	save "$PROJ_PATH/analysis/processed/intermediate/ama/intership_hospitals.dta", replace
	
	// Load combined AMA/AHA/AMD hospital data 
	import excel using "$PROJ_PATH/analysis/raw/hospitals/all_hosp.xlsx", sheet("Sheet1") firstrow clear
	drop if year == 1911
	save "$PROJ_PATH/analysis/processed/intermediate/hospitals/aha_amd_hospitals_combined.dta", replace

	// Load African American hospitals from Pollitt
	import excel using "$PROJ_PATH/analysis/raw/hospitals/pollitt-nc-african-american-hospitals.xlsx", sheet("African American Hospitals") firstrow case(lower) allstring clear
	save "$PROJ_PATH/analysis/processed/intermediate/hospitals/pollitt_nc_african_american_hospitals.dta", replace
	
	// Load state and federal institutions from AMD 
	import excel using "$PROJ_PATH/analysis/raw/amd_hospitals/amd_state_and_federal_institutions.xlsx", firstrow case(lower) allstring clear
	destring year, replace
	keep state city hospitalname yearestablished publicorprivate type beds year
	save "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/amd_state_and_federal_institutions.dta", replace
	
	// Load raw AMD hospital data 
	local year_list "1906 1909 1912 1916 1918 1921 1923"

	foreach y of local year_list {
		import excel using "$PROJ_PATH/analysis/raw/amd_hospitals/Final_AMD_`y'.xlsx", firstrow case(lower) allstring clear
		gen year = `y'
		order year 
		save "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/Final_AMD_`y'.dta", replace
	}

	local another_year_list "1925 1927 1929 1931 1934 1936 1938 1940 1942"

	foreach z of local another_year_list {
		import excel using "$PROJ_PATH/analysis/raw/amd_hospitals/Final_`z'-North Carolina.xlsx", firstrow case(lower) allstring clear
		keep if !missing(state)
		gen year = `z'
		order year 
		save "$PROJ_PATH/analysis/processed/intermediate/amd_hospitals/Final_AMD_`z'.dta", replace 
	}

}

*******************************
// Process raw Duke files *****
*******************************

if `duke' {

	// Create inflation factor by year
	import excel "$PROJ_PATH/analysis/raw/duke/inflation_factors.xlsx", sheet("Sheet1") firstrow clear
	save "$PROJ_PATH/analysis/processed/intermediate/duke/inflation_factors.dta", replace

	// Create financial data
	import excel "$PROJ_PATH/analysis/raw/duke/returns_by_year.xlsx", sheet("Sheet1") firstrow cellrange(A1:M35) clear 
	save "$PROJ_PATH/analysis/processed/intermediate/duke/returns_by_year.dta", replace

		// List of hospital locations
		import excel using "$PROJ_PATH/analysis/raw/duke/labc_locations_1925_1962.xlsx", firstrow case(lower) clear
		save "$PROJ_PATH/analysis/processed/intermediate/duke/labc_locations_1925_1962.dta", replace

		// List of locations receiving capital expenditures, 1927-1938
		import excel "$PROJ_PATH/analysis/raw/duke/ce_locations_1927_1938.xlsx", sheet("Locations") firstrow clear 
		save "$PROJ_PATH/analysis/processed/intermediate/duke/ce_locations_1927_1938.dta", replace
		
		// List of locations receiving capital expenditures, 1939-1962
		import excel using "$PROJ_PATH/analysis/raw/duke/ce_locations_1939_1962.xlsx", firstrow case(lower) clear
		save "$PROJ_PATH/analysis/processed/intermediate/duke/ce_locations_1939_1962.dta", replace

		// Separate list of locations receiving capital expenditures, 1927-1938
		import excel "$PROJ_PATH/analysis/raw/duke/ce_locations_1927_1938_entry_2.xlsx", sheet("Locations") firstrow clear
		save "$PROJ_PATH/analysis/processed/intermediate/duke/ce_locations_1927_1938_entry_2.dta", replace

	// Capital expenditures, 1928 to 1931 (separate files) 
	local files : dir "$PROJ_PATH/analysis/raw/duke/capital_expenditures/by_year_1928_1931/" files "Final_CE-*.xlsx", respectcase
	foreach file in `files' {
		import excel using $PROJ_PATH/analysis/raw/duke/capital_expenditures/by_year_1928_1931/`file', firstrow case(lower) clear
		local file_name: subinstr local file ".xlsx" ".dta"

		// Add filename containing the year
		gen filename = "`file'"
		
		// Empty rows imported in 1928
		drop if missing(imageno) & missing(hospital)
		
		// Standardize variable names
		capture rename town location
		capture rename othercontributions localcontribution
		capture rename total estimatedcostofproject

		save "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/`file_name'", replace
	}

	// Load 1932-1938 data - current and outstanding appropriations are in separate worksheets
	import excel using "$PROJ_PATH/analysis/raw/duke/capital_expenditures/Final_CE-1932-1938.xlsx", firstrow case(lower) sheet("Current") clear
	save "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-1932-1938_current.dta", replace

	// Load 1932-1938 data - current and outstanding appropriations are in separate worksheets
	import excel using "$PROJ_PATH/analysis/raw/duke/capital_expenditures/Final_CE-1932-1938.xlsx", firstrow case(lower) sheet("Outstanding") clear
	save "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/Final_CE-1932-1938_outstanding.dta", replace
	
	// Capital expenditures, 1939 to 1962 (separate files) 
	local files : dir "$PROJ_PATH/analysis/raw/duke/capital_expenditures/by_year_1939_1962/" files "Final_CE-*.xlsx", respectcase
	foreach file in `files' {
		import excel using $PROJ_PATH/analysis/raw/duke/capital_expenditures/by_year_1939_1962/`file', cellrange(A2) case(lower) allstring clear
		local file_name: subinstr local file ".xlsx" ".dta"
		
		// Add filename containing the year
		gen filename = "`file'"
		
		// Rename variables
		rename A imageno
		rename B hospital 
		rename C location 
		rename D unpaid_app_t_1 
		rename E appropriation 
		rename F app_payments 
		rename G unpaid_app_t 
		rename H purpose 
		cap rename I estimated_cost 
		
		cap drop J
		
		// Empty rows imported
		drop if missing(imageno) & missing(location)
		
		save "$PROJ_PATH/analysis/processed/intermediate/duke/capital_expenditures/`file_name*'", replace
	}
	
}

**********************************************************
// Extract community health department (CHD) data ********
**********************************************************

if `chd' {

	import excel using "$PROJ_PATH/analysis/raw/chd/chd_operation_dates.xlsx", cellrange(A1:F786) firstrow case(lower) clear
	save "$PROJ_PATH/analysis/processed/intermediate/chd/chd_operation_dates.dta", replace
}

************************************
// Process NC vital stats data *****
************************************

if `vital_stats' {

	// Births by race for denominator of Y	
	forvalues y = 1922/1948 {
	
		// Import data
		import excel using "$PROJ_PATH/analysis/raw/nc_vital_stats/births_by_race/`y'.xlsx", clear firstrow
		
		desc, f
		save "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/births_by_race_`y'.dta", replace
	}
	
	// Pre-period pneumonia mortality data 1920-1926 for shift-share instrument design
	forvalues y = 1922(1)1926 {
	
		if `y' == 1922 {
			local max_row 204
		}
		else if `y' == 1923 | `y' == 1925 {
			local max_row 203
		}
		else if `y' == 1924 | `y' == 1926 {
			local max_row 202
		}
			
		import excel using "$PROJ_PATH/analysis/raw/nc_vital_stats/pneumonia_mortality/Final_transcription-`y'.xlsx", sheet("Final") cellrange(A1:AB`max_row') firstrow case(lower) clear
		desc, f
		save "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/pneumonia_mortality_`y'.dta", replace
	
	}
	
	// Maternal and infant mortality data from North Carolina archives for online appendix 
	
	// Import infant mortality rate from 1918 to 1922
	import excel "$PROJ_PATH/analysis/raw/nc_vital_stats/infant_maternal_mortality/1918-1922-infant-mortality-rate-only.xlsx", firstrow clear 
	desc, f
	save "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_1918_1922.dta", replace 
	
	// Import data for 1923-1942
	forvalues year = 1923/1942 {
		import excel "$PROJ_PATH/analysis/raw/nc_vital_stats/infant_maternal_mortality/`year'.xlsx", firstrow clear
		desc, f 
		save "$PROJ_PATH/analysis/processed/intermediate/nc_vital_stats/infant_maternal_mortality_`year'.dta", replace 
	}
}

************************************
// Load raw AMD physician data *****
************************************

if `amd_physicians' {
	
	// Load raw AMD data for NC
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1912.xlsx", sheet("1912") cellrange(A2:T1854) firstrow case(lower) allstring clear
	gen year = 1912 
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1912.dta", replace 
	
	
	// Excel file for 1914 and 1918 is formatted differently
	// (1) Two years in one file. Each in separate tab.
	// (2) Page name only entered for first line of page. All rows with page name are otherwise empty 
	// (3) State, city, pop, county only entered for first line of city. 

	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1914.xlsx", sheet("1914") cellrange(A2:W2008) firstrow case(lower) allstring clear
	gen year = 1914
	replace pagename = strtrim(pagename)
	gen flag_page_id = !missing(pagename)
	carryforward pagename, replace
	carryforward state city pop county, replace
	drop if flag_page_id == 1 & missing(name)
	drop flag_page_id pagename
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1914.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1918.xlsx", sheet("1918") cellrange(A2:W2223) firstrow case(lower) allstring clear
	gen year = 1918
	replace pagename = strtrim(pagename)
	gen flag_page_id = !missing(pagename)
	replace state = "" if state == " " | state == "." | state == "`"
	carryforward pagename, replace
	carryforward state city pop county, replace
	assert name == "" if flag_page_id == 1
	drop if flag_page_id == 1
	drop flag_page_id pagename
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1918.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1921.xlsx", sheet("1921") cellrange(A2:T2262) firstrow case(lower) allstring clear
	gen year = 1921 
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1921.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1923.xlsx", sheet("1923") cellrange(A2:V2260) firstrow case(lower) allstring clear
	gen year = 1923
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1923.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1925.xlsx", sheet("1925") cellrange(A2:T2299) firstrow case(lower) allstring clear
	gen year = 1925
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1925.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1927.xlsx", sheet("1927") cellrange(A2:V2367) firstrow case(lower) allstring clear
	gen year = 1927
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1927.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1929.xlsx", sheet("1929") cellrange(A2:U2394) firstrow case(lower) allstring clear
	gen year = 1929
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1929.dta", replace 

	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1931.xlsx", sheet("1931") cellrange(A2:V2248) firstrow case(lower) allstring clear
	gen year = 1931
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1931.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1934.xlsx", sheet("1934") cellrange(A2:T2502) firstrow case(lower) allstring clear
	gen year = 1934
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1934.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1936.xlsx", sheet("1936") cellrange(A2:V2622) firstrow case(lower) allstring clear
	gen year = 1936
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1936.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1938.xlsx", sheet("1938") cellrange(A2:T2721) firstrow case(lower) allstring clear
	gen year = 1938
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1938.dta", replace 
	
	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1940.xlsx", sheet("1940") cellrange(A2:V2801) firstrow case(lower) allstring clear
	rename licensedinstatewherelocated symbol2
	rename doesnotshowlicenseinstatel  symbol3
	gen year = 1940
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1940.dta", replace 

	
	import excel using "$PROJ_PATH/analysis/raw/amd_physicians/amd_physicians_nc_1942.xlsx", sheet("1942") cellrange(A2:U2951) firstrow case(lower) allstring clear
	gen year = 1942
	save "$PROJ_PATH/analysis/processed/intermediate/amd_physicians/amd_physicians_nc_1942.dta", replace 
	
}

***************************************
// AMD History of medical schools *****
***************************************

if `amd_med_schools' {
		
	// Import U.S. Medical schools file
	import excel "$PROJ_PATH/analysis/raw/amd_med_schools/us-medical-schools-alphabetical-1942.xlsx", sheet("Alphabetical List") cellrange(A1:D802) firstrow clear
	save "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/us_medical_schools_alphabetical_1942.dta", replace
	
	// Import AMA ratings
	import excel using "$PROJ_PATH/analysis/raw/amd_med_schools/med_school_ratings.xlsx", sheet("medschoolcode_ratings") cellrange(A1:N182) firstrow clear
	save "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/med_school_ratings.dta", replace
	
	// Import 1- or 2-year college pre-requisite requirement
	import excel "$PROJ_PATH/analysis/raw/amd_med_schools/med_school_college_requirements.xlsx", firstrow clear
	save "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/med_school_college_requirements.dta", replace
	
	// Import U.S. Medical schools history file
	import excel "$PROJ_PATH/analysis/raw/amd_med_schools/history-medical-schools-1942.xlsx", sheet("History of Medical Schools") cellrange(A1:Z454) firstrow clear
	save "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/history_medical_schools_1942.dta", replace
	
	// Load raw AMD med school data with foreign medical schools  
	use school_code foreign using "$PROJ_PATH/analysis/raw/amd_med_schools/medical_schools_list_(1923 AMD).dta", clear
	save "$PROJ_PATH/analysis/processed/intermediate/amd_med_schools/foreign_medical_schools_list_1923.dta", replace

}

************************************************************
// Import infant mortality data from Price V. Fishback *****
************************************************************

if `southern_deaths' {
	
	// Import data from Price V. Fishback
	import excel using "$PROJ_PATH/analysis/raw/pvf/bdct2140.xls", sheet("data") cellrange(A1:W19430) firstrow case(lower) clear 
	compress
	desc, f
	save "$PROJ_PATH/analysis/processed/intermediate/pvf/bdct2140.dta", replace 
	
}

*********************************************************************************
// Load geocoded 1870 census locations ******************************************
// Process raw GNIS (Geographic National Information System) data ***************
*********************************************************************************

if `gnis' {
	
	// Unzip raw GNIS data
	cd "$PROJ_PATH/analysis/raw/gnis"
	unzipfile "NationalFile_20190301.zip"
	cd "$PROJ_PATH"
	
	// Load raw GNIS data
	import delim using "$PROJ_PATH/analysis/raw/gnis/NationalFile_20190301.txt", case(lower) delim("|") encoding("utf-8") stringcols(1 10/11) stripq(yes) clear

	keep state_alpha state_numeric feature_* prim_*
	order state_alpha state_numeric feature_* prim_*
	destring feature_id, replace
	
	rename (state_alpha state_numeric prim_lat_dec prim_long_dec) (stateabb statefip lat_dec long_dec)
	drop prim_*
	
	keep if statefip == 37
	
	save "$PROJ_PATH/analysis/processed/intermediate/gnis/gnis.dta", replace
	rm "$PROJ_PATH/analysis/raw/gnis/NationalFile_20190301.txt"
		
}

*******************************************
// Import single year population data *****
*******************************************

if `nc_pop' {

	infix year 1-4 str state 5-6 StateFIPS 7-8 CountyFIPS 9-11 registry 12-13 race 14 origin 15 age 17-18 population 19-27 using "$PROJ_PATH/analysis/raw/seer/nc_1969_2019_single_ages.txt", clear
	
	gen fips = StateFIPS*10000 + CountyFIPS*10
	
	// Restrict to blacks and whites
	keep if race == 1 | race == 2
	
	gcollapse (sum) population, by(fips age year race)
	
	// Fill in zeros
	rename population pop_
	greshape wide pop_ , i(fips age year) j(race)

	recode pop_1 (mis = 0)
	recode pop_2 (mis = 0)
	
	
	greshape long pop_ , i(fips age year) j(race)
	
	rename pop_ population

	compress
	sort fips race age year 
	desc, f
	
	save "$PROJ_PATH/analysis/processed/intermediate/seer/nc_population_single_ages_by_year_race.dta", replace
}


if `south_pop' {

	// Note that below includes north and south carolina 
	local file_list ///
		al.1969_2020.singleages.adjusted.txt ///
		ar.1969_2020.singleages.txt ///
		fl.1969_2020.singleages.txt ///
		ga.1969_2020.singleages.txt ///
		ky.1969_2020.singleages.txt ///
		la.1969_2020.singleages.adjusted.txt ///
		md.1969_2020.singleages.txt ///
		ms.1969_2020.singleages.adjusted.txt ///
		nc_1969_2019_single_ages.txt ///
		ok.1969_2020.singleages.txt ///
		sc.1969_2020.singleages.txt ///
		tn.1969_2020.singleages.txt ///
		tx.1969_2020.singleages.adjusted.txt ///
		va.1969_2020.singleages.txt ///
		wv.1969_2020.singleages.txt
		
	local file_num : list sizeof local(file_list) 
	local i = 1
	foreach x in `file_list' {

		infix year 1-4 str state 5-6 StateFIPS 7-8 CountyFIPS 9-11 registry 12-13 race 14 origin 15 age 17-18 population 19-27 using "$PROJ_PATH/analysis/raw/seer/`x'", clear
		
		gen fips = StateFIPS*10000 + CountyFIPS*10
		
		// Restrict to blacks and whites
		keep if race == 1 | race == 2
		
		gcollapse (sum) population, by(fips age year race)
		
		// Fill in zeros
		rename population pop_
		greshape wide pop_ , i(fips age year) j(race)

		recode pop_1 (mis = 0)
		recode pop_2 (mis = 0)
		
		greshape long pop_ , i(fips age year) j(race)
		
		rename pop_ population

		compress
		sort fips race age year 
		desc, f
		
		tempfile south_pop_`i'
		save `south_pop_`i'', replace empty
		local i = `i' + 1
	}
	
	use  `south_pop_1', clear
	local i = 2 
	forvalues i = 2(1)`file_num' {
		append using `south_pop_`i''
	}
	compress
	save "$PROJ_PATH/analysis/processed/intermediate/seer/south_population_single_ages_by_year_race.dta", replace
	
}


***************************************
// Extract NARA Numident files ********
***************************************

if `numident' {
	
	// Unzip raw files 
	cd "$PROJ_PATH/analysis/raw/numident/ss5"

	local filelist : dir "$PROJ_PATH/analysis/raw/numident/ss5" files "*.zip", respectcase

	foreach file in `filelist' {
		unzipfile `file', replace 
	}

	cd "$PROJ_PATH/analysis/raw/numident/death"

	local filelist : dir "$PROJ_PATH/analysis/raw/numident/death" files "*.zip", respectcase

	foreach file in `filelist' {
		unzipfile `file', replace 
	}

	cd "$PROJ_PATH"

	// Load SS5 files
	local file_list "01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20"

	foreach n of local file_list {
		clear
		quietly infix                   ///
			str		refnum		1-11	///
			str		interview	12-12	///
			str		ssn			13-21	///
			str		citcode		22-22	///
			str		offcode		23-25	///
			str		formcode	26-26	///
			str		entrycode	27-27	///
			str		printcode	28-28	///
			int		cycleyr		29-32	///
			byte	cyclemon	33-34	///
			byte	cycleday	35-36	///
			str		frstname	37-51	///
			str		frstover	52-52	///
			str		midname		53-67	///
			str		midover		68-68	///
			str		lastname	69-88	///
			str		lastover	89-89	///
			str		suffix		90-93	///
			byte	mobss5		97-98	///
			byte	dobss5		99-100	///
			int		yobss5		101-104	///
			byte	sex			105-105 ///
			byte	race		106-106 ///
			str		momfrstn	107-121 ///
			str		momfnovr	122-122 ///
			str		mommidnm	123-137 ///
			str		mommnovr	138-138 ///
			str		momlastn	139-158 ///
			str		momlnovr	159-159 ///
			str		momsuffix	160-163 ///
			str		popfrstn	164-178 ///
			str		popfnovr	179-179 ///
			str		popmidnm	180-194 ///
			str		popmnovr	195-195 ///
			str		poplastn	196-215 ///
			str		poplnovr	216-216 ///
			str 	popsuffix	217-220 ///
			str		pobcity		221-232 ///
			str		pobover		233-233 ///
			str		pobstctry	234-235 ///
			str		foreignbp	236-236 ///
			str		disability	361-361 ///
			using "$PROJ_PATH/analysis/raw/numident/ss5/NUMSS5`n'_PU.txt", clear

		label var refnum    `"Unique identification number for the enumeration record"'
		label var interview	`"Evidence submitted with an SSN card application"'
		label var ssn		`"Social security number"'
		label var citcode	`"U.S. citizenship or alien status"'
		label var offcode	`"Office code of originating office"'
		label var formcode	`"Form used as an application for initial issuance of SSN"'
		label var entrycode	`"Input source or type of data identifier"'
		label var printcode	`"Print name format"'
		label var cycleyr	`"Year when record posted on NUMIDENT"'
		label var cyclemon	`"Month when record posted on NUMIDENT"'
		label var cycleday	`"Day when record posted on NUMIDENT"'
		label var frstname 	`"First name"'
		label var midname 	`"Middle name"'
		label var lastname 	`"Last name"'
		label var suffix 	`"Suffix or title"'
		label var yobss5	`"Year of birth in SS5 file"'
		label var mobss5	`"Month of birth in SS5 file"'
		label var dobss5	`"Day of birth in SS5 file"'
		label var sex		`"Sex"'
		label var race		`"Race"'
		label var momfrstn	`"First name of mother"'
		label var momfnovr	`"Overflow flag for first name of mother"'
		label var mommidnm	`"Middle name of mother"'
		label var mommnovr	`"Overflow flag for middle name of mother"'
		label var momlastn	`"Last name of mother"'
		label var momlnovr	`"Overflow flag for last name of mother"'
		label var momsuffix	`"Suffix of mother"'
		label var popfrstn	`"First name of father"'
		label var popfnovr	`"Overflow flag for first name of father"'
		label var popmidnm	`"Middle name of father"'
		label var popmnovr	`"Overflow flag for middle name of father"'
		label var poplastn	`"Last name of father"'
		label var poplnovr	`"Overflow flag for last name of father"'
		label var popsuffix	`"Suffix of father"'
		label var pobcity	`"City or county of birth"'
		label var pobover	`"Overflow flag for place of birth"'
		label var pobstctry	`"State or country of birth"'
		label var foreignbp	`"Foreign birth place"'
		label var disability `"Title II disability status"'
		
		label define sex_lbl 0 `"Unknown"'
		label define sex_lbl 1 `"Male"', add
		label define sex_lbl 2 `"Female"', add
		label values sex sex_lbl

		label define race_lbl 0 `"Unknown"'
		label define race_lbl 1 `"White"', add
		label define race_lbl 2 `"Black"', add
		label define race_lbl 3 `"Other"', add
		label define race_lbl 4 `"Asian"', add
		label define race_lbl 5 `"Hispanic"', add
		label define race_lbl 6 `"North American native"', add
		label values race race_lbl

		// Drop redacted records
		drop if ssn == "ZZZZZZZZZ"

		keep ssn cycle* yobss5 mobss5 dobss5 pobcity pobover pobstctry foreignbp disability race sex

		save "$PROJ_PATH/analysis/processed/temp/ss5`n'.dta", replace

	}

	// Save all records
	clear
	foreach n of local file_list {
		append using "$PROJ_PATH/analysis/processed/temp/ss5`n'.dta"
	}
	compress
	save "$PROJ_PATH/analysis/processed/intermediate/numident/ss5/ss5_files.dta", replace
 
	foreach n of local file_list {
		rm "$PROJ_PATH/analysis/raw/numident/ss5/NUMSS5`n'_PU.txt"
		rm "$PROJ_PATH/analysis/processed/temp/ss5`n'.dta"
	}

	// Load death files
	foreach n of local file_list {
		clear
		quietly infix                   ///
			str		refnum		1-11	///
			str		ssn			13-21	///
			str		entrycode	27-27	///
			int		cycleyr		29-32	///
			byte	cyclemon	33-34	///
			str		cycleday	35-36	///
			str		frstname	37-52	///
			str		midname		53-68	///
			str		lastname	69-89	///
			str		suffix		90-93	///
			byte	mobdth		97-98	///
			byte	dobdth		99-100	///
			int		yobdth		101-104	///
			byte	sex			105-105 ///
			str		othernum	107-115	///
			byte	rimcode		116-116	///
			str		prfdth		117-117 ///
			str		proginv		118-118 ///
			str		zipresid	119-127 ///
			str		ziplumps	128-136 ///
			str		dobexcep	137-137 ///
			str		spexch		138-138 ///
			str		mbrdobex	139-139 ///
			str		dthsrc		142-143 ///
			str		verifedri	144-144 ///
			byte	mod			145-146 ///
			byte	dod			147-148 ///
			int		yod			149-152 ///
			str		dthcertno	153-178 ///
			str		dthpost		179-186 ///
			using "$PROJ_PATH/analysis/raw/numident/death/NUMDEATH`n'_PU.txt", clear

		label var refnum    `"Unique identification number for the enumeration record"'
		label var ssn		`"Social security number"'
		label var entrycode	`"Input source or type of data identifier"'
		label var cycleyr	`"Year when record posted on NUMIDENT"'
		label var cyclemon	`"Month when record posted on NUMIDENT"'
		label var cycleday	`"Day when record posted on NUMIDENT"'
		label var frstname 	`"First name"'
		label var midname 	`"Middle name"'
		label var lastname 	`"Last name"'
		label var suffix 	`"Suffix or title"'
		label var yobdth	`"Year of birth in death file"'
		label var mobdth	`"Month of birth in death file"'
		label var dobdth	`"Day of birth in death file"'
		label var sex		`"Sex"'
		label var othernum	`"Other number"'
		label var rimcode	`"Record indication match code"'
		label var prfdth	`"Proof of death"'
		label var proginv	`"Program invovement indicator"'
		label var zipresid	`"Residence ZIP code"'
		label var ziplumps	`"Lump sum death payment ZIP code"'
		label var dobexcep	`"Special indicator for DOB exception"'
		label var spexch	`"Special exception change indicator"'
		label var mbrdobex	`"MBR DOB exception indicator"'
		label var dthsrc	`"External source of death information"'
		label var verifedri	`"Verified Electronic Death Registration Indicator"'
		label var mod		`"Month of death"'
		label var dod		`"Day of death"'
		label var yod		`"Year of death"'
		label var dthcertno	`"Death certificate number"'
		label var dthpost	`"Date death information posted on NUMIDENT"'

		label define sex_lbl 0 `"Unknown"'
		label define sex_lbl 1 `"Male"', add
		label define sex_lbl 2 `"Female"', add
		label values sex sex_lbl

		keep ssn yobdth mobdth dobdth mod dod yod sex
		save "$PROJ_PATH/analysis/processed/temp/dth`n'.dta", replace

	}

	// Save all records
	clear
	foreach n of local file_list {
		append using "$PROJ_PATH/analysis/processed/temp/dth`n'.dta"
	}
	gisid ssn
	save "$PROJ_PATH/analysis/processed/intermediate/numident/death/death_files.dta", replace

	foreach n of local file_list {
		rm "$PROJ_PATH/analysis/raw/numident/death/NUMDEATH`n'_PU.txt"
		rm "$PROJ_PATH/analysis/processed/temp/dth`n'.dta"
	}

}


disp "DateTime: $S_DATE $S_TIME"

* EOF
