// summary stats by country code
// number of new projects and number of new watchers

global output = "$path\output"
global raw = "$path\database\extractions"
cd "$path\database\stata"

*sum_bycountry will include country_code, year, month, n of new users, n of new projects, n of received stars
// watchers aka stars to projects
import delimited "$raw\sum_watchers.csv", bindquote(strict) delimiter("|") clear
drop if mi(owner_country, month, year)
collapse (sum) watchers, by(owner_country month year)

// run together until the merge is done
preserve 
// projects
foreach x in projects users {
import delimited "$raw\sum_`x'_country.csv", bindquote(strict) delimiter("|") clear
ren first_country owner_country
drop if mi(owner_country, month, year)
tempfile t`x'
save `t`x''
}
restore 
foreach x in projects users {
merge 1:1 owner_country month year using `t`x''
drop _merge
}
// run until here 
//
keep if inrange(year, 2008, 2018)

order owner_country year month new_projects new_users watchers
ren watchers stars
gen d = string(year)+"/"+string(month)+"/"+"01"
gen date = date(d, "YMD")
format date %td
drop d 

cap drop cum*
sort owner_country date, stable
foreach x in projects users {
bys owner_country: gen cum_`x' = sum(new_`x')
}

foreach x in new_pr new_u stars {
replace `x' = 0 if mi(`x')
}

ren owner_country country_code
save sum_bycountry, replace

use sum_bycountry, replace
do "$codes/data prep/help_country_codes"
renvars region1 region2, postfix("_owner")

collapse (sum) new_projects new_users stars, by(region2_owner month year)
save sum_byregion, replace














