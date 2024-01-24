/* Clean birth and death place strings */

replace ${event_place} = "Arkansas" if ${event_place} == "On Boat On Miss River-Located Borders of States of Tenn-Miss-Ark, Ark"
replace ${event_place} = "North Carolina" if ${event_place} == "Dont Know Oxpeat He Was Born in The State, He"
replace ${event_place} = "Concord, Cabarrus, North Carolina" if ${event_place} == "Mac Starnes Father Concord N C Route #6 Is Given As Corressondent of Patient, N C"
replace ${event_place} = "At Sea" if ${event_place} == "Europes To America Born On Geo Atlantie Ovan, America"
replace ${event_place} = "" if ${event_place} == "The Family Moved Beford Any Famil Histrey Coutrlbe Obtainer" | ${event_place} == "Dont Know Was Lued As A Glam and Braryht To NC, NC"

replace ${event_place} = upper(${event_place})
replace ${event_place} = trim(${event_place})

replace ${event_place} = subinstr(${event_place},"."," ",.)
replace ${event_place} = subinstr(${event_place},"-"," ",.)
replace ${event_place} = subinstr(${event_place},";",",",.)
replace ${event_place} = subinstr(${event_place},"  "," ",.)
replace ${event_place} = subinstr(${event_place},"  "," ",.)
replace ${event_place} = trim(${event_place})
replace ${event_place} = subinstr(${event_place}," ,",",",.)

local symbol_list "? - ( ) ' & / # : * | $"
foreach symbol of local symbol_list {
	replace ${event_place} = subinstr(${event_place},"`symbol'","",.)
}
replace ${event_place} = subinstr(${event_place},"1ST","",.)
replace ${event_place} = subinstr(${event_place},"2ND","",.)
replace ${event_place} = subinstr(${event_place},"3RD","",.)
forvalues x = 4(1)9 {
	replace ${event_place} = subinstr(${event_place},"`x'TH","",.)
}
forvalues x = 0(1)9 {
	replace ${event_place} = subinstr(${event_place},"`x'","",.)
}

replace ${event_place} = trim(${event_place})
replace ${event_place} = subinstr(${event_place},"^,","",.)
replace ${event_place} = trim(${event_place})
replace ${event_place} = subinstr(${event_place},"  "," ",.)
replace ${event_place} = subinstr(${event_place},"  "," ",.)
replace ${event_place} = regexr(${event_place},"^NEAR ","")
replace ${event_place} = regexr(${event_place},"^,( )*","")
replace ${event_place} = trim(${event_place})

replace ${event_place} = "" if ${event_place} == "ST" | ${event_place} == "ND" | ${event_place} == "RD" | ${event_place} == "TH"
replace ${event_place} = regexr(${event_place},"^ST ","")
replace ${event_place} = regexr(${event_place},"^ND ","")
replace ${event_place} = regexr(${event_place},"^RD ","")
replace ${event_place} = regexr(${event_place},"^TH ","")
replace ${event_place} = trim(${event_place})

replace ${event_place} = regexr(${event_place}," DENMAK",", DENMARK")

replace ${event_place} = "" if ${event_place} == "UNITED STATES"
replace ${event_place} = regexr(${event_place},", UNITED STATES,",",")
replace ${event_place} = regexr(${event_place},", UNITED STATES,",",")
replace ${event_place} = regexr(${event_place},", UNITED STATES$","")
replace ${event_place} = regexr(${event_place},", UNITED STATES$","")
replace ${event_place} = regexr(${event_place},", US$","")
replace ${event_place} = regexr(${event_place},", USA$","")
replace ${event_place} = regexr(${event_place},", USA$","")
replace ${event_place} = regexr(${event_place},", USA,",",")
replace ${event_place} = regexr(${event_place},", USA,",",")
replace ${event_place} = regexr(${event_place},"^US ","")

replace ${event_place} = regexr(${event_place}," CARO(LI)*(N)*,"," CAROLINA,")
replace ${event_place} = regexr(${event_place}," CARO$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CARO(LINIA)* "," CAROLINA ")
replace ${event_place} = regexr(${event_place}," CAROLINA[S|R]$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIN(IA)*$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIA$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIMA$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROINA$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIN A$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIAN$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROHINA$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROL$"," CAROLINA")
replace ${event_place} = regexr(${event_place}," CAROLIN A$"," CAROLINA")

