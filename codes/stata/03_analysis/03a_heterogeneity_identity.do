// aggregate to a panel (because of Anonym countries)
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
gen ua_user = (region_author == "UA")
gen ua_ru_post = ua_user*ru_project*post

// RU-UA collaborations
gen ua_project = (region_owner == "UA")
gen ru_user = (region_author == "RU")
gen ru_ua_post = ru_user*ua_project*post

// Other affected countries to RU (negative attitudes toward RU as well)
gen antiru_user = (region_author == "Other affected")
gen antiru_project = (region_owner == "Other affected")

gen antiru_ru_post = antiru_user*ru_project*post
gen ru_antiru_post = antiru_project*ru_user*post

// joint ua_ru_post
gen joint_ua_ru_post = ua_ru_post + ru_ua_post

foreach x of varlist new_projects3m new_users3m stars3m commit* {
gen log_`x' = log(`x' + 1)
}

*lab var ru_post "RU*Post"
lab var ua_ru_post "UA-RU, Post"
lab var joint_ua_ru_post "UA-RU or RU-UA, Post"
*lab var ua_post "UA*Post"
lab var ru_ua_post "RU-UA, Post"
lab var antiru_ru_post "Other affected - RU, Post"
lab var ru_antiru_post "RU - Other affected, Post"
lab var log_new_projects "New projects, 3m"
lab var log_new_users "New users, 3m"
lab var log_stars "Stars, 3m" 
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
*global controls = ""
global controls = "log_new_projects log_new_users log_stars3m"
global fe = "c" // c - for region*time, cc - for country*time // results are very similar

foreach x in tex txt {
	capture erase "$output/tables/$name_table.`x'"
	}
preserve
keep if inrange(year, 2012,2018) 
drop if region_author == "Other affected"
drop if region_owner == "Other affected"
foreach y of varlist commits_int commit_user commit_project_user  commit_inten {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post /// 
$controls, absorb(cc month_day##user_$fe month_day##owner_$fe) cluster(month_day)
test ua_ru_post = ru_ua_post
scalar test = r(p)
outreg2 using "$output/tables/$name_table.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), pval of UA-RU = RU-UA, test) nonotes label nocons
}
restore

// the same but keep only international commits 
// ppml -- the same as poisson 
foreach x in tex txt {
	capture erase "$output/tables/intonly_$name_table.`x'"
	}
preserve
keep if inrange(year, 2012,2018) 
drop if region_author == "Other affected"
drop if region_owner == "Other affected"
drop if country_author == country_owner 
foreach y of varlist commits_int commit_user  commit_project_user  commit_inten  {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post  /// 
log_new_projects log_new_users log_stars3m, absorb(cc month_day##user_$fe month_day##owner_$fe) cluster(month_day)
test ua_ru_post = ru_ua_post
scalar test = r(p)
outreg2 using "$output/tables/intonly_$name_table.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), pval of UA-RU = RU-UA, test) nonotes label nocons
}
restore

// quarterly treatment effects, baseline 

do "$codes/analysis/help/centering_dl"

foreach x of varlist t_* pre_* post_* {
g ua_ru_`x' = ua_user*ru_project*`x'
g ru_ua_`x' = ru_user*ua_project*`x'
g joint_ua_ru_`x' = (ru_user*ua_project + ua_user*ru_project)*`x'
}

sum time
global min = abs(r(min))
global max = r(max)
foreach x of numlist 1/$min  {
label var ua_ru_pre_`x' "-`x'"
label var ru_ua_pre_`x' "-`x'"
label var joint_ua_ru_pre_`x' "-`x'"
}
foreach x of numlist 0/$max  {
label var ua_ru_post_`x' "+`x'"
label var ru_ua_post_`x' "+`x'"
label var joint_ua_ru_post_`x' "+`x'"
}

// treatment effect
preserve
keep if inrange(year, 2012,2018) 
drop if region_author == "Other affected"
drop if region_owner == "Other affected"
drop *_post_13 *_post_14 *_post_15 *_post_16 *_post_17 *_post_18 *_post_19 // replaced by t_after -- for brevety, but doesn't affect the results
*drop if country_author == country_owner 
foreach y of varlist  commit_inten { // commits_int commit_user  commit_project_user  commit_inten
local lab: var label `y'
ppmlhdfe `y' ua_ru_pre_* ua_ru_post_* ua_ru_t_after  /// 
             ru_ua_pre_* ru_ua_post_* ru_ua_t_after ///
$controls, absorb(cc month_day##user_$fe month_day##owner_$fe) cluster(month_day)

/*
coefplot,  omitted ylabel(, labcolor(white)) xline(0, lc(gs12)) color(cranberry) msize(large) ///
ciopts(recast(rcap) lwidth(0.7)) mlabel(@b) mlabsize(medsmall) ///
mlabgap(1.5) mlabposition(1) format("%9.3f") xlabel(,  format(%9.0f)) ///
keep(log_dist foreign_country foreign_comlang) title("Observations with contributions >0") 
*/

coefplot, omitted yline(0) xline(8, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large) vert color(navy) ///
keep(ua_ru_pre_8 ua_ru_pre_7  ua_ru_pre_6 ua_ru_pre_5 ua_ru_pre_4 ///
ua_ru_pre_3 ua_ru_pre_2 ua_ru_pre_1 ua_ru_post*) ///
title("UA to RU, $name2") ///
ytitle("UA*RU x with time dummies") xtitle("Quarters since Q1, 2014") xlab(,labs(vsmall))
graph save "UARU$name", replace

coefplot, omitted yline(0) xline(8, lwidth(0.5 ) lc(gs12)) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large)  vert color(cranberry) ///
keep(ru_ua_pre_8 ru_ua_pre_7 ru_ua_pre_6 ru_ua_pre_5 ru_ua_pre_4 ///
ru_ua_pre_3 ru_ua_pre_2 ru_ua_pre_1 ru_ua_post*) ///
 title("RU to UA, $name2") ///
ytitle("RU*UA x with time dummies") xtitle("Quarters since Q1, 2014") xlab(,labs(vsmall))
graph save "RUUA$name", replace
}
restore

