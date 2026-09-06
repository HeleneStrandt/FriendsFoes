// users_names: assigns identity  and gender based on first name

use users, clear
keep if region == "UA"
/* for trading with enemy paper 
keep name city* location* long* lat*  form_address 
order name city* location* long* lat*  form_address 
renvars city location longitude lat, postfix("2018")
ren longitude long2018
renvars, subst("16" "2016")
duplicates drop
replace form_address = substr(form_address, 1, strpos(form_address, "\n")-2)
save ua_users_names, replace
*/
keep name
replace name = lower(name)
replace name = trim(name)
drop if mi(name) | name == ("\N")
duplicates drop
split name, parse(" ")
gen n = 1
foreach x of varlist name* {
bys `x': egen count_`x' = sum(n)
}
sum count*
save "full_namesUA", replace

// most popular names
gen identity = ""
foreach y in 1 2 3 4 5 {
foreach x in cyril anatoly andy vitalik mark andre john eduard daniel valerii ///
stepan timur artyom ostap roma peter petr maks den arthur stas anatoliy mike serge ///
paul nick vitaly vitali valik viktor ruslan victor vlad yaroslav vitaliy eugene denis artem ///
ivan andrew anton alex roman lee alec eldar serhio steve harry nicholas artiom ///
seva tony denis dennis kir steven ulia anastasi natali natalli nataly kate katya ///
oksana julia yulia anastasi  natalia  anna inna mariia edward ed lyudmila ///
maria marija mariya maryia anna nina ///
petr lyubov ljubov kate raisa tamara nastia ///
 alla sofia Денис axel masha andru  ksenia Артур arkad iaroslav ignat sergio george georgii georgey serge ///
jeka Артем Антон leo joseph vsevolod yarik yuliia raul Роман nata iuliia rita robert romeo juli jack jonathan marta chris ///
 philip  arthur george vika helen max mary martin zakhar zhenya tim timofey serj stan stanislaw svyatoslav serveryn sir marat liubov nastya nik rustam serg sam {
replace identity = "undef" if strpos(name`y', "`x'")
}
}

foreach y in 1 2 3 4 5 {
foreach x in slavko andrij herman andry sergij serhiy fedir khrystyna eugen mykhaylo myroslav olexiy kyrylo danylo arsen yevhen borys ///
valentyn evgen kostiantyn  kostiantin ievgen petro olexandr nazar serhii mykhailo oleksiy ///
vladyslav vadym mykola oleksii serhiy ihor oleh vasyl sergeii oleks demian ///
 pavlo maksym bohdan yury sergiy andriy kyiv taras volodym volodim  dmytro dmitro marko ///
evhenii hennadii ukrainian grygori myr valery illia tymur illya yevgen yevhen mykyta mikita maxym maksym ///
olexi olexy hlib glib myron rostyslav oles andrian lyubomyr iryna maryna kateryna svitlana vira nadiya ///
nadya nadiia hanna ivanna myroslava tetiana olexander valentyna darya darina daryna olesia yana jana maryana olha olena tetyana ///
halina oleksandra viktorya henadi hennagi ganna lesya michal yurko andrii sergii serhij ///
Олекс Сергій Володимир Володімір Микита Михайло Ігор Павло Дмитро Петро ///
Данило Мар Тарас Назар Мар'ян Є і І Дарина ///
Тетяна Ганна Олен Яна  {
replace identity = "UA" if strpos(name`y', "`x'")
}
} 

foreach y in 1 2 3 4 5 {
foreach x in aleks alekse sergei nikola iakov nikolai aleksand ilya yevgeny egor orest david dmitrij gennadiy rodion alona alena aljona dmytry pasha ///
nickolai Андрей Валерий serhey yevhenii nicolai sviatoslav aleskander fedor yegor yurij constantine ///
danil illia viacheslav michail volodia miroslav iurii yuri yura jurij valeriy nikita mikhail evgeniy misha sasha kostya valentin vasiliy vova sergei ///
sergej sergey mihail leonid slava yura  vyacheslav gennady slavik maksim andrei kostia konstantyn konstantin ///
michael vladislav stanislav vadim boris bogdan dima aleksandr maxim dmitriy yuriy ///
alexey oleg vladim vanya vasily vasya hleb igor rostislav gleb pavel ilia illarion dmitry dimon dimitriy dimitry dmitri dmitrii daniil andrey sergey alexander rinat filip constantin ///
kiril kolya miron irina marina elena olga valentina galina tatiana lena ///
ekaterina vera victoria viktoria svetlana daria alyona tania tanya tolik ///
Константин Николай Владислав Станислав Иван Евгений Алекс Сергей Владимир Никита Михаил Игорь Павел Дмитрий Петр Даниил Илья /// 
Татьяна Елена Алена София Наталия Виктория Виктор Виталий Вера Надежда Геннадий ///
 Кирилл Юрий {
replace identity = "RU" if strpos(name`y', "`x'")
}
}
tab identity

// female 
gen female = 0
foreach y in 1 2 3 4 5 {
foreach x in victoriia khrystyna vlada  iuliia juli yuli anastasi  natalia marina kateryna irina elena oksana ///
olga iryna anna inna ivanna mariia myroslava lyudmila alona irene masha tetiana ///
maria marija mariya maryia anna hanna ganna valentina valentyna ///
olga olha galina halina tatiana tetyana tetiana nadia nadiya nadija nadiia ///
iryna irina olena elena lena alena aljona lesya alesia olesia ///
natal nina lyubov ljubov kate ekaterina kateryna katya svitlana svetlana ///
aleksandra oleksandra vyra vira raisa tamara nastia nastya anastast alla ///
marina maryna yana jana sofia victoria viktoria vika vica maryana mariana ///
nata marta valeriia tania tanya jane alyona darina daria darya daryna diana ana vera natasha zlata ///
алентина рыстина Светлана Роксолана Ольга Дарья {
replace female = 1 if strpos(name`y', "`x'")
}
}
// evident mistakes
foreach x in  vitaliy  tolyaafanasev stanislav stepan rostyslav oleksii oleksandr ilya denis ///
daniel artem andrey anatol aliaksei ali alexandr {
replace female = 0 if name1 == "`x'"
}

tab female
keep name identity female
bys name: gen n = _N
tab n
drop n
save "identity_names", replace

