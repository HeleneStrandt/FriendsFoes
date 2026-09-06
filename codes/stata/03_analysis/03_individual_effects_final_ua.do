// individual level regressions
set more off
cd "$processed"

// use data set with full set of control countries, regressions take a while
import delimited for_regression_p2c_ua_251125.csv, varnames(1) encoding(UTF-8) clear 

// Balanced panel (no expand necessary bc done in python, "unbalanced" bc users join in different years)
egen cc = group(author_id country_owner company_owner)
xtset cc year 
bys author_id: egen m  = max(dlk) // anytime dlk
tab m
drop if m == 1
drop m dlk

// fill missing with zero
foreach x in n_owners n_projects commits_int commits_ext total_followers_pre2014 followers_ru_pre2014 followers_ua_pre2014 total_stars_pre2014 stars_ru_pre2014 stars_ua_pre2014 contributors ua_contributors ru_contributors  {
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

// note: for some users, their locations within Ukraine can be missing if they moved to another country (not an issue for users with fixed locations)

// fill company_author because it is available only if a person is an active user 
bys author_id year: egen m = max(company_author)
replace company_author = m if mi(company_author)
tab company_author 
drop m 
bys author_id: egen m = max(company_author)
replace company_author = m if mi(company_author)
drop m

// fill ru_identity (can be missing if an individual moves out of ukraine)
bys author_id: egen m = mode(ru_identity), maxmode
replace ru_identity = m if mi(ru_identity)
drop m

gen post = (year > 2013)

// UA-RU collaborations
gen ru_project = (country_owner == "ru")
gen ru_post = ru_project*post

encode country_owner, gen(cp) 

// Probability to work with a Russian 
gen ru_commit = (commits_int > 0) if country_owner == "ru"
bys author_id year: egen total_activity = sum(commits_int) // note that here we count total activity with other users, excludes self-commits
bys author_id year: egen total_activity_ru = sum(commits_int) if country_o == "ru"
bys author_id year: gen n = _n
bys author_id year cp: gen nru = _n 
gen active = (total_activity > 0)

sum total_activity if year < 2014 & n == 1
sum total_activity_ru if year < 2014 & nru == 1 & country_o == "ru" 

gen gh_exper = year - year_created_a

lab var ru_post "UA-RU $\times$ Post 2013"
lab var commits_int "Commits, total"
lab var n_owners "Unique, project owners"
lab var n_projects "Unique, projects"
lab var commits_ext "Commits, extensive"
lab var ru_commit "Any commit to RU" //use only within UA


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
gen west_ua = (ru_identity == 0) 
gen kiev_central = (ru_identity == 0.5) 

*company_owner - defined

*name
gen ua_name = (ethnicities == "ukrainian") 
gen ru_name = (ethnicities == "russian") 
gen no_name = (ua_name+ru_name ==0)  // neutral names + those without any name
sum *name 

* worked with russians before 
bys author_id: egen m_c = max(commits_int) if year < 2014 & country_owner == "ru" 
bys author_id: egen com_ru = mean(m_c)
gen contributed_ru = (com_ru > 0 & !mi(com_ru)) if year_created_a < 2014
drop m_c com_ru

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

gen language_ua = 100-language_ru
sum language_ua

global hetero = "west_ua kiev_central language_ru language_ua russians company_owner ua_name ru_name contributed_ru prod1 prod2 prod3 stars1 stars2 stars3"

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
cap gen post_ru_`x' = ru_post*`x' 
}

* label baseline heterogeneity vars
lab var post_ru_west_ua "West UA $\times$ RU $\times$ Post 2013"
lab var post_ru_kiev_central "Kiev/Central UA $\times$ RU $\times$ Post 2013"
lab var post_ru_language_ru "Share Russian speakers  $\times$ RU $\times$ Post 2013" 
lab var post_ru_russians "Share Russians $\times$ RU $\times$ Post 2013"
lab var post_ru_language_ua "Share Ukrainian speakers $\times$ RU $\times$ Post 2013" 
lab var post_ru_ua_name "UA name $\times$ RU $\times$ Post 2013"
lab var post_ru_ru_name "RU name $\times$ RU $\times$ Post 2013"
lab var post_ru_company_owner "To company $\times$ RU $\times$ Post 2013"
lab var post_ru_contributed_ru "Contributed to RU $\times$ RU $\times$ Post 2013"
foreach x in 1 2 3 {
lab var post_ru_prod`x' "Productivity `x'. $\times$ RU $\times$ Post 2013"
lab var post_ru_stars`x' "Stars `x'. $\times$ RU $\times$ Post 2013"
}

