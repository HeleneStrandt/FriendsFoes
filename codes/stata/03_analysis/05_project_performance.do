// effects on projects 
// individual level regressions1
set scheme white_w3d, perm

clear
set more off
cd "$processed"

*global output = "$path\draft\draft\output_progrs"
*global codes "$path\codes\codes\stata"
*global raw = "$path\database\extractions"
*cd "$path/database\stata_tmp"

// use pre-2014 characterstics to compare treated and non-treated projects
import delimited "treated_projects.csv", encoding(UTF-8) clear

set seed 310823

/*
# projects that had an ua-ru collaboration in 2013
# only projects with at least 2 different authors and 2 different countries 
#( only non-forked projects)
# only those where project_year < 2014
*/
count // 32.021

// drop projects from DLK
drop if dlk_owner == 1
gen company = (!mi(company13))
gen tt = string(min(project_year, 2013))+"-"+ string(project_month)+"-"+"01" // some projects were updated and the date is no longer adequate 
gen age = (date("2013-12-31", "YMD")-date(tt, "YMD"))/30
drop tt

gen ua_owner = (country_owner == "ua")
gen ru_owner = (country_owner == "ru")

// summary statistics by country
tab country_owner if treated ==1
count if treated == 1 & country_owner == "ua" // 12%
count if treated == 1 & country_owner == "ru" // 23.82%
gen control_country_owner = 0
foreach x in us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace control_country_owner = 1 if strpos(country_owner, "`x'")
}
tab control_country_owner // 82.81%
count if treated == 1 & country_owner == "us" // 106/340
count if treated == 1 & control_country_owner == 1 & country_owner != "us" // 72/340
count if treated == 1 & control_country_owner == 0 // 162/340

*** balance table
// compare treated and untreated projects, unmatched 
global name balance_proj_all
global var treated
global weight "" // [iweight=cem_weights]
global keep1 ""
global keep2 ""
*global chars age forked n_authors n_author_countries commits_int_pre commits_nself_int project_stars_pre 
*global tosum1 project_forks_pre ua_owner ru_owner company owner_commits_pre owner_stars_pre owner_contributors_pre $chars
global chars age forked n_authors n_author_countries commits_int_pre project_stars_pre ua_owner ru_owner
global tosum1 company owner_commits_pre owner_stars_pre owner_contributors_pre $chars

foreach x in $tosum1 {
replace `x' = 0 if mi(`x')
}

lab var company "Project is company-owned"
lab var owner_commits_pre "Commits by project owner"
lab var owner_stars_pre "Stars of project owner"
lab var owner_contributors_pre "Contributors of project owner"
lab var age "Project age in months"
lab var forked "Project is forked"
lab var n_authors "Contributors to project"
lab var n_author_countries "Contributing countries to project"
lab var commits_int "Contributions to project"
lab var project_stars_pre "Stars of project"
lab var ua_owner "Project owner is Ukrainian"
lab var ru_owner "Project owner is Russian"
	

foreach x in tex txt {
capture erase "$output/tables/$name.`x'
}
global var treated
global weight "" // [iweight=cem_weights]
global keep1 ""
global keep2 ""
global lab "Unmatched"
do "$codes/analysis/help/balance_projects" 

// matching untreated to treated projects
cap drop cem_*
cem $chars, treatment($var) showbreaks k2k // note that because one unit is randomly selected there might be random small differences in replications!

// compare treated and untreated projects, matched
global var treated
global weight "" // [iweight=cem_weights]
global keep1 " & cem_matched ==1"
global keep2 "keep if cem_matched ==1"
global lab "Matched"

do "$codes/analysis/help/balance_projects" 

bys project_id: gen n = _N 
tab n
drop n
save "treated_projects2", replace

*** project performance regressions
// import project performance file 
import delimited "perf_projects.csv", encoding(UTF-8) clear
gen company_cur = (!mi(company))
drop company_current
compress, nocoalesce

