// baseline table

foreach y of varlist $varlist {
local lab: var label `y'
ppmlhdfe `y' ua_ru_post ru_ua_post /// 
$controls, absorb(cc month_day##user_$fe month_day##owner_$fe) ///
cluster($cluster)
coefplot, title("`lab'") omitted yline(0) ///
ciopts(recast(rcap) lwidth(0.5) color(ebblue)) msize(large) vert mcolor(ebblue*1.5) ///
keep(ua_ru_post ru_ua_post) ysize(2) xsize(4) legend(off)
graph save "`y'", replace
test ua_ru_post = ru_ua_post
scalar test = r(p)
sum `y' if year < 2014 & country_a == "ua" & country_o == "ru"
scalar y_ua = r(mean)
scalar sd_ua= r(sd)
sum `y' if year < 2014 & country_a == "ru" & country_o == "ua"
scalar y_ru = r(mean)
scalar sd_ru= r(sd)

outreg2 using "$output/tables/$name.tex", append  tex(frag) ///
keep(ua_ru_post ru_ua_post)  ctitle("`lab', $spec") alpha(0.001, 0.01, 0.05) ///
addstat(Pseudo R2, e(r2_p), ///
Mean\ Y^{UA-RU}, y_ua,  ///
Mean\ Y^{RU-UA}, y_ru) nonotes label nocons
}
//pval of UA-RU = RU-UA, test,
//sd^{UA-RU}, sd_ua,
//sd^{RU-UA}, sd_ru
