// followers_users
// counts the number of followers each user from the sample gets
cd "$path"

import delimited "$raw\followers_uni.csv", bindquote(strict) clear

gen dd = substr(created_at, 1, 8) + "01"
gen month = date(dd, "YMD", 2000)
format month %td

ren follower_country country_code
do "$codes/data prep/country_codes"
renvars country_code region, postfix("_follower")

gen followers_month = 1

collapse (sum) followers_month, by(user_id month)
xtset user_id month
bys user_id: gen cum_followers = sum(followers_month)
save users_followers, replace
