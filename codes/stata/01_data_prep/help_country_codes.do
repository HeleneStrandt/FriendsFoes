/// country_codes


// For authors: UA, RU, Control (neutral) countries, Other affected; 
// For owners: same as authors + EU, exUSSR, Overseas, Other
gen region = "" 
foreach x in ru ua ua_west ua_east ua_center {
replace region = upper("`x'") if country_code == "`x'"
}

foreach x in us de gb fr ca au nl jp cn se in br it by {
replace region = "Control neutral" if country_code == "`x'"
}

foreach x in cz lt lv ee pl {
replace region = "Other affected" if country_code == "`x'"
}

*For owners (except for those in Control, replace region if missing)
*1.EU + EEA + israel 
global EUEEA = "at be bg hr cy cz de dk ee es fi fr gr gb hu ie it nl lt lv lu mt pl pt se ro si sk uk no ch is li"

*2. ex-USSR 
global exUSSR = "am az by ge kz kg md tj tm uz"

*3.Overseas
global Overseas = "us au ca br jp in nz cn id tr il"

foreach x in $Overseas {
replace region = "Overseas" if mi(region) & country_code == "`x'" 
}
foreach x in $EUEEA {
replace region = "EU+EEA" if mi(region) & country_code == "`x'"
}
foreach x in $exUSSR {
replace region = "exUSSR" if mi(region) &  country_code == "`x'"
}
replace region = "Other" if mi(region)
tab region