* label network heterogeneity vars
//lab var post_ru_total_followers_pre2014 "Followers pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_followers_ru "RU followers pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_followers_ua "UA followers pre 2014 $\times$ RU $\times$ Post 2013"
//lab var post_ru_total_stars_pre2014 "Watchers pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_stars_ru "RU Watchers pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_stars_ua "UA Watchers pre 2014 $\times$ RU $\times$ Post 2013"
//lab var post_ru_contributors "Contributors pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_contributors_ua "UA contributors pre 2014 $\times$ RU $\times$ Post 2013"
lab var post_ru_contributors_ru "RU contributors pre 2014 $\times$ RU $\times$ Post 2013"

encode district_en, gen(geo)

compress, nocoalesce

global outcomes = "commits_int"

global name = "03_individual_ppml_ua"
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}


// allow to identify the effect for RU*post (excludes year#cp FEs)
/*
global controls = "company_author gh_exper" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global fe = "year geo#post geo#cp cp#company_owner" // without cp##post -- not really changes much
global cluster = "author_id"
global hetero = "post_ru_west_ua post_ru_kiev_central"

foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' ru_post $hetero /// 
$controls, absorb($fe) cluster($cluster)
outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep(ru_post $hetero) sortvar(ru_post $hetero)  ctitle("`lab', UA to RU") ///
addstat(Unique users, e(N_clust), Pseudo R2, e(r2_p)) nonotes label nocons ///
addtext(FE, $fe)
}
*/

// focus on active users only 
// with stricter fixed effects 
//egen cp_x_year = group(cp year) // use cp#year

//global controls = "company_author" // post_company_owner l.ascommits_cum l.asowners_cum l.ascountries_cum"
global controls = ""
global fe = "year#company_owner geo#year geo#cp cp#year cp#company_owner" // cc year geo#post geo#cp cp#post cp#company_owner // year or without cp##post -- not really changes much
//global fe = "author_id#cp year#cp author_id#year" // too many obs serparated
global cluster = "author_id" //
global hetero = "post_ru_west_ua post_ru_kiev_central post_ru_company_owner"
global keepvar = "post_ru_west_ua post_ru_kiev_central"
global sortvar = "post_ru_west_ua post_ru_kiev_central post_ru_language_ua post_ru_ua_name post_ru_ru_name post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru post_ru_company_owner post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3" 


********* start heterogeneity regressions
set more off
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ua" 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe $outcomes $hetero /// 
$controls, absorb($fe) cluster($cluster)


sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', UA to RU") alpha(0.001, 0.01, 0.05) ///
addtext("post_ru_company_owner","Yes", "post_ru_contributed_ru","Yes",  ///
            "post_ru_prod1","", "post_ru_prod2","", "post_ru_prod3","", ///
            "post_ru_stars1","", "post_ru_stars2","", "post_ru_stars3","") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 
x
// restrict to users who existed before // in addition control for productivity  
global controlsr = "post_contributed_ru post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ru_west_ua post_ru_kiev_central post_ru_company_owner post_ru_contributed_ru post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3"
global keepvar = "post_ru_west_ua post_ru_kiev_central post_ru_contributed_ru"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ua"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)


sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar)  ctitle("`lab', UA to RU") alpha(0.001, 0.01, 0.05) ///
addtext("post_ru_company_owner","Yes", "post_ru_contributed_ru","Yes", ///
            "post_ru_prod1","Yes", "post_ru_prod2","Yes", "post_ru_prod3","Yes", ///
            "post_ru_stars1","Yes", "post_ru_stars2","Yes", "post_ru_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


// alternative way to measure identity: share of ukrainian speakers and name
global controlsr = "post_ua_name post_ru_name post_contributed_ru post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ru_language_ua post_ru_ua_name post_ru_ru_name post_ru_company_owner post_ru_contributed_ru post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3"
global keepvar = "post_ru_language_ua post_ru_ua_name post_ru_ru_name"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ua" 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar( $sortvar) ctitle("`lab', UA to RU") alpha(0.001, 0.01, 0.05) ///
addtext("post_ru_company_owner","Yes", "post_ru_contributed_ru","Yes", ///
            "post_ru_prod1","Yes", "post_ru_prod2","Yes", "post_ru_prod3","Yes", ///
            "post_ru_stars1","Yes", "post_ru_stars2","Yes", "post_ru_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


// network heterogeneity analysis
// alternative way to measure identity: share of ukrainian speakers and name
global controlsr = "post_contributed_ru post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru post_ru_company_owner post_ru_contributed_ru post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3"
global keepvar = "post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ua" 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', UA to RU") alpha(0.001, 0.01, 0.05) ///
addtext("post_ru_company_owner","Yes", "post_ru_contributed_ru","Yes", ///
            "post_ru_prod1","Yes", "post_ru_prod2","Yes", "post_ru_prod3","Yes", ///
            "post_ru_stars1","Yes", "post_ru_stars2","Yes", "post_ru_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


***** west/east and social network in one regression 
global controlsr = "post_contributed_ru post_prod1 post_prod2 post_prod3 post_stars1 post_stars2 post_stars3" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global hetero = "post_ru_west_ua post_ru_kiev_central post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru post_ru_company_owner post_ru_contributed_ru post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3"
global keepvar = "post_ru_west_ua post_ru_kiev_central post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru"
preserve 
keep if total_activity > 0 & year_created_a < 2014 & cc2013 == "ua" 
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar)  ctitle("`lab', UA to RU") alpha(0.001, 0.01, 0.05) ///
addtext("post_ru_company_owner","Yes", "post_ru_contributed_ru","Yes", ///
            "post_ru_prod1","Yes", "post_ru_prod2","Yes", "post_ru_prod3","Yes", ///
            "post_ru_stars1","Yes", "post_ru_stars2","Yes", "post_ru_stars3","Yes") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 



x
**** for Appendix: include year cc FEs, report ru_post, provide estimates for West/Central and names
global name = "03_individual_ppml_ua_ccFE"
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}

