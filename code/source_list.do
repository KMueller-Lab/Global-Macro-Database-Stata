
* Create the source_list csv 
filelist, dir("$dataclean") pat("*dta")
keep filename
ren filename source_name
replace source_name = strtrim(subinstr(source_name, ".dta", "", .))

* Name the country specific sources correctly 
replace source_name = "CS" + regexs(2) + "_" + regexs(1) if regexm(source_name, "^([A-Z][A-Z][A-Z])_([0-9]+)$")

* Save 
export delimited using "$datahelpers/source_list.csv", replace
