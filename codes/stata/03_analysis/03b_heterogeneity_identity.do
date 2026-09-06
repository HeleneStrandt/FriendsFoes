// aggregate to a panel 
collapse (sum) commits* n_*, by(country_o country_au month year)

// merge with region dummies (for fixed effects)
ren country_author country_code
do "$codes/data prep/help_country_codes"
renvars region, postfix("_author")
ren country_code country_author
tab country_author if region == "Control neutral"

ren country_owner country_code
do "$codes/data prep/help_country_codes"
renvars region, postfix("_owner")
ren country_code country_owner

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

sum commit*
gen commit_inten = commits_int/commits_ext
gen commit_user = n_authors
gen commit_inten_user = commits_int/n_authors
gen commit_project_user = commits_ext/n_authors

egen cc = group(country_author country_owner)

gen month_day = (mofd(date))
format month_day %tm //
xtset cc month_day 
tsfill, full

// merge with country-level activity for controls
// need to add controls for ua_west ,ua_east, ua_center later
/*
ren country_owner country_code
merge m:1 country_code month year using sum_bycountry
drop if _merge == 2
xtset cc month_day 
foreach x of varlist new_projects new_users stars {
replace `x' = 0 if mi(`x')
gen `x'3m = `x' + l.`x' + l2.`x'
}
ren country_code country_owner
drop _merge
*/

xtset cc month_day
foreach y of numlist -11/11 {
foreach x in country_owner country_author region_owner region_author {
bys cc: replace `x' = `x'[_n+`y'] if missing(`x')
bys cc: replace `x' = `x'[_n-`y'] if missing(`x')
}
}
foreach x of varlist commit* {
replace `x' = 0 if mi(`x')
}
gen yy = substr(string(month_day, "%tm"), 1, 4)
destring yy, replace
replace year = yy if mi(year)
drop yy
g yy = substr(string(month_day, "%tm"), 6, .)
destring yy, replace
replace month = yy if mi(month)
drop yy
replace date = date(string(year)+"-"+string(month)+"-"+"1", "YMD") if mi(date)

xtset cc month_day
sum month_day if strpos(string(month_day, "%tm"), "2014m2") 
global monthX = r(mean)

gen post = (month_day >=$monthX)

// UA-RU collaborations
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
gen antiru_user = (region_author == "Other affected")
gen antiru_project = (region_owner == "Other affected")

gen antiru_ru_post = antiru_user*ru_project*post
gen ru_antiru_post = antiru_project*ru_user*post

/*foreach x of varlist new_projects3m new_users3m stars3m commit* {
gen log_`x' = log(`x' + 1)
}
*/

*lab var ru_post "RU*Post"
/*
lab var ua_ru_post "UA-RU, Post"
lab var ru_ua_post "RU-UA, Post"

lab var west_east_post "WEST-EAST UA"
lab var east_west_post "EAST-WEST UA"
lab var east_ru_post "EAST UA-RU"
lab var west_ru_post "WEST UA-RU"
lab var ru_east_post "RU - EAST UA" 
lab var ru_west_post "RU - WEST UA"
*/

lab var ua_ru_post "UA-RU, No name"
lab var ru_ua_post "RU-UA, No name"

lab var west_east_post "WEST-EAST UA"
lab var east_west_post "EAST-WEST UA"
lab var east_ru_post "RU name -RU"
lab var west_ru_post "UA name-RU"
lab var ru_east_post "RU - RU name" 
lab var ru_west_post "RU - UA name"


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

encode region_author, gen(user_c)
encode region_owner, gen(owner_c) 

encode country_author, gen(user_cc)
encode country_owner, gen(owner_cc) 

set matsize 800 //10000
tab year

// ppml -- the same as poisson 
global controls = ""
*global controls = "log_new_projects log_new_users log_stars3m"
global fe = "c" // c - for region*time, cc - for country*time // results are very similar

foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2012,2018) 
drop if region_author == "Other affected"
drop if region_owner == "Other affected"
foreach y of varlist commits_int commit_user commit_project_user  commit_inten {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post ///
$controls , absorb(cc month_day##user_$fe month_day##owner_$fe) cluster(month_day)
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large) vert color(navy) ///
keep(ua_ru_post west_ru_post east_ru_post) ysize(2) xsize(4) legend(off)
graph save "`y'_ua_ru", replace
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large) vert color(navy) ///
keep(ru_ua_post ru_west_post ru_east_post) ysize(2) xsize(4) legend(off)
graph save "`y'_ru_ua", replace
test west_ru_post = east_ru_post
scalar test = r(p)
outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post /// 
west_ru_post ru_west_post east_ru_post ru_east_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), pval of WEST UA-RU = EAST UA-RU, test) nonotes label nocons
}
restore

