// individual level regressions
cd "$processed"
set more off

// use full set of control countries
import delimited for_regression_p2c_ru_301125-dlk.csv, varnames(1) encoding(UTF-8) clear // for one specification that includes dlk

*import delimited for_regression_p2c_ru_050623-3ua.csv, varnames(1) encoding(UTF-8) clear 
// nobs = 4981128

// Strongly balanced panel
egen cc = group(author_id country_owner company_owner)
xtset cc year 

sort author_id country_owner company_owner year

// fill missing with zero
foreach x in n_owners n_projects commits_int commits_ext total_followers_pre2014 followers_ru_pre2014 followers_ua_pre2014 total_stars_pre2014 stars_ru_pre2014 stars_ua_pre2014 contributors ua_contributors ru_contributors {
replace `x' = 0 if mi(`x') 
}

// set cumulative commtis to the previous non-missing period for those who are inactive (later years)
xtset cc year
foreach x in commits_cum owners_cum countries_cum stars_cum {
replace `x' = l.`x' if mi(`x')
}

// set cumulative commits to zero if the person was still inactive (earlier years)
foreach x in commits_cum owners_cum countries_cum stars_cum {
replace `x' = 0 if mi(`x')
}

sum commits_cum owners_cum countries_cum stars_cum

// note: for some users, their locations within Ukraine can be missing if they moved to another country

// fill company_author because it is available only if a person is an active user 
encode country_owner, gen(cp)

gen country_owner_forFE = country_owner
replace country_owner_forFE = "ua" if (country_owner_forFE == "ua_central" | country_owner_forFE == "ua_west" | country_owner_forFE == "ua_east")
tab country_owner_forFE
tab country_owner if country_owner_forFE == "ua"
encode country_owner_forFE, gen(FE_cp)

bys author_id year: egen m = max(company_author)
replace company_author = m if mi(company_author)
tab company_author 
drop m 
bys author_id: egen m = max(company_author)
replace company_author = m if mi(company_author)
drop m

gen post = (year > 2013)

// UA-RU collaborations (overall)
gen ua_project = (strpos(country_owner, "ua"))
gen ua_post = ua_project*post

// Probability to work with a Russian 
gen ua_commit = (commits_int > 0) if strpos(country_owner, "ua")
bys author_id year: egen total_activity = sum(commits_int) // note that here we count total activity with other users, excludes self-commits
bys author_id year: egen total_activity_ua = sum(commits_int) if ua_project == 1
bys author_id year: gen n = _n
gen country_b = country_owner
replace country_b = "ua" if strpos(country_owner, "ua")
bys author_id year country_b: gen nua = _n 
gen active = (total_activity > 0)

sum total_activity if year < 2014 & n == 1 & active == 1
sum total_activity_ua if year < 2014 & nua == 1 & country_b == "ua" & active==1

gen gh_exper = year - year_created_a

lab var ua_post "RU-UA $\times$ Post 2013"
lab var commits_int "Commits, total"
lab var n_owners "Unique, project owners"
lab var n_projects "Unique, projects"
lab var commits_ext "Commits, extensive"
lab var ua_commit "Any commit to RU" //use only within UA



foreach x of varlist *cum total_activity {
cap gen log`x' = log(`x'+1)
}
foreach x of varlist *cum total_activity {
cap gen as`x' = asinh(`x')
}
compress, nocoalesce


****************************************************
// heterogeneity analysis  

*location 
foreach x in ua_west ua_east ua_central {
	gen `x' = (country_owner == "`x'") 
}

*company_owner - defined

* worked with ukrainians before 
bys author_id: egen m_c = max(commits_int) if year < 2014 & strpos(country_owner,"ua") 
bys author_id: egen com_ua = mean(m_c)
gen contributed_ua = (com_ua > 0 & !mi(com_ua)) if year_created_a < 2014
drop m_c com_ua

* productivity before 2014 
bys author_id: egen m_c = max(commits_cum) if year == 2013
xtile user_coms = m_c if m_c > 0, nq(3)
tab user_coms, gen(uc)

