# Replication code and data for "The Gift of a Lifetime: The Hospital, Modern Medicine, and Mortality"
 
---
contributors:
  - Alex Hollingsworth
  - Chris Karbownik
  - Melissa A. Thomasson
  - Anthony Wray
---

# README

## Overview

The code in this replication package constructs the analysis datasets used to reproduce the figures and tables in the following article:

Hollingsworth, Alex, Krzysztof Karbownik, Melissa A. Thomasson, and Anthony Wray. "The Gift of a Lifetime: The Hospital, Modern Medicine, and Mortality." Forthcoming at the _American Economic Review_.

Some public-use datasets from IPUMS USA cannot be included in the repository. These must first be downloaded using the IPUMS data extraction system before running our code. Instructions for accessing data from IPUMS USA are provided below. 

In addition the NUMIDENT data must be downloaded from https://doi.org/10.3886/E207202V1. Instructions for where to place the data are provided below. 

The code is executed using Stata version 18 and R version 4.3.1. To recreate our paper, navigate to the home directory `duke-replication` and open the stata project `duke-replication.stpr`, then run the do file `0_run_all.do`. This will run all of the code to create the figures and tables in the manuscript, including the online appendix. The replicator should expect the code to run for about 2 hours.

## Data Availability and Provenance Statements

### Statement about Rights

- I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the [LICENSE.txt](LICENSE.txt) file.

### License for Data

The data are licensed under a MIT License license. See LICENSE.txt for details.

### Summary of Availability

- All data **are** publicly available.

### Details on each Data Source

The data used to support the findings of this study have been deposited in the replication package hosted at OpenICPSR (openicpsr-197844). Data hand-collected by the authors, and made available under a MIT license, include:

1. Capital expenditures and investment return data from _The Duke Endowment_.
2. Hospital data from the annual reports "Hospital Service in the United States" and the dates when hospitals were approved to offer internships, published in the _Journal of the American Medical Association (JAMA)_.
3. Hospital, medical school, and physician data from the _American Medical Directory (AMD)_.
4. Mortality and population data by race from the _Annual Report of the Bureau of Vital Statistics of the North Carolina State Board of Health_

Here we provide further details on the sources for all datasets used in the study:

Data on __The Duke Endowment__'s capital expenditures were hand-entered from printed volumes of the _Annual Report of the Hospital Section_ from 1925 to 1962 (The Duke Endowment, 1925a). 

