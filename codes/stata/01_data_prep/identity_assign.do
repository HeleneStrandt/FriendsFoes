// identity_c assignment
gen identity_c = "."
replace identity_c = "ua" if strpos(location, "yiv") | strpos(location, "KYIV") | strpos(location, "iyv")
replace identity_c = "ua" if strpos(location, "viv") | strpos(location, "Lwiw")
replace identity_c = "ua" if strpos(location, "kiv")
replace identity_c = "ua" if strpos(location, "desa")
replace identity_c = "ua" if strpos(location, "nipr")
replace identity_c = "ua" if strpos(location, "aporizh")
replace identity_c = "ua" if strpos(location, "ivn")
replace identity_c = "ua" if strpos(location, "il")
replace identity_c = "ua" if strpos(location, "Rih")
replace identity_c = "ua" if strpos(location, "rnihiv")
replace identity_c = "ua" if strpos(location, "ykola")
replace identity_c = "ua" if strpos(location, "rnigiv")
replace identity_c = "ua" if strpos(location, "rniv") | strpos(location, "chiv")
replace identity_c = "ua" if strpos(location, "ovohrad")
replace identity_c = "ua" if strpos(location, "Zaporijja")
replace identity_c = "ua" if strpos(location, "zhhorod")
replace identity_c = "ua" if strpos(location, "Ryh") | strpos(location, "Roh") | strpos(location, "Rig")
replace identity_c = "ua" if strpos(location, "Donet'sk") | strpos(location, "Donets'k") | strpos(location, "Rig")


replace identity_c = "ru" if strpos(location, "iev")
replace identity_c = "ru" if strpos(location, "vov")
replace identity_c = "ru" if strpos(location, "kov")
replace identity_c = "ru" if strpos(location, "dessa")
replace identity_c = "ru" if strpos(location, "nepro")
replace identity_c = "ru" if strpos(location, "aporozh")
replace identity_c = "ru" if strpos(location, "ovn")
replace identity_c = "ru" if strpos(location, "nopol")
replace identity_c = "ru" if strpos(location, "Rog")
replace identity_c = "ru" if strpos(location, "rog")
replace identity_c = "ru" if strpos(location, "rnigov")
replace identity_c = "ru" if strpos(location, "ikola")
replace identity_c = "ru" if strpos(location, "Zaporoje")
replace identity_c = "ru" if strpos(location, "zhgorod")
replace identity_c = "ru" if strpos(location, "Zaporojye")
replace identity_c = "ru" if strpos(location, "Zaporozjie")


gen identity_n = "." 
replace identity_n = "ua" if strpos(name, "ndrii") 
replace identity_n = "ua" if strpos(name, "aras") 
replace identity_n = "ua" if strpos(name, "azar") 
replace identity_n = "ua" if strpos(name, "Mykol") 
replace identity_n = "ua" if strpos(name, "mytro") 
replace identity_n = "ua" if strpos(name, "mitro") 
replace identity_n = "ua" if strpos(name, "Oleks") | strpos(name, "oleks") | strpos(name, "olex") | strpos(name, "Olex")
replace identity_n = "ua" if strpos(name, "Volod") | strpos(name, "volod")
replace identity_n = "ua" if strpos(name, "Bohdan") | strpos(name, "bohdan")
replace identity_n = "ua" if strpos(name, "evhen") 
replace identity_n = "ua" if strpos(name, "Serh")  | strpos(name, "Serhi")  | strpos(name, "Sergi")
replace identity_n = "ua" if strpos(name, "Vasyl")  | strpos(name, "vasyl") 


replace identity_n = "ru" if strpos(name, "ndre") 
replace identity_n = "ru" if strpos(name, "Nikol")   
replace identity_n = "ru" if strpos(name, "mitry") 
replace identity_n = "ru" if strpos(name, "Aleks") | strpos(name, "aleks") | strpos(name, "alex") | strpos(name, "Alex")
replace identity_n = "ru" if strpos(name, "Vladim") | strpos(name, "vladi")
replace identity_n = "ru" if strpos(name, "ogdan") 
replace identity_n = "ru" if strpos(name, "Serge") 
replace identity_n = "ru" if strpos(name, "Vasili") |  strpos(name, "Vasyli") 

gen identity16=identity_c 
replace identity16 = identity_n if mi(identity16) | identity16 == "."

replace identity16 = "ru/ua" if identity16 == "."
tab identity16
replace identity16 = "" if region != "UA"