foreach x in 1 2 3 {
replace uc`x' = 0 if m_c == 0
bys author_id: egen prod`x' = mean(uc`x') 
}
drop m_c user_coms

* popularity before 2014
bys author_id: egen m_c = max(stars_cum) if year == 2013
xtile user_coms = m_c if m_c > 0, nq(3)
tab user_coms, gen(us)

foreach x in 1 2 3 {
replace us`x' = 0 if m_c == 0
bys author_id: egen stars`x' = mean(us`x') 
}
drop m_c user_coms
drop uc* us*

global hetero = "ua_west ua_central ua_east company_owner contributed_ua prod1 prod2 prod3 stars1 stars2 stars3"

gen followers_ua = (followers_ua_pre2014 > 0)
gen followers_ru = (followers_ru_pre2014 > 0)
gen stars_ua = (stars_ua_pre2014 > 0)
gen stars_ru = (stars_ru_pre2014 > 0)
gen contributors_ua = (ua_contributors > 0)
gen contributors_ru = (ru_contributors > 0) 
global network = "followers_ua followers_ru stars_ua stars_ru contributors_ua contributors_ru"

cap drop post_*
foreach x of varlist $hetero $network {
cap gen post_`x' = post*`x'
cap gen post_ua_`x' = ua_post*`x' 
}

* label baseline heterogeneity vars
label var post_ua_ua_west "West UA $\times$ Post 2013"
label var post_ua_ua_central "Kiev/Central UA $\times$ Post 2013"
lab var post_ua_company_owner "To company $\times$ UA $\times$ Post 2013"
lab var post_ua_contributed_ua "Contributed to UA $\times$ UA $\times$ Post 2013"
foreach x in 1 2 3 {
lab var post_ua_prod`x' "Productivity `x'. $\times$ UA $\times$ Post 2013"
lab var post_ua_stars`x' "Stars `x'. $\times$ UA $\times$ Post 2013"
}

* label network heterogeneity vars
//lab var post_ru_total_followers_pre2014 "Followers pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ua_followers_ru "RU followers pre 2014 $\times$ UA $\times$ Post 2013"
lab var post_ua_followers_ua "UA followers pre 2014 $\times$ UA $\times$ Post 2013"
//lab var post_ua_total_stars_pre2014 "Watchers pre 2014 $\times$ UA $\times$ Post 2013"
lab var post_ua_stars_ru "RU Watchers pre 2014 $\times$ UA $\times$ Post 2013"
lab var post_ua_stars_ua "UA Watchers pre 2014 $\times$ UA $\times$ Post 2013"
//lab var post_ua_contributors "Contributors pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ua_contributors_ua "UA contributors pre 2014 $\times$ UA $\times$ Post 2013"
lab var post_ua_contributors_ru "RU contributors pre 2014 $\times$ UA $\times$ Post 2013"


compress, nocoalesce

global outcomes = "commits_int"

global name = "03_individual_ppml_ru"

foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}

global controls = "company_author" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global fe = "year#company_owner FE_cp#year FE_cp#company_owner" // year#company_owner cp#year cp#company_owner,  author_id#c.year or without cp##post -- not really changes much
global cluster = "author_id"
global hetero = "post_ua_ua_west post_ua_ua_central post_ua_company_owner"
global keepvar = "post_ua_ua_west post_ua_ua_central"
global sortvar = "post_ua_ua_west post_ua_ua_central post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru post_ua_company_owner post_ua_contributed_ua post_ua_prod1 post_ua_prod2 post_ua_prod3 post_ua_stars1 post_ua_stars2 post_ua_stars3"

/*
// restrict to users who existed before 
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ru"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y'  ua_post $hetero /// 
$controls, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ua if year < 2014 & country_b == "ua" & nua == 1
scalar y_mean_ua = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', RU to UA") ///
addtext("post_ua_company_owner","Yes", "post_ua_contributed_ua","", ///
            "post_ua_prod1","", "post_ua_prod2","", "post_ua_prod3","", ///
            "post_ua_stars1","", "post_ua_stars2","", "post_ua_stars3","") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to UA, y_mean_ua) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 
*/

