// users_locations
// define identity based on reported locations

use users, clear
keep if region == "UA"
keep location* 
gen n = 1 
replace location = lower(trim(location))
replace location16 = lower(trim(location16))
foreach x of varlist location* {
bys `x': egen count_`x' = sum(n)
}
duplicates drop 
count
gsort -count_location

cap drop identity
gen identity_c = "."
replace identity_c = "UA" if strpos(location, "kyiv") 
replace identity_c = "UA" if strpos(location, "lviv") | strpos(location, "lwiw")
replace identity_c = "UA" if strpos(location, "arkiv")
replace identity_c = "UA" if strpos(location, "odesa")
replace identity_c = "UA" if strpos(location, "dnipr")
replace identity_c = "UA" if strpos(location, "zaporizh")
replace identity_c = "UA" if strpos(location, "rivn")
replace identity_c = "UA" if strpos(location, "rih")
replace identity_c = "UA" if strpos(location, "rnihiv")
replace identity_c = "UA" if strpos(location, "ykola")
replace identity_c = "UA" if strpos(location, "rnigiv")
replace identity_c = "UA" if strpos(location, "rniv") | strpos(location, "chiv")
replace identity_c = "UA" if strpos(location, "ovohrad")
replace identity_c = "UA" if strpos(location, "zaporijja")
replace identity_c = "UA" if strpos(location, "horod") | strpos(location, "hrad")
replace identity_c = "UA" if strpos(location, "ryh") | strpos(location, "roh") | strpos(location, "Rig")
replace identity_c = "UA" if strpos(location, "donet'sk") | ///
strpos(location, "donets'k") | strpos(location, "rig")
foreach x in viv pil bil hansk volodim volodym buniv khrakiv kyiw oleksa livka nivtsi nivci cherkasy chercasy ///
 kyyiv kyiev kiyv kyiw ternopil pil cherkasy frankiv ivano-franki vinnytsia ///
vinnitsia  vinnytsiya l'viv zhytomyr zhitomyr vyshneve bila vinnitsya vinnitsia vinnytsia boryspil kyev ///
luhansk vinnytsya uzhorod {
replace identity_c = "UA" if strpos(location, "`x'")
}


replace identity_c = "RU" if strpos(location, "kiev")
replace identity_c = "RU" if strpos(location, "lvov")
replace identity_c = "RU" if strpos(location, "arkov")
replace identity_c = "RU" if strpos(location, "odessa")
replace identity_c = "RU" if strpos(location, "dnepr")
replace identity_c = "RU" if strpos(location, "zaporozh")
replace identity_c = "RU" if strpos(location, "rovn")
replace identity_c = "RU" if strpos(location, "nopol")
replace identity_c = "RU" if strpos(location, "rog")
replace identity_c = "RU" if strpos(location, "rnigov")
replace identity_c = "RU" if strpos(location, "ikola")
replace identity_c = "RU" if strpos(location, "zaporoje")
replace identity_c = "RU" if strpos(location, "gorod") | strpos(location, "grad")
replace identity_c = "RU" if strpos(location, "zaporojye")
replace identity_c = "RU" if strpos(location, "zaporozjie")
foreach x in vinitsa vinnitsa gansk dniepro vladimir vladym bunov aleksa lovka bol pol aev novtsy novci cherkassy kiew ternopol ivano-franko vinnica vinnitsa vinnytsa ///
 l'vov zhitomir zhytomir belaya belaia boryspol  lugansk {
replace identity_c = "RU" if strpos(location, "`x'")
}
tab identity 

ren identity_c identity_location
ren location location18
ren location16 location


// identity as of 2016
gen identity_c = "."
replace identity_c = "UA" if strpos(location, "kyiv") 
replace identity_c = "UA" if strpos(location, "lviv") | strpos(location, "lwiw")
replace identity_c = "UA" if strpos(location, "arkiv")
replace identity_c = "UA" if strpos(location, "odesa")
replace identity_c = "UA" if strpos(location, "dnipr")
replace identity_c = "UA" if strpos(location, "zaporizh")
replace identity_c = "UA" if strpos(location, "rivn")
replace identity_c = "UA" if strpos(location, "rih")
replace identity_c = "UA" if strpos(location, "rnihiv")
replace identity_c = "UA" if strpos(location, "ykola")
replace identity_c = "UA" if strpos(location, "rnigiv")
replace identity_c = "UA" if strpos(location, "rniv") | strpos(location, "chiv")
replace identity_c = "UA" if strpos(location, "ovohrad")
replace identity_c = "UA" if strpos(location, "zaporijja")
replace identity_c = "UA" if strpos(location, "horod") | strpos(location, "hrad")
replace identity_c = "UA" if strpos(location, "ryh") | strpos(location, "roh") | strpos(location, "Rig")
replace identity_c = "UA" if strpos(location, "donet'sk") | ///
strpos(location, "donets'k") | strpos(location, "rig")
foreach x in viv pil bil hansk luhans volodim volodym buniv khrakiv kyiw oleksa livka nivtsi nivci cherkasy chercasy ///
 kyyiv kyiev kiyv kyiw ternopil pil cherkasy frankiv ivano-franki vinnytsia ///
vinnitsia  vinnytsiya l'viv zhytomyr zhitomyr vyshneve bila vinnitsya vinnitsia vinnytsia boryspil kyev ///
luhansk vinnytsya uzhorod chortkiv cherkassi ///
ї і І Луцьк Хмельницький {
replace identity_c = "UA" if strpos(location, "`x'")
}


replace identity_c = "RU" if strpos(location, "kiev")
replace identity_c = "RU" if strpos(location, "lvov")
replace identity_c = "RU" if strpos(location, "arkov")
replace identity_c = "RU" if strpos(location, "odessa")
replace identity_c = "RU" if strpos(location, "dnepr")
replace identity_c = "RU" if strpos(location, "zaporozh")
replace identity_c = "RU" if strpos(location, "rovn")
replace identity_c = "RU" if strpos(location, "nopol")
replace identity_c = "RU" if strpos(location, "rog")
replace identity_c = "RU" if strpos(location, "rnigov")
replace identity_c = "RU" if strpos(location, "ikola")
replace identity_c = "RU" if strpos(location, "zaporoje")
replace identity_c = "RU" if strpos(location, "gorod") | strpos(location, "grad")
replace identity_c = "RU" if strpos(location, "zaporojye")
replace identity_c = "RU" if strpos(location, "zaporozjie")
foreach x in kiev chernov vinitsa vinnitsa gansk dniepro vladimir vladym bunov aleksa lovka bol pol aev novtsy novci cherkassy kiew ternopol ivano-franko vinnica vinnitsa vinnytsa ///
 l'vov zhitomir zhytomir lugan belaya cherkassy belaia boryspol  lugansk ///
 Киев киев Украина Харьков Черкассы lugansk ///
 украина Рог рог имферополь мельницкий Луцк Запорожье Днепропетровск ///
 Великобри  {
replace identity_c = "RU" if strpos(location, "`x'")
}
tab identity_c if !mi(location)
tab location if identity_c == "." & count_location16 ==1

ren (location location18) (location16 location)
ren identity_c identity_location16
keep location* identity*

save identity_locations, replace

