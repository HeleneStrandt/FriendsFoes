// merging commits - users - projects info for regression // 
cd "$path"

use commits_ghtorrent, replace

// merge with user information 
merge m:1 user_id using users_reg
keep if _merge == 3
drop _merge

gen dd = substr(created_at, 1, 8) + "01"
gen month_user_start = date(dd, "YMD", 2000)
format month_user %td

cap drop org_user company_user
gen company_user = (!mi(company) | !mi(company16))
gen org_user = (type == "ORG")

*drop irrelevant vars for now
drop type created_at  login* name email region form_add mailto dd 

renvars country_code location city lat longitude deleted country_code16 female identity ///
identity_mailru corporate_mail, postfix("_user")

keep if user_region == "RU"
drop if city_user == "\N" 

replace city_user = "St. Petersburg" if strpos(city_user, "Peters")

ren commits_month commits

/* get only activity of RU users by city  
preserve
collapse (sum) commits (firstnm) longitude_user lat_user , by(year city_user)
sort city* year
order year city_user longitude lat  commits
export excel using "ru_activity_cities.xls", firstrow(variables) replace
restore
*/

// merge with projects information 
merge m:1 repo_id using projects_reg
keep if _merge == 3
drop _merge

// in commits, repo_id is the first repo where the commits are submitted 
// in the pull-workflow, users submit commits to cloned repos, not to the central one
// if a repo was forked, instead of repo_id and all other project info, use
// info on forks

replace repo_id = forked_from if !mi(forked_from)
replace month_project_start = month_parent_start if !mi(forked_from)
replace owner_id = parent_owner_id if !mi(forked_from)
foreach x in longitude lat org language deleted country_code region city {
replace `x'_owner = `x'_parent_owner if !mi(forked_from)
}
drop *parent*
replace forked_from = 0 if mi(forked_from)
replace forked_from = 1 if forked_from != 0

drop if user_id == owner_id // only different people 
keep if user_region == "RU" & region_owner == "RU"
count
drop if city_user == "\N" | city_owner == "\N"

replace city_owner = "St. Petersburg" if strpos(city_owner, "Peters")


collapse (sum) commits (firstnm) longitude_user lat_user longitude_owner lat_owner, ///
by(city_user city_owner year)

order year *_owner *_user commits
sort *_owner *_user year

export excel using "ru_connection_cities.xls", firstrow(variables)replace


