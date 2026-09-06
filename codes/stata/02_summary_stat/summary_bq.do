// summary graph with big query data on push events
cd "$path"

clear all
set matsize 11000
set maxvar 32767 

// only direct push contributions (first directory, no forks)
import delimited "$raw/summary_country_to_country2.csv", clear

drop if country_code == owner_country_code // only international commits
tab country_code
*drop if owner_country_code == "\N"

gen month = string(y) + "-" + string(m) + "-" +  "1"
gen date = date(month, "YMD")
format date %td

gen month_day = (mofd(date))
format month_day %tm //
egen cc = group(country_code owner_country_code)
xtset cc month_day 
tsfill, full

foreach x of varlist *push* {
replace `x' = 0 if mi(`x')
}

foreach y of numlist -11/11 {
foreach x in country_code owner_country {
bys cc: replace `x' = `x'[_n+`y'] if missing(`x')
bys cc: replace `x' = `x'[_n-`y'] if missing(`x')
}
}

sort country_code owner_country_code date
twoway ///
(line ext_pushes date if country_code == "ua" & owner_country_code == "pl") ///
(line ext_pushes date if country_code == "ua" & owner_country_code == "ru"), /// 
legend(label (1 "ua-by") label ( 2 "ua-ru")) xline(19724)

sum date if month == "2014-2-1"
global monthX = r(mean)

gen post = (date >=$monthX)
hist date if post

// UA-RU collaborations
gen ru_project = (owner_country_code == "ru")
gen ru_post = ru_project*post

gen ua_user = (country_code == "ua")
gen ua_ru_post = ua_user*ru_post

// RU-UA collaborations
gen ua_project = (owner_country_code == "ua")
gen ua_post = ua_project*post

gen ru_user = (country_code == "ru")
gen ru_ua_post = ru_user*ua_post

// joint ua_ru_post
gen joint_ua_ru_post = ua_ru_post + ru_ua_post

ren y year
gen int_pushes = sum_size_pushes/ext_pushes

lab var ru_post "RU*Post"
lab var ua_ru_post "UA*RU*Post"
lab var joint_ua_ru_post "Joint UA*RU*Post"
lab var ua_post "UA*Post"
lab var ru_ua_post "RU*UA*Post"
gen log_ext_pushes = log(ext_pushes + 1)
gen log_int_pushes = log(int_pushes + 1)

lab var log_ext_pushes "Commits, extensive"
lab var log_int_pushes "Commits, intensive"

encode country_code, gen(user_c)
encode owner_country, gen(owner_c)
 

bys cc: egen mean = mean(ext_pushes)
drop if mean < 3

// poisson zero-inflated - baseline model, no 3diff
drop if country_code == "\N"
drop if owner_country == "\N"
set emptycells drop

cap drop insample
gen insample = 0
foreach x in ru ua  {
replace insample = 1 if country_code == "`x'"
}

foreach x in tex txt {
	capture erase "$output/tables/bq.`x'"
	}
preserve
keep if inrange(year, 2012,2017) & insample == 1
foreach y of varlist log_*pushes {
local lab: var label `y'
xtreg `y' i.month_day i.month_day#user_c joint_ua_ru_post ua_ru_post, fe 
outreg2 using "$tables/bq.tex", append  tex(frag) ///
keep(joint_ua_ru_post ua_ru_post)  ctitle("`lab'") ///
 nonotes label nocons
}
restore


ren y year
keep if  country_code == "ua" // commits only from UA or RU
gen geo = ""
replace geo =  "UA_RU" if (country_code == "ru" & owner_country_code == "ua") | ///
(country_code == "ua" & owner_country_code == "ru")
replace geo = "Other" if mi(geo)

gen q = quarter(date)
gen q_year = string(q)+"_"+string(year)

bys q_year: egen month_nm = min(date)
format month_nm %td

collapse (firstnm) month_nm y (sum) *pushes, by(q_year geo)

reshape wide *pushes*, i(q_year y month_nm) j(geo) string


gen quarter_day = (qofd(month))
format quarter_day %tq // (216 is the T = 0)
tsset quarter_day
tsfill 

// absolute dynamics: UA-RU and UA+RU with other countries
gen date = string(month, "%td")
sum quarter if strpos(date, "01oct2013") 
global monthX = r(mean)

preserve
keep if inrange(quarter, 207,231)
graph twoway ///
(connected ext_pushesUA_RU quarter_day, lc(white) lwidth(1) lpattern(solid) ///
msymbol(o) msize(large) mcolor(white) yaxis(1) ) ///
(connected ext_pushesOther quarter_day, lc(green*0.7) lwidth(1) lpattern(dash) ///
msymbol(d) msize(large) mcolor(green) yaxis(2) ), ///
xline($monthX, lwidth(0.7))   ///
ytitle("commits by RU(UA) users to UA(RU) projects", axis(1) size(small)) ///
ytitle("commits by RU and UA users to other countries", axis(2) size(small)) ///
xtitle("") title("")  ///
legend(label (1 "UA to RU or RU to UA") label ( 2 "UA and RU to Other"))
graph export "$figures/bq_ext_pushes.pdf", replace
restore

preserve
keep if inrange(quarter, 207,231)
graph twoway ///
(connected sum_size_pushesUA_RU quarter_day, lc(navy*0.7) lwidth(1.3) lpattern(solid) ///
msymbol(o) msize(large) mcolor(navy) yaxis(1) ) ///
(connected sum_size_pushesOther quarter_day, lc(green*0.7) lwidth(1.3) lpattern(dash) ///
msymbol(d) msize(large) mcolor(green) yaxis(2) ), ///
xline($monthX, lwidth(0.7))   ///
ytitle("commits by RU(UA) users to UA(RU) projects", axis(1) size(small)) ///
ytitle("commits by RU and UA users to other countries", axis(2) size(small)) ///
xtitle("") title("")  ///
legend(label (1 "UA to RU or RU to UA") label ( 2 "UA and RU to Other"))
graph export "$figures/bq_ext_pushes.pdf", replace
restore
