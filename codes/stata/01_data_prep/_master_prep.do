// data prep
* Project root
global root "`c(pwd)'"

* Data
global path         "$root/database"
global raw          "$root/database/extractions"
global processed    "$root/database/stata"

* Output
global output       "$root/output"
global figures      "$root/output/figures"
global tables       "$root/output/tables"

* Code
global codes	    "$root/code/stata"


cd "$processed"


// prepare summary stat on stars, projects and users by country code
// will be used for summary stats and for controls
do "$codes/01_data_prep/01_summary_country"
* output: sum_bycountry

// prepare users 
do "$codes/01_data_prep/02_users" 
* output: users_reg

// prepare UA users for heterogeneity analysis
//do "$codes/data prep/02_users_ua"
* called within: geocoding, ukraine_prep (still has to be checked and updated)
* called within: help_users_names and help_users_locations to assign identities

// prepare projects, inlc. forked projects
do "$codes/01_data_prep/03_projects" 
* output: projects_reg

// prepare data on followers of users in the sample
// later for user-level
do "$codes/01_data_prep/04_users_followers"
* output: users_followers

// prepare data on project membership of users in the sample
// later for user-level
do "$codes/01_data_prep/05_project_members"
* output: project_members

// prepare data on stars and commits to projects in the sample
// later for project-level
do "$codes/01_data_prep/06_projects_activity"
* output: projects_commits and projects_stars

// merge everything and prepare for regression
do "$codes/01_data_prep/07_merging"
* output: for_regression 









