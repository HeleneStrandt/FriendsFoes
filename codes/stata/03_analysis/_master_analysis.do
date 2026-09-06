// master file for analysis
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

// 1. Descriptives 
// Figure 1 (attitudes of Ukraine/Russia) and Figure XX (attitudes within Ukraine)
// KSIS data
do "$codes/03_analysis/01_descriptives_attitudes.do"

// Figure 2 (raw contributions of Ukraine/Russia between each other and the rest of the world)
do "$codes/03_analysis/01_descriptives_turnover.do"

// Figures 7-10 in the Appendix with summary of activity by country 
do "$codes/03_analysis/01_descriptives_summary.do"


*************************************************
// 2. Baseline analysis 
// Main table, event studies, robustness based on location and different control groups
do "$codes/03_analysis/02_baseline.do"


*************************************************
// 3. Individual-level analysis for mechanisms 
// Tables with individual effects for Ukrainian and Russian users 
do "$codes/03_analysis/03_individual_effects_final_ua.do"
do "$codes/03_analysis/03_individual_effects_final_ru.do"
do "$codes/03_analysis/heterogeneity.do"


*************************************************
// 4. Individual productivity effects 
do "$codes/03_analysis/04_inidividual_productivity"


*************************************************
// 5. Project-level effects 
do "$codes/03_analysis/05_project_performance.do"


*************************************************







