local package_list blindschemes avar shp2dta carryforward gtools distinct bacondecomp jarowinkler estout ///
    strgroup regsave csdid jwdid event_plot drdid sumup unique ranktest weakiv

foreach package in `package_list' {
    cap ssc install `package'
}


cap net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

cap net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

cap mata mata mlib index

cap ssc install ivreg2 // Install ivreg2, the core package
cap net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/")

cap net install ppmlhdfe, from("https://raw.githubusercontent.com/sergiocorreia/ppmlhdfe/master/src/")

cap net install lincomestadd, from("https://github.com/benzipperer/lincomestadd/raw/master")

cap ado tf 
cap net install tf, force from("http://www.princeton.edu/~davidlee/wp/")
