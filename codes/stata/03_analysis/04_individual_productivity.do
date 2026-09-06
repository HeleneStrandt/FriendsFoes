// individual level regressions1
*ssc install cem
*ssc install distinct
set scheme white_w3d, perm

clear
set more off
cd "$processed"

*global output = "$path\draft\draft\output_progrs"
*global codes "$path\codes\codes\stata"
*global raw = "$path\database\extractions"
*cd "$path/database\stata_tmp"

// indirectly treated
foreach x in ua ru ua_nf ru_nf {
preserve
import delimited indirect_treated_`x'.csv, varnames(1) encoding(UTF-8) clear 
duplicates drop
ren id user_id
gen indirect_of = "`x'"
save "indirect_treated_`x'", replace
restore
}

**********************************
** 1) CEM 
import delimited for_regressionq_ind_effects_all.csv, varnames(1) encoding(UTF-8) clear 

// keep only control countries 
gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(cc2013, "`x'") 
}
tab sample
keep if sample == 1

// Strongly balanced panel
duplicates drop
xtset user_id year 

bys user_id: egen dlk_ever  = max(dlk) 
tab dlk_e
drop if dlk_e == 1

// fill missing with zeros
sum commits_pre - n_countries_o
foreach x of varlist commits_pre - n_countries_o {
replace `x' = 0 if mi(`x')
}
keep if year == 2013
// among them keep only those users who contributed to either RU or UA before 2014
keep if inlist(cc, "ua", "ru") | commits_toru_pre +  contributions_fromru_pre + commits_toua_pre +  contributions_fromua_pre > 0


foreach x in ua ru ua_nf ru_nf {
merge 1:1 user_id using indirect_treated_`x'
drop if _merge == 2
cap gen in_treat_by`x' = (_merge == 3)
drop _merge
}

count if in_treat_byua*in_treat_byru == 1
count if in_treat_byua+in_treat_byru > 0

// experience 
gen experi = (date("2013-12-31", "YMD")- ///
date(string(year_created)+"-"+string(month_created)+"-"+"1", "YMD"))/365

// treatment definition = user from ua/ru and cooperated with ru/ua before 2014
// do not include those treated indirectly
count if cc == "ua" & (commits_toru_pre + contributions_fromru_pre > 0) // 455
count if cc == "ru" & (commits_toua_pre + contributions_fromua_pre > 0) // 556

gen ua_treat = (cc == "ua" & (commits_toru_pre + contributions_fromru_pre > 0)) if cc!= "ru"
gen commits_toru_pre_sh = max(commits_toru_pre/commits_pre, 0) if cc!= "ru"
gen ru_treat = (cc == "ru" & (commits_toua_pre + contributions_fromua_pre > 0)) if cc!= "ua"
gen commits_toua_pre_sh = max(commits_toua_pre/commits_pre, 0) if cc!= "ua"

// for those who are treated both directly and indirectly, set indirect treatment to zero
foreach x in ua ru {
replace in_treat_by`x' = 0 if ua_treat == 1 | ru_treat == 1
replace in_treat_by`x'_nf = 0 if ua_treat == 1 | ru_treat == 1
}

foreach x in ua ru {
replace `x'_treat = . if in_treat_byua+in_treat_byru > 0
}

sum *treat* if cc == "ua"
sum *treat* if cc == "ru"

gen commits_self_sh = max(commits_toself/commits_sent, 0)
gen commits_home_sh = max((commits_tohome-commits_toself)/commits_sent, 0)
gen commits_home_pre_sh = max((commits_tohome_pre)/commits_pre, 0) // pre includes only commits to others

// summary of ua/ru users and other users before matching
global chars = "year_created commits_pre commits_home_pre_sh commits_stars owners_pre n_countries_c projects_pre contributions_pre  user_stars_cum user_follow_cum"
lab var year_created "Entry year on GitHub"
lab var commits_pre "Commits sent"
lab var commits_home_pre_sh "Share of commits sent to home"
lab var commits_stars "Commits sent weighted by project quality"
lab var owners_pre "Project owners collaborated with"
lab var n_countries_c "Countries collaborated with" // Countries of sent commits
lab var projects_pre "Projects owned"
lab var contributions_pre "Contributions received"
lab var user_stars_cum "User stars"
lab var user_follow_cum "User followers"

// balance table 
global lab "Unmatched"
foreach y in ua ru {
preserve 
keep if !mi(`y'_treat)

gen cem_matched = 1
gen cem_weights = 1

global name balance_`y'
foreach x in tex txt {
capture erase "$output/tables/$name.`x'
}

