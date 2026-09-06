******** quarterly treatment effect regressions with hetoregeinty 
set scheme white_w3d, perm

clear
set more off
cd "$processed"

import delimited for_regressionq_ident.csv, varnames(1) encoding(UTF-8) clear

// keep ua and ru + control group as authors
tab country_author
gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if country_a == "`x'"
}
tab sample
keep if sample == 1

// if country is anonym
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}

// drop donetsk-luhansk-crimea
foreach x in author owner {
drop if dlk_`x' == 1 & country_`x' == "ua"
tab dlk_`x'
}

************************************
** share of Russians in Ukrainian region
global name = "03_ua_identity"
global name2 = "Low share of Russians"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & ru_identity_`x' !=0
tab ru_identity_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

global name = "03_ru_identity"
global name2 = "High share of Russians"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & ru_identity_`x' != 1
tab ru_identity_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_ua_identity" "UARU03_ru_identity", ysize(1) ///
 xsize(2) 
graph export "$output/figures/uaru_iden.pdf", replace

graph combine "RUUA03_ua_identity" "RUUA03_ru_identity", ysize(1) ///
 xsize(2) 
graph export "$output/figures/ruua_iden.pdf", replace

***************************************
** consider center (Kyiv and Ukraine unclassified), west and east ua as three separate countries
global name = "03_ppml_west_east"
preserve 
foreach x in author owner {
replace country_`x' = "ua_west" if ru_identity_`x' == 0
replace country_`x' = "ua_east" if ru_identity_`x' == 1
replace country_`x' = "ua_center" if ru_identity_`x' == 0.5
}
do "$codes/analysis/03b_heterogeneity_identity"
restore 

graph combine commits_int_ua_ru.gph commits_int_ru_ua.gph, rows(1) ///
ycommon xcommon ysize(3) xsize(7)
graph export "$output/tables/03_commits_int.pdf", replace

graph combine commit_user_ua_ru.gph commit_user_ru_ua.gph, rows(1) ///
ycommon xcommon ysize(3) xsize(7)
graph export "$output/tables/03_commit_user.pdf", replace


****************************************
** name identity
import delimited for_regressionq_ident_name.csv, varnames(1) encoding(UTF-8) clear

// keep ua and ru + control group as authors
tab country_author
gen sample = 0
foreach x in ua ru us de gb fr ca au nl pl jp cn se in br it by cz lt lv ee {
replace sample = 1 if country_a == "`x'"
}
tab sample
keep if sample == 1

// if country is anonym
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}

// drop donetsk-luhansk-crimea
foreach x in author owner {
drop if dlk_`x' == 1 & country_`x' == "ua"
tab dlk_`x'
}

// keep only central 
foreach x in author owner {
replace name_class_`x' = "Missing" if mi(name_class_`x')
replace name_class_`x' = "Missing" if country_`x' != "ua"
tab name_class_`x' if country_`x' == "ua"
}
/*
*/
// name matters: collaboration is lower if there is a name
// 'RU identity' in West Ukraine
global name = "03_west_name_cl"
preserve 
foreach x in author owner {
drop if ru_identity_`x' > 0.5 & country_`x' == "ua"
tab ru_identity_`x'
}

foreach x in author owner {
replace country_`x' = "ua_west" if name_class_`x' == "ua" & country_`x' == "ua"
replace country_`x' = "ua_east" if name_class_`x' == "ru" & country_`x' == "ua"
replace country_`x' = "ua_center" if name_class_`x' == "Missing" & country_`x' == "ua"
}
do "$codes/analysis/03b_heterogeneity_identity"
restore 

graph combine commits_int_ua_ru.gph commits_int_ru_ua.gph, rows(1) ///
ycommon xcommon ysize(3) xsize(7) title("West Ukraine and Kyiv") 
graph export "$output/tables/03_commits_int_name.pdf", replace


global name = "03_east_name_cl"
preserve 
foreach x in author owner {
drop if ru_identity_`x' < 1 & country_`x' == "ua"
tab ru_identity_`x'
}

foreach x in author owner {
replace country_`x' = "ua_west" if name_class_`x' == "ua" & country_`x' == "ua"
replace country_`x' = "ua_east" if name_class_`x' == "ru" & country_`x' == "ua"
replace country_`x' = "ua_center" if name_class_`x' == "Missing" & country_`x' == "ua"
}
do "$codes/analysis/03b_heterogeneity_identity"
restore 

global name = "03_west_east_nonames"
preserve 
foreach x in author owner {
drop if country_`x' == "ru" & inlist(name_class_`x', "ru", "ua")
drop if country_`x' == "ua" & inlist(name_class_`x', "ru", "ua")
}
foreach x in author owner {
replace country_`x' = "ua_west" if ru_identity_`x' == 0
replace country_`x' = "ua_east" if ru_identity_`x' == 1
replace country_`x' = "ua_center" if ru_identity_`x' == 0.5
}
do "$codes/analysis/03b_heterogeneity_identity"
restore 