set more off
// add contributed before 
global controlsr = "post_contributed_ua" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ua_ua_west post_ua_ua_central post_ua_company_owner post_ua_contributed_ua"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ru"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ua if year < 2014 & country_b == "ua" & nua == 1
scalar y_mean_ua = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', RU to UA") alpha(0.001, 0.01, 0.05) ///
addtext("post_ua_company_owner","Yes", "post_ua_contributed_ua","Yes", ///
            "post_ua_prod1","", "post_ua_prod2","", "post_ua_prod3","", ///
            "post_ua_stars1","", "post_ua_stars2","", "post_ua_stars3","") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to UA, y_mean_ua) nonotes label nocons
//addtext(FE, $fe)
}
restore 


set more off
// add productivity
global controlsr = "post_contributed_ua post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ua_ua_west post_ua_ua_central post_ua_company_owner post_ua_contributed_ua post_ua_prod1 post_ua_prod2 post_ua_prod3 post_ua_stars1 post_ua_stars2 post_ua_stars3"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ru"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ua if year < 2014 & country_b == "ua" & nua == 1
scalar y_mean_ua = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', RU to UA") alpha(0.001, 0.01, 0.05) ///
addtext("post_ua_company_owner","Yes", "post_ua_contributed_ua","Yes", ///
            "post_ua_prod1","Yes", "post_ua_prod2","Yes", "post_ua_prod3","Yes", ///
            "post_ua_stars1","Yes", "post_ua_stars2","Yes", "post_ua_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to UA, y_mean_ua) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


// add network
global controlsr = "post_contributed_ua post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ua_followers_ua post_ua_followers_ru post_ua_stars_ua post_ua_stars_ru post_ua_contributors_ua post_ua_contributors_ru post_ua_company_owner post_ua_contributed_ua post_ua_prod1 post_ua_prod2 post_ua_prod3 post_ua_stars1 post_ua_stars2 post_ua_stars3"
global keepvar = "post_ua_ua_west post_ua_ua_central post_ua_followers_ua post_ua_followers_ru post_ua_stars_ua post_ua_stars_ru post_ua_contributors_ua post_ua_contributors_ru"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ru"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ua if year < 2014 & country_b == "ua" & nua == 1
scalar y_mean_ua = r(mean)

outreg2 using "$output/tables/${name}.tex", append tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', RU to UA") alpha(0.001, 0.01, 0.05) ///
addtext("post_ua_company_owner","Yes", "post_ua_contributed_ua","Yes", ///
            "post_ua_prod1","Yes", "post_ua_prod2","Yes", "post_ua_prod3","Yes", ///
            "post_ua_stars1","Yes", "post_ua_stars2","Yes", "post_ua_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to UA, y_mean_ua) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


// include west/east and network
global controlsr = "post_contributed_ua post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ua_ua_west post_ua_ua_central post_ua_followers_ua post_ua_followers_ru post_ua_stars_ua post_ua_stars_ru post_ua_contributors_ua post_ua_contributors_ru post_ua_company_owner post_ua_contributed_ua post_ua_prod1 post_ua_prod2 post_ua_prod3 post_ua_stars1 post_ua_stars2 post_ua_stars3"
global keepvar = "post_ua_ua_west post_ua_ua_central post_ua_followers_ua post_ua_followers_ru post_ua_stars_ua post_ua_stars_ru post_ua_contributors_ua post_ua_contributors_ru"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ru"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ua if year < 2014 & country_b == "ua" & nua == 1
scalar y_mean_ua = r(mean)

outreg2 using "$output/tables/${name}.tex", append tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', RU to UA") alpha(0.001, 0.01, 0.05) ///
addtext("post_ua_company_owner","Yes", "post_ua_contributed_ua","Yes", ///
            "post_ua_prod1","Yes", "post_ua_prod2","Yes", "post_ua_prod3","Yes", ///
            "post_ua_stars1","Yes", "post_ua_stars2","Yes", "post_ua_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to UA, y_mean_ua) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


// add a specification that includes commits from dlk too -- no qualitative changes 
// open the file --dlk.csv and run all transformations + the last regression 

*http://eprints.lse.ac.uk/90298/  -- data on protests in Russia by city 2007-16

