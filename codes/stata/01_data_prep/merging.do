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
drop type created_at  ///
long* lat* login* name email region form_add mailto dd 

renvars country_code location* deleted country_code16 female identity ///
identity_mailru corporate_mail, postfix("_user")

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
foreach x in org language deleted country_code region {
replace `x'_owner = `x'_parent_owner if !mi(forked_from)
}
drop *parent*
replace forked_from = 0 if mi(forked_from)
replace forked_from = 1 if forked_from != 0

order repo_id user_id month commits

collapse (sum) commits_month ///
(firstnm) date_commit - region_owner, by(repo_id user_id month)

// merge with projects' stars and number of commits
// !! need to include forks !! 
merge m:1 repo_id month using projects_commits
drop if _merge ==2
drop _merge
replace project_commits_month = 0 if mi(project_commits_month)

merge m:1 repo_id month using projects_stars
drop if _merge == 2 
drop _merge 
ren stars_month project_stars_month
replace project_stars = 0 if mi(project_stars)

// merge with followers
// !! why so many unmerged from using ? 
merge m:1 user_id month using users_followers
drop if _merge == 2
drop _merge 
replace followers_month = 0 if mi(followers_month)

// final cleaninings
drop if mi(user_id) | mi(repo_id)
egen cc = group(repo_id user_id)
xtset cc month

// cumulatives: 
cap drop cum_*
bys repo_id month: gen first = (_n == 1)
bys repo_id: gen cum_stars = sum(first*project_stars)
bys repo_id: gen cum_commits = max(sum(first*project_commits),sum(first*commits_month))

drop first
bys user_id month: gen first = (_n == 1)
xtset cc month
bys user_id: gen cum_follwers = sum(first*followers_month)
drop first

save merged_full, replace


