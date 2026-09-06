// centering the data around the conflict
cap drop time t_*
cap drop p_*

// q3 is (t-1)
gen time = int((quarter_day - $qX)) - 1

// manual dummy creation
tab time, gen(t_)
sum quarter_day
scalar start = r(min) - $qX -1

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
g treated_`x' = treated*`x'
g ua_treat_`x' = ua_treat*`x'
g ru_treat_`x' = ru_treat*`x'
}

sum time
global min = abs(r(min))
global max = r(max)
foreach x of numlist 1/$min  {
label var treated_pre_`x' "-`x'"
label var ua_treat_pre_`x' "-`x'"
label var ru_treat_pre_`x' "-`x'"
}
foreach x of numlist 0/$max  {
label var treated_post_`x' "+`x'"
label var ua_treat_post_`x' "+`x'"
label var ru_treat_post_`x' "+`x'"
}
