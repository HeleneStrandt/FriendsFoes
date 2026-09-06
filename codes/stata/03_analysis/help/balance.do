
// note: make sure btoutreg, btouttable, tmeans are in your ado folder 

foreach xx in 0 1 {
preserve 
keep if $var == `xx' & cem_matched == 1
qui reg commits_sent $tosum1 $weight
btoutreg2 using "$output/tables/$name.tex", append tex(frag) ctitle("Treat = `xx', $lab") ///
nonotes nor2 nocons label  ///
stats(mean sd) bracket(sd) //help btoutreg2 --> stats
restore
}

// 

preserve 
keep if cem_matched == 1
reg n_countries_o $tosum1 $weight  if !mi($var)
tmeans $var $tosum1  $weight
btoutreg2 using "$output/tables/${name}.tex", append tex(frag) ctitle(Diff. T-C, $lab) ///
nonotes nocons nor2 ///
stats(coef se) paren(se) dec(3) label  //help btoutreg2 --> stats
restore 

