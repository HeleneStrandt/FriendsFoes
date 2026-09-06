// descriptives I
// share of UA/RU in foreign commits of UA and RU programmers
cd "$processed"

global name = "01_desc_attitudes"

import excel "..\attitudes.xlsx", sheet("Sheet2") firstrow clear
drop if mi(month)
gen date = date(month+"01", "YMD")
gen m = mofd(date)
format m %tm

drop if mi(UARU)

sum m if month == "201311"
global monthX = r(mean)

graph twoway ///
(connected UARU m,  msymbol(o) msize(large) lc(ebblue*0.7) mcolor(ebblue) ) ///
(connected RUUA m,  msymbol(s) msize(large) lc(maroon*0.7) mcolor(maroon)  ) ///
, xline($monthX, lwidth(0.7))    ///
ytitle("Percent of population",  size(small))  ///
xtitle("") title("") ///
xlabel(622 625 632 637 640 646 649 651 656 659 661 664 668 673 676 680 683 685 688 692 695 697 704 709 716, grid angle(90)) ///
legend(label (1 "In Ukraine to Russia") label ( 2 "In Russia to Ukraine") position(6) rows(1) region(lcolor(white)))
graph export "$output/figures/${name}_ua_ru.pdf", replace


import excel "..\attitudes.xlsx", sheet("Sheet1") firstrow clear
drop if mi(month)

gen date = date(month+"01", "YMD")
gen m = mofd(date)
gen y = year(date)
format m %tm

sum m if month == "201311"
global monthX = r(mean)

foreach x in Western Central Southern Eastern  {
gen nn = `x' if m == $monthX
egen mean = mean(nn)
gen norm_`x' = `x'/mean
drop nn mean
} 


foreach x in West Centr South East {
replace `x' = `x'*100
}

preserve 
keep if inrange(m, 622, 716)
graph twoway ///
(connected South m,  msymbol(+) msize(large) lc(eltblue) mcolor(eltblue) ) ///
(connected Eastern m,  msymbol(t) msize(large) lc(emidblue) mcolor(emidblue)  ) ///
(connected Western m,  msymbol(o) msize(large) lc(edkblue)  mcolor(edkblue) ) ///
(connected Central m,  msymbol(d) msize(large)  lc(ebblue) mcolor(ebblue) ), ///
xline($monthX, lwidth(0.7))    ///
ytitle("Positive and very positive attitudes toward Russia, percent",  size(small)) ///
xtitle("") title("") ///
xlabel(622 625 632 637 640 646 649 651 656 659 661 664 668 673 676 680 683 685 688 692 695 697 704 709 716, grid angle(90)) ///
legend(label (1 "Southern") label ( 2 "Eastern") label ( 3 "Western") label ( 4 "Central") position(6) rows(1) region(lcolor(white)))
graph export "$output/figures/${name}_ua.pdf", replace
restore

preserve 
keep if inrange(m, 622, 716)
graph twoway ///
(connected norm_South m,  msymbol(+) msize(large) lc(eltblue) mcolor(eltblue) ) ///
(connected norm_Eastern m,  msymbol(t) msize(large) lc(emidblue) mcolor(emidblue)  ) ///
(connected norm_Western m,  msymbol(o) msize(large) lc(edkblue)  mcolor(edkblue) ) ///
(connected norm_Central m,  msymbol(d) msize(large)  lc(ebblue) mcolor(ebblue) ), ///
xline($monthX, lwidth(0.7)) ylabel(0(0.2)1.2)    ///
ytitle("Positive and very positive attitudes toward Russia, percent (November 2013 = 1) ",  size(small)) ///
xtitle("") title("") ///
xlabel(622 625 632 637 640 646 649 651 656 659 661 664 668 673 676 680 683 685 688 692 695 697 704 709 716, grid angle(90)) ///
legend(label (1 "Southern") label ( 2 "Eastern") label ( 3 "Western") label ( 4 "Central") position(6) rows(1) region(lcolor(white)))
graph export "$output/figures/${name}_ua_norm.pdf", replace
restore



