// projects 
// geo data on project owner - could add 'type' and 'email' of owner later (org vs user)
cd "$path"

// forks
import delimited "$raw/forks_from_commits_uni.csv", bindquote(strict) clear

ren parent_project_id forked_from

replace country_code = "\N" if strlen(country_code) > 2
do "$codes/data prep/country_codes"

replace company = "" if company == "\N"
gen company_parent_owner = (!mi(company))
gen org_parent_owner = (type == "ORG")

gen dd = substr(created_at, 1, 8) + "01"
gen month = date(dd, "YMD", 2000)
format month %td
ren month month_parent_start
ren owner_id parent_owner_id
ren v15 longitude
renvars country_code city region location language deleted longitude lat, postfix("_parent_owner")

destring deleted, replace force
replace deleted = 0 if deleted > 1 // some mistakes in coding 

keep forked_from parent_owner_id language month deleted country_code org region ///
company_parent_owner city* location longitude lat
save forks, replace


import delimited "$raw/projects_from_commits_uni.csv", bindquote(strict) clear

gen dd = substr(created_at, 1, 8) + "01"
gen month = date(dd, "YMD", 2000)
format month %td
ren month month_project_start

replace company = "" if company == "\N"
gen company_owner = (!mi(company))
gen org_owner = (type == "ORG")

destring forked_from, replace force
destring deleted, replace force
replace deleted = 0 if deleted > 1 // some mistakes in coding 

replace country_code = "\N" if strlen(country_code) > 2

do "$codes/data prep/country_codes"

ren v18 longitude 
renvars country_code city location longitude lat language deleted,  postfix("_owner")

keep repo_id owner_id longitude lat location* city* language month forked deleted country_code org  ///
company_owner 

merge m:1 forked using forks
drop _merge

save projects_reg, replace


