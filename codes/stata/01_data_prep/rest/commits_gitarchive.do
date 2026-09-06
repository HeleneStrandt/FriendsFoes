// commits_gitarchive


// extraction from sql: project and user info
import delimited "$raw/projects_from_commits.csv", bindquote(strict) varnames(1) stripquote(yes) encoding(UTF-8) clear
ren repo_id project_id
save "project_from_commits", replace

// doing the same with push requests 
import delimited "$raw/pushes12-19.csv", bindquote(strict) varnames(1) stripquote(yes) encoding(UTF-8) clear

gen m = string(a_y) + "-" + string(a_m) + "-01" 
gen month = date(m, "YMD", 2000)
tab month if a_y == 2014 & a_m == 3
duplicates drop 
format month %td

drop a_m m b_login 
ren (a_y a_actor_login a_repo_name a_pushes b_id b_region) ///
(year user_login project_name pushes_month user_id user_region) 

save pushesBQ, replace
keep project_name a_repo_id 
duplicates drop
ren (project_name1 project_name2) (owner_login repo_name)
drop project_name
save projects_BQ_sample, replace
export delimited using "$raw\users_from_commits.csv", replace
// merge on users now in sqlite

import delimited using "$raw\users_from_commits.csv", clear
ren v9 longitude
do "$codes/data prep/country_codes"
drop repo_name username16 userdate16 userloc16
duplicates drop
drop n
save owner_info, replace

use pushesBQ, replace
split project_name, parse("/")
ren (project_name1 project_name2) (owner_login repo_name)
drop project_name
count
drop if user_login == owner_login
merge m:1 owner_login using owner_info, keepusing(region country_code)
drop if _merge == 2
drop _merge
ren region project_region
save pushes_merged, replace

collapse (sum) pushes_month (firstnm) year, by(user_region month)
encode user_region, gen(cc)
xtset cc month


preserve 
global y = "pushes_month"
global monthX = 19783
keep if inrange(year, 2012, 2018) 
graph twoway ///
(line $y month if user_region == "RU", yaxis(1) yscale(range(0) axis(1))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if user_region == "UA", yaxis(1) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dash_dot)) ///   
(connected $y month if project_region == "control", yaxis(1) yscale(range(0) axis(1)) msymbol(oh) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)),
legend(label (1 "RUe") label (2 "UA") ///
label (3 "Control") label (4 "RU") size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) 
restore




// merge for the baseline regressions (can do more complicated controls later)
use commits_RU_UA, replace
destring project_id, replace force
drop if mi(project_id)
merge m:1 project_id using project_from_commits, keepusing(country_code owner_id)
drop _merge 

do "$codes/data prep/country_codes"
replace region = "Other" if mi(region)
ren region project_region

save commits_regress, replace

// baseline analysis for UA
use pushes_merged, replace
gen pushes_ex_month = 1
replace project_region = "Other" if mi(project_region)

collapse (sum) pushes* (firstnm) year, by(month *region)

egen cc = group(user_region project_region)
xtset cc month

gen post = (month >19783)
tab month if post

gen ru = (project_region == "RU")

gen ru_post = ru*post

foreach x of varlist push* {
gen log_`x' = log(`x' + 1)
}

set matsize 10000
foreach x in tex txt {
	capture erase "$output/baseline.`x'"
	}
preserve
keep if inrange(year, 2012,2016) & user_region == "UA" & project_region != "Other"
foreach y of varlist push* {
xtreg log_`y'  i.month ru_post, fe robust 
btoutreg2 using "$output/baseline.tex", append  tex(frag pretty) ///
keep(ru_post)  ctitle("`y'") ///
addtext(Month FE, yes, Receiv. region FE, yes, Robust, yes) ///
label nocons
}
restore

// examine:

gen q = quarter(month)
gen q_year = string(q)+"_"+string(year)
collapse (firstnm) month year (sum) push*, by(q_year *region)
egen cc = group(user_region project_region)
xtset cc month

preserve 
global y = "pushes_ex_month"
global monthX = 19783
keep if inrange(year, 2012, 2018) & user_region == "RU"
graph twoway ///
(line $y month if project_region == "RU", yaxis(1) yscale(range(0) axis(1))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if project_region == "Europe", yaxis(1) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dash_dot)) ///   
(connected $y month if project_region == "Europe", yaxis(1) yscale(range(0) axis(1)) msymbol(+) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)), ///  
legend(label (1 "RU") label (2 "Europe") ///
label (3 "PostSoviet")  size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) 
restore



///
ytitle("to RU and UA", size(small) axis(1)) ///
ytitle("to other Europe and Overseas", size(small) axis(2)) 
graph save "$output/sum_commits", replace
graph export "$output/sum_commits.pdf", replace
restore 