global controls = "post_company_owner company_author" // l.ascommits_cum l.asowners_cum l.ascountries_cum"
global fe = "year cc" // cc year geo#post geo#cp cp#post cp#company_owner // year or without cp##post -- not really changes much
global cluster = "author_id" //
global hetero = "post_ru_west_ua post_ru_kiev_central post_ru_company_owner"
global keepvar = "ru_post post_ru_west_ua post_ru_kiev_central"
global sortvar = "ru_post post_ru_west_ua post_ru_kiev_central post_ru_language_ua post_ru_ua_name post_ru_ru_name post_ru_followers_ua post_ru_followers_ru post_ru_stars_ua post_ru_stars_ru post_ru_contributors_ua post_ru_contributors_ru post_ru_company_owner post_ru_prod1 post_ru_prod2 post_ru_prod3 post_ru_stars1 post_ru_stars2 post_ru_stars3" 

cap drop active_cc
bysort cc: egen active_cc = sum(commits_int) // drop cc units that are 0 in each year
preserve 
keep if active_cc > 0 & year_created_a < 2014 & cc2013 == "ua"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' ru_post $hetero /// 
$controls, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($keepvar) sortvar($sortvar) ctitle("`lab', UA to RU") ///
addtext("post_ru_company_owner","Yes",  ///
            "post_ru_prod1","", "post_ru_prod2","", "post_ru_prod3","", ///
            "post_ru_stars1","", "post_ru_stars2","", "post_ru_stars3","") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
//addtext(FE, $fe)
}
restore 


x
**** re-run heterogeneity by region, previous specification 
// 
global name = "03_individual_hetero_ppml_ua"
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}

// west
preserve 
keep if ru_identity == 0 & year_created_a < 2014 & cc2013 == "ua" & total_activity > 0    //& country_owner != "ua"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' ru_post $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($hetero) sortvar($sortvar) ctitle("`lab', West") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
addtext(FE, $fe)
}
restore 

// central/kiev
preserve 
keep if ru_identity == 0.5 & year_created_a < 2014 & cc2013 == "ua" & total_activity > 0  //& country_owner != "ua"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' ru_post $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($hetero) sortvar($sortvar) ctitle("`lab', Kyiv/Ukraine") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
addtext(FE, $fe)
}
restore 

//East
preserve 
keep if ru_identity == 1 & year_created_a < 2014 & cc2013 == "ua" & total_activity > 0  //& country_owner != "ua"
foreach y of varlist $outcomes {
local lab: var label `y'
ppmlhdfe `y' ru_post $hetero /// 
$controls $controlsr, absorb($fe) cluster($cluster)

sum total_activity if year < 2014 & n == 1
scalar y_mean = r(mean)

sum total_activity_ru if year < 2014 & country_o == "ru" & nru == 1
scalar y_mean_ru = r(mean)

outreg2 using "$output/tables/${name}.tex", append  tex(frag) ///
keep($hetero) sortvar($sortvar) ctitle("`lab', East") ///
addstat(Pseudo R2, e(r2_p), Unique users, e(N_clust), Mean commits, y_mean, Mean commits to RU, y_mean_ru) nonotes label nocons ///
addtext(FE, $fe)
}
restore 


*******************************************************************************************************
// repeat the same for russians (idea: distinguish between west, east and kyiv/rest of ukraine) 
// or try to distinguish whether a city had a did not have protests between 2007 and 2012 (except for Moscow and St. Petersburg)






