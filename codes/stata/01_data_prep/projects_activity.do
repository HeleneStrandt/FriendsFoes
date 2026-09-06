// projects_activity
// counts the number of stars and comments each project receives by month
cd "$path"

foreach  x in 1 2 {
import delimited "$raw\projects_from_commits_commits`x'.csv", bindquote(strict) clear
save projects_from_commits_commits`x', replace
}
append using projects_from_commits_commits1

gen date = datecommits2017
replace date = datecommitsc if mi(date)
gen month = date(date, "YMD", 2000)
format month %td
gen year = year(month)
keep if inrange(year, 2008, 2018)
drop datec*

destring repo_id, replace force
duplicates drop 

bys repo_id month: gen n = _N
bys repo_id month: egen max = max(commits)
keep if commits_month == max
drop n max

xtset repo_id month
bys repo_id: gen cum_commits = sum(commits)
ren commits_month project_commits_month

save projects_commits, replace

import delimited "$raw\watchers_from_commits_uni.csv", bindquote(strict) clear
ren project_id repo_id
gen month = date(date, "YMD", 2000)
format month %td
gen year = year(month)
keep if inrange(year, 2008, 2018)
tab year
duplicates drop

collapse (sum) watchers_month, by(repo_id month) 
ren watchers_month stars_month

xtset repo_id month
bys repo_id: gen cum_stars = sum(stars_month)

save projects_stars, replace