// diaspora
/* drop ru and and ua as countries, count only if they are abroad */
import delimited for_regressionq_ident_name.csv, varnames(1) encoding(UTF-8) clear

// keep ua and ru + control group as authors
tab country_author
gen sample = 0
foreach x in ua ru us de gb fr ca au nl pl jp cn se in br it by cz lt lv ee {
replace sample = 1 if country_a == "`x'"
}
tab sample
keep if sample == 1

// if country is anonym
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}

// drop UA or RU users, keep only diaspora 
tab name_class_a if country_a != "ua" & name_class_a == "ua"
tab name_class_a if country_a != "ru" & name_class_a == "ru"
foreach x in author owner {
drop if inlist(country_`x', "ru", "ua")
}
tab name_class_a
tab name_class_o

foreach x in author owner {
replace country_`x' = "ru" if name_class_`x' == "ru"
replace country_`x' = "ua" if name_class_`x' == "ua"
}

global name = "03_diaspora"
global name2 = ""
global name_table "03_diaspora"
preserve
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_diaspora" "RUUA03_diaspora", ysize(1) ///
 xsize(2) 
graph export "$output/figures/uaru_diaspora.pdf", replace

****************************************

// movers vs stayers
use for_regression_move, replace
drop index
compress, nocoalesce

// keep ua and ru + control group as authors
tab country_author
gen sample = 0
foreach x in ua ru us de gb fr ca au nl pl jp cn se in br it by cz lt lv ee {
replace sample = 1 if country_a == "`x'"
}
tab sample
keep if sample == 1

// if country is anonym
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}

foreach x in author owner {
drop if country_`x' == "ua" & dlk_`x' ==1 
tab dlk_`x'
}
count


************************************
global name = "03_same_location"
global name2 = "Non-missing location 2013-16"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & nmloc_`x' == 0
tab nmloc_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 


global name = "03_stayers"
global name2 = "Stayers"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & stayers_`x' == 0
drop if country_`x' == "ru" & stayers_`x' == 0
tab nmloc_`x'
tab stayers_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_stayers" "RUUA03_stayers", ysize(1) ///
 xsize(2) ycommon xcommon
graph export "$output/figures/stayers.pdf", replace


global name = "03_movers"
global name2 = "Movers from UA"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & stayers_`x' == 1
*drop if country_`x' == "ru" & stayers_`x' == 1
tab nmloc_`x'
tab stayers_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_movers" "RUUA03_movers", ysize(2) ///
 xsize(3) ycommon xcommon
graph export "$output/figures/moversUA.pdf", replace


global name = "03_movers"
global name2 = "Movers from RU"
preserve
foreach x in author owner {
*drop if country_`x' == "ua" & stayers_`x' == 1
drop if country_`x' == "ru" & stayers_`x' == 1
tab nmloc_`x'
tab stayers_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_movers" "RUUA03_movers", ysize(2) ///
 xsize(3) ycommon xcommon
graph export "$output/figures/moversRU.pdf", replace



***************************
// Direct (forked ==0) vs. Indirect contributions

use for_regression_forked, replace
drop index
compress, nocoalesce

// keep ua and ru + control group as authors
tab country_author
gen sample = 0
foreach x in ua ru us de gb fr ca au nl pl jp cn se in br it by cz lt lv ee {
replace sample = 1 if country_a == "`x'"
}
tab sample
keep if sample == 1

