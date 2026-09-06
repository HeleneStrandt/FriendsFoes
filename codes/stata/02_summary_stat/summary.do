// summary statistics of the key variables
cd "$path"

// entry of projects by region and month

import delimited "$raw/sum_projects_country.csv", varnames(1) clear
drop if mi(date)
gen month = date(date, "YMD", 2000)
tab month if strpos(date, "2014-03-01") //19783 is the month for xline
format month %td
gen year = year(month)

keep if inrange(year, 2008, 2018) // the rest are noise
tab year

// see the biggest players
bys country_code: egen total_projects = sum(projects_month)
bys country_code: gen n = 1 if _n == 1
sort total

// create regions
// the largest regions: us, cn, in, gb, de, br, ca, fr, ru, jp, au, es, nl, usa
do "$codes/data prep/country_codes"

collapse (sum) projects_month (firstnm) year, by(region month)
encode region, gen(cc)
xtset cc month


// graph 
preserve 
global y = "projects_month"
global monthX = 19783
keep if inrange(year, 2011, 2017) 
graph twoway ///
(line $y month if region == "Europe", yaxis(2) yscale(range(0) axis(2))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if region == "Overseas", yaxis(2) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dot)) ///   
(connected $y month if region == "RU", yaxis(1) yscale(range(0) axis(1)) msymbol(oh) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)) ///   
(connected $y month if region == "UA", yaxis(1) yscale(range(0) axis(1)) msymbol(+) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)), ///  
legend(label (1 "Europe") label (2 "Overseas") ///
label (3 "RU") label (4 "UA") size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) ///
ytitle("by RU and UA", size(small) axis(1)) ///
ytitle("by other Europe and Overseas", size(small) axis(2)) 
graph save "$output/sum_projects", replace
graph export "$output/sum_projects.pdf", replace
restore 

// try the same, but collapse on quarterly level
gen q = quarter(month)
gen q_year = string(q)+"_"+string(year)
collapse (firstnm) month year (sum) projects_month, by(q_year region)
sort region month

preserve 
global y = "projects_month"
global monthX = 19783
keep if inrange(year, 2011, 2017) 
graph twoway ///
(line $y month if region == "Europe", yaxis(2) yscale(range(0) axis(2))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if region == "Overseas", yaxis(2) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dash_dot)) ///   
(connected $y month if region == "RU", yaxis(1) yscale(range(0) axis(1)) msymbol(oh) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)) ///   
(connected $y month if region == "UA", yaxis(1) yscale(range(0) axis(1)) msymbol(+) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)), ///  
legend(label (1 "Europe") label (2 "Overseas") ///
label (3 "RU") label (4 "UA") size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) ///
ytitle("by RU and UA", size(small) axis(1)) ///
ytitle("by other Europe and Overseas", size(small) axis(2)) 
graph save "$output/sum_projects", replace
graph export "$output/sum_projects.pdf", replace
restore 

// entry of users by region and month
import delimited "$raw/sum_users_country.csv", varnames(1) clear
drop if mi(date)
gen month = date(date, "YMD", 2000)
tab month if strpos(date, "2014-03-01") //19783 is the month for xline
format month %td
gen year = year(month)

keep if inrange(year, 2008, 2018) // the rest are noise
tab year


// create regions
// the largest regions: us, cn, in, gb, de, br, ca, fr, ru, jp, au, es, nl, usa
do "$codes/data prep/country_codes"

collapse (sum) users_month (firstnm) year, by(region month)
encode region, gen(cc)
xtset cc month


// graph 
preserve 
global y = "users_month"
global monthX = 19783
keep if inrange(year, 2011, 2017) 
graph twoway ///
(line $y month if region == "Europe", yaxis(2) yscale(range(0) axis(2))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if region == "Overseas", yaxis(2) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dash_dot)) ///   
(connected $y month if region == "RU", yaxis(1) yscale(range(0) axis(1)) msymbol(oh) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)) ///   
(connected $y month if region == "UA", yaxis(1) yscale(range(0) axis(1)) msymbol(+) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)), ///  
legend(label (1 "Europe") label (2 "Overseas") ///
label (3 "RU") label (4 "UA") size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) ///
ytitle("by RU and UA", size(small) axis(1)) ///
ytitle("by other Europe and Overseas", size(small) axis(2)) 
graph save "$output/sum_projects", replace
graph export "$output/sum_projects.pdf", replace
restore 

// try the same, but collapse on quarterly level
gen q = quarter(month)
gen q_year = string(q)+"_"+string(year)
collapse (firstnm) month year (sum) users_month, by(q_year region)
sort region month

preserve 
global y = "users_month"
global monthX = 19783
keep if inrange(year, 2011, 2017) 
graph twoway ///
(line $y month if region == "Europe", yaxis(2) yscale(range(0) axis(2))  lc(navy) lwidth(0.5) lpattern(dash)) /// 
(line $y month if region == "Overseas", yaxis(2) yscale(range(0) axis(1)) lc(navy) lwidth(0.5) lpattern(dash_dot)) ///   
(connected $y month if region == "RU", yaxis(1) yscale(range(0) axis(1)) msymbol(oh) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)) ///   
(connected $y month if region == "UA", yaxis(1) yscale(range(0) axis(1)) msymbol(+) msize(small) mcolor(cranberry) lc(navy) lwidth(0.5) lpattern(solid)), ///  
legend(label (1 "Europe") label (2 "Overseas") ///
label (3 "RU") label (4 "UA") size(small)) ///
title("") xtitle("")  xline($monthX, lwidth(0.3)) ///
ytitle("by RU and UA", size(small) axis(1)) ///
ytitle("by other Europe and Overseas", size(small) axis(2)) 
graph save "$output/sum_projects", replace
graph export "$output/sum_projects.pdf", replace
restore 




