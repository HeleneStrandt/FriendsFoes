// descriptive graphs
// number of new projects, users and watchers, by month and region
cd "$processed"


foreach x in sum_users_country sum_projects_country sum_watchers {
import delimited $raw/`x'.csv, varnames(1) encoding(UTF-8) clear delimiter("|")
save `x', replace
}

use sum_watchers, replace
drop if inlist(watcher_c, "ua", "ru")
drop if owner_c == watcher_c
collapse (sum) watchers_m, by(owner_country year month)
drop if mi(owner_c)
ren owner_country country_code
foreach x in projects users {
merge 1:1 country_code year month using sum_`x'_country
drop _merge
}
keep if inrange(year, 2011, 2018)
drop if mi(country_code)

gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(country_code, "`x'") 
}
tab sample
keep if sample == 1

gen region = country if inlist(country, "ua", "ru")
replace region = "Control countries" if mi(region)

collapse (sum) watcher new_p new_u, by(region year month)

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

gen dates = string(date, "%td")
sum date if strpos(dates, "01nov2013") 
global monthX = r(mean)

// normalize 
foreach x in watchers new_projects new_users {
gen nn = `x' if date == $monthX
bys region: egen mean = mean(nn)
gen n`x' = `x'/mean
drop nn mean
}

encode region, gen(r)
xtset r date

lab var nwatchers "Stars"
lab var nnew_projects "Projects registered"
lab var nnew_users "Users registered"

foreach x in nwatchers nnew_projects nnew_users {
global y "`x'"
local lab: var label `x'
graph twoway ///
(connected $y date if region == "ua", msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///  
(connected $y date if region == "ru", msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon) ) ///
(connected $y date if region == "Control countries", msymbol(t) msize(large) lc(emerald*0.7) mcolor(emerald) ) ///  
, ytitle("`lab'") ///
legend(label (1 "UA") label (2 "RU") label (3 "Control") ) ///
xtitle("") xline($monthX, lwidth(0.7)) xlabel(, format($td) labsize(small) alternate) xsize(2) ysize(1)
graph export "$output/figures/`x'_sum.pdf", replace
}
***************************************************************

// summary of commits
import delimited for_regressionq_bl.csv, varnames(1) encoding(UTF-8) clear
collapse (sum) commits_int, by(month year country_author)
drop if mi(country_author)

gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(country_a, "`x'") 
}
tab sample
keep if sample == 1

keep if inrange(year, 2011, 2018)

gen region = country_author if inlist(country, "ua", "ru")
replace region = "Control countries" if mi(region)
/*
foreach x in de gb fr nl se it by cz lt lv ee pl {
replace region = "Europe" if strpos(country, "`x'")
}
foreach x in us ca br {
replace region = "America" if strpos(country, "`x'")
}
foreach x in au jp cn in  {
replace region = "Asia" if strpos(country, "`x'")
}
*/
collapse (sum) commits_int, by(year region month)

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

gen dates = string(date, "%td")
sum date if strpos(dates, "01nov2013") 
global monthX = r(mean)

// normalize 
gen nn = commits_int if date == $monthX
bys region: egen mean = mean(nn)
gen ncommits = commits_int/mean
drop nn mean

encode region, gen(r)
xtset r date

global y "ncommits"
graph twoway ///
(connected $y date if region == "ua", msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///    
(connected $y date if region == "ru", msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon) ) ///
(connected $y date if region == "Control countries", msymbol(t) msize(large) lc(emerald*0.7) mcolor(emerald) ) ///  
, ytitle("Commits") ///
legend(label (1 "UA") label (2 "RU") label (3 "Control") ) ///
xtitle("") xline($monthX, lwidth(0.7)) xlabel(, format($td) labsize(small) alternate) xsize(2) ysize(1)
graph export "$output/figures/commits_sum.pdf", replace