global var `y'_treat
global weight "" // "[iweight=cem_weights]"
global tosum1 $chars 
do "$codes/analysis/help/balance" // produces balance tables, but ado files necessary
//
restore
}


// match on pre-2014 characteristics 
cap drop cem_*
foreach x in ua ru {
preserve
keep if !mi(`x'_treat)
global mchars = "experi n_countries_c owners_pre commits_pre commits_stars commits_home_pre_sh projects_pre contributions_pre user_stars_cum user_follow_cum"
cem $mchars, treatment(`x'_treat) showbreaks k2k
renvars cem_strata cem_matched cem_weights, postfix("_`x'") 
keep user_id cem*
save "cem1_`x'", replace
restore 
}

foreach x in ua ru {
merge 1:1 user_id using cem1_`x'
drop _merge
}

// balance table matched
global lab "Matched"
foreach y in ua ru {
preserve 
keep if !mi(`y'_treat)

gen cem_matched = cem_matched_`y'
gen cem_weights = cem_weights_`y'

global name balance_`y'
global var `y'_treat
global weight "" //"[iweight=cem_weights]"
global tosum1 $chars 
do "$codes/analysis/help/balance"
restore
}
//


**********************************
** 2) diff-in-diff
import delimited for_regressionq_ind_effects_all.csv, varnames(1) encoding(UTF-8) clear 

// keep only control countries 
gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(cc2013, "`x'") 
}
tab sample
keep if sample == 1

// Strongly balanced panel
duplicates drop
xtset user_id year 

bys user_id: egen dlk_ever  = max(dlk) 
tab dlk_e
drop if dlk_e == 1

// fill missing with zeros
sum commits_pre - n_countries_o
foreach x of varlist commits_pre - n_countries_o {
replace `x' = 0 if mi(`x')
}


foreach x in ua ru {
merge m:1 user_id using cem1_`x'
drop _merge
}


/*
foreach x in ua ru ua_nf ru_nf {
merge 1:1 user_id using indirect_treated_`x'
drop if _merge == 2
cap gen in_treat_by`x' = (_merge == 3)
drop _merge
}
count if in_treat_byua*in_treat_byru == 1

*/

// experience 
gen experi = (date("2013-12-31", "YMD")- ///
date(string(year_created)+"-"+string(month_created)+"-"+"1", "YMD"))/365
*hist experi

// treatment definition = cooperated with Ukrainians/Russians before 2014
gen ua_treat = (cc == "ua" & (commits_toru_pre + contributions_fromru_pre > 0)) if cc!= "ru"
gen share_with_ru_pre = max((commits_toru_pre + contributions_fromru_pre)/(commits_pre+contributions_pre), 0)
gen ru_treat = (cc == "ru" & (commits_toua_pre + contributions_fromua_pre > 0)) if cc!= "ua"
gen share_with_ua_pre = max((commits_toua_pre + contributions_fromua_pre)/(commits_pre+contributions_pre), 0)

/*
// for those who are treated both directly and indirectly, set indirect treatment to zero
foreach x in ua ru {
replace in_treat_by`x' = 0 if ua_treat == 1 | ru_treat == 1
replace in_treat_by`x'_nf = 0 if ua_treat == 1 | ru_treat == 1
}
*/

sum *treat* if cc == "ua"
sum *treat* if cc == "ru"

gen commits_self_sh = max(commits_toself/commits_sent, 0)
gen commits_home_sh = max((commits_tohome-commits_toself)/commits_sent, 0)
gen commits_home_pre_sh = max((commits_tohome_pre)/commits_pre, 0) // pre includes only commits to others

sum commits_self_sh commits_sent
sum commits_self_sh if commits_sent == 0

gen post = (year > 2013)
tab year if post

gen west_ua = (ru_identity == 0)
gen east_ua = (ru_identity == 1)
gen kiev_central = (ru_identity == 0.5)

foreach x in west_ua kiev_central {
gen post_`x' = post*`x'
gen post_ua_treat_`x' = post*ua_treat*`x'
}

