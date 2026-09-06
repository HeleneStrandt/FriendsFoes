// descriptives I
// share of UA/RU in foreign commits of UA and RU programmers
*ssc install schemepack, replace
set scheme white_w3d, perm

cd "$processed"
set more off


global name = "01_desc_baseline"

import delimited for_regressionq_bl.csv, varnames(1) encoding(UTF-8) clear

*cap drop if forked == 1
cap ren (cc2013_author cc2013_owner) (country_author country_owner)

drop if country_author == country_owner // only international commits
drop if country_owner == ""
drop if country_a == ""

/*
drop if country_o == "us"
drop if country_a == "us"
*/

// drop dlk
drop if country_a == "ua" & dlk_a==1
drop if country_o == "ua" & dlk_o==1

keep if country_author == "ru" | country_author == "ua" // commits from UA or RU
gen geo = ""
replace geo =  "UA_RU" if (country_author == "ru" & country_owner == "ua") | ///
(country_author == "ua" & country_owner == "ru")
replace geo = "Other" if mi(geo)

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

gen q = quarter(date)
gen q_year = string(q)+"_"+string(year)
bys q_year: egen month_nm = min(date)
format month_nm %td

collapse (firstnm) month_nm year (sum) commit*, by(q_year geo)

reshape wide commit*, i(q_year year month_nm) j(geo) string
sort month_nm

foreach x in commits_int commits_ext {
gen `x' = `x'UA_RU + `x'Other
}

gen quarter_day = (qofd(month))
format quarter_day %tq // (215 is the T of normalization)
tsset quarter_day
tsfill, full 

// absolute dynamics: UA-RU and UA+RU with other countries
gen date = string(month, "%td")
sum quarter if strpos(date, "01oct2013") 
global monthX = r(mean)

// normalize 
cap drop norm_*
foreach x in intUA_RU intOther extUA_RU extOther {
gen nn = commits_`x' if quarter_day == $monthX
egen mean = mean(nn)
gen norm_`x' = commits_`x'/mean
//drop nn mean
} 
x
global t1 = "norm_extOther"
global t2 = "norm_extUA_RU"

preserve
keep if inrange(year, 2011, 2018)
graph twoway ///
(connected $t2 quarter_day, msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///
(connected $t1 quarter_day, msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon)  ), ///
xline($monthX, lwidth(0.7))   ///
ytitle("International collaborations, normalized to Q4 2013",  size(small)) ///
xtitle("") title("")  ///
legend(label (1 "Ukraine-Russia collaborations") ///
label ( 2 "Ukraine-Control Countries and Russia-Control Countries collaborations") position(6) rows(2) region(lcolor(white)))
graph export "$output/figures/desc_turnover_ext_total.pdf", replace
restore

global t1 = "norm_intOther"
global t2 = "norm_intUA_RU"
preserve
graph twoway ///
(connected $t2 quarter_day, msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///
(connected $t1 quarter_day, msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon)  ), ///
xline($monthX, lwidth(0.7))   ///
ytitle("International collaborations, normalized to Q4 2013",  size(small)) ///
xtitle("") title("")  ///
legend(label (1 "Ukraine-Russia collaborations") ///
label ( 2 "Ukraine-Control Countries and Russia-Control Countries collaborations") position(6)  rows(2) region(lcolor(white)))
graph export "$output/figures/desc_turnover_int_total.pdf", replace
restore

// with other countries - to compare 
// for presentation, not needed in the draft
global main = "ua"
global partner = "de"
global out = "ru"

global Main = upper("$main")
global P = upper("$partner")
global main_p = "${Main}_${P}"

import delimited for_regressionq_bl.csv, varnames(1) encoding(UTF-8) clear

drop if country_author == country_owner // only international commits
drop if country_owner == ""
drop if country_a == ""

// drop dlk
drop if country_a == "ua" & dlk_a==1
drop if country_o == "ua" & dlk_o==1

keep if country_author == "$partner" | country_author == "$main" // commits from UA or RU
drop if country_owner == "$out" // to make sure there is no downward pressure on 'Rest of the world'
gen geo = ""
replace geo =  "$main_p" if (country_author == "$partner" & country_owner == "$main") | ///
(country_author == "$main" & country_owner == "$partner")
replace geo = "Other" if mi(geo)

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

gen q = quarter(date)
gen q_year = string(q)+"_"+string(year)

bys q_year: egen month_nm = min(date)
format month_nm %td

collapse (firstnm) month_nm year (sum) commit*, by(q_year geo)

reshape wide commit*, i(q_year year month_nm) j(geo) string

foreach x in commits_int commits_ext {
gen `x' = `x'$main_p + `x'Other
}

gen quarter_day = (qofd(month))
format quarter_day %tq // (215 is the T of normalization )
tsset quarter_day
tsfill 

// absolute dynamics: UA-RU and UA+RU with other countries
gen date = string(month, "%td")
sum quarter if strpos(date, "01oct2013") 
global monthX = r(mean)

// normalize 
foreach x in int$main_p intOther ext$main_p extOther {
gen nn = commits_`x' if quarter_day == $monthX
egen mean = mean(nn)
gen norm_`x' = commits_`x'/mean
drop nn mean
} 

global t1 = "norm_extOther"
global t2 = "norm_ext${main_p}"

preserve
graph twoway ///
(connected $t2 quarter_day, msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///
(connected $t1 quarter_day, msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon)  ), ///
xline($monthX, lwidth(0.7))   ///
ytitle("International collaborations, normalized to Q4 2013",  size(small)) ///
xtitle("") title("")  ///
legend(label (1 "$Main-$P collaborations") ///
label ( 2 "$Main-Rest of World and $P-Rest of World collaborations") rows(2) position(6) )
graph export "$output/figures/desc_turnover_ext_total_${main_p}.pdf", replace
restore

