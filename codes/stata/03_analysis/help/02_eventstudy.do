// event study
foreach y of varlist $varlist { 
local lab: var label `y'
ppmlhdfe `y' ua_ru_pre_* ua_ru_post_* ua_ru_t_after  /// 
             ru_ua_pre_* ru_ua_post_* ru_ua_t_after ///
$controls, nocons absorb(cc month_day##user_$fe month_day##owner_$fe) cluster(cc month_day)


coefplot, omitted yline(0) xline(8, lwidth(0.5) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue) ) msize(large) msymbol(O) mcolor(ebblue*1.5) vert  ///
keep(ua_ru_pre_8 ua_ru_pre_7  ua_ru_pre_6 ua_ru_pre_5 ua_ru_pre_4 ///
ua_ru_pre_3 ua_ru_pre_2 ua_ru_pre_1 ua_ru_post*) ///
title("${title1}") subtitle("${name2}") ylab(-1(0.2)1) ///
ytitle("UA*RU x with time dummies") xtitle("Quarters since Q4, 2013") xlab(, labs(vsmall))
graph save "UARU${name}_`y'", replace

coefplot, omitted yline(0) xline(8, lwidth(0.5 ) lc(gs12)) ///
ciopts(recast(rcap) color(ebblue) ) msize(large) msymbol(O) mcolor(ebblue*1.5) vert  ///
keep(ru_ua_pre_8 ru_ua_pre_7 ru_ua_pre_6 ru_ua_pre_5 ru_ua_pre_4 ///
ru_ua_pre_3 ru_ua_pre_2 ru_ua_pre_1 ru_ua_post*) ///
 title("${title2}") subtitle("${name2}") ylab(-1(0.2)1)  ///
ytitle("RU*UA x with time dummies") xtitle("Quarters since Q4, 2013") xlab(, labs(vsmall))
graph save "RUUA${name}_`y'", replace
graph combine "UARU${name}_`y'" "RUUA${name}_`y'", ycommon xcommon ysize(2) xsize(4)
graph export "$output/figures/${name}_`y'_event.pdf", replace
}