// import data: create quarterly identifiers, collapse at quarterly level
gen tt = string(year) + "-" + string(month) + "-01"
gen date = date(tt, "YMD") 
capture drop quarter_day

gen quarter_day = (qofd(date))
format quarter_day %tq // (216 is the T = 0)
tab quarter_day
drop tt
sort project_id year month

x

// check this collapse! sums n_authors and n_author_countries
collapse (sum) n_authors n_author_countries commits_all_int commits_all_ext commits_nself_int commits_nself_ext ///
commits_ru_int commits_ru_ext commits_ua_int commits_ua_ext project_stars project_forks (firstnm) company_cur, by(project_id quarter_day)
//collapse (mean) n_authors n_author_countries commits_all_int commits_all_ext commits_nself_int commits_nself_ext ///
//commits_ru_int commits_ru_ext commits_ua_int commits_ua_ext project_stars project_forks (firstnm) company_cur (min) quarter_day, by(project_id month)

// get time of the first commit
bys project_id: egen first_commit = min(quarter_day)
format first_commit %tq
xtset project_id quarter_day // month
tsfill, full

foreach x of varlist company_cur first_commit {
bys project_id: egen m = mode(`x'), minmode
replace `x' = m if mi(`x')
drop m
}
drop if quarter_day < first_commit

bys project_id: egen ll = max(quarter_day) if !mi(commits_all_int)
bys project_id: egen last_commit = mean(ll)
drop ll
format last %tq

// replace missing with zeros 
foreach x of varlist n_authors n_author_countries commits_all_int commits_all_ext commits_nself_int commits_nself_ext ///
commits_ru_int commits_ru_ext commits_ua_int commits_ua_ext project_stars project_forks {
replace `x' = 0 if mi(`x')
}
compress, nocoalesce
save "perf_projects_quarterly", replace 


use "perf_projects_quarterly", replace 
gen year = year(dofq(quarter_day))
merge m:1 project_id using treated_projects2
drop if _merge == 1
drop _merge

// for monthly data: treatment starts in december 2013 (Maidan started in November)
sum quarter_day if quarter_day == tq(2013q3) //  
global qX = r(mean)

gen post = (quarter_day >=$qX) // treatment is starting from Q4 2013
gen treat_post = treated*post

gen owner_region = "ua" if country_owner == "ua" 
replace owner_region = "ru" if country_owner == "ru"
replace owner_region = "Other" if mi(owner_region)

foreach x of varlist ua ru  {
gen post_`x' = post * `x'
}

encode owner_region, gen(owner_r)
gen ua_treat = (owner_region == "ua" & treated==1)
gen ru_treat = (owner_region == "ru" & treated==1)

gen ua_treat_post = ua_treat*post
gen ru_treat_post = ru_treat*post

label var treat_post "Post $\times$ Treat"
label var ua_treat_post "Post $\times$ Treat $\times$ UA"
label var ru_treat_post "Post $\times$ Treat $\times$ RU"
label var post_ua "Post $\times$ UA"
label var post_ru "Post $\times$ RU"

replace age = round(age)

lab var commits_nself_in "Commits"
lab var n_authors "Contributors" 
lab var n_author_countries "Countries"
lab var commits_ru_int "RU Commits"
lab var commits_ua_int "UA Commits"
lab var project_stars "Stars"
lab var project_forks "Forks"

// first: do it for matched only cem_matched == 1 with strata*time fixed effects 
foreach x of varlist commits_int_pre project_stars_pre project_forks_pre {
cap gen log_`x' = log(`x'+1)
gen c`x' = log_`x'*quarter_day  // month
}


* regressions
set more off
global varlist commits_ru_int commits_ua_int commits_nself_int n_authors n_author_countries project_stars project_forks
global fe "project_id quarter_day" // month "cem_strata#post owner_r
global controls "" //"ccommits_int_pre cproject_stars_pre cproject_forks_pre"
global cluster "cem_strata"