tab cc if cem_matched_ua == 1 & ua_treat == 0
tab cc if cem_matched_ru == 1 & ru_treat == 0

foreach x in ua ru {
gen `x' = (cc == "`x'")
}

foreach x in ua ru {
gen worked_with`x' = (commits_to`x'_pre + contributions_from`x'_pre > 0)
}

cap drop post_*
foreach x of varlist ua_treat* ru_treat* ua ru  {
gen post_`x' = post * `x'
}

gen post_worked_forua = post*worked_withru
gen post_worked_forru = post*worked_withua

gen post_share_ua_treat = post_ua_treat*share_with_ru 
gen post_share_ru_treat = post_ru_treat*share_with_ua

gen post_share_ua_treat_d = (post_ua_treat*share_with_ru > 0.1)
gen post_share_ru_treat_d = (post_ru_treat*share_with_ua > 0.1)

//egen country = group(cc2013_user)
//encode country, gen(cc_for_FE)

global outcomes = "commits_sent commits_stars n_owners n_projects commits_received n_contributors stars_own_projects"

lab var post_share_ru_treat "Post $\times$ Treat $\times Share UA"
lab var post_share_ua_treat "Post $\times$ Treat $\times Share RU"
lab var post_share_ru_treat_d "Post $\times$ Treat $\times Share UA"
lab var post_share_ua_treat_d "Post $\times$ Treat $\times Share RU"

lab var post_ua "Post $\times$ UA"
lab var post_ru "Post $\times$ RU"
lab var post_ua_treat "Post $\times$ Treat"
lab var post_ru_treat "Post $\times$ Treat"
lab var commits_sent "Commits sent"
lab var commits_stars "Commits sent, quality weighted"
lab var n_owners "Owners"
lab var n_projects "Projects"
lab var stars_own_projects "Stars"
lab var commits_received "Commits received"
lab var n_contributors "Contributors"

// define additional controls
foreach x of varlist commits_pre owners_pre projects_pre contributions_pre user_stars_cum {
cap gen log_`x' = log(`x'+1)
gen c`x' = log_`x'*(year-2010)
}

// regressions
set more off
global fe "year user_id"  //  year_created
global controls = "ccommits_pre cowners_pre cprojects_pre cuser_stars_cum" // "commits_pre owners_pre projects_pre contributors_pre user_stars_cum"
/*
foreach cc in ua ru {
foreach x in tex txt {
	capture erase "$output/tables/05_effects_`cc'.`x'"
	}

preserve
keep if cem_matched_`cc' == 1 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' post_`cc'_treat /// // post_share_`cc'_treat_d post_`cc'_treat_west post_`cc'_treat_kiev post_west post_kiev ///
 $controls, absorb($fe) cluster(cem_strata_`cc') nocons

bys user_id: egen maxy = max(`y')
distinct user_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

sum `y' if year < 2014 & `cc'_treat == 1
scalar y_mean = r(mean)
sum `y' if year < 2014 & `cc'_treat == 0
scalar y_mean2 = r(mean)

outreg2 using "$output/tables/05_effects_`cc'.tex", append  tex(frag) ///
keep(post_`cc'_treat)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), Unique users, n, Mean outcome treated, y_mean, Mean outcome control, y_mean2) nonotes label nocons
}
restore
}
*/

