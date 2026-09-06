// users

// merge single files together
cd "$raw/commits"
local files: dir . files "users_sample*"
local j = 1
foreach i in `files' {
import delimited "`i'", bindquote(strict)  varnames(1) stripquote(yes) encoding(UTF-8) clear
tempfile t`j'
save `t`j''
local j = `j' + 1
}
use `t1', replace 
foreach i of numlist 2/`j' {
append using `t`i'', force 
}

// 


foreach x in RU UA control {
import delimited "$raw/users_`x'2018uni.csv", bindquote(strict) ///
varnames(1) stripquote(yes) encoding(UTF-8) clear
ren v7 longitude
gen region = "`x'"
ren (v14-v20) (login16 company16 location16 country_code16 city16 long16 lat16)
save "users_`x'", replace
}

// 
use users_RU, replace
append using users_UA
append using users_control
duplicates drop
bys id: keep if _n == 1
save users, replace

// save users' ids from the sample (can be later used for merging)
// upload to the sqlite database
use users, replace
keep id login 
duplicates drop
bys id: keep if _n == 1

drop if mi(id)
export delimited using "$raw\users_ids.csv", replace


// assign identity based on names
do "$codes/users_names"

// assign identity based on location 
do "$codes/users_locations" 

// merge identity to user data 
use users, replace 
foreach x of varlist name location* {
replace `x' = lower(trim((`x')))
}
merge m:1 name using identity_names
drop _merge

merge m:1 location location16 using identity_locations
drop _merge

tab identity_location
tab identity_location16

ren identity identity_name
// 
foreach x in name location location16 {
gen identcode_`x' = 0 if region == "UA" & identity_`x' == "undef" | identity_`x' == "."
replace identcode_`x' = 1 if region == "UA" & identity_`x' == "UA"
replace identcode_`x' = -1 if region == "UA" & identity_`x' == "RU"
}

gen identity = identity_location16
replace identity = identity_name if mi(identity)
tab identity

// identify company users
replace company = lower(trim(company))
replace company16 = lower(trim(company16))
foreach x of varlist company* {
replace `x' = "" if `x' == "\n"
}

// company or organisation (ever was)
gen org = 0
replace org = 1 if type == "ORG" | !mi(company) | !mi(company16)

// extract email info 
replace email = "" if email == "\N"
gen mailto = substr(email, strpos(email, "@")+1, .)
tab mailto if region == "UA"
gen identity_mailru = (strpos(mailto, ".ru") > 0) if !mi(email) & region == "UA"
tab identity_mail
pwcorr identc* identity_mail

// personal email
replace mailto = lower(mailto) 
gen corporate_mail = 1 if !mi(email)
foreach x in inbox aol rambler icloud protonmail zoho net online outlook noreply.github mail.ru list.ru yandex gmail ///
gmx googlemail mail.ua hotmail yahoo ukr.net ua.fm meta.ua tut.by i.ua {
replace corporate_mail = 0 if strpos(mailto, "`x'") & !mi(email)
}
tab corporate

ren id user_id

save users_reg, replace

use users_reg, replace
// use old identity assignment
cap drop identity16
do "$codes/data_prep/identity_assign.do"

save users_reg, replace
keep user_id identity16
duplicates drop
save user_identities16