- In most volumes, details on the Endowment's capital appropriations and payments appear in tables titled "Construction and Equipment Appropriations" (1928 to 1931) or "Construction, Equipment and Purchase Appropriations and Payments" (1939 to 1962). In other years, the relevant information is found in the text of the report. 
- Further information on the name and location of Duke funded hospitals was obtained from a table titled "Location, Auspices, Beds, and Days of Care" in the annual reports. 
- The print volumes of the _Annual Report of the Hospital Section_ can be found in many library collections.
- Capital expenditures are adjusted for inflation using the All Urban Consumers (Current Series) from the [Bureau of Labor Statistics](http://www.bls.gov/cpi/data.htm) (Sahr 2018). 
Data on The Duke Endowment's statement of income, including the annual return of the Endowment were hand-entered from printed volumes of the _Yearbook of The Duke Endowment_ (The Duke Endowment, 1925b).

- The yearbooks and other archival records of The Duke Endowment are located in [The Duke Endowment Archives](https://archives.lib.duke.edu/catalog/dukeend) and are accessible by visiting the Rubenstein Library at Duke University in Durham, NC. 

Data from __"Hospital Service in the United States"__ -- the annual presentation of hospital data by the Council on Medical Education and Hospitals of the American Medical Association -- were hand-entered from issues of the _**Journal of the American Medical Association (JAMA)**_ which are [available online](https://jamanetwork.com/). The paper uses issues from 1921, 1926, and 1928 to 1951, each of which contain statistics on the previous year. 

- The paper also uses datasets derived from the annual reports _JAMA_ that were collected by one of the study's co-authors for another publication (Esteves et al. 2022). 

The paper uses hand-collected data on hospitals, medical schools, and physicians in North Carolina from the _American Medical Directory_, published by the _American Medical Association_. Data were extracted from PDF scans, obtained from [HathiTrust](https://catalog.hathitrust.org/Record/000543547), for the folowing volumes: 1906, 1909, 1911, 1912, 1916, 1918, 1921, 1923, 1927, 1931, 1936, 1940, and 1942. Hard copies of the following volumes were consulted in various library: 1918, 1921, 1923, 1925, 1927, 1929, 1931, 1934, 1936, 1938, 1940, and 1942.

Annual data on the number of births by race, infant mortality, maternal mortality, and pneumonia mortality for the state of North Carolina were hand-entered from digital copies of the _Annual Report of the Bureau of Vital Statistics of the North Carolina State Board of Health_ (NC-BVS, 1922). The reports are available online from [North Carolina Digital Collections](https://digital.ncdcr.gov/) -- the digital collections of the State Archives of North Carolina and the State Library of North Carolina.

Data on county health departments were hand-collected from Ferrell and Mead (1933), available online from [HathiTrust](https://catalog.hathitrust.org/Record/006695536). For further information about county health departments, see Hoehn-Velasco (2018; 2021).

Data on the __Geographic Names Information System (GNIS)__ were downloaded from the U.S. Geological Survey (USGS, 2019) on 1 March 2019. This data product was last updated on 25 August 2021 and is archived by the USGS [here](https://prd-tnm.s3.amazonaws.com/StagedProducts/GeographicNames/Archive/MainDomestic/NationalFile.zip). The current version of GNIS data is available for download via the [U.S. Board on Geographic Names website](https://www.usgs.gov/us-board-on-geographic-names/download-gnis-data). A copy of the data file is provided as part of this archive. The data are in the public domain.

The paper uses the "U.S. County-Level Natality and Mortality Data, 1915-2007" (ICPSR 36603) distributed by the Inter-university Consortium for Political and Social Research (Bailey et al. 2018). Data is subject to a redistribution restriction, but can be freely downloaded from [ICPSR](https://doi.org/10.3886/ICPSR36603.v2). Users will first need to create an account by filling out a [registration form](https://www.icpsr.umich.edu/cgi-bin/newacct) and agree to the conditions of use. Save the data file `36603-0001-Data.dta` to the `raw/icpsr/` folder. 

The paper uses __IPUMS NHGIS__ data (Manson et al. 2019; 2022). IPUMS NHGIS does not allow for redistribution without permission, but their [terms of use](https://www.nhgis.org/ipums-nhgis-terms-use) makes an exception for users to "publish a subset of the data to meet journal requirements for accessing data related to a particular publication." A copy of the data files are provided as part of this archive.

The paper uses __IPUMS USA__ [full count U.S. Census microdata](https://usa.ipums.org/usa/full_count.shtml). IPUMS USA does not allow users to redistribute IPUMS-USA Full-Count data, but these data can be freely downloaded from the [IPUMS-USA extract system](https://usa.ipums.org/usa-action/variables/group). Users must first fill out the registration form, including a brief description of the project, and agree to the conditions of use. In lieu of providing a copy of the data files as part of this archive, we include codebook files for each of the four full count extracts used, which provide information on the variables and observations to be selected. For convenience, below we provide extract-specific instructions for downloading the data and adding them to this archive:

A. 1910-1940 U.S. Census Full-Count data for North Carolina. The folder `raw/ipums/` includes the codebook files in plain text  (`usa_00086.cbk`), xml (`usa_00086.xml`) and PDF (`usa_00086.pdf`) formats. 
  1. Navigate to [https://usa.ipums.org/usa-action/variables/group](https://usa.ipums.org/usa-action/variables/group)
  2. Click on the blue box "SELECT SAMPLES" on the left-hand side
  3. Deselect all datasets under the tab "USA SAMPLES"
  4. Click on the tab "USA FULL COUNT"
  5. Select the 1910, 1920, 1930, and 1940 100% options and click on "SUBMIT SAMPLE SELECTIONS"
  6. Select the exact variables listed in `usa_00086.cbk` (some variables are preselected)
  7. Click on "CREATE DATA EXTRACT"
  8. Apply a sample restriction of only residents of North Carolina (STATEFIP code 37): Under "OPTIONS" click on "SELECT CASES," then on the next page select "STATEFIP" and click "SUBMIT," then on the next page select "37 NORTH CAROLINA" and click again on "SUBMIT"
  9. On the "EXTRACT REQUEST" page, if "DATA FORMAT" has not defaulted to ".dta (Stata)" click on "Change" to the right of "DATA FORMAT" 
  10. On the "DATA FORMAT AND STRUCTURE" page, ensure that "Stata (.dta)" is selected under "Data Format" and "Rectangular - person (default)" is selected under "Data Structure"
  10. Provide a brief description of the extract and click on "SUBMIT EXTRACT." Instructions for retrieving the data will be sent to the email address registered to the account.
  11. Download the `.dta` file to the `raw/ipums/` folder. If the user has not previously submitted an extract, the file will be called `usa_00001.dta`. 
  12. On line 17 of the program `4_1_compile_ipums_data.do` change `usa_00086` to the name of the file downloaded in step 12.

B. 1940 U.S. Census Full-Count data for North Carolina. The folder `raw/ipums/` includes the codebook files in plain text  (`usa_00087.cbk`), xml (`usa_00087.xml`) and PDF (`usa_00087.pdf`) formats. 
  1. Follow steps 1 to 4 under extract A
  2. Select the 1940 100% option and click on "SUBMIT SAMPLE SELECTIONS"
  3. Select the exact variables listed in `usa_00087.cbk` (some variables are preselected)
  4. Follow steps 7 to 11 under extract A
  5. On line 24 of the program `3_0_ipums_data_for_geocode_nc_deaths.do` change `usa_00087` to the name of the file downloaded in step 4.

C. 1920 and 1930 U.S. Census Full-Count data
  1. Follow steps 1 to 4 under extract A
  2. Select the 1920 and 1930 100% options and click on "SUBMIT SAMPLE SELECTIONS"
  3. Select the exact variables listed in `User Extract usa_00004.pdf` (some variables are preselected)
  4. Click on "CREATE DATA EXTRACT"
  5. Follow steps 9 and 10 under extract A
  6. Download the `.dta` file to the `raw/ipums/us/` folder. If the user has not previously submitted an extract, the file will be called `usa_00001.dta`. 
  7. On line 18 of the program `1_1_process_ipums_data.do` change `usa_00004` to the name of the file downloaded in step 6.

  D. 1920 and 1930 U.S. Census Full-Count data
  1. Follow steps 1 to 4 under extract A
  2. Select the 1920 and 1930 100% options and click on "SUBMIT SAMPLE SELECTIONS"
  3. Select the exact variables listed in `User Extract usa_00005.pdf` (some variables are preselected)
  4. Click on "CREATE DATA EXTRACT"
  5. Follow steps 9 and 10 under extract A
  6. Download the `.dta` file to the `raw/ipums/us/` folder. If the user has not previously submitted an extract, the file will be called `usa_00001.dta`. 
  7. On line 48 of the program `1_1_process_ipums_data.do` change `usa_00005` to the name of the file downloaded in step 6.

The paper also uses other data from __IPUMS USA__. In such cases, IPUMS USA does not allow for redistribution without permission, but their [terms of use](https://usa.ipums.org/usa/terms.shtml) makes an exception for users to "publish a subset of the data to meet journal requirements for accessing data related to a particular publication." A copy of the following IPUMS-USA data files are provided as part of this archive:
- Data on ICPSR county codes were downloaded from [IPUMS USA](https://usa.ipums.org/usa/volii/ICPSR.shtml). 
- A code list for the IPUMS variable PLACENHG was downloaded from [IPUMS USA](https://usa.ipums.org/usa-action/variables/PLACENHG#codes_section). 

The North Carolina death certificate data used in this paper were obtained from Cook et al. (2014; 2016) via a request to the authors. A copy of the data file is provided as part of this archive. Please contact John Parman for more information about the data in Cook et al. (2014; 2016). 

The paper uses data from the public-use __NUMIDENT__ Application (SS-5) and Death Files (SSA 2007). The data were purchased from the Electronic Records Division of the National Archives and Records Administration (NARA). Further information about the data files included in the  Public-Use NUMIDENT can be found [here](https://aad.archives.gov/aad/series-description.jsp?s=5057) or by contacting the Electronic Records Division at [cer@nara.gov](cer@nara.gov). There are no access or use restrictions on the Public Use NUMIDENT data files. As such, we have posted the data to a separate repository where interested users can access the data with no restrictions on redistribution beyond attribution to this paper. This repository can be found here: https://doi.org/10.3886/E207202V1. To place this data in the appropriate spot for the project follow these steps: 
  1. Navigate to https://doi.org/10.3886/E207202V1
  2. Download the `numident/death` directory and all of its contents
  3. Copy the contents of this directory  (two files, ` NUMDEATH01-10_PU.zip` and `NUMDEATH11-20_PU.zip`) into the `analysis/raw/numident/death` directory of this project
  4. Download the `numident/ss5` directory and all of its contents
  5.  Copy the contents of this directory  (four files, `NUMSS5_01-05_PU.zip`, `NUMSS5_06-10_PU.zip`, `NUMSS5_11-15_PU.zip`, and `NUMSS5_16-20_PU.zip`) into the `analysis/raw/numident/ss5` directory of this project

Single year of age population estimates by county were downloaded from the National Cancer Institute's Surveillance, Epidemiology, and End Results (SEER) Program (SEER, 2022). Data can be downloaded from [here](https://seer.cancer.gov/popdata/download.html), under "County-Level Population Files - Single-year Age Groups." A copy of the data files are provided as part of this archive. The data are in the public domain.

Supplementary analysis was performed using data from:
- Fishback, Haines, and Kantor (2007) (city-level infant mortality data, 1921-1940)
- Haines (2008), Arias (2010), and Arias et al. (2021) (life expectancy)
- IPUMS USA (2015) (ICPSR county codes)
- Pollitt (2017) (African American hospitals)

Many of the sources for these datasets are available online. This is the case for Haines (2008), Arias (2010), Arias et al. (2021), and IPUMS USA (2015). Please contact Price V. Fishback for access to the Fishback, Haines, and Kantor (2007) city-level infant mortality data. Pollitt (2017) is available for loan in many library collections.

## Dataset list

The following table provides a list of all datasets included in this replication package (stored within the `analysis/raw` directory) and their provenance.

| Data file and subdirectory               | Source                       | Notes                                       |Provided |
|------------------------------------------|------------------------------|---------------------------------------------|---------|
| `ama/aha_data_all_states.dta`            | Esteves et al. (2022)        | "Hospital Service in the US," 1920-1942| Yes |
| `ama/Final_AMA_Hospitals_1921.xlsx`      | _JAMA_ (1921)  | "Hospital Service in the US," Data for 1920 | Yes | 
| `ama/Final_AMA_Hospitals_1926.xlsx`      | _JAMA_ (1926)  | "Hospital Service in the US," Data for 1925 | Yes |
| `ama/Final_AMA_Hospitals_1928.xlsx`      | _JAMA_ (1928)  | "Hospital Service in the US," Data for 1927 | Yes |
| `ama/Final_AMA_Hospitals_1929.xlsx`      | _JAMA_ (1929)  | "Hospital Service in the US," Data for 1928 | Yes |
| `ama/Final_AMA_Hospitals_1930.xlsx`      | _JAMA_ (1930)  | "Hospital Service in the US," Data for 1929 | Yes |
| `ama/Final_AMA_Hospitals_1931.xlsx`      | _JAMA_ (1931)  | "Hospital Service in the US," Data for 1930 | Yes |
| `ama/Final_AMA_Hospitals_1932.xlsx`      | _JAMA_ (1932)  | "Hospital Service in the US," Data for 1931 | Yes |
| `ama/Final_AMA_Hospitals_1933.xlsx`      | _JAMA_ (1933)  | "Hospital Service in the US," Data for 1932 | Yes |
| `ama/Final_AMA_Hospitals_1934.xlsx`      | _JAMA_ (1934)  | "Hospital Service in the US," Data for 1933 | Yes |
| `ama/Final_AMA_Hospitals_1935.xlsx`      | _JAMA_ (1935)  | "Hospital Service in the US," Data for 1934 | Yes |
| `ama/Final_AMA_Hospitals_1936.xlsx`      | _JAMA_ (1936)  | "Hospital Service in the US," Data for 1935 | Yes |
| `ama/Final_AMA_Hospitals_1937.xlsx`      | _JAMA_ (1937)  | "Hospital Service in the US," Data for 1936 | Yes |
| `ama/Final_AMA_Hospitals_1938.xlsx`      | _JAMA_ (1938)  | "Hospital Service in the US," Data for 1937 | Yes |
| `ama/Final_AMA_Hospitals_1939.xlsx`      | _JAMA_ (1939)  | "Hospital Service in the US," Data for 1938 | Yes |
| `ama/Final_AMA_Hospitals_1940.xlsx`      | _JAMA_ (1940)  | "Hospital Service in the US," Data for 1939 | Yes |
| `ama/Final_AMA_Hospitals_1941.xlsx`      | _JAMA_ (1941)  | "Hospital Service in the US," Data for 1940 | Yes |
| `ama/Final_AMA_Hospitals_1942.xlsx`      | _JAMA_ (1942)  | "Hospital Service in the US," Data for 1941 | Yes |
| `ama/Final_AMA_Hospitals_1943.xlsx`      | _JAMA_ (1943)  | "Hospital Service in the US," Data for 1942 | Yes |
| `ama/Final_AMA_Hospitals_1944.xlsx`      | _JAMA_ (1944)  | "Hospital Service in the US," Data for 1943 | Yes |
| `ama/Final_AMA_Hospitals_1945.xlsx`      | _JAMA_ (1945)  | "Hospital Service in the US," Data for 1944 | Yes |
| `ama/Final_AMA_Hospitals_1946.xlsx`      | _JAMA_ (1946)  | "Hospital Service in the US," Data for 1945 | Yes |
| `ama/Final_AMA_Hospitals_1947.xlsx`      | _JAMA_ (1947)  | "Hospital Service in the US," Data for 1946 | Yes |
| `ama/Final_AMA_Hospitals_1948.xlsx`      | _JAMA_ (1948)  | "Hospital Service in the US," Data for 1947 | Yes |
| `ama/Final_AMA_Hospitals_1949.xlsx`      | _JAMA_ (1949)  | "Hospital Service in the US," Data for 1948 | Yes |
| `ama/Final_AMA_Hospitals_1950.xlsx`      | _JAMA_ (1950)  | "Hospital Service in the US," Data for 1949 | Yes |
| `ama/Final_AMA_Hospitals_1951.xlsx`      | _JAMA_ (1951)  | "Hospital Service in the US," Data for 1950 | Yes |
| `ama/Internships.xlsx`                   | _JAMA_, various years | Year of approval for hospitals to offer medical internships | Yes |
| `amd_hospitals/amd_state_and_federal_institutions.xlsx` | _AMD_, various years | State and federal institutions  | Yes |
| `amd_hospitals/Final_1925-North Carolina.xlsx`          | _AMD_ (1925) | List of hospitals in NC in 1925 | Yes |
| `amd_hospitals/Final_1927-North Carolina.xlsx`          | _AMD_ (1927) | List of hospitals in NC in 1927 | Yes |
| `amd_hospitals/Final_1929-North Carolina.xlsx`          | _AMD_ (1929) | List of hospitals in NC in 1929 | Yes |
| `amd_hospitals/Final_1931-North Carolina.xlsx`          | _AMD_ (1931) | List of hospitals in NC in 1931 | Yes |
| `amd_hospitals/Final_1934-North Carolina.xlsx`          | _AMD_ (1934) | List of hospitals in NC in 1934 | Yes |
| `amd_hospitals/Final_1936-North Carolina.xlsx`          | _AMD_ (1936) | List of hospitals in NC in 1936 | Yes |
| `amd_hospitals/Final_1938-North Carolina.xlsx`          | _AMD_ (1938) | List of hospitals in NC in 1938 | Yes |
| `amd_hospitals/Final_1940-North Carolina.xlsx`          | _AMD_ (1940) | List of hospitals in NC in 1940 | Yes |
| `amd_hospitals/Final_1942-North Carolina.xlsx`          | _AMD_ (1942) | List of hospitals in NC in 1942 | Yes |
| `amd_hospitals/Final_AMD_1906.xlsx`                     | _AMD_ (1906) | List of hospitals in NC in 1906 | Yes |
| `amd_hospitals/Final_AMD_1909.xlsx`                     | _AMD_ (1909) | List of hospitals in NC in 1909 | Yes |
| `amd_hospitals/Final_AMD_1912.xlsx`                     | _AMD_ (1912) | List of hospitals in NC in 1912 | Yes |
| `amd_hospitals/Final_AMD_1916.xlsx`                     | _AMD_ (1916) | List of hospitals in NC in 1916 | Yes |
| `amd_hospitals/Final_AMD_1918.xlsx`                     | _AMD_ (1918) | List of hospitals in NC in 1918 | Yes |
| `amd_hospitals/Final_AMD_1921.xlsx`                     | _AMD_ (1921) | List of hospitals in NC in 1921 | Yes |
| `amd_hospitals/Final_AMD_1923.xlsx`                     | _AMD_ (1923) | List of hospitals in NC in 1923 | Yes |
| `amd_med_schools/history-medical-schools-1942.xlsx`     | _AMD_ (1942) | "History of Medical Schools" | Yes |
| `amd_med_schools/med_school_college_requirements.xlsx`  | _JAMA_, various years | Pre-requisites for medical schools | Yes |
| `amd_med_schools/med_school_ratings.xlsx`               | _JAMA_, various years | _AMA_ ratings | Yes |
| `amd_med_schools/medical_schools_list_(1923 AMD).dta`   | _AMD_ (1923) | List of medical schools in 1923 | Yes |
| `amd_med_schools/us-medical-schools-alphabetical-1942.xlsx` | _AMD_ (1942) | "Medical Schools - Alphabetical List" | Yes |
| `amd_physicians/amd_physicians_nc_1912.dta`             | _AMD_ (1912) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1914.dta`             | _AMD_ (1914) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1918.dta`             | _AMD_ (1918) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1921.dta`             | _AMD_ (1921) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1923.dta`             | _AMD_ (1923) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1925.dta`             | _AMD_ (1925) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1927.dta`             | _AMD_ (1927) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1929.dta`             | _AMD_ (1929) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1931.dta`             | _AMD_ (1931) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1934.dta`             | _AMD_ (1934) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1936.dta`             | _AMD_ (1936) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1938.dta`             | _AMD_ (1938) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1940.dta`             | _AMD_ (1940) | Physicians of NC | Yes     |
| `amd_physicians/amd_physicians_nc_1942.dta`             | _AMD_ (1942) | Physicians of NC | Yes     |
| `cdc-wonder/imr-and-life-expectancy-by-year.xlsx` | Haines (2008), Arias (2010), Arias et al. (2021) | Life expectancy | Yes |
| `chd_operation_dates.xlsx` | Ferrell and Mead (1933) | County health departments | Yes | 
| `duke/capital_expenditures/by_year_1928_1931/Final_CE-1928.xlsx` | The Duke Endowment (1928) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1928_1931/Final_CE-1929.xlsx` | The Duke Endowment (1929) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1928_1931/Final_CE-1930.xlsx` | The Duke Endowment (1930) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1928_1931/Final_CE-1931.xlsx` | The Duke Endowment (1931) | Capital expenditures | Yes | 
| `duke/capital_expenditures/Final_CE-1932-1938.xlsx`              | The Duke Endowment (1932-1938) | Capital expenditures | Yes |
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1939.xlsx` | The Duke Endowment (1939) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1940.xlsx` | The Duke Endowment (1940) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1941.xlsx` | The Duke Endowment (1941) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1942.xlsx` | The Duke Endowment (1942) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1943.xlsx` | The Duke Endowment (1943) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1944.xlsx` | The Duke Endowment (1944) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1945.xlsx` | The Duke Endowment (1945) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1946.xlsx` | The Duke Endowment (1946) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1947.xlsx` | The Duke Endowment (1947) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1948.xlsx` | The Duke Endowment (1948) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1949.xlsx` | The Duke Endowment (1949) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1950.xlsx` | The Duke Endowment (1950) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1951.xlsx` | The Duke Endowment (1951) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1952.xlsx` | The Duke Endowment (1952) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1953.xlsx` | The Duke Endowment (1953) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1954.xlsx` | The Duke Endowment (1954) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1955.xlsx` | The Duke Endowment (1955) |Capital expenditures| Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1956.xlsx` | The Duke Endowment (1956) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1957.xlsx` | The Duke Endowment (1957) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1958.xlsx` | The Duke Endowment (1958) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1959.xlsx` | The Duke Endowment (1959) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1960.xlsx` | The Duke Endowment (1960) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1961.xlsx` | The Duke Endowment (1961) | Capital expenditures | Yes | 
| `duke/capital_expenditures/by_year_1939_1962/Final_CE-1962.xlsx` | The Duke Endowment (1962) | Capital expenditures | Yes | 
| `duke/ce_locations_1927_1938.xslsx` | _Annual Report of the Hospital Section_ | Locations of Duke funded hospitals | Yes | 
| `duke/ce_locations_1927_1938_entry_2.xslsx` | _Annual Report of the Hospital Section_ | Locations of Duke funded hospitals  | Yes | 
| `duke/inflation_factors.xslsx` | Sahr (2018) | Consumer Price Index (CPI) Conversion Factors | Yes | 
| `duke/labc_locations_1925_1962.xslsx` | _Annual Report of the Hospital Section_ | Locations of Duke funded hospitals  | Yes | 
| `duke/returns_by_year.xslsx` | _Yearbook of The Duke Endowment_ | Annual return of Endowment|  Yes | 
| `gnis/NationalFile_20190301.txt`         | USGS (2019)  | GNIS National File| Yes |
| `gnis/stateabb.dta` | Authors | Crosswalk of state names and abbreviations | Yes | 
| `hospitals/all_hosp.xlsx` | Esteves et al. (2022) | _AMA_ hospital data | Yes | 
| `hospitals/pollitt-nc-african-american-hospitals.xslx` | Pollitt (2017) | African American hospitals | Yes | 
| `icpsr/36603-0001-Data.dta` | Bailey et al. (2018) | U.S. county-level natality and mortality data | Yes | 
| `icpsr/icpsrcnt.xls` | IPUMS USA (2015)| ICPSR county codes | Yes | 
| `ipums/us/usa_00004.dta` | Ruggles et al. (2023b) | 1920 and 1930 U.S. Census Full Counts | No |
| `ipums/us/usa_00005.dta` | Ruggles et al. (2023b) | 1920 and 1930 U.S. Census Full Counts | No |
| `ipums/ipums_placenhg_code_list.xlsx` | IPUMS USA (2021) | PLACENHG code list | Yes | 
| `ipums/usa_00086.dta` | Ruggles et al. (2023a) | 1910-1940 US Full-Count Censuses (residents of North Carolina subsamples) | No | 
| `ipums/usa_00087.dta` | Ruggles et al. (2023a) | 1940 US Full-Count Census (residents of North Carolina subsample) | No |
| `nc_deaths/nc_deaths_raw.dta` | Cook et al. (2014; 2016) | NC death certificates | Yes |  
| `nc_vital_stats/births_by_race/1922.xlsx` | NC-BVS (1922) | Births by race in 1922 | Yes | 
| `nc_vital_stats/births_by_race/1923.xlsx` | NC-BVS (1923) | Births by race in 1923 | Yes | 
| `nc_vital_stats/births_by_race/1924.xlsx` | NC-BVS (1924) | Births by race in 1924 | Yes | 
| `nc_vital_stats/births_by_race/1925.xlsx` | NC-BVS (1925) | Births by race in 1925 | Yes | 
| `nc_vital_stats/births_by_race/1926.xlsx` | NC-BVS (1926) | Births by race in 1926 | Yes | 
| `nc_vital_stats/births_by_race/1927.xlsx` | NC-BVS (1927) | Births by race in 1927 | Yes | 
| `nc_vital_stats/births_by_race/1928.xlsx` | NC-BVS (1928) | Births by race in 1928 | Yes | 
| `nc_vital_stats/births_by_race/1929.xlsx` | NC-BVS (1929) | Births by race in 1929 | Yes | 
| `nc_vital_stats/births_by_race/1930.xlsx` | NC-BVS (1930) | Births by race in 1930 | Yes | 
| `nc_vital_stats/births_by_race/1931.xlsx` | NC-BVS (1931) | Births by race in 1931 | Yes | 
| `nc_vital_stats/births_by_race/1932.xlsx` | NC-BVS (1932) | Births by race in 1932 | Yes | 
| `nc_vital_stats/births_by_race/1933.xlsx` | NC-BVS (1933) | Births by race in 1933 | Yes | 
| `nc_vital_stats/births_by_race/1934.xlsx` | NC-BVS (1934) | Births by race in 1934 | Yes | 
| `nc_vital_stats/births_by_race/1935.xlsx` | NC-BVS (1935) | Births by race in 1935 | Yes | 
| `nc_vital_stats/births_by_race/1936.xlsx` | NC-BVS (1936) | Births by race in 1936 | Yes | 
| `nc_vital_stats/births_by_race/1937.xlsx` | NC-BVS (1937) | Births by race in 1937 | Yes | 
| `nc_vital_stats/births_by_race/1938.xlsx` | NC-BVS (1938) | Births by race in 1938 | Yes | 
| `nc_vital_stats/births_by_race/1939.xlsx` | NC-BVS (1939) | Births by race in 1939 | Yes | 
| `nc_vital_stats/births_by_race/1940.xlsx` | NC-BVS (1940) | Births by race in 1940 | Yes | 
| `nc_vital_stats/births_by_race/1941.xlsx` | NC-BVS (1941) | Births by race in 1941 | Yes | 
| `nc_vital_stats/births_by_race/1942.xlsx` | NC-BVS (1942) | Births by race in 1942 | Yes | 
| `nc_vital_stats/births_by_race/1943.xlsx` | NC-BVS (1943) | Births by race in 1943 | Yes | 
| `nc_vital_stats/births_by_race/1944.xlsx` | NC-BVS (1944) | Births by race in 1944 | Yes | 
| `nc_vital_stats/births_by_race/1945.xlsx` | NC-BVS (1945) | Births by race in 1945 | Yes | 
| `nc_vital_stats/births_by_race/1946.xlsx` | NC-BVS (1946) | Births by race in 1946 | Yes | 
| `nc_vital_stats/births_by_race/1947.xlsx` | NC-BVS (1947) | Births by race in 1947 | Yes | 
| `nc_vital_stats/births_by_race/1948.xlsx` | NC-BVS (1948) | Births by race in 1948 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1918-1922-infant-mortality-rate-only.xlsx` | NC-BVS (1922)| Infant mortality, 1918-1922 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1923.xlsx` | NC-BVS (1923) | Infant and maternal mortality in 1923 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1924.xlsx` | NC-BVS (1924) | Infant and maternal mortality in 1924 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1925.xlsx` | NC-BVS (1925) | Infant and maternal mortality in 1925 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1926.xlsx` | NC-BVS (1926) | Infant and maternal mortality in 1926 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1927.xlsx` | NC-BVS (1927) | Infant and maternal mortality in 1927 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1928.xlsx` | NC-BVS (1928) | Infant and maternal mortality in 1928 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1929.xlsx` | NC-BVS (1929) | Infant and maternal mortality in 1929 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1930.xlsx` | NC-BVS (1930) | Infant and maternal mortality in 1930 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1931.xlsx` | NC-BVS (1931) | Infant and maternal mortality in 1931 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1932.xlsx` | NC-BVS (1932) | Infant and maternal mortality in 1932 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1933.xlsx` | NC-BVS (1933) | Infant and maternal mortality in 1933 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1934.xlsx` | NC-BVS (1934) | Infant and maternal mortality in 1934 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1935.xlsx` | NC-BVS (1935) | Infant and maternal mortality in 1935 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1936.xlsx` | NC-BVS (1936) | Infant and maternal mortality in 1936 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1937.xlsx` | NC-BVS (1937) | Infant and maternal mortality in 1937 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1938.xlsx` | NC-BVS (1938) | Infant and maternal mortality in 1938 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1939.xlsx` | NC-BVS (1939) | Infant and maternal mortality in 1939 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1940.xlsx` | NC-BVS (1940) | Infant and maternal mortality in 1940 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1941.xlsx` | NC-BVS (1941) | Infant and maternal mortality in 1941 | Yes | 
| `nc_vital_stats/infant_maternal_mortality/1942.xlsx` | NC-BVS (1942) | Infant and maternal mortality in 1942 | Yes | 
| `nc_vital_stats/pneumonia_mortality/Final_transcription-1922.xlsx` | NC-BVS (1922) | Pneumonia mortality in 1922 | Yes | 
| `nc_vital_stats/pneumonia_mortality/Final_transcription-1923.xlsx` | NC-BVS (1923) | Pneumonia mortality in 1923 | Yes | 
| `nc_vital_stats/pneumonia_mortality/Final_transcription-1924.xlsx` | NC-BVS (1924) | Pneumonia mortality in 1924 | Yes | 
| `nc_vital_stats/pneumonia_mortality/Final_transcription-1925.xlsx` | NC-BVS (1925) | Pneumonia mortality in 1925 | Yes | 
| `nc_vital_stats/pneumonia_mortality/Final_transcription-1926.xlsx` | NC-BVS (1926) | Pneumonia mortality in 1926 | Yes | 
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1900/US_county_1900.*` | Manson et al. (2022) | NHGIS US county boundaries (1900) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1910/US_county_1910.*` | Manson et al. (2022) | NHGIS US county boundaries (1910) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1920/US_county_1920.*` | Manson et al. (2022) | NHGIS US county boundaries (1920) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1930/US_county_1930.*` | Manson et al. (2022) | NHGIS US county boundaries (1930) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1940/US_county_1940.*` | Manson et al. (2022) | NHGIS US county boundaries (1940) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1950/US_county_1950.*` | Manson et al. (2022) | NHGIS US county boundaries (1950) | Yes |
| `nhgis/nhgis0033_shapefile_tl2000_us_county_1960/US_county_1960.*` | Manson et al. (2022) | NHGIS US county boundaries (1960) | Yes |
| `nhgis/nhgis0034_shapefile_tlgnis_us_place_point_1940/US_place_point_1940.*` | Manson et al. (2022) | NHGIS US Place Points (1940) | Yes |
| `nhgis/nhgis0035_shapefile_tlgnis_us_place_point_1940/US_place_point_1920.*` | Manson et al. (2022) | NHGIS US Place Points (1920) | Yes |
| `nhgis/nhgis0035_shapefile_tlgnis_us_place_point_1940/US_place_point_1930.*` | Manson et al. (2022) | NHGIS US Place Points (1930) | Yes |
| `nhgis/nhgis0036_shapefile_tlgnis_us_place_point_1940/US_place_point_1910.*` | Manson et al. (2022) | NHGIS US Place Points (1910) | Yes |
| `nhgis/tables/nhgis0029_ds31_1900_county.dat` | Manson et al. (2019) | NHGIS County-level data (1900) | Yes |
| `nhgis/tables/nhgis0029_ds37_1910_county.dat` | Manson et al. (2019) | NHGIS County-level data (1910) | Yes |
| `nhgis/tables/nhgis0029_ds43_1920_county.dat` | Manson et al. (2019) | NHGIS County-level data (1920) | Yes |
| `nhgis/tables/nhgis0029_ds54_1930_county.dat` | Manson et al. (2019) | NHGIS County-level data (1930) | Yes |
| `nhgis/tables/nhgis0029_ds78_1940_county.dat` | Manson et al. (2019) | NHGIS County-level data (1940) | Yes |
| `nhgis/tables/nhgis0029_ds84_1950_county.dat` | Manson et al. (2019) | NHGIS County-level data (1950) | Yes |
| `nhgis/tables/nhgis0029_ds91_1960_county.dat` | Manson et al. (2019) | NHGIS County-level data (1960) | Yes |
| `numident/ferrie_crosswalk.dta`                     | Black et al. (2015) | NUMIDENT place of birth text string to GNIS Feature ID crosswalk | Yes |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH01_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH02_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH03_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH04_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH05_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH06_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH07_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH08_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH09_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH01-10_PU/NUMDEATH10_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH11_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH12_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH13_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH14_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH15_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH16_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH17_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH18_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH19_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/death/NUMDEATH11-20_PU/NUMDEATH20_PU.txt` | SSA (2007) | NUMIDENT Death Files | No |
| `numident/ss5/NUMSS5_01-05_PU/NUMSS5_01_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_01-05_PU/NUMSS5_02_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_01-05_PU/NUMSS5_03_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_01-05_PU/NUMSS5_04_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_01-05_PU/NUMSS5_05_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_06-10_PU/NUMSS5_06_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_06-10_PU/NUMSS5_07_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_06-10_PU/NUMSS5_08_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_06-10_PU/NUMSS5_09_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_06-10_PU/NUMSS5_10_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_11-15_PU/NUMSS5_11_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_11-15_PU/NUMSS5_12_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_11-15_PU/NUMSS5_13_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_11-15_PU/NUMSS5_14_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_11-15_PU/NUMSS5_15_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_16-20_PU/NUMSS5_16_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_16-20_PU/NUMSS5_17_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_16-20_PU/NUMSS5_18_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_16-20_PU/NUMSS5_19_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `numident/ss5/NUMSS5_16-20_PU/NUMSS5_20_PU.txt`     | SSA (2007) | NUMIDENT Application (SS-5) Files | No |
| `pvf/bdct2140.xls`                          | Fishback, Haines, and Kantor (2007) | City-level data, 1921-1940| Yes |
| `seer/al.1969_2020.singleages.adjusted.txt` | SEER (2022) | Single year of age population estimates | Yes |
| `seer/ar.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/fl.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/ga.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/ky.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/la.1969_2020.singleages.adjusted.txt` | SEER (2022) | Single year of age population estimates | Yes |
| `seer/md.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/ms.1969_2020.singleages.adjusted.txt` | SEER (2022) | Single year of age population estimates | Yes |
| `seer/nc.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/ok.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/sc.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/tn.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/tx.1969_2020.singleages.adjusted.txt` | SEER (2022) | Single year of age population estimates | Yes |
| `seer/va.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |
| `seer/wv.1969_2020.singleages.txt`          | SEER (2022) | Single year of age population estimates | Yes |

## Computational requirements



### Software Requirements


- The replication package contains all programs used for computation in the `analysis/scripts/libraries/stata-18` and `analysis/scripts/libraries/R` directories.  

All software used for stata is contained within the `analysis/scripts/libraries/stata-18` directory. If you'd like to use updated versions of this code (which may be different than the versions we used) you may install stata packages using the `analysis/scripts/code/_install_stata_packages.do` file. Note that you may need to delete and then reinstall all the packages in `analysis/scripts/libraries/stata-18/g` related to gtools since gtools will install machine specific libraries. 

Packages and version control related to R should be in `analysis/scripts/libraries/R` and are controlled using `renv` package. Please see the file `analysis/scripts/code/_install_R_packages.R`.


- Stata (Version 18)
- R 4.3.1

Portions of the code use shell commands, which may require unix.

### Controlled Randomness

- Whenever a random seed is used we use `12345`. These are set on the following lines, in the following scripts. 

  - Line 33 of `analysis/scripts/code/6.09_online_appendix_k_ri.do`
  - Line 32 of `analysis/scripts/code/6.11_online_appendix_m_psm.do`
  - Line 516 of `analysis/scripts/code/6.11_online_appendix_m_psm.do`
  - Line 32 of `analysis/scripts/code/6.05_online_appendix_g_other_results.do`


### Memory, Runtime, Storage Requirements


#### Summary

Approximate time needed to reproduce the analyses on a standard (2024) desktop machine:

- 1-3 hours

Approximate storage space needed:

- 25 GB - 250 GB

#### Details

The code was last run on a **10-core Mac Studio with an Apple M2 Ultra chip, running MacOS version 14.2.1 with 192 GB of RAM and 3TB of free space**. Computation took **81 minutes 28.2 seconds** to run.

Each section of the code took the following time to run

- Build data: 52 minutes
- Main figures and tables: 2 minutes
- Online appendix, specification chart, and sample chart: 27 minutes
- In-text citations: < 1 minute

## Description of programs/code

- The program `0_run_all.do` will run all programs in the sequence listed below. If running in any order other than the one outlined above, your results may differ.
  - Custom ado files have been stored in the `analysis/scripts/programs` directory and ado packages have been included in the `analysis/scripts/libraries` directory. The `0_run_all.do` file sets the `.ado` directories appropriately. 
- The program `analysis/scripts/code/1_process_raw_data.do` will extract and reformat all datasets referenced above, with the exception of IPUMS full count data that are subject to restrictions on redistribution and are not included in the public repository. 
  - The program `analysis/scripts/code/1_1_process_ipums_data.do` separately cleans IPUMS USA Full-Count data. 
- The program `analysis/scripts/code/2_clean_data.do` cleans all datasets provided in the public repository.
  - The program `analysis/scripts/code/_gnis_nhgis_overlay.R` is called by `analysis/scripts/code/2_clean_data.do` to create an overlay of county boundaries from GNIS and NHGIS.
- The program `analysis/scripts/code/3_0_ipums_data_for_geocode_nc_deaths.do` processes IPUMS-USA Full-Count data used in preparation for running `analysis/scripts/code/3_geocode_nc_deaths.do`
  - The program `analysis/scripts/code/_placenhg_nhgis_overlay.R` is called by `analysis/scripts/code/3_0_ipums_data_for_geocode_nc_deaths.do` to overlay NHGIS place point coordinates on NHGIS county boundaries. 
- The program `analysis/scripts/code/3_geocode_nc_deaths.do` maps place of birth text strings in the North Carolina death certificates to birth counties.
  - The programs in `analysis/scripts/code/3_geocode_nc_deaths/` are called by `analysis/scripts/code/3_geocode_nc_deaths.do` in the process of coding the birth county.
- The program `analysis/  scripts/code/4_compile_data.do` compiles all the datasets generated from public datasets to create the analysis datasets. 
  - The program `analysis/scripts/code/4_1_compile_ipums_data.do` constructs analysis datasets that use IPUMS data as inputs. 
- The program `analysis/scripts/code/5_tables.do` generates all tables in the main body of the article.
- The programs `analysis/scripts/code/5_figures.do` generates Figures 1 to 4 in the main body of the article.
  - The program `analysis/scripts/code/5_maps.R` is called by `analysis/scripts/code/5_figures.do` to generate the maps in Figure 1
- The names of output files begin with an appropriate prefix (e.g. `table_5_*.tex`, `figure_2b2_*.pdf`) and should be easy to correlate with the manuscript. In figures with multiple sub-elements, the prefix of the file name includes, in order, the figure number, the panel (as displayed in the manuscript), and the row number (not shown in the manuscript). 
- Separate programs generate all tables and figures in each online appendix. The correspondence between appendices and programs goes as follows (Appendix A and H do not include any analysis):
  - Appendix B: `analysis/scripts/code/6.01_online_appendix_b_hospitals.do` 
  - Appendix C: `analysis/scripts/code/6.02_online_appendix_c_doctors.do`
  - Appendix D: `analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do`
  - Appendix E: `analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do`
  - Appendix G: `analysis/scripts/code/6.05_online_appendix_g_other_results.do`
  - Appendix J: `analysis/scripts/code/6.06_online_appendix_j_non_nc.do`
  - Appendix F: `analysis/scripts/code/6.07_online_appendix_f_long_run.do`
  - Appendix I: `analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do`
    - The program `analysis/scripts/code/6.08.1_bacon_decomp.R` is called by `analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do`
  - Appendix K: `analysis/scripts/code/6.09_online_appendix_k_ri.do`
  - Appendix L: `analysis/scripts/code/6.10_online_appendix_l_extended_panel.do`
  - Appendix M: `analysis/scripts/code/6.11_online_appendix_m_psm.do`
  - Appendix N: `analysis/scripts/code/6.12_online_appendix_n_summary_stats.do`
  - Appendix J: `analysis/scripts/code/6.13_online_appendix_j_iv.do`
- The programs `analysis/scripts/code/7_combined_spec_chart.R` and `analysis/scripts/code/7_sample_chart.R` create Figures 5a and 5b respectively.
- The program `analysis/scripts/code/8_intext_stats.do` computes various statistics described in the manuscript that are not derived from any of the exhibits.

### License for Code

The code is licensed under a MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

To perform a clean run

1.  Be sure to have downloaded the publicly available IPUMS and ICPSR data that we are not allowed to redistribute
2. Be sure to download the NUMIDENT data from https://doi.org/10.3886/E207202V1.
3. Delete the following two directories:
  
  - `/processed`
  - `/output`

4. Open the stata project `duke-replication.stpr` or make the working directory of Stata is the same directory `duke-replication.stpr` is located in
5. Run this file, `0_run_all.do`



## List of tables and programs

The provided code reproduces:

- All numbers provided in text in the paper
- All tables and figures in the paper


| Figure/Table #    | Program                            | Line Numbers                        | Output File                                     | Note                            |
|-------------------|------------------------------------|-------------------------------------|-------------------------------------------------|---------------------------------|
| Table 1           | analysis/scripts/code/5_tables.do  | 255-292                             | table_1_county_level_hospitals.tex              ||
| Table 2           | analysis/scripts/code/5_tables.do  | 517-577                             | table_2_county_level_doctors_2yr_as_quality.tex ||
| Table 3           | analysis/scripts/code/5_tables.do  | 689-712                             | table_3_infant_mortality_poisson_extensive.tex  ||
| Table 4           | analysis/scripts/code/5_tables.do  | 767-889  | table_4_infant_mortality_poisson_intensive.tex  ||
| Table 5           | analysis/scripts/code/5_tables.do  | 1066                           | table_5_continuous_sulfa_interaction.tex        ||
| Table 6           | analysis/scripts/code/5_tables.do  | 1195-1218                           | table_6_long_run_mortality_poisson.tex          ||
| Figure 1a         | analysis/scripts/code/5_figures.do | 79                               | figure_1a_share_counties_treated.pdf            ||
| Figure 1b         | analysis/scripts/code/5_maps.R     | 76                               | figure_1b_duke_map.pdf                          ||
| Figure 1c         | analysis/scripts/code/5_figures.do | 134                             | figure_1c_infant_morality_by_race_over_time.pdf ||
| Figure 1d         | analysis/scripts/code/5_maps.R     | 91                               | figure_1d_imr_map.pdf                           ||
| Figure 2a1        | analysis/scripts/code/5_figures.do | 289                               | figure_2a1_total_beds_by_year.pdf               ||
| Figure 2b1        | analysis/scripts/code/5_figures.do | 289                               | figure_2b1_likely_beds_by_year.pdf              ||
| Figure 2c1        | analysis/scripts/code/5_figures.do | 289                             | figure_2c1_private_beds_by_year.pdf             ||
| Figure 2a2        | analysis/scripts/code/5_figures.do | 379                               | figure_2a2_total_beds_by_event_time.pdf         ||
| Figure 2b2        | analysis/scripts/code/5_figures.do | 379                               | figure_2b2_likely_beds_by_event_time.pdf        ||
| Figure 2c2        | analysis/scripts/code/5_figures.do | 379                             | figure_2c2_private_beds_by_event_time.pdf       ||
| Figure 2a3        | analysis/scripts/code/5_figures.do | 816                               | figure_2a3_total_beds_first_stage.pdf           ||
| Figure 2b3        | analysis/scripts/code/5_figures.do | 816                               | figure_2b3_likely_beds_first_stage.pdf          ||
| Figure 2c3        | analysis/scripts/code/5_figures.do | 816                             | figure_2c3_private_beds_first_stage.pdf         ||
| Figure 3a1        | analysis/scripts/code/5_figures.do | 860                               | figure_3a1_pooled_rMD_by_treat_status.pdf       ||
| Figure 3b1        | analysis/scripts/code/5_figures.do | 880                              | figure_3b1_pooled_rMD_good_by_treat_status.pdf  ||
| Figure 3c1        | analysis/scripts/code/5_figures.do | 899                             | figure_3c1_pooled_rMD_bad_by_treat_status.pdf   ||
| Figure 3a2        | analysis/scripts/code/5_figures.do | 959                               | figure_3a2_pooled_rMD_by_event_time.pdf         ||
| Figure 3b2        | analysis/scripts/code/5_figures.do | 978                            | figure_3b2_pooled_rMD_good_by_event_time.pdf    ||
| Figure 3c2        | analysis/scripts/code/5_figures.do | 997                             | figure_3c2_pooled_rMD_bad_by_event_time.pdf     ||
| Figure 3a3        | analysis/scripts/code/5_figures.do | 1436                               | figure_3a3_pooled_rMD_first_stage.pdf           ||
| Figure 3b3        | analysis/scripts/code/5_figures.do | 1436                               | figure_3b3_pooled_rMD_good_first_stage.pdf      ||
| Figure 3c3        | analysis/scripts/code/5_figures.do | 1436                             | figure_3c3_pooled_rMD_bad_first_stage.pdf       ||
| Figure 4a1        | analysis/scripts/code/5_figures.do | 1497                               | figure_4a1_imr_by_treatment_status_pooled.pdf   ||
| Figure 4b1        | analysis/scripts/code/5_figures.do | 1515                              | figure_4b1_imr_by_treatment_status_black.pdf    ||
| Figure 4c1        | analysis/scripts/code/5_figures.do | 1533                            | figure_4c1_imr_by_treatment_status_white.pdf    ||
| Figure 4a2        | analysis/scripts/code/5_figures.do | 1597                               | figure_4a2_imr_by_event_time_pooled.pdf         ||
| Figure 4b2        | analysis/scripts/code/5_figures.do | 1615                              | figure_4b2_imr_by_event_time_black.pdf          ||
| Figure 4c2        | analysis/scripts/code/5_figures.do | 1633                             | figure_4c2_imr_by_event_time_white.pdf          ||
| Figure 4a3        | analysis/scripts/code/5_figures.do | 2126                               | figure_4a3_imr_event_study_pooled.pdf           ||
| Figure 4b3        | analysis/scripts/code/5_figures.do | 2126                               | figure_4b3_imr_event_study_black.pdf            ||
| Figure 4c3        | analysis/scripts/code/5_figures.do | 2126                             | figure_4c3_imr_event_study_white.pdf            ||
| Figure 5a         | analysis/scripts/code/7_combined_spec_chart.R                     | 420                             | figure_5a_spec_chart_combined.pdf            ||
| Figure 5b         | analysis/scripts/code/7_sample_chart.R                            | 198                            | figure_5b_sample_chart.pdf            ||
| Table B1          | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 175-197                             | table_b1_county_level_hospitals_robustness.tex              ||
| Figure B1a1       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 314                            | figure_b1a1_total_hospitals_by_year.pdf                     ||
| Figure B1a2       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 314                             | figure_b1a2_likely_hospitals_by_year.pdf                    ||
| Figure B1a3       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 314                             | figure_b1a3_private_hospitals_by_year.pdf                   ||
| Figure B1b1       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 755                             | figure_b1b1_total_hospitals_first_stage.pdf                 ||
| Figure B1b2       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 755                             | figure_b1b2_likely_hospitals_first_stage.pdf                ||
| Figure B1b3       | analysis/scripts/code/6.01_online_appendix_b_hospitals.do           | 755                           | figure_b1b3_private_hospitals_first_stage.pdf               ||
| Table C1          | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 237-269                             | table_c1_county_level_doctors_robustness.tex                ||
| Table C2          | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 416-479                             | table_c2_county_level_doctors_alt_qual_high.tex             ||
| Table C3          | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 493-555                             | table_c3_county_level_doctors_alt_qual_low.tex              ||
| Table C4          | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 685-741                             | table_c4_county_level_doctors_other_metrics.tex             ||
| Figure C1a1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 792                             | figure_c1a1_black_rMD_by_treatment_status.pdf                     ||
| Figure C1a2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 812                             | figure_c1a2_black_rMD_good_by_treatment_status.pdf                     ||
| Figure C1a3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 832                             | figure_c1a3_black_rMD_bad_by_treatment_status.pdf                     ||
| Figure C1b1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 792                             | figure_c1b1_all_black_doctors_first_stage.pdf                     ||
| Figure C1b2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 812                             | figure_c1b2_good_black_doctors_first_stage.pdf                     ||
| Figure C1b3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 832                             | figure_c1b3_bad_black_doctors_first_stage.pdf                     ||
| Figure C2a1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 866                             | figure_c2a1_white_rMD_by_treatment_status.pdf                     ||
| Figure C2a2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 886                             | figure_c2a2_white_rMD_good_by_treatment_status.pdf                     ||
| Figure C2a3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 906                             | figure_c2a3_white_rMD_bad_by_treatment_status.pdf                     ||
| Figure C2b1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 866                             | figure_c2b1_all_white_doctors_first_stage.pdf                     ||
| Figure C2b2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 886                             | figure_c2b2_good_white_doctors_first_stage.pdf                     ||
| Figure C2b3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 906                             | figure_c2b3_bad_white_doctors_first_stage.pdf                     ||
| Figure C3a1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1416                             | figure_c3a1_med_profs_by_treatment_status_nurse.pdf                     ||
| Figure C3a2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1416                             | figure_c3a2_med_profs_by_treatment_status_hosp_attendant.pdf                     ||
| Figure C3a3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1416                            | figure_c3a3_med_profs_by_treatment_status_hosp_clerical.pdf                     ||
| Figure C3b1       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1504                             | figure_c3b1_event_study_hosp_staff_nurse.pdf                     ||
| Figure C3b2       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1504                             | figure_c3b2_event_study_hosp_staff_hosp_attendant.pdf                     ||
| Figure C3b3       | analysis/scripts/code/6.02_online_appendix_c_doctors.do             | 1504                             | figure_c3b3_event_study_hosp_staff_hosp_clerical.pdf                     ||
| Table D1          | analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do    | 214-236                             | table_d1_infant_mortality_robustness.tex                ||
| Table D2          | analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do    | 392-414                             | table_d2_infant_mortality_log_specs.tex                ||
| Figure D1a        | analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do    | 662                            | figure_d1a_event_study_pooled_imr_stacked_poisson_kappa_*_controls_no.pdf                ||
| Figure D1b        | analysis/scripts/code/6.03_online_appendix_d_infant_mortality.do    | 662                             | figure_d1b_event_study_pooled_imr_stacked_poisson_kappa_*_controls_yes.pdf                ||
| Table E1          | analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do       | 69-283                             | table_e1_het_summary.tex                ||
| Figure E1         | analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do       | 349                             | figure_e1_share_rec_pay_by_years_since_app.pdf                     ||
| Figure E2a        | analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do       | 490                             | figure_e2a_bin_pooled.pdf                     ||
| Figure E2b        | analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do       | 510                             | figure_e2b_app_pooled.pdf                     ||
| Figure E2c        | analysis/scripts/code/6.04_online_appendix_e_heterogeneity.do       | 530                             | figure_e2c_pay_pooled.pdf                     ||
| Table F1          | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 191-214                             | table_F1_later_life_mortality_with_rates.tex ||
| Table F2          | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 412-435                             | table_F2_later_life_mortality_collapsed.tex ||
| Table F3          | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 600-623                             | table_F3_combined_mortality_clean_controls ||
| Table F4          | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 832-855                             | table_F4_later_life_mortality_add_south_carolina ||
| Figure F1         | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 924                             | figure_F1_life_exp_at_birth_with_numident_restrictions.pdf ||
| Figure F2         | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 1196                            | figure_F2_long_run_unbalanced_event_study.pdf ||
| Figure F3         | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 1004                             | figure_F3_unbalanced_event_time_long_run.pdf ||
| Figure F4         | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 1439                             | figure_F4_long_run_unbalanced_event_study_extended.pdf ||
| Figure F5 (top)   | analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 1737                             | figure_F5_balanced_event_study.pdf ||
| Figure F5 (bottom)| analysis/scripts/code/6.07_online_appendix_f_long_run.do            | 1549                             | figure_F5_bot_balanced_event_time_long_run ||
| Table G1          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 264                             | table_g1_covariance_balance_test.tex                ||
| Table G2          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 362-370                           | table_g2_maternal_mortality_diff_specs.tex                ||
| Table G3          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 593-615                             | table_g3_short_run_fertility_diff_specs.tex                ||
| Table G4          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 711-733                             | table_g4_infant_mortality_poisson_by_timing.tex                ||
| Table G5          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 1032-1054                             | table_g5_stillborn_unnamed_infants.tex                ||
| Table G6          | analysis/scripts/code/6.05_online_appendix_g_other_results.do       | 1143-1235                             | table_g6_sulfa_dd_poisson.tex                ||
| Table I1          | analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do    | 171                            | table_i1_bacon_summary.tex              ||
| Figure I1a        | analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do    | 120                             | figure_i1a_bacon_decomp_diagnostic.pdf                     ||
| Figure I1b        | analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do    | 120                            | figure_i1b_bacon_decomp_diagnostic_bk.pdf                     ||
| Figure I1c        | analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do    | 120                             | figure_i1c_bacon_decomp_diagnostic_wt.pdf                     ||
| Figure I2         | analysis/scripts/code/6.08.0_online_appendix_i_es_diagnostics.do    | 222                            | figure_i2_event_study_n_treated_units.pdf                     ||
| Table J1          | analysis/scripts/code/6.13_online_appendix_j_iv.do                  | 465-637                             | table_j1_iv_pooled_imr_intensive.tex                ||
| Figure J1a        | analysis/scripts/code/6.06_online_appendix_j_non_nc.do              | 181                             | figure_j1a_imr_treated_vs_southern_bk.pdf                     ||
| Figure J1b        | analysis/scripts/code/6.06_online_appendix_j_non_nc.do              | 211                             | figure_j1b_imr_treated_vs_southern_wt.pdf                     ||
| Figure J2a        | analysis/scripts/code/6.06_online_appendix_j_non_nc.do              | 468                             | figure_j2a_es_other_southern_states_imr_pooled.pdf                     ||
| Figure J2b        | analysis/scripts/code/6.06_online_appendix_j_non_nc.do              | 468                             | figure_j2b_es_other_southern_states_imr_black.pdf                     ||
| Figure J2c        | analysis/scripts/code/6.06_online_appendix_j_non_nc.do              | 468                             | figure_j2c_es_other_southern_states_imr_white.pdf                     ||
| Figure K1         | analysis/scripts/code/6.09_online_appendix_k_ri.do                  | 221                             | figure_k1_ri_all_cty_b.pdf                     ||
| Table L1          | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 424-461                             | table_l1_county_level_hospitals_1922_1950.tex                ||
| Table L2          | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 1207                             | table_l2_combined_mortality_poisson_clean_controls_1962.tex                ||
| Figure L1a        | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 723                             | figure_l1a_total_beds_first_stage_1922_1950.pdf                     ||
| Figure L1b        | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 723                            | figure_l1b_likely_beds_first_stage_1922_1950.pdf                     ||
| Figure L1c        | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 723                             | figure_l1c_private_beds_first_stage_1922_1950.pdf                     ||
| Figure L2a        | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 872                            | figure_l2a_imr_bailey_treated_vs_bailey_south_1962.pdf                     ||
| Figure L2b        | analysis/scripts/code/6.10_online_appendix_l_extended_panel.do      | 872                             | figure_l2b_pooled_other_southern_states_event_study_bailey.pdf                     ||
| Table M1          | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 444-460                             | table_m1_imr_poisson_clean_cntrls_psm.tex                ||
| Table M2          | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 946-969                             | table_m2_combined_mortality_poisson_clean_controls_psm_900.tex                ||
| Table M3          | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 946-969                             | table_m3_combined_mortality_poisson_clean_controls_psm_750.tex                ||
| Table M4          | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 946-969                             | table_m4_combined_mortality_poisson_clean_controls_psm_500.tex                ||
| Figure M1a1       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 384-414                             | figure_m1a1_psm_top100pct_fake_treat_clean_cntrls_pooled_by_treatment_over_time.pdf                     ||
| Figure M1a2       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 |  384-414                              | figure_m1a2_psm_top100pct_fake_treat_clean_cntrls_black_by_treatment_over_time.pdf                     ||
| Figure M1a3       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 |  384-414                              | figure_m1a3_psm_top100pct_fake_treat_clean_cntrls_white_by_treatment_over_time.pdf                     ||
| Figure M1b1       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 |  384-414                              | figure_m1b1_psm_top250pct_fake_treat_clean_cntrls_pooled_by_treatment_over_time.pdf                     ||
| Figure M1b2       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 384-414                             | figure_m1b2_psm_top250pct_fake_treat_clean_cntrls_black_by_treatment_over_time.pdf                     ||
| Figure M1b3       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 384-414                             | figure_m1b3_psm_top250pct_fake_treat_clean_cntrls_white_by_treatment_over_time.pdf                     ||
| Figure M1c1       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 384-414                              | figure_m1c1_psm_top500pct_fake_treat_clean_cntrls_pooled_by_treatment_over_time.pdf                     ||
| Figure M1c2       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 |  384-414                             | figure_m1c2_psm_top500pct_fake_treat_clean_cntrls_black_by_treatment_over_time.pdf                     ||
| Figure M1c3       | analysis/scripts/code/6.11_online_appendix_m_psm.do                 | 384-414                              | figure_m1c3_psm_top500pct_fake_treat_clean_cntrls_white_by_treatment_over_time.pdf                     ||
| Table N1          | analysis/scripts/code/6.12_online_appendix_n_summary_stats.do       | 78-259                             | table_n1_summary_treatment_mortality.tex                ||
| Table N2          | analysis/scripts/code/6.12_online_appendix_n_summary_stats.do       | 287-393                             | table_n2_summary_first_stage.tex                ||

## Data citations 

American Medical Association (AMA). 1906. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1909. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1912. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1916. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1918. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1921. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1923. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1925. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1927. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1929. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1931. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1934. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1936. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1938. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1940. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1942. American medical directory. Chicago: American Medical Association [etc.].

American Medical Association (AMA). 1921. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1926. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1928. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1929. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1930. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1931. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1932. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1933. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1934. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1935. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1936. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1937. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1938. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1939. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1940. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1941. "Hospital Service in the United States." _Journal of the American Medical Association_.

American Medical Association (AMA). 1942. "Hospital Service in the United States." _Journal of the American Medical Association_.

Arias E. United States life tables, 2010. National vital statistics reports; vol 63 no 7. Hyattsville, MD: National Center for Health Statistics. 2014.

Arias E, Tejada-Vera B, Ahmad F, Kochanek KD. Provisional life expectancy estimates for 2020. Vital Statistics Rapid Release; no 15. Hyattsville, MD: National Center for Health Statistics. July 2021. DOI: https://dx.doi.org/10.15620/cdc:107201.

Bailey, Martha, Karen Clay, Price Fishback, Michael R. Haines, Shawn Kantor, Edson Severnini, and Anna Wentz. U.S. County-Level Natality and Mortality Data, 1915-2007. ICPSR36603-v2. Ann Arbor, MI: Inter-university Consortium for Political and Social Research [distributor], 2018-05-02. http://doi.org/10.3886/ICPSR36603.v2

Black, Dan A., Seth G. Sanders, Evan J. Taylor, and Lowell J. Taylor. “The Impact of the Great Migration on Mortality of African Americans: Evidence from the Deep South.” American Economic Review 105, no. 2 (February 2015): 477–503. https://doi.org/10.1257/aer.20120642.

Cook, Lisa D., Trevon D. Logan, and John M. Parman (2014) "Distinctively Black Names in the American Past," Explorations in Economic History, Vol. 53, pp. 64–82.

Cook, Lisa D., Trevon D. Logan, and John M. Parman (2016) "The Mortality Consequences of Distinctively Black Names," Explorations in Economic History, Vol. 59, pp. 114–125.

Esteves, Rui, Kris James Mitchener, Peter Nencka, and Melissa A. Thomasson. "Do Pandemics Change Healthcare? Evidence from the Great Influenza." Cambridge, MA: National Bureau of Economic Research, November 2022. https://doi.org/10.3386/w30643.

Ferrell, J. Atkinson and Mead, P. A. (1936). History of county health organizations in the United States, 1908-33. Washington: U.S. Gov't. Print. Off..

Fishback, Price V., Michael R. Haines, and Shawn Kantor (2007) “Births, Deaths, and New Deal Relief during the Great Depression,” The Review of Economics and Statistics, Vol. 89, No. 1, pp. 1–14.

Haines, Michael. "Fertility and Mortality in the United States." EH.Net Encyclopedia, edited by Robert Whaples. March 19, 2008. https://eh.net/encyclopedia/fertility-and-mortality-in-the-united-states/.

Hoehn-Velasco, Lauren (2018) “Explaining Declines in US Rural Mortality, 1910-1933: The Role of County Health Departments,” Explorations in Economic History, Vol. 70, pp. 42–72.

Hoehn-Velasco, Lauren (2021) “The Long-term Impact of Preventative Public Health Programs,” Economic Journal, Vol. 131, No. 634, pp. 797–826.

Hollingsworth, Alex, Krzysztof Karbownik, Melissa A. Thomasson, and Anthony Wray. "The Gift of a Lifetime: The Hospital, Modern Medicine, and Mortality." American Economic Review VOL, no. NN (Month YYYY): pppp-pp. https://doi.org/10.1257/aer.YYYYNNNN.

Hollingsworth, Alex, Krzysztof Karbownik, Melissa A. Thomasson, and Anthony Wray. "The Gift of a Lifetime: The Hospital, Modern Medicine, and Mortality." Cambridge, MA: National Bureau of Economic Research, November 2022. https://doi.org/10.3386/w30663.

IPUMS USA. 2015. "ICPSR County Codes." Accessed August 28, 2023. https://usa.ipums.org/usa/volii/ICPSR.shtml. 

IPUMS USA. 2021. "PLACENHG Code List." Accessed September 5, 2023. https://usa.ipums.org/usa/resources/volii/ipums_placenhg_code_list.xlsx. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1922. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1922. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1923. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1924. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1925. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1926. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1927. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1928. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1929. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1930. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1931. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1932. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1933. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1934. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1935. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1936. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1937. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1938. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1939. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1940. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1941. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1942. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1943. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1944. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1945. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1946. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1947. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

North Carolina. Bureau of Vital Statistics (NC-BVS). 1948. Annual report of the Bureau of Vital Statistics of the North Carolina State Board of Health. Raleigh, NC: Bureau of Vital Statistics of the North Carolina State Board of Health. 

Pollitt, Phoebe Ann. 2017. African American Hospitals in North Carolina: 39 Institutional Histories, 1880-1967. Jefferson, NC: McFarland.

Sahr, Robert C. 2018. Consumer Price Index (CPI) Conversion Factors for Dollars of 1774 to estimated 2028 to Convert to Dollars of 2017. Accessed October 18, 2018. https://liberalarts.oregonstate.edu/sites/liberalarts.oregonstate.edu/files/polisci/faculty-research/sahr/inflation-conversion/pdf/cv2017.pdf

Social Security Administration (SSA). 2007. "Numerical Identification Files (NUMIDENT), created, 1936 - 2007, documenting the period 1936 - 2007." [dataset] Washington, DC: Social Security Administration. 

Steven Manson, Jonathan Schroeder, David Van Riper, and Steven Ruggles. IPUMS National Historical Geographic Information System: Version 14.0 [Database]. Minneapolis, MN: IPUMS. 2019. http://doi.org/10.18128/D050.V14.0.

Steven Manson, Jonathan Schroeder, David Van Riper, Tracy Kugler, and Steven Ruggles. IPUMS National Historical Geographic Information System: Version 17.0 [dataset]. Minneapolis, MN: IPUMS. 2022. http://doi.org/10.18128/D050.V17.0.

Steven Ruggles, Sarah Flood, Matthew Sobek, Danika Brockman, Grace Cooper,  Stephanie Richards, and Megan Schouweiler. IPUMS USA: Version 13.0 [dataset]. Minneapolis, MN: IPUMS, 2023a. https://doi.org/10.18128/D010.V13.0

Steven Ruggles, Sarah Flood, Matthew Sobek, Daniel Backman, Annie Chen, Grace Cooper,  Stephanie Richards, Renae Rogers, and Megan Schouweiler. IPUMS USA: Version 14.0 [dataset]. Minneapolis, MN: IPUMS, 2023b. https://doi.org/10.18128/D010.V14.0.

Surveillance, Epidemiology, and End Results (SEER) Program. 2022. "County-Level Population Files - Single-year Age Groups." National Cancer Institute. Accessed June 29, 2022. https://seer.cancer.gov/popdata/download.html. 

The Duke Endowment. 1925a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment.

The Duke Endowment. 1926a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1927a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1928a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1929a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1930a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1931a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1932a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1933a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1934a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1935a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1936a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1937a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1938a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1939a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1940a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1941a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1942a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1943a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1944a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1945a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1946a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1947a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1948a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1949a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1950a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1951a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1952a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1953a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1954a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1955a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1956a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1957a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1958a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1959a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1950a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1961a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment.

The Duke Endowment. 1962a. _Annual Report of the Hospital Section_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1925b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment.

The Duke Endowment. 1926b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1927b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1928b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1929b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1930b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1931b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1932b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1933b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1934b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1935b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1936b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1937b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1938b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1939b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1940b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1941b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1942b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1943b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1944b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1945b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1946b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1947b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1948b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1949b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1950b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1951b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1952b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1953b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1954b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1955b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1956b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1957b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1958b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1959b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1950b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

The Duke Endowment. 1961b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment.

The Duke Endowment. 1962b. _Yearbook of the Duke Endowment_. Charlotte, NC: The Duke Endowment. 

U.S. Geological Survey (USGS). 2019. US Geographic Names Information System (GNIS) - National File: US Geological Survey. Accessed 1 March 2019. 

## Package Citations

### Stata

Baum, C.F., Schaffer, M.E. 2013.  avar: Asymptotic covariance estimation for iid and non-iid data robust to heteroskedasticity, autocorrelation, 1- and 2-way clustering, common cross-panel autocorrelated disturbances, etc. http://ideas.repec.org/c/boc/bocode/XXX.html, revised 28 July 2015.

Christopher F Baum & Mark E Schaffer & Steven Stillman, 2002. "IVREG2: Stata module for extended instrumental variables/2SLS and GMM estimation," Statistical Software Components S425401, Boston College Department of Economics, revised 30 Jul 2023.

Daniel Bischof, 2016. "BLINDSCHEMES: Stata module to provide graph schemes sensitive to color vision deficiency," Statistical Software Components S458251, Boston College Department of Economics, revised 07 Aug 2020.

Joshua Bleiberg, 2021. "STACKEDEV: Stata module to implement stacked event study estimator," Statistical Software Components S459027, Boston College Department of Economics.

Kirill Borusyak, 2021. "DID_IMPUTATION: Stata module to perform treatment effect estimation and pre-trend testing in event studies," Statistical Software Components S458957, Boston College Department of Economics, revised 22 Nov 2023.

Kirill Borusyak, 2021. "EVENT_PLOT: Stata module to plot the staggered-adoption diff-in-diff ("event study") estimates," Statistical Software Components S458958, Boston College Department of Economics, revised 26 May 2021. 

Tony Brady, 1998. "UNIQUE: Stata module to report number of unique values in variable(s)," Statistical Software Components S354201, Boston College Department of Economics, revised 18 Jun 2020.

Mauricio Caceres Bravo, 2018. "GTOOLS: Stata module to provide a fast implementation of common group commands," Statistical Software Components S458514, Boston College Department of Economics, revised 05 Dec 2022.

Sergio Correia, 2016. "FTOOLS: Stata module to provide alternatives to common Stata commands optimized for large datasets," Statistical Software Components S458213, Boston College Department of Economics, revised 21 Aug 2023.

Sergio Correia, 2018. "IVREGHDFE: Stata module for extended instrumental variable regressions with multiple levels of fixed effects," Statistical Software Components S458530, Boston College Department of Economics, revised 7 Jul 2018.

Sergio Correia, 2014. "REGHDFE: Stata module to perform linear or instrumental-variable regression absorbing any number of high-dimensional fixed effects," Statistical Software Components S457874, Boston College Department of Economics, revised 21 Aug 2023.

Sergio Correia & Paulo Guimaraes & Thomas Zylkin, 2019. "PPMLHDFE: Stata module for Poisson pseudo-likelihood regression with multiple levels of fixed effects," Statistical Software Components S458622, Boston College Department of Economics, revised 25 Feb 2021.

Kevin Crow, 2006. "SHP2DTA: Stata module to converts shape boundary files to Stata datasets," Statistical Software Components S456718, Boston College Department of Economics, revised 17 Jul 2015.

Clément de Chaisemartin & Xavier D'Haultfoeuille & Yannick Guyonvarch, 2019. "DID_MULTIPLEGT: Stata module to estimate sharp Difference-in-Difference designs with multiple groups and periods," Statistical Software Components S458643, Boston College Department of Economics, revised 17 Dec 2023.

James Feigenbaum, 2014. "JAROWINKLER: Stata module to calculate the Jaro-Winkler distance between strings," Statistical Software Components S457850, Boston College Department of Economics, revised 5 Oct 2016.

Keith Finlay & Leandro Magnusson & Mark E Schaffer, 2013. "WEAKIV: Stata module to perform weak-instrument-robust tests and confidence intervals for instrumental-variable (IV) estimation of linear, probit and tobit models," Statistical Software Components S457684, Boston College Department of Economics, revised 18 Oct 2016.

Matthieu Gomez, 2015. "SUMUP: Stata module to compute summary statistics by group," Statistical Software Components S458129, Boston College Department of Economics.

Andrew Goodman-Bacon & Thomas Goldring & Austin Nichols, 2019. "BACONDECOMP: Stata module to perform a Bacon decomposition of difference-in-differences estimation," Statistical Software Components S458676, Boston College Department of Economics, revised 21 Sep 2022.

Ben Jann, 2004 "ESTOUT: Stata module to make regression tables," Statistical Software Components S439301, Boston College Department of Economics, revised 12 Feb 2023.

David Kantor, 2004. "CARRYFORWARD: Stata module to carry forward previous observations," Statistical Software Components S444902, Boston College Department of Economics, revised 15 Jan 2016.

Frank Kleibergen & Mark E Schaffer & Frank Windmeijer, 2007. "RANKTEST: Stata module to test the rank of a matrix," Statistical Software Components S456865, Boston College Department of Economics, revised 29 Sep 2020.

David S.Lee & Justin McCrary & Marcelo J. Moreira & Jack Porter, 2022. "TF: An additional option for ivreg2: tF critical values and standard error adjustments," http://www.princeton.edu/~davidlee/wp/tf. Accessed 30 Aug 2023. 

Gary Longton & Nicholas J. Cox, 2002. "DISTINCT: Stata module to display distinct values of variables," Statistical Software Components S424201, Boston College Department of Economics, revised 21 Mar 2012.

David Molitor & Julian Reif, 2019. "RSCRIPT: Stata module to call an R script from Stata," Statistical Software Components S458644, Boston College Department of Economics, revised 03 Jun 2023.

Julian Reif, 2008. "REGSAVE: Stata module to save regression results to a Stata-formatted dataset," Statistical Software Components S456964, Boston College Department of Economics, revised 03 Dec 2023.

Julian Reif, 2010. "STRGROUP: Stata module to match strings based on their Levenshtein edit distance," Statistical Software Components S457151, Boston College Department of Economics, revised 22 Aug 2023.

Julian Reif, 2008. "TEXSAVE: Stata module to save a dataset in LaTeX format," Statistical Software Components S456974, Boston College Department of Economics, revised 28 May 2023.

Fernando Rios-Avila, 2022. "JWDID: Stata module to estimate Difference-in-Difference models using Mundlak approach," Statistical Software Components S459114, Boston College Department of Economics, revised 17 Nov 2023.

Fernando Rios-Avila & Pedro H.C. Sant'Anna & Brantly Callaway, 2021. "CSDID: Stata module for the estimation of Difference-in-Difference models with multiple time periods," Statistical Software Components S458976, Boston College Department of Economics, revised 25 Feb 2023.

Fernando Rios-Avila & Pedro H.C. Sant'Anna & Asjad Naqvi, 2021. "DRDID: Stata module for the estimation of Doubly Robust Difference-in-Difference models," Statistical Software Components S458977, Boston College Department of Economics, revised 18 Oct 2022.

Liyang Sun, 2021. "EVENTSTUDYINTERACT: Stata module to implement the interaction weighted estimator for an event study," Statistical Software Components S458978, Boston College Department of Economics, revised 11 Sep 2022.

Liyang Sun, 2020. "EVENTSTUDYWEIGHTS: Stata module to estimate the implied weights on the cohort-specific average treatment effects on the treated (CATTs) (event study specifications)," Statistical Software Components S458833, Boston College Department of Economics, revised 04 Aug 2021.

George G. Vega Yon & Brian Quistorff, 2019. "parallel: A command for parallel computing," Stata Journal, StataCorp LP, vol. 19(3), pages 667-684, September.

Ben Zipperer, 2018. "lincomestadd." _GitHub_. https://github.com/benzipperer/lincomestadd/. Accessed August 30, 2023. 

### R

Bache, Stefan Milton, and Hadley Wickham. Magrittr: A Forward-Pipe Operator for R, 2022. https://magrittr.tidyverse.org.

Bergé, Laurent. "Efficient Estimation of Maximum Likelihood Models with Multiple Fixed-Effects: The R Package FENmlm." CREA Discussion Papers, no. 13 (2018).

Berge, Laurent. Fixest: Fast Fixed-Effects Estimations, 2023. https://lrberge.github.io/fixest/.

Callaway, Brantly, and Pedro H. C. Sant’Anna. Did: Treatment Effects with Multiple Periods and Groups, 2022. https://bcallaway11.github.io/did/.

———. "Difference-in-Differences with Multiple Time Periods." Journal of Econometrics, 2021. https://doi.org/10.1016/j.jeconom.2020.12.001.

Chang, Winston. Extrafont: Tools for Using Fonts, 2023. https://github.com/wch/extrafont.

Csárdi, Gábor, Jim Hester, Hadley Wickham, Winston Chang, Martin Morgan, and Dan Tenenbaum. Remotes: R Package Installation from Remote Repositories, Including GitHub, 2023. https://remotes.r-lib.org.

Dowle, Matt, and Arun Srinivasan. Data.Table: Extension of `data.Frame`, 2023. https://r-datatable.com.

Elbers, Benjamin. Tidylog: Logging for Dplyr and Tidyr Functions, 2020. https://github.com/elbersb/tidylog/.

Garnier, Simon. Viridis: Colorblind-Friendly Color Maps for R, 2023. https://sjmgarnier.github.io/viridis/.

Garnier, Simon, Ross, Noam, Rudis, Robert, Camargo, et al. Viridis(Lite) - Colorblind-Friendly Color Maps for R, 2023. https://doi.org/10.5281/zenodo.4679423.

Gomez, Matthieu. Statar: Tools Inspired by Stata to Manipulate Tabular Data, 2023. https://github.com/matthieugomez/statar.

Grolemund, Garrett, and Hadley Wickham. "Dates and Times Made Easy with Lubridate." Journal of Statistical Software 40, no. 3 (2011): 1–25.

Lüdecke, Daniel. Sjlabelled: Labelled Data Utility Functions, 2022. https://strengejacke.github.io/sjlabelled/.

Pebesma, Edzer. Sf: Simple Features for R, 2023. https://r-spatial.github.io/sf/.
———. "Simple Features for R: Standardized Support for Spatial Vector Data." The R Journal 10, no. 1 (2018): 439–46. https://doi.org/10.32614/RJ-2018-009.

Pebesma, Edzer, and Roger Bivand. Spatial Data Science: With Applications in R. Chapman and Hall/CRC, 2023. https://doi.org/10.1201/9780429459016.

Pedersen, Thomas Lin. Patchwork: The Composer of Plots, 2023. https://patchwork.data-imaginist.com.

Rinker, Tyler, and Dason Kurkiewicz. Pacman: Package Management Tool, 2019. https://github.com/trinker/pacman.

Spinu, Vitalie, Garrett Grolemund, and Hadley Wickham. Lubridate: Make Dealing with Dates a Little Easier, 2023. https://lubridate.tidyverse.org.

Urbanek, Simon, and Jeffrey Horner. Cairo: R Graphics Device Using Cairo Graphics Library for Creating High-Quality Bitmap (PNG, JPEG, TIFF), Vector (PDF, SVG, PostScript) and Display (X11 and Win32) Output, 2023. http://www.rforge.net/Cairo/.

Ushey, Kevin, and Hadley Wickham. Renv: Project Environments, 2023. https://rstudio.github.io/renv/.

Wickham, Hadley. Ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2016. https://ggplot2.tidyverse.org.

———. Tidyverse: Easily Install and Load the Tidyverse, 2023. https://tidyverse.tidyverse.org.

Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy D’Agostino McGowan, Romain François, Garrett Grolemund, et al. "Welcome to the Tidyverse." Journal of Open Source Software 4, no. 43 (2019): 1686. https://doi.org/10.21105/joss.01686.

Wickham, Hadley, Winston Chang, Lionel Henry, Thomas Lin Pedersen, Kohske Takahashi, Claus Wilke, Kara Woo, Hiroaki Yutani, and Dewey Dunnington. Ggplot2: Create Elegant Data Visualisations Using the Grammar of Graphics, 2023. https://ggplot2.tidyverse.org.

Wickham, Hadley, Evan Miller, and Danny Smith. Haven: Import and Export SPSS, Stata and SAS Files, 2023. https://haven.tidyverse.org.

Wickham, Hadley, Davis Vaughan, and Maximilian Girlich. Tidyr: Tidy Messy Data, 2023. https://tidyr.tidyverse.org.

Zhu, Hao. KableExtra: Construct Complex Table with Kable and Pipe Syntax, 2021. http://haozhu233.github.io/kableExtra/.



---

## Acknowledgements

Some content on this page was copied from [Hindawi](https://www.hindawi.com/research.data/#statement.templates). Other content was adapted  from [Fort (2016)](https://doi.org/10.1093/restud/rdw057), Supplementary data, with the author's permission.
