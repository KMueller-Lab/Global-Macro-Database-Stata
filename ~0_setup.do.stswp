* ==============================================================================
* GLOBAL MACRO DATABASE
* by Karsten Müller, Chenzi Xu, Mohamed Lehbib, Ziliang Chen
* ==============================================================================
*
* MASTER DO FILE 
* 
* Intended to be run using Stata 18.
* 
* Author:
* Mohamed Lehbib
* National University of Singapore
* 
* Created: 2026-01-08
*
* ==============================================================================
* Toggle options 
* 
* Turn these options on with a "1" or off with a "0", depending on what you 
* actually want to run.
* ==============================================================================

clear all 
global helpers_data		0	// Create the helper files 

* ==============================================================================
* Prepare folder paths and define programs 
* ==============================================================================

* Set path folder

if "`c(username)'"=="mohamedlehbib"{
	global package_path "/Users/mohamedlehbib/Downloads/GitHub/Global-Macro-Database-Stata"
}

if "`c(username)'"=="kmueller"{
	global package_path "C:/Users/kmueller/Desktop/GitHub/Global-Macro-Database-Stata"
}

if "`c(username)'"=="kmueller"{
	global package_path "C:\Users\kmueller\Documents\GitHub\Global-Macro-Database-Stata" // Home laptop
}

* Set sub-paths
global dataclean		"$package_path/data/clean"
global datafinal		"$package_path/data/final"
global datahelpers		"$package_path/data/helpers"
global codefolder		"$package_path/code"


cd "$package_path"
* Delete all stswp files
if "`c(os)'" == "Windows" {
        shell del "*.stswp" /q /s
    }
else {
	shell find . -name "*.stswp" -type f -delete
	shell find . -name "*.DS_Store" -type f -delete
	
}

* ==============================================================================
* Create the helper files 
* ==============================================================================

if $helpers_data == 1 {
	
	* Create the source_list which is list of clean datasets 
	do "$codefolder/source_list.do"
	
	* Create the bib dataframe 
	do "$codefolder/bib_to_df.do"
	
	* Assert all sources have citation 
	ren source source_name 
	gen source_name_lower = strlower(source_name)
	tempfile temp
	save `temp', replace 
	
	import delimited using "$datahelpers/source_list.csv", clear varnames(1) encoding(utf-8) 
	gen source_name_lower = strlower(source_name)
	merge 1:1 source_name_lower using `temp', assert(2 3)
	
	* Keep the citation for sources, gmd paper, and stata article paper 
	keep if _merge == 3 | inlist(source_name_lower, "gmd", "lehbib2025gmd")
	
	* Clean up and export the updated bib dataframe 
	drop source_name_lower _merge
	
	* Assert nothing is missing
	assert citation != ""
	assert strpos(citation, "@")
	
	* Export 
	export delimited using "$datahelpers/bib_dataframe.csv", replace
	
	* Create varlist from docvars 
	qui import delimited using "$datahelpers/docvars.csv", clear
	keep codes units label
	ren (codes units label) (variables units definition)
	export delimited using "$datahelpers/varlist.csv", replace
	
}