// define strata categories for clustering standard errors
cap drop cem_strata_forclustering max_cem_strata_ua
gen cem_strata_forclustering = cem_strata_ua
egen max_cem_strata_ua = max(cem_strata_ua)
replace cem_strata_forclustering = cem_strata_ru + max_cem_strata_ua + 1 if !mi(cem_strata_ru)
sum cem_strata_ua cem_strata_ru cem_strata_forclustering
tab cem_strata_forclustering


*** ua and ru treated individuals and their matched controls in one reg
set more off
global fe "year user_id"  //  country#post
global controls = "ccommits_pre cowners_pre cprojects_pre cuser_stars_cum" // "commits_pre owners_pre projects_pre contributors_pre user_stars_cum"
global cluster "user_id" // cem_strata_forclustering
preserve
set more off
foreach x in tex txt {
	capture erase "$output/tables/05_effects_individual_uaru_joint.`x'"
	}
cap drop post_* 

foreach x of varlist ru_treat ua_treat {
replace `x' = 0 if mi(`x')
}

foreach x of varlist ua_treat* ru_treat* ua ru  {
gen post_`x' = post * `x'
}

keep if cem_matched_ua == 1 | cem_matched_ru == 1

gen treat = ua_treat + ru_treat
gen treat_post = treat * post
lab var treat_post "Post $\times$ Treat"
lab var post_ua_treat "Post $\times$ Treat $\times$ UA"
lab var post_ua "Post $\times$ UA"

replace post_ru_treat = 0 if mi(post_ru_treat)
replace post_ua_treat = 0 if mi(post_ua_treat)

tab post_ru_treat treat_post
tab post_ua_treat treat_post

foreach y of varlist $outcomes {
local lab: var label `y' 
ppmlhdfe `y' treat_post post_ua_treat post_ua $controls, absorb($fe) cluster($cluster)
// post_ua

bys user_id: egen maxy = max(`y')
distinct user_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

sum `y' if year < 2014 & treat == 1
scalar y_mean = r(mean)
sum `y' if year < 2014 & treat == 0
scalar y_mean2 = r(mean)

outreg2 using "$output/tables/05_effects_individual_uaru_joint.tex", append  tex(frag) ///
keep(treat_post post_ua_treat post_ua)  ctitle("`lab'") alpha(0.001, 0.01, 0.05) ///
addstat(Pseudo R2, e(r2_p), Unique users, n, Mean\ Y^{T}, y_mean, Mean\ Y^{C}, y_mean2) nonotes label nocons
}
restore


x
/*
// add initial control for productivity, but in the continuous way does not really mitigate
foreach x in ua ru {
gen post_`x'_treat_stars = log_user_stars_cum*post_`x'_treat
lab var post_`x'_treat_stars "Post $\times$ Treat $\times$ stars"
}

global cluster user_id

foreach cc in ua ru {
foreach x in tex txt {
	capture erase "$output/tables/05_effects_`cc'p.`x'"
	}
preserve
keep if cem_matched_`cc' == 1 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' post_`cc'_treat  post_`cc'_treat_stars  /// // post_share_`cc'_treat_d post_`cc'_treat_west post_`cc'_treat_kiev post_west post_kiev ///
 $controls, absorb($fe) cluster($cluster) nocons

bys user_id: egen maxy = max(`y')
distinct user_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

sum `y' if year < 2014 & `cc'_treat == 1
scalar y_mean = r(mean)
sum `y' if year < 2014 & `cc'_treat == 0
scalar y_mean2 = r(mean)

outreg2 using "$output/tables/05_effects_`cc'p.tex", append  tex(frag) ///
keep(post_`cc'_treat post_`cc'_treat_stars)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), Unique users, n, Mean outcome treated, y_mean, Mean outcome control, y_mean2) nonotes label nocons
}
restore
}
*/

// event study
set more off
cap drop post_* 
cap drop pre_*
cap drop time
cap drop t_*
cap drop ua_treat_pre*
cap drop ru_treat_pre*
cap drop ua_treat_post*
cap drop ru_treat_post*
do "$codes/analysis/help/centering_y"

foreach x of varlist  pre_* post_* {
g ua_treat_`x' = ua_treat*`x'
g ru_treat_`x' = ru_treat*`x'
}

sum time
global min = abs(r(min))
global max = r(max)
foreach x of numlist 1/$min  {
label var ua_treat_pre_`x' "-`x'"
label var ru_treat_pre_`x' "-`x'"
}
foreach x of numlist 0/$max  {
label var ua_treat_post_`x' "+`x'"
label var ru_treat_post_`x' "+`x'"
}

// fe, controls, clusters are the same
global fe "year user_id"  // user_id year_created
global controls = "ccommits_pre cowners_pre cprojects_pre cuser_stars_cum" //"commits_pre owners_pre projects_pre contributors_pre user_stars_cum"

foreach cc in ua ru {
preserve
keep if cem_matched_`cc' == 1 
foreach y of varlist $outcomes { 
local lab: var label `y'
ppmlhdfe `y' `cc'_treat_pre_* `cc'_treat_post_*  ///
$controls, absorb($fe) cluster(cem_strata_`cc')

coefplot, omitted yline(0) xline(3, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue)) msize(large) msymbol(o) mcolor(ebblue*1.5) vert ///
keep(`cc'_treat_pre* `cc'_treat_post*) ///
title("`lab'") ///
ytitle("Treat x with time dummies") xtitle("Years since 2013") xlab(,labs(vsmall))
graph save "`y'_`cc'", replace
}
restore
}

