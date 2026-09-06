// centering the data around the conflict
// would use quarterly grouped data
capture drop quarter_day
cap drop p_* t*

gen quarter_day = (qofd(date))
format quarter_day %tq // (216 is the T = 0)
tab quarter_day
cap drop t*

sum quarter_day if month_day == tm(2013q11)  // btw: start of Euro-Maidan in the end of November 2013, might go one period back

global qX = r(mean)
gen time = int((quarter_day - $qX))

// manual dummy creation
tab time, gen(t_)
sum quarter_day
scalar start = r(min) - $qX

local j = abs(start)
forvalues t = 1(1)`j' {
local name = "pre_" + "`j'"
local lab = "-" + "`j'"
di "`name'"
ren t_`t' `name'
label var `name' "`lab'"
local j = `j' - 1
}

local j = 0
foreach x of varlist t_* {
local name = "post_" + "`j'"
local lab = "+" + "`j'"
di "`name'"
ren `x' `name'
label var `name' "`lab'"
local j = `j' + 1
}

replace pre_1 = 0 // reference category is the quarter before conflict

cap drop t_before t_after
gen t_before = 0
replace t_before=1 if time<-8
gen t_after = 0
replace t_after=1 if time>12 & !mi(time)

foreach x of varlist t_* pre_* post_* {
g ua_ru_`x' = ua_user*ru_project*`x'
g ru_ua_`x' = ru_user*ua_project*`x'
g joint_ua_ru_`x' = (ru_user*ua_project + ua_user*ru_project)*`x'
}

sum time
global min = abs(r(min))
global max = r(max)
foreach x of numlist 1/$min  {
label var ua_ru_pre_`x' "-`x'"
label var ru_ua_pre_`x' "-`x'"
label var joint_ua_ru_pre_`x' "-`x'"
}
foreach x of numlist 0/$max  {
label var ua_ru_post_`x' "+`x'"
label var ru_ua_post_`x' "+`x'"
label var joint_ua_ru_post_`x' "+`x'"
}
