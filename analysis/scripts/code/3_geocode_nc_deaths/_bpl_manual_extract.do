gen county_nhgis = ""
gen state = "North Carolina" if bstate == 37
gen bcity = "" 

replace county_nhgis = "Pitt" if regexm(bpl,"Greenville") & state == "North Carolina"
replace bcity = "Greenville" if regexm(bpl,"Greenville") & state == "North Carolina"

replace county_nhgis = "Bladen" if regexm(bpl,"Abb(.)*urg")
replace state = "North Carolina" if regexm(bpl,"Abb(.)*urg")
replace bcity = "Abbottsburg" if regexm(bpl,"Abb(.)*urg")

replace state = "North Carolina" if regexm(bpl,"Ab[a-z]*d[a-z]*n") & state == "State not identified"
replace bcity = "Aberdeen" if regexm(bpl,"Ab[a-z]*d[a-z]*n") & state == "North Carolina"
replace county_nhgis = "Moore" if regexm(bpl,"Ab[a-z]*d[a-z]*n") & state == "North Carolina"

replace state = "North Carolina" if regexm(bpl,"Alb[a-z]*le")
replace bcity = "Albemarle" if regexm(bpl,"Alb[a-z]*le")
replace county_nhgis = "Stanly" if regexm(bpl,"Alb[a-z]*le")

replace state = "North Carolina" if regexm(bpl,"R[a-z]*c[a-z]*w[a-z]*l")
replace bcity = "Rockwell" if regexm(bpl,"R[a-z]*c[a-z]*w[a-z]*l")
replace county_nhgis = "Rowan" if regexm(bpl,"R[a-z]*c[a-z]*w[a-z]*l")

replace state = "North Carolina" if regexm(bpl,"Co[a-z]*cord")
replace county_nhgis = "Cabarrus" if regexm(bpl,"Co[a-z]*cord")
replace bcity = "Concord" if regexm(bpl,"Co[a-z]*cord")

replace state = "North Carolina" if regexm(bpl,"Woodbury")
replace bcity = "Woodbury" if regexm(bpl,"Woodbury")
replace county_nhgis = "Mecklenburg" if regexm(bpl,"Woodbury")

replace state = "North Carolina" if regexm(bpl,"Swans[b|h][a-z]*")
replace bcity = "Swansboro" if regexm(bpl,"Swans[b|h][a-z]*")
replace county_nhgis = "Onslow" if regexm(bpl,"Swans[b|h][a-z]*")

replace state = "North Carolina" if regexm(bpl,"G(.)*ld[ ]H[a-z]*ll")
replace bcity = "Gold Hill" if regexm(bpl,"G(.)*ld[ ]H[a-z]*ll")
replace county_nhgis = "Rowan" if regexm(bpl,"G(.)*ld[ ]H[a-z]*ll")

replace state = "North Carolina" if regexm(bpl,"R[a-z]c[h|k][y|i|e]* M[A-Z|a-z][^d]")
replace bcity = "Rocky Mount" if regexm(bpl,"R[a-z]c[h|k][y|i|e]* M[A-Z|a-z][^d]")
replace county_nhgis = "Edgecombe" if regexm(bpl,"R[a-z]c[h|k][y|i|e]* M[A-Z|a-z][^d]") & regexm(upper(bpl),"NASH") == 0

replace state = "North Carolina" if regexm(bpl,"Gr[a-z]*nsb")
replace bcity = "Greensboro" if regexm(bpl,"Gr[a-z]*nsb")
replace county_nhgis = "Guilford" if regexm(bpl,"Gr[a-z]*nsb")

replace state = "North Carolina" if regexm(bpl,"[4|F][a-z]*[ ]O[a-z]*k")
replace bcity = "Four Oaks" if regexm(bpl,"[4|F][a-z]*[ ]O[a-z]*k")
replace county_nhgis = "Johnston" if regexm(bpl,"[4|F][a-z]*[ ]O[a-z]*k")

replace state = "North Carolina" if regexm(bpl,"T[a-z]b[a-z][a-z][ ]")
replace bcity = "Tabor City" if regexm(bpl,"T[a-z]b[a-z][a-z][ ]")
replace county_nhgis = "Columbus" if regexm(bpl,"T[a-z]b[a-z][a-z][ ]")

replace state = "North Carolina" if regexm(bpl,"N[a-z][a-z][ ]B[a-z]rn")
replace bcity = "New Bern" if regexm(bpl,"N[a-z][a-z][ ]B[a-z]rn")
replace county_nhgis = "Craven" if regexm(bpl,"N[a-z][a-z][ ]B[a-z]rn")

replace state = "North Carolina" if regexm(bpl,"71[ ]*[s|S]t")
replace bcity = "71st Township" if regexm(bpl,"71[ ]*[s|S]t")
replace county_nhgis = "Cumberland" if regexm(bpl,"71[ ]*[s|S]t")

