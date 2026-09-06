// baseline regressions with hetoregeinty
set scheme white_w3d, perm

clear
set more off
cd "$processed"

import delimited for_regressionq_bl.csv, varnames(1) encoding(UTF-8) clear
do "$codes/analysis/help/00_prep_analysis"

// ppml -- the same as poisson 
global spec = ""
global controls = ""
global fe = "c" // c - for region*time, cc - for country*time // results are very similar
global cluster = "month_day cc"
x
global name = "02_baseline_ppml"
global name2 = ""
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2011,2018) 
global varlist = "commits_int commit_user n_projects"
do "$codes/analysis/help/02_baseline"

keep if commits_int > 0
global varlist = "commit_project_user  commit_inten"
do "$codes/analysis/help/02_baseline"
restore 
graph combine commits_int.gph commit_user.gph commit_project_user.gph commit_inten.gph, rows(2) ///
ycommon xcommon ysize(3) xsize(5)
graph export "$output/tables/$name.pdf", replace

// repeat the same but vary the control group
global name = "02_robustness_control" 
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
// repeat the estimates from the baseline estimation 
global varlist = "commits_int"
preserve
keep if inrange(year, 2011,2018)
global spec = "Baseline"
do "$codes/analysis/help/02_baseline"
restore 	
	
// only international commits 	
preserve
keep if inrange(year, 2011,2018) & country_a != country_o
global spec = "Only international"
do "$codes/analysis/help/02_baseline"
restore 

// without anonymous projects
// only international commits 	
preserve
keep if inrange(year, 2011,2018) & country_o != "Other countries" //& country_a != country_o
global spec = "No anonymous locations"
do "$codes/analysis/help/02_baseline"
restore 

// drop European countries
preserve
keep if inrange(year, 2011,2018) // & country_a != country_o
keep if inlist(country_author, "ua", "ru", "us", "br", "au", "ca", "cn", "in", "jp")
keep if inlist(country_owner, "ua", "ru", "us", "br", "au", "ca", "cn", "in", "jp")
global spec = "No European countries"
do "$codes/analysis/help/02_baseline"
restore 

// drop US and Canada
preserve
keep if inrange(year, 2011,2018) // & country_a != country_o
drop if inlist(country_author, "us", "ca")
drop if inlist(country_owner, "us", "ca")
global spec = "No US and Canada"
do "$codes/analysis/help/02_baseline"
restore 

// save results to a benchmark column for robustness to location 
// the rest of the table is in the end of this do file !
global name = "03_robustness_location"
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2011,2018)
global varlist = "commits_int"
global spec = "Baseline"
do "$codes/analysis/help/02_baseline"
restore 


// quarterly treatment effects, baseline 
do "$codes/analysis/help/centering_dl"
global name = "02_baseline"

// treatment effect
preserve
keep if inrange(year, 2011,2018) //& country_owner != "us" | country_author != "us"
*drop if region_author == "Other affected"
*drop if region_owner == "Other affected"
drop *_post_13 *_post_14 *_post_15 *_post_16 *_post_17 *_post_18 *_post_19 *_post_20  // replaced by t_after -- for brevety, but doesn't affect the results
*drop if country_author == country_owner 

global varlist = "commit_user" //n_projects commits_int  commits_ext
global title1 = "Ukrainian contributors to Russia"
global title2 = "Russian contributors to Ukraine"
do "$codes/analysis/help/02_eventstudy"

global varlist = "n_projects" //n_projects commits_int  commits_ext
global title1 = "Russian projects with UA contributors"
global title2 = "Ukrainian projects with RU contributors"
do "$codes/analysis/help/02_eventstudy"

global varlist = "commits_int" //n_projects commits_int  commits_ext
global title1 = "Ukrainian total commits to Russia"
global title2 = "Russian total commits to Ukraine"
do "$codes/analysis/help/02_eventstudy"

global varlist = "commits_ext" //n_projects commits_int  commits_ext
global title1 = "Ukrainian collaborations with Russia"
global title2 = "Russian collaborations with Ukraine"
do "$codes/analysis/help/02_eventstudy"
restore


// continue with location robustness

// ppml -- the same as poisson 
global controls = ""
global fe = "c" // c - for region*time, cc - for country*time // results are very similar
global cluster = "month_day cc"
global varlist = "commits_int"
global name = "03_robustness_location" 


// limit to only those where users who existed prior to 2014
import delimited for_regressionq_2013-s.csv, varnames(1) encoding(UTF-8) clear
do "$codes/analysis/help/00_prep_analysis"
preserve
keep if inrange(year, 2011,2018) 
global spec "Users added before 2014"
do "$codes/analysis/help/02_baseline"
restore
// we don't have ee-lt and ee-lv because the first conributions between these countries are in 2014

// fixed locations 
import delimited for_regressionq_2013.csv, varnames(1) encoding(UTF-8) clear
ren (cc2013_author cc2013_owner) (country_author country_owner )
do "$codes/analysis/help/00_prep_analysis"
preserve
keep if inrange(year, 2011,2018) 
global spec "Location as of 2013"
do "$codes/analysis/help/02_baseline"
restore
// check number of observations
// no commits in lv-by in addition to the previous 

// for users before 2014 who moved to another location 
import delimited for_regressionq_2013_movers.csv, varnames(1) encoding(UTF-8) clear
drop if (inlist(cc2013_author ,"ua", "ru") & stayer_a == 0) | (inlist(cc2013_owner ,"ua", "ru") & stayer_o == 0)
ren (cc2013_author cc2013_owner) (country_author country_owner)
do "$codes/analysis/help/00_prep_analysis"
preserve
keep if inrange(year, 2011,2018) 
global spec "Stayers only"
do "$codes/analysis/help/02_baseline"
restore










