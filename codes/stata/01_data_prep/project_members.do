// project members 
// extracted information on project membership for UA/RU/control users
// geo data are for project owners
cd "$path"

import delimited "$raw\projects_members_uni.csv", bindquote(strict) ///
 clear
 
gen dd = substr(created_at, 1, 8) + "01"
gen month = date(dd, "YMD", 2000)
format month %td

do "$codes/data prep/country_codes"

renvars country_code region, postfix("_owner_pm")
ren month month_pm

keep user_id repo_id country_code region month
bys user_id repo_id: gen n = _N
tab n
drop n
save project_members, replace
