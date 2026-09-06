/// Merging locations

cd "$processed"

// import users with geo coordinates (prepared before in python, see extract.py)
import delimited "$raw\users_UA_geo.csv",  varnames(1) clear 
drop in 1
destring user_id, replace
destring lat, replace
destring lng, replace
export excel using "..\ukraine\users_UA_geo.xlsx", firstrow(variables) replace
//
/*
arcmap:
got shape files for ukraine regions/districts
chose geo coordinates WGS1984
lat == Y coord, lng == X coord (import feature as XY table)
right-click: spatial join
to export: spatial stat/utilities/export to ASCII
*/
//
import delimited "$raw\users_UA_coordin.csv",  delimiter(";")  varnames(1) clear 
ren id_1 code_geo
// see the codes for ukraine_regions in codes/ukraine_prep
merge m:1 code_geo using "ukraine_regions"
keep user_id district_en russians language_ru_T incumbent_ru_T
drop if mi(user_id)
duplicates drop
save "users_ua_geo", replace
