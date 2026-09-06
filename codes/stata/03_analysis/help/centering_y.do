// centering the data around the conflict
// would use quarterly grouped data
cap drop p_* t*
global yX = 2014
gen time = int((year - $yX))

// manual dummy creation
tab time, gen(t_)
sum year
scalar start = r(min) - $yX

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

replace pre_1 = 0 // reference category is 2013

cap drop t_before t_after
gen t_before = 0
replace t_before=1 if time<-8
gen t_after = 0
replace t_after=1 if time>12 & !mi(time)