graph combine "commits_sent_ru.gph" "commits_stars_ru.gph"  "n_projects_ru.gph" "commits_received_ru.gph", ///
 rows(2) ycommon ysize(2) xsize(3) title("A: Users in Russia")
graph export "$output/figures/RU-user-effect.pdf", replace

graph combine "commits_sent_ua.gph" "commits_stars_ua.gph"  "n_projects_ua.gph" "commits_received_ua.gph", ///
 rows(2) ycommon ysize(2) xsize(3) title("B: Users in Ukraine")
graph export "$output/figures/UA-user-effect.pdf", replace



/// robustness check if the results hold without matching 
// works, but needs time to run due to many observations 
/*
foreach x in ua ru {
merge m:1 user_id using indirect_treated_`x'
drop if _merge == 2
cap gen in_treat_by`x' = (_merge == 3)
drop _merge
}

foreach x in ua ru {
replace in_treat_by`x' = 0 if ua_treat == 1 | ru_treat == 1
}

foreach x in ua ru {
replace `x'_treat = . if in_treat_byua+in_treat_byru > 0
}

global fe "year user_id year_created"  // user_id
global cluster = "user_id"
global controls = "ccommits_pre cowners_pre cprojects_pre cuser_stars_cum" // "commits_pre owners_pre projects_pre contributors_pre user_stars_cum"

foreach cc in ua ru {
foreach x in tex txt {
	capture erase "$output/tables/05_effects_`cc'_nm.`x'"
	}
preserve
keep if !mi(`cc'_treat) 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' post_`cc'_treat /// // post_share_`cc'_treat_d post_`cc'_treat_west post_`cc'_treat_kiev post_west post_kiev ///
 $controls, absorb($fe) cluster($cluster) nocons

bys user_id: egen maxy = max(`y')
distinct user_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

sum `y' if year < 2014 & `cc'_treat == 1
scalar y_mean = r(mean)
sum `y' if year < 2014 & `cc'_treat == 0
scalar y_mean2 = r(mean)

outreg2 using "$output/tables/05_effects_`cc'_nm.tex", append  tex(frag) ///
keep(post_`cc'_treat)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), Unique users, n, Mean outcome treated, y_mean, Mean outcome control, y_mean2) nonotes label nocons
}
restore
}
*/
