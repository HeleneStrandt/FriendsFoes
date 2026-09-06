// general data prepartion file before the regression 

// drop donetsk-luhansk-crimea
foreach x in author owner {
drop if dlk_`x' == 1 & country_`x' == "ua"
tab dlk_`x'
}

// keep users from ua + ru + control group as authors
tab country_author
tab country_o
// condition: having either RU/UA or one of control countries at any point between 2012-2018, hence more countries
// not critical to keeping vs. dropping them 
gen sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(country_a, "`x'") 
}
tab sample
keep if sample == 1

// keep users from ua + ru + control group countries + "other countries" as owners
replace sample = 0
foreach x in ua ru us de gb fr ca au nl jp cn se in br it by cz lt lv ee pl {
replace sample = 1 if strpos(country_o, "`x'") 
}
tab sample
replace country_o = "Other countries" if sample == 0
tab country_o

// if country is anonym
/*
foreach x in country_author country_owner {
replace `x' = "Anonym" if mi(`x')
}
*/

// aggregate to a panel (because of Anonym countries)
collapse (sum) commits* n_*, by(country_o country_au month year)

// merge with region dummies (for fixed effects)
ren country_author country_code
do "$codes/data prep/help_country_codes"
renvars region, postfix("_author")
ren country_code country_author
tab country_author if region == "Control neutral"

ren country_owner country_code
do "$codes/data prep/help_country_codes"
renvars region, postfix("_owner")
ren country_code country_owner

gen date = date(string(year)+"-"+string(month)+"-"+"1", "YMD")
format date %td

sum commit*
gen commit_inten = commits_int/commits_ext
gen commit_user = n_authors
gen commit_inten_user = commits_int/n_authors
gen commit_project_user = commits_ext/n_authors

egen cc = group(country_author country_owner)

gen month_day = (mofd(date))
format month_day %tm //
xtset cc month_day 
tsfill, full

// merge with country-level activity for controls
ren country_owner country_code
merge m:1 country_code month year using sum_bycountry
drop if _merge == 2
xtset cc month_day 
foreach x of varlist new_projects new_users stars {
replace `x' = 0 if mi(`x')
gen `x'3m = `x' + l.`x' + l2.`x'
}
ren country_code country_owner

drop _merge

xtset cc month_day
foreach y of numlist -11/11 {
foreach x in country_owner country_author region_owner region_author {
bys cc: replace `x' = `x'[_n+`y'] if missing(`x')
bys cc: replace `x' = `x'[_n-`y'] if missing(`x')
}
}
foreach x of varlist commit* n_projects {
replace `x' = 0 if mi(`x')
}
gen yy = substr(string(month_day, "%tm"), 1, 4)
destring yy, replace
replace year = yy if mi(year)
drop yy
g yy = substr(string(month_day, "%tm"), 6, .)
destring yy, replace
replace month = yy if mi(month)
drop yy
replace date = date(string(year)+"-"+string(month)+"-"+"1", "YMD") if mi(date)


xtset cc month_day
sum month_day if strpos(string(month_day, "%tm"), "2013m12") 
global monthX = r(mean)

gen post = (month_day >=$monthX)

// UA-RU collaborations
gen ru_project = (region_owner == "RU")
gen ua_user = (region_author == "UA")
gen ua_ru_post = ua_user*ru_project*post

// RU-UA collaborations
gen ua_project = (region_owner == "UA")
gen ru_user = (region_author == "RU")
gen ru_ua_post = ru_user*ua_project*post

// Other affected countries to RU (negative attitudes toward RU as well)
gen antiru_user = (region_author == "Other affected")
gen antiru_project = (region_owner == "Other affected")

gen antiru_ru_post = antiru_user*ru_project*post
gen ru_antiru_post = antiru_project*ru_user*post

// joint ua_ru_post
gen joint_ua_ru_post = ua_ru_post + ru_ua_post

foreach x of varlist new_projects3m new_users3m stars3m commit* {
gen log_`x' = log(`x' + 1)
}

*lab var ru_post "RU*Post"
lab var ua_ru_post "UA-RU $\times$ Post 2013"
lab var joint_ua_ru_post "UA-RU or RU-UA $\times$ Post 2013"
*lab var ua_post "UA*Post"
lab var ru_ua_post "RU-UA $\times$ Post 2013"
lab var antiru_ru_post "Other affected - RU $\times$ Post 2013"
lab var ru_antiru_post "RU - Other affected $\times$ Post 2013"
lab var log_new_projects "New projects, 3m"
lab var log_new_users "New users, 3m"
lab var log_stars "Stars, 3m" 
lab var commits_ext "Contributions"
lab var commit_inten "Commits, per user-project"
lab var commits_int "Commits, total"
lab var commit_user "Unique, contributors"
lab var commit_inten_user "Contributions, per user"
lab var commit_project_user "Projects, per user"
lab var n_projects "Unique, projects"

encode region_author, gen(user_c)
encode region_owner, gen(owner_c) 

encode country_author, gen(user_cc)
encode country_owner, gen(owner_cc) 

set matsize 800 //10000
tab year