global name "projects_perf1"
foreach x in tex txt {
capture erase "$output/tables/$name.`x'
}

x
set more off
preserve
keep if inrange(year, 2011,2018) 
keep if cem_matched == 1 // & forked == 0 
//tab country_owner if treated ==0
foreach y of varlist $varlist {
local lab: var label `y'
ppmlhdfe `y' treat_post ua_treat_post ru_treat_post $controls, absorb($fe) cluster($cluster)
//  post_ua post_ru
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large) vert color(navy) ///
keep(treat_post ua_treat_post ru_treat_post) ysize(2) xsize(4) legend(off)
graph save "`y'", replace

foreach x in 0 1 {
sum `y' if quarter_day < $qX  & treated == `x'
scalar ymean`x' = r(mean)
}

bys project_id: egen maxy = max(`y')

distinct project_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(treat_post ua_treat_post ru_treat_post post_ua post_ru)  ctitle("`lab'") alpha(0.001, 0.01, 0.05) ///
addstat(Pseudo R2, e(r2_p), Unique projects, n, ///
Mean\ Y^{T}, ymean1, Mean\ Y^{C}, ymean0) nonotes label nocons
}
restore 

x
// include all projects, adding more fixed effects (in addition post#owner_r)
// age, owner_region*quarter d, linear n_commits_pre*time, linear n_stars_pre*time
/*
global varlist commits_nself_int n_authors n_author_countries commits_ru_int commits_ua_int project_stars project_forks
global fe "project_id age quarter_day" // post#owner_r
global controls "ccommits_int_pre cproject_stars_pre cproject_forks_pre"
global cluster "project_id"

global name "projects_perf1_all_fec"
foreach x in tex txt {
capture erase "$output/tables/$name.`x'
}

preserve
keep if inrange(year, 2011,2018) 
*keep if cem_matched == 1 
foreach y of varlist $varlist {
local lab: var label `y'
ppmlhdfe `y' treat_post ua_treat_post ru_treat_post $controls, absorb($fe) cluster($cluster)
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5)) msize(large) vert color(navy) ///
keep(treat_post ua_treat_post ru_treat_post) ysize(2) xsize(4) legend(off)
graph save "`y'", replace
foreach x in 1 2 3 {
sum `y' if quarter_day < $qX  & owner_r == `x', detail
scalar ymean`x' = r(mean)
}

bys project_id: egen maxy = max(`y')

distinct project_id if maxy > 0 
scalar n = r(ndistinct)
drop maxy

outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(treat_post ua_treat_post ru_treat_post)  ctitle("`lab'") ///
addstat(Pseudo R2, e(r2_p), Unique projects, n, ///
Mean outcome UA, ymean3, Mean outcome RU, ymean2, Mean outcome Other, ymean1) nonotes label nocons
}
restore 
*/

// dynamic treatment effects 
do "$codes/analysis/help/centering_pr"
global name "perf_event"
global controls "ccommits_int_pre" //"ccommits_int_pre cproject_stars_pre cproject_forks_pre" //hold also with these conrols
global fe "project_id quarter_day"  // project_id quarter_day post#owner_r cem_strata#post age
global varlist  "commits_ru_int commits_ua_int commits_nself_int n_authors n_author_countries project_stars project_forks"
global cluster "cem_strata"

