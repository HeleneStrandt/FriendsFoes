// baseline table for robustness
// prepare variables 
do "$codes/analysis/help/00_prep_analysis"

// ppml -- the same as poisson 
global controls = ""
*global controls = "log_new_projects log_new_users log_stars3m"
global fe = "c" // c - for region*time, cc - for country*time // results are very similar
global cluster = "month_day cc" 

foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2011,2018) 
*drop if region_author == "Other affected"
*drop if region_owner == "Other affected"
global varlist = "commits_int commit_user n_projects"
do "$codes/analysis/help/02_baseline"

keep if commits_int > 0
global varlist = "commit_project_user  commit_inten"
do "$codes/analysis/help/02_baseline"
restore 
graph combine commits_int.gph commit_user.gph commit_project_user.gph commit_inten.gph, rows(2) ///
ycommon xcommon ysize(3) xsize(5)
graph export "$output/tables/$name.pdf", replace

/*
// the same but keep only international commits 
global name = "intonly_$name"
foreach x in tex txt {
	capture erase "$output/tables/$name.`x'"
	}
preserve
keep if inrange(year, 2011,2018) & country_a != country_o
*drop if region_author == "Other affected"
*drop if region_owner == "Other affected"
global varlist = "commits_int commit_user n_projects"
do "$codes/analysis/help/02_baseline"

keep if commits_int > 0
global varlist = "commit_project_user  commit_inten"
do "$codes/analysis/help/02_baseline"
restore 
*/


// quarterly treatment effects, baseline 
do "$codes/analysis/help/centering_dl"

// treatment effect
preserve
keep if inrange(year, 2011,2018) 
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
global title1 = "Ukrainian contributions to Russia"
global title2 = "Russian contributions to Ukraine"
do "$codes/analysis/help/02_eventstudy"

global varlist = "commits_ext" //n_projects commits_int  commits_ext
global title1 = "Ukrainian contributions to Russia"
global title2 = "Russian contributions to Ukraine"
do "$codes/analysis/help/02_eventstudy"
restore



