*** Preparation of additional data on Ukraine
global codes "$path\codes\stata"

cd "$path/database/stata"
import delimited "$path/database/extractions/ukraine_data.csv", clear // note: was deleted by mistake

// goal: aggreagate the data on region (oblast) level)
destring population, replace force
drop if mi(population)
gen code = int(region_code/100000000)

gen oblast = 0
replace oblast = 1 if code*100000000 == region_code 

gen cc = 0
replace cc = 1 if oblast == 0 & !mi(language_ru)
bysort code: egen pop_T = sum(population*oblast)
bysort code: egen pop_T2 = sum(population*cc) 
replace pop_T2 = pop_T if pop_T2 == 0
replace incumbent_ru = . if oblast == 1 & code != 1 & code != 80 & code != 85

foreach x of varlist *_ru {
bysort code: egen tot_`x' = sum(population*`x')
gen `x'_T = tot_`x'/pop_T2
drop tot_`x'
}

// save on oblast level (if needed can go more regional, but no real need)
keep district_en code pop_T language_ru_T incumbent_ru_T russians oblast 
keep if oblast == 1
duplicates drop

do "$codes\data prep\help_ukraine_prep_rename"
save "ukraine_regions", replace

// some graph
twoway (scatter incumbent_ru_T russians, mlabel(district_en) mlabsize(tiny)) ///
(lfit incumbent_ru_T russians), ytitle("for Party of Regions in 2012, %") ///
xtitle("Ethnic Russian, %")
graph save votes1.gph, replace

// some graph
twoway (scatter incumbent_ru_T language_ru_T, mlabel(district_en) mlabposition(3)  mlabsize(tiny)) ///
(lfit incumbent_ru_T language_ru_T), ytitle("for Party of Regions in 2012, %")  ///
xtitle("Russian as the native language, %")
graph save votes2.gph, replace
graph combine votes1.gph votes2.gph, ycommon