replace ${event_place} = regexr(${event_place},"NTH NEAR CARO","NORTH CARO")
replace ${event_place} = regexr(${event_place},"NORTH V CARO","NORTH CARO")
replace ${event_place} = regexr(${event_place},"NASH CAROLINA","NASH, NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"PITT CAROLINA","PITT, NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^ORTH CAR","NORTH CAR")
replace ${event_place} = regexr(${event_place},"^[N|R]OTH CAR","NORTH CAR")
replace ${event_place} = regexr(${event_place},"^MERTH CAR","NORTH CAR")
replace ${event_place} = regexr(${event_place},"^N RTH CAR","NORTH CAR")
replace ${event_place} = regexr(${event_place},"CAROLINAMOORE","CAROLINA, MOORE")
replace ${event_place} = regexr(${event_place},"^BO CAROLINA","NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^MARTH CARO","NORTH CARO")
replace ${event_place} = regexr(${event_place},"^MOTH CARO","NORTH CARO")
replace ${event_place} = regexr(${event_place},"[B|C|M|W|H]ORTH CARO","NORTH CARO")
replace ${event_place} = regexr(${event_place},", N CARBLINA",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^N(O|C)*(R)* CAR","NORTH CAR")
replace ${event_place} = regexr(${event_place},",[ ]*N[O]*(R)*(TH)*(,)* CAROLIN(A)*,",", NORTH CAROLINA,")
replace ${event_place} = regexr(${event_place},",[ ]*N[O]*(R)*(TH)*(,)* CAROLIN(A)*$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"(,)* CAROLINE$","")
replace ${event_place} = regexr(${event_place},"(,)* N[ ]*C$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*N[ ]*C$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place}," N[ ]*C "," NORTH CAROLINA ")
replace ${event_place} = regexr(${event_place}," N[ ]*C$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*[N][ ]CAR(O)*$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"[,]*[ ]*NORTH CAROLINA, NORTH CAROLINA",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"CAROLINA[ ][A-Z]$","CAROLINA")
replace ${event_place} = regexr(${event_place},"[^A-Z][ ]*NC, NORTH CAROLINA"," NORTH CAROLINA")
replace ${event_place} = trim(${event_place})
replace ${event_place} = regexr(${event_place},"^NC, NORTH CAROLINA","NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*N(O)* CAR,",", NORTH CAROLINA,")
replace ${event_place} = regexr(${event_place},",[ ]*N(O)* CAR$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place}," N(O)*(R)*(TH)* CAR(O)*$"," NORTH CAROLINA") if regexm(${event_place},"[A-Z][ ]N(O)*(RTH)* CAR(O)*$")
replace ${event_place} = regexr(${event_place}," N CAROLINA,"," NORTH CAROLINA,") if regexm(${event_place},"[A-Z][ ]N CAROLINA,")
replace ${event_place} = regexr(${event_place}," N CAR ",", NORTH CAROLINA, ")
replace ${event_place} = regexr(${event_place},"NORTH, CAROLINA","NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"NORTH CAROLINE","NORTH CAROLINA")
replace ${event_place} = regexr(${event_place}," NORTH CAROLINA",", NORTH CAROLINA") if regexm(${event_place},"[A-Z][ ]NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^N[A-Z]*[ ]CARO[A-Z]*$","NORTH CAROLINA") if regexm(${event_place},"NASH") == 0
replace ${event_place} = regexr(${event_place},"^N[A-Z]*[ ]CARO[A-Z]*,","NORTH CAROLINA,") if regexm(${event_place},"NASH") == 0
replace ${event_place} = regexr(${event_place},",N[A-Z]*[ ]CARO[A-Z]*$",",NORTH CAROLINA") if regexm(${event_place},"NASH") == 0

replace ${event_place} = regexr(${event_place},"SOU, CARO","SOUTH CARO")
replace ${event_place} = regexr(${event_place},"SUOTH CARO","SOUTH CARO")
replace ${event_place} = regexr(${event_place},"^OUTH CARO","SOUTH CARO")
replace ${event_place} = regexr(${event_place},"SOUTHBCAROLINA","SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^S[O|C]* CAR","SOUTH CAR")
replace ${event_place} = regexr(${event_place},"[B|C|M|W]OUTH CARO","SOUTH CARO")
replace ${event_place} = regexr(${event_place},",[ ]*S[O]*(UTH)* CAROLIN(A)*,",", SOUTH CAROLINA,")
replace ${event_place} = regexr(${event_place},",[ ]*S[O]*(UTH)* CAROLIN(A)*$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"(,)* S[ ]*C$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*S[ ]*C$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place}," S[ ]*C "," SOUTH CAROLINA ")
replace ${event_place} = regexr(${event_place}," S[ ]*C$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*[S][ ]CAR(O)*$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"[,]*[ ]*SOUTH CAROLINA, SOUTH CAROLINA",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"[^A-Z][ ]*SC, SOUTH CAROLINA"," SOUTH CAROLINA")
replace ${event_place} = trim(${event_place})
replace ${event_place} = regexr(${event_place},"^SC, SOUTH CAROLINA","SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},",[ ]*S(O)* CAR,",", SOUTH CAROLINA,")
replace ${event_place} = regexr(${event_place},",[ ]*S(O)* CAR$",", SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place}," S(O)* CAR$"," SOUTH CAROLINA") if regexm(${event_place},"[A-Z][ ]S(O)* CAR$")
replace ${event_place} = regexr(${event_place}," S CAROLINA,"," SOUTH CAROLINA,") if regexm(${event_place},"[A-Z][ ]S CAROLINA,")
replace ${event_place} = regexr(${event_place}," S CAR ",", SOUTH CAROLINA, ")
replace ${event_place} = regexr(${event_place},"SOUTH, CAROLINA","SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"SOUTH CAROLINE","SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^S[A-Z]*[ ]CARO[A-Z]*$","SOUTH CAROLINA")
replace ${event_place} = regexr(${event_place},"^S[A-Z]*[ ]CARO[A-Z]*,","SOUTH CAROLINA,")
replace ${event_place} = regexr(${event_place},",S[A-Z]*[ ]CARO[A-Z]*$",",SOUTH CAROLINA")

replace ${event_place} = regexr(${event_place}," NO CARO"," NORTH CARO")
replace ${event_place} = regexr(${event_place}," SO CARO"," SOUTH CARO")

replace ${event_place} = regexr(${event_place},"CAROLINA","CAROLINA,") if regexm(${event_place},"CAROLINA[ ][A-Z]")
replace ${event_place} = regexr(${event_place},"[ ]NORTH CAROLINA",", NORTH CAROLINA") if regexm(${event_place},"[A-Z][ ]NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},"[ ]SOUTH CAROLINA",", SOUTH CAROLINA") if regexm(${event_place},"[A-Z][ ]SOUTH CAROLINA")

replace ${event_place} = regexr(${event_place},", ALA$",", ALABAMA")
replace ${event_place} = regexr(${event_place},", ARK$",", ARKANSAS")
replace ${event_place} = regexr(${event_place},", CALIF$",", CALIFORNIA")
replace ${event_place} = regexr(${event_place},", DELEWARE$",", DELAWARE")
replace ${event_place} = regexr(${event_place},", FLA$",", FLORIDA")
replace ${event_place} = regexr(${event_place},", NENTUCKY$",", KENTUCKY")
replace ${event_place} = regexr(${event_place},", MISS$",", MISSISSIPPI")
replace ${event_place} = regexr(${event_place},", NO CARO[L]*INA$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},", BC$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},", CN$",", NORTH CAROLINA")
replace ${event_place} = regexr(${event_place},", PENN$",", PENNSYLVANIA")
replace ${event_place} = regexr(${event_place},", TENN$",", TENNESSEE")
replace ${event_place} = regexr(${event_place},", TEX$",", TEXAS")
replace ${event_place} = regexr(${event_place},", WVA$",", WEST VIRGINIA")
replace ${event_place} = regexr(${event_place},"^BC ","")

replace ${event_place} = "NORTH DAKOTA" if ${event_place} == "DAKOTA TERRITORY"
replace ${event_place} = "NORTH CAROLINA" if ${event_place} == "NO CAROINA" | ${event_place} == "NORTH,CAR"
replace ${event_place} = "MISSISSIPPI" if ${event_place} == "MISSIS" | ${event_place} == "MISSIPPIS"

replace ${event_place} = trim(${event_place})
replace ${event_place} = regexr(${event_place},",$","")

replace ${event_place} = regexr(${event_place},"^T(O)*W(N)*(S)*(H)*(I)*P[ ]","")
replace ${event_place} = regexr(${event_place},"[ ]T(O)*W(N)*(S)*(H)*(I)*P$","")
replace ${event_place} = regexr(${event_place},"[ ]T(O)*W(N)*(S)*(H)*(I)*P[ ]"," ")
replace ${event_place} = regexr(${event_place}," T[P|S]$","")
replace ${event_place} = regexr(${event_place}," TWPH$","")
replace ${event_place} = regexr(${event_place}," TWONSHIP$","")
replace ${event_place} = regexr(${event_place}," TOWN$","")
replace ${event_place} = regexr(${event_place},"TOWNSHIP$","")
replace ${event_place} = regexr(${event_place},"^TOWN ","")
replace ${event_place} = regexr(${event_place}," RFD$","")

replace ${event_place} = subinstr(${event_place},"  "," ",.)
replace ${event_place} = subinstr(${event_place},"  "," ",.)

replace ${event_place} = "ALAMANCE" if ${event_place} == "OLD CHATHAM CO NEAR PLEASANT HILL WHICH IS NOW ALAMANCE CO"
replace ${event_place} = "HARRIS, FRANKLIN" if ${event_place} == "AT HOME FRANKLIN HARRIS T S HARE OF DEATH"
replace ${event_place} = "" if ${event_place} == "NOT KNOWN HERE HE LOUCE HERE FROM ONE OTHER COUNTY AND NO ONE HERE SUMS TO KNOW ANY THING ABOUT LIME, HE"
replace ${event_place} = "" if ${event_place} == "THE FAMILY MOVED BEFORE ANY FAMIL HISTORY COULD BE OBTAINED"
replace ${event_place} = "" if ${event_place} == "HAS BEEN AT HOME YEARS DONT KNOW WHEN HAS BIRTHPLACE"
replace ${event_place} = "" if ${event_place} == "ON BOAT ON MISS RIVERLOCATED BORDERS OF STATES OF TENNMISSARK, ARK"

replace ${event_place} = regexr(${event_place}," FROM "," ")
replace ${event_place} = regexr(${event_place},"^MI(LE)*[S|D]*( )*NORTH ","")
replace ${event_place} = regexr(${event_place},"^MI(LE)*[S|D]*( )*WEST ","")
replace ${event_place} = regexr(${event_place},"^MI(LE)*[S|D]*( )*SOUTH ","")
replace ${event_place} = regexr(${event_place},"^MI(LE)*[S|D]*( )*EAST ","")
replace ${event_place} = regexr(${event_place},"^MI(LES)* SW ","")
replace ${event_place} = regexr(${event_place},"^[A-Z][ ]","")
replace ${event_place} = regexr(${event_place},"^OF[ ]","")
replace ${event_place} = regexr(${event_place},"STILL BORN","")
replace ${event_place} = regexr(${event_place},"CO CO","CO")

replace ${event_place} = "" if length(${event_place}) <= 2
replace ${event_place} = trim(${event_place})

replace ${event_place} = regexr(${event_place},"[ ]CO$","") 
replace ${event_place} = regexr(${event_place},"[ ]CO$","") 
replace ${event_place} = regexr(${event_place},"[ ]CO,",",")
replace ${event_place} = regexr(${event_place},"[ ]COUNTY$","") 
replace ${event_place} = regexr(${event_place},"[ ]COUNTY,",",")
replace ${event_place} = regexr(${event_place},"[ ]CO[ ]"," ")
replace ${event_place} = trim(${event_place})

replace ${event_place} = regexr(${event_place},"^NEAR ","")
replace ${event_place} = regexr(${event_place},"^NEAR ","")

replace ${event_place} = "" if ${event_place} == "NORTH CAROLINA" | ${event_place} == "NOT AVAILABLE" | ${event_place} == "CAROLINA" | ${event_place} == "COUNTY"
replace ${event_place} = regexr(${event_place},"^MILER WEST ","")
replace ${event_place} = regexr(${event_place},"^MILAS WESHOF ","")
replace ${event_place} = regexr(${event_place},"^MALES ","")
replace ${event_place} = regexr(${event_place},"^MILES ","")
replace ${event_place} = regexr(${event_place},"^MAR ","")
replace ${event_place} = regexr(${event_place},"^ORA ","")
replace ${event_place} = regexr(${event_place},"^CITY ","")
replace ${event_place} = regexr(${event_place}," CITY$","")
replace ${event_place} = regexr(${event_place},"^TOWENSHIP ","")
replace ${event_place} = regexr(${event_place},"^EAR ","")
replace ${event_place} = regexr(${event_place},"^ROUT[E]* ","")
replace ${event_place} = regexr(${event_place},"^RT ","")
replace ${event_place} = regexr(${event_place},"^IN ","")
replace ${event_place} = regexr(${event_place},"^,","")
replace ${event_place} = regexr(${event_place},"^,","")
replace ${event_place} = regexr(${event_place},",,",",")
replace ${event_place} = regexr(${event_place},",,",",")
replace ${event_place} = regexr(${event_place},",$","")
replace ${event_place} = trim(${event_place})

replace ${event_place} = "" if ${event_place} == "ROUTE" | ${event_place} == "ROUT" | regexm(${event_place},"^NOT ") | regexm(${event_place},"^NO [I|K|N|OR|U][A-Z]+$") | regexm(${event_place},"^UNOB")
replace ${event_place} = regexr(${event_place},"^M[T|A][ ]","MOUNT ")
replace ${event_place} = regexr(${event_place},"CAROLINA, BEACH","CAROLINA BEACH")

replace ${event_place} = regexr(${event_place},", NORTH CAROLINA$","")
