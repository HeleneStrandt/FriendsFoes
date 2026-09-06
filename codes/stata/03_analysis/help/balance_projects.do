// note: make sure btoutreg, btouttable, tmeans are in your ado folder 

foreach x in 0 1 {
preserve 
keep if $var == `x' $keep1
qui reg commits_nself_int $tosum1 $weight
btoutreg2 using "$output/tables/$name.tex", append tex(frag) ctitle("Treat = `x', $lab") ///
nonotes nor2 nocons label  ///
stats(mean sd) bracket(sd) //help btoutreg2 --> stats
restore
}

// 
preserve 
$keep2
reg owner_id $tosum1 
tmeans $var $tosum1 $weight
btoutreg2 using "$output/tables/$name.tex", append tex(frag) ctitle(Diff. T-C, $lab) ///
nonotes nocons nor2 ///
stats(coef se) paren(se) dec(3) label  //help btoutreg2 --> stats
restore 
