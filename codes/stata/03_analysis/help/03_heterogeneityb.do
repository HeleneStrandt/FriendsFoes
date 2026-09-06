// aggregate to a panel 
do "$codes/analysis/help/00_prep_analysis"


// UA-RU collaborations
cap drop ru_project ua_project ru_user ua_user ua_ru_post ru_ua_post

gen ru_project = (region_owner == "RU")
gen ua_project = (inlist(country_o, "ua_center"))
gen ru_user = (region_author == "RU")
gen ua_user = (inlist(country_a, "ua_center"))

gen ua_ru_post = ua_user*ru_project*post // baseline
gen ru_ua_post = ru_user*ua_project*post

// RU-UA collaborations
gen west_project = (region_owner == "UA_WEST")
gen east_project = (region_owner == "UA_EAST")

gen west_user = (region_author == "UA_WEST")
gen east_user = (region_author == "UA_EAST")

// UA-west east collaborations
gen east_west_post = east_user*west_project*post
gen west_east_post = west_user*east_project*post

gen east_ru_post = east_user*ru_project*post
gen ru_east_post = ru_user*east_project*post

gen west_ru_post = west_user*ru_project*post
gen ru_west_post = ru_user*west_project*post

// Other affected countries to RU (negative attitudes toward RU as well)
cap drop antiru_u antiru_project antiru_ru_post ru_antiru_post

gen antiru_user = (region_author == "Other affected")
gen antiru_project = (region_owner == "Other affected")

gen antiru_ru_post = antiru_user*ru_project*post
gen ru_antiru_post = antiru_project*ru_user*post

/*foreach x of varlist new_projects3m new_users3m stars3m commit* {
gen log_`x' = log(`x' + 1)
}
*/

*lab var ru_post "RU*Post"

if "$name" == "03_ppml_west_east" {
lab var ua_ru_post "Central UA-RU"
lab var ru_ua_post "RU- Central UA"

lab var west_east_post "WEST-EAST UA"
lab var east_west_post "EAST-WEST UA"
lab var east_ru_post "EAST UA-RU"
lab var west_ru_post "WEST UA-RU"
lab var ru_east_post "RU - EAST UA" 
lab var ru_west_post "RU - WEST UA"

}
else {
lab var ua_ru_post "UA-RU, No name"
lab var ru_ua_post "RU-UA, No name"

lab var west_east_post "WEST-EAST UA"
lab var east_west_post "EAST-WEST UA"
lab var east_ru_post "RU name -RU"
lab var west_ru_post "UA name-RU"
lab var ru_east_post "RU - RU name" 
lab var ru_west_post "RU - UA name"
}

*lab var ua_post "UA*Post"
lab var antiru_ru_post "Other affected - RU, Post"
lab var ru_antiru_post "RU - Other affected, Post"
/*
lab var log_new_projects "New projects, 3m"
lab var log_new_users "New users, 3m"
lab var log_stars "Stars, 3m" 
*/
lab var commits_ext "Commits, extensive"
lab var commit_inten "Contributions, per user-project"
lab var commits_int "Commits, total"
lab var commit_user "Unique, contributors"
lab var commit_inten_user "Contributions, per user"
lab var commit_project_user "Projects, per user"
lab var n_projects "Unique, projects"

set matsize 10000
tab year

// ppml -- the same as poisson 
global controls = "" //"log_new_projects log_new_users log_stars3m"
global fe = "c" // c - for region*time, cc - for country*time // results are very similar
global cluster "month_day cc"

foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2011,2018) 
*drop if region_author == "Other affected"
*drop if region_owner == "Other affected"
foreach y of varlist commits_int commit_user n_projects  {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post ///
$controls , absorb(cc month_day##user_$fe month_day##owner_$fe) cluster($cluster)
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(vlarge) vert color(navy) ///
keep(ua_ru_post west_ru_post east_ru_post) ysize(2) xsize(4) xlabel(,labsize(medlarge)) legend(off)
graph save "`y'_ua_ru", replace
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(vlarge) vert color(navy) ///
keep(ru_ua_post ru_west_post ru_east_post) xlabel(,labsize(medlarge)) ysize(2) xsize(4) legend(off)
graph save "`y'_ru_ua", replace
test west_ru_post = east_ru_post
scalar test = r(p)
outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), pval of WEST UA-RU = EAST UA-RU, test) nonotes label nocons
}


keep if commits_int > 0
foreach y of varlist commit_project_user  commit_inten {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post ///
$controls , absorb(cc month_day##user_$fe month_day##owner_$fe) cluster($cluster)
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(vlarge) xlabel(,labsize(medlarge)) vert color(navy) ///
keep(ua_ru_post west_ru_post east_ru_post) ysize(2) xsize(4) legend(off)
graph save "`y'_ua_ru", replace
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(vlarge) vert color(navy) ///
keep(ru_ua_post ru_west_post ru_east_post) xlabel(,labsize(medlarge)) ysize(2) xsize(4) legend(off)
graph save "`y'_ru_ua", replace
test west_ru_post = east_ru_post
scalar test = r(p)
outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), pval of WEST UA-RU = EAST UA-RU, test) nonotes label nocons
}

restore






