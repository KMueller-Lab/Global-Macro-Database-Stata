
* Create the source_list csv 
filelist, dir("$dataclean") pat("*dta")
keep filename
ren filename source_name
replace source_name = strtrim(subinstr(source_name, ".dta", "", .))

* Name the country specific sources correctly 
replace source_name = "CS" + substr(source_name, -1, 1) + "_" + substr(source_name, 1, 3) if strlen(source_name) == 5 & regexm(source_name, "_[0-9]$")

* Save 
export delimited using "$datahelpers/source_list.csv", replace