// if country is anonym
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}

foreach x in author owner {
drop if country_`x' == "ua" & dlk_`x' ==1 
tab dlk_`x'
}
count


************************************
global name = "04_direct"
global name2 = "Direct contributions"
preserve
drop if forked == 1
tab forked
do "$codes/analysis/03a_heterogeneity_identity"
restore 
graph combine "UARU04_direct" "RUUA04_direct", ysize(1) ///
 xsize(2) ycommon xcommon
graph export "$output/figures/direct.pdf", replace


global name = "04_indirect"
global name2 = "Contributions via a fork"
preserve
foreach x in author owner {
drop if forked == 0
tab forked
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 
graph combine "UARU04_indirect" "RUUA04_indirect", ysize(1) ///
 xsize(2) ycommon xcommon
graph export "$output/figures/indirect.pdf", replace




global name = "03_movers"
global name2 = "Movers from UA"
preserve
foreach x in author owner {
drop if country_`x' == "ua" & stayers_`x' == 1
*drop if country_`x' == "ru" & stayers_`x' == 1
tab nmloc_`x'
tab stayers_`x'
}
do "$codes/analysis/03a_heterogeneity_identity"
restore 

graph combine "UARU03_movers" "RUUA03_movers", ysize(2) ///
 xsize(3) ycommon xcommon
graph export "$output/figures/moversUA.pdf", replace 





foreach hetero in ukrainian  {
cap drop parameter
gen parameter = `hetero'
global lab: var label `hetero'
preserve 
do "$codes/analysis/03a_heterogeneity_identity" 
restore
}

// try diff-in-diff within Ukraine
use for_regression, replace
tab district
foreach x in Krym Sevastopol Luhansk Donetsk  {
drop if strpos(district, "`x'") > 0
}
bys user_id month region_owner: gen n_users = 1 if _n == 1


foreach hetero in ukrainian {
cap drop parameter
gen parameter = `hetero'
global lab: var label `hetero'
preserve 
*drop if strpos(district, "Misto Kyiv")
do "$codes/analysis/heterogeneity_regress5" 
restore
}


use for_regression, replace
foreach x in Krym Sevastopol Luhansk Donetsk   {
drop if strpos(district, "`x'") > 0
}

count
bys user_id month region_owner: gen n_users = 1 if _n == 1

// check why pm does not work well!!
foreach hetero in direct  {
cap drop parameter
gen parameter = `hetero'
global lab: var label `hetero'
preserve 
do "$codes/analysis/heterogeneity_regress" 
restore
}

// 
use for_regression, replace
foreach x in Krym Sevastopol Luhansk Donetsk   {
drop if strpos(district, "`x'") > 0
}

foreach hetero in project_before user_before ru_before  {
cap drop parameter

gen parameter = `hetero'
global lab: var label `hetero'
preserve 
do "$codes/analysis/heterogeneity_regress2" 
restore
}



// try diff-in-diff within Ukraine, but with language identity measure

use for_regression, replace
tab district
foreach x in Krym Sevastopol Luhansk Donetsk  {
drop if strpos(district, "`x'") > 0
}
bys user_id month region_owner: gen n_users = 1 if _n == 1
merge m:1 user_id using user_identities16
drop if _merge == 2
drop _merge

cap drop UA_identity
gen UA_identity = (identity16 == "ua") if ///
user_region == "UA"
tab UA_ident
pwcorr UA_ident ukrainian2

foreach hetero in UA_identity {
cap drop parameter
gen parameter = `hetero'
global lab: var label `hetero'
preserve 
do "$codes/analysis/heterogeneity_regress6" 
restore
}