replace state = "North Carolina" if regexm(bpl,"Alm[a-z]nd")
replace bcity = "Almond" if regexm(bpl,"Alm[a-z]nd")
replace county_nhgis = "Swain" if regexm(bpl,"Alm[a-z]nd")

replace state = "North Carolina" if regexm(bpl,"Neuse") & regexm(bpl,"Lenoir") == 0
replace bcity = "Neuse" if regexm(bpl,"Neuse") & regexm(bpl,"Lenoir") == 0
replace county_nhgis = "Wake" if regexm(bpl,"Neuse") & regexm(bpl,"Lenoir") == 0

replace state = "North Carolina" if regexm(bpl,"W[a-z]nst[a-z]n") & regexm(bpl,"[S|L][a-z]l[a-z][m|n]")
replace bcity = "Winston-Salem" if regexm(bpl,"W[a-z]nst[a-z]n") & regexm(bpl,"[S|L][a-z]l[a-z][m|n]")
replace county_nhgis = "Forsyth" if regexm(bpl,"W[a-z]nst[a-z]n") & regexm(bpl,"[S|L][a-z]l[a-z][m|n]")

replace state = "North Carolina" if regexm(bpl,"W S[a-z]*[l|m]") & regexm(bpl,"Pines") == 0
replace bcity = "Winston-Salem" if regexm(bpl,"W S[a-z]*[l|m]") & regexm(bpl,"Pines") == 0
replace county_nhgis = "Forsyth" if regexm(bpl,"W S[a-z]*[l|m]") & regexm(bpl,"Pines") == 0

replace state = "North Carolina" if regexm(bpl,"B[a-z][h|H][a-z]m[a-z]") | bpl == "??Homa"
replace bcity = "Bahamas" if regexm(bpl,"B[a-z][h|H][a-z]m[a-z]") | bpl == "??Homa"
replace county_nhgis = "Durham" if regexm(bpl,"B[a-z][h|H][a-z]m[a-z]") | bpl == "??Homa"

replace state = "North Carolina" if regexm(bpl,"Z[a-z]b") | regexm(bpl,"Z(a-z)*l(a-z)[n|m]")
replace bcity = "Zebulon" if regexm(bpl,"Z[a-z]b") | regexm(bpl,"Z(a-z)*l(a-z)[n|m]")
replace county_nhgis = "Wake" if regexm(bpl,"Z[a-z]b") | regexm(bpl,"Z(a-z)*l(a-z)[n|m]")

replace state = "North Carolina" if bpl == "Abashie, Herthell co, NC, NC"
replace bcity = "Ahoskie" if bpl == "Abashie, Herthell co, NC, NC"
replace county_nhgis = "Hertford" if bpl == "Abashie, Herthell co, NC, NC"

replace state = "North Carolina" if regexm(bpl,"^C[h|l]") & regexm(bpl,"Hi") 
replace bcity = "Chapel Hill" if regexm(bpl,"^C[h|l]") & regexm(bpl,"Hi") 
replace county_nhgis = "Orange" if regexm(bpl,"^C[h|l]") & regexm(bpl,"Hi") 

replace state = "North Carolina" if regexm(bpl,"Durham") 
replace bcity = "Durham" if regexm(bpl,"Durham")
replace county_nhgis = "Durham" if regexm(bpl,"Durham")

replace state = "North Carolina" if regexm(bpl,"Wake Forest") 
replace bcity = "Wake Forest" if regexm(bpl,"Wake Forest")
replace county_nhgis = "Wake" if regexm(bpl,"Wake Forest")

replace state = "North Carolina" if regexm(bpl,"Kann") 
replace bcity = "Kannapolis" if regexm(bpl,"Kann")
replace county_nhgis = "Cabarrus" if regexm(bpl,"Kann")

replace state = "North Carolina" if regexm(bpl,"Holly Spring") 
replace bcity = "Holly Springs" if regexm(bpl,"Holly Spring")
replace county_nhgis = "Wake" if regexm(bpl,"Holly Spring")

replace state = "North Carolina" if regexm(bpl,"Wilmington") 
replace bcity = "Wilmington" if regexm(bpl,"Wilmington")
replace county_nhgis = "New Hanover" if regexm(bpl,"Wilmington")

replace state = "North Carolina" if regexm(bpl,"Morrisville") 
replace bcity = "Morrisville" if regexm(bpl,"Morrisville")
replace county_nhgis = "Wake" if regexm(bpl,"Morrisville")

replace state = "North Carolina" if regexm(bpl,"Wilson") 
replace bcity = "Wilson" if regexm(bpl,"Wilson")
replace county_nhgis = "Wilson" if regexm(bpl,"Wilson")

replace state = "North Carolina" if regexm(bpl,"Rocky Mount") | regexm(bpl,"Rocky MT")
replace bcity = "Rocky Mount" if regexm(bpl,"Rocky Mount") | regexm(bpl,"Rocky MT")
replace county_nhgis = "Edgecombe" if regexm(bpl,"Rocky Mount") | regexm(bpl,"Rocky MT")