set more off
preserve 
keep if inrange(year, 2011, 2018)
keep if cem_matched == 1  
drop *_post_13 *_post_14 *_post_15 *_post_16 *_post_17 *_post_18 *_post_19
foreach y of varlist $varlist { 
local lab: var label `y'
ppmlhdfe `y' treated_t_before treated_pre_* treated_post_* treated_t_after  /// 
             ua_treat_t_before ua_treat_pre_* ua_treat_post_* ua_treat_t_after  ///
			 ru_treat_t_before ru_treat_pre_* ru_treat_post_* ru_treat_t_after  ///
$controls, nocons absorb($fe) cluster($cluster)

coefplot, omitted yline(0) xline(4, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue)) msize(large) msymbol(o) mcolor(ebblue*1.5) vert  ///
keep(treated_pre_4 treated_pre_3 treated_pre_2 treated_pre_1 treated_post_0 treated_post_1 treated_post_2 treated_post_3 treated_post_4 treated_post_5 treated_post_6) ///
title("`lab'") subtitle("${name2}")  ///
ytitle("Owner not in {UA, RU} x time dummies") xtitle("Quarters since Q4, 2013") xlab(, labs(vsmall))
graph save "Other${name}_`y'", replace

coefplot, omitted yline(0) xline(4, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue)) msize(large) msymbol(o) mcolor(ebblue*1.5) vert ///
keep(ua_treat_pre_4 ua_treat_pre_3 ua_treat_pre_2 ua_treat_pre_1 ua_treat_post*) ///
title("`lab'") subtitle("${name2}") ///
ytitle("Owner from UA x time dummies") xtitle("Quarters since Q4, 2013") xlab(, labs(vsmall))
graph save "UA${name}_`y'", replace

coefplot, omitted yline(0) xline(4, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue)) msize(large) msymbol(o) mcolor(ebblue*1.5) vert ///
keep(ru_treat_pre* ru_treat_post*) ///
title("`lab'") subtitle("${name2}")  ///
ytitle("Owner from RU x time dummies") xtitle("Quarters since Q4, 2013") xlab(, labs(vsmall))
graph save "RU${name}_`y'", replace

graph combine "Other${name}_`y'" "UA${name}_`y'" "RU${name}_`y'", ycommon xcommon ysize(2) xsize(6)
graph export "$output/figures/${name}_`y'_event.pdf", replace
}
restore 


graph combine "RUperf_event_commits_nself_int.gph" "RUperf_event_n_authors.gph"  "RUperf_event_n_author_countries.gph" "RUperf_event_commits_ua_int.gph" "RUperf_event_project_stars.gph" "RUperf_event_project_forks.gph", /// 
rows(2) ycommon ysize(2) xsize(5) ///
title("A: Russian projects")
graph export "$output/figures/RU-project-effect.pdf", replace

graph combine "UAperf_event_commits_nself_int.gph" "UAperf_event_n_authors.gph"  "UAperf_event_n_author_countries.gph" "UAperf_event_commits_ru_int.gph" "UAperf_event_project_stars.gph" "UAperf_event_project_forks.gph", ///
rows(2) ycommon ysize(2) xsize(5) ///
title("B: Ukrainian projects")
graph export "$output/figures/UA-project-effect.pdf", replace
/*
graph combine "RUperf_event_commits_nself_int.gph" "RUperf_event_n_authors.gph"  "RUperf_event_n_author_countries.gph", rows(1) ycommon ysize(2) xsize(5) ///
 title("Russian projects")
graph export "$output/figures/RU-project-effect.pdf", replace

graph combine "UAperf_event_commits_nself_int.gph" "UAperf_event_n_authors.gph"  "UAperf_event_n_author_countries.gph", rows(1) ycommon ysize(2) xsize(5) ///
title("Ukrainian projects")
graph export "$output/figures/UA-project-effect.pdf", replace

// other outcomes
graph combine "RUperf_event_commits_ua_int.gph" "RUperf_event_project_stars.gph"  "RUperf_event_project_forks.gph", rows(1) ycommon ysize(2) xsize(5) ///
 title("Russian projects")
graph export "$output/figures/RU-project-effect2.pdf", replace

graph combine "UAperf_event_commits_ru_int.gph" "UAperf_event_project_stars.gph"  "UAperf_event_project_forks.gph", rows(1) ycommon ysize(2) xsize(5) ///
title("Ukrainian projects")
graph export "$output/figures/UA-project-effect2.pdf", replace
*/












