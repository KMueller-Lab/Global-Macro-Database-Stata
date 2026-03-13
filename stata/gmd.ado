*! version 2.0.0 10jan2026 Mohamed Lehbib and Karsten Müller

********************************************************************************
* Initial set up and syntax 
********************************************************************************

cap program drop gmd
program define gmd
    version 15.0
    
    * Define syntax with optional arguments for version, country, raw data, etc.
    syntax [anything] [, VErsion(string) COUntry(string) Raw VARS(string) Sources(string) CITE(string) print(string) Network(string) Fast(string)] 
    
    * Calculate number of variables 
    local word_count = wordcount("`anything'")
	
     
********************************************************************************
* Checking dependencies, setting package versions 
********************************************************************************
    
    * Check if the required 'missings' package is installed
    cap which missings
    if _rc !=0 {
        di as error "This command requires the 'missings' package."
        di as text "To install it, type " "{stata ssc install missings:ssc install missings}"
        exit 498
    }
    
    * Define the current internal package version
    local package_version = "2.0.0"
 
********************************************************************************
* Print option (Internal Helper)
* This is called by clickable links to display APA-style citations for the GMD
********************************************************************************
    if "`print'" != "" {
        
        * Print GMD NBER Paper citation
        if strlower("`print'") == "gmd" {
            di as text "Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). The Global Macro Database: A New International Macroeconomic Dataset (NBER Working Paper No. 33714)."
        }
        * Print Stata Journal citation
        else if strlower("`print'") == "stata" {
            di as text "Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database. Working Paper."
        }
        * Handle invalid print arguments
        else {
            di as err "Invalid option for print(). valid arguments are 'GMD' or 'Stata'."
            exit 198
        }
        * Exit immediately so this helper doesn't run the rest of the program
        exit
    }   
	
********************************************************************************
* Compares package version against data version in CSV
* Check version logic, determine which one to use 
* Check if the user has internet by trying to fetch the versions.csv 
********************************************************************************
    preserve
    cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/versions.csv", clear varnames(1)
	
    if _rc == 0 {
        * Parse version strings (YYYY_MM) into sortable numbers
        qui gen year = substr(versions, 1, 4)
        qui gen month = substr(versions, -2, 2)
        qui destring year month, replace
        gsort -year -month
        
        * Check if package is outdated
        local package = version_package in 1 
        if "`package'" != "`package_version'" {
            di as text "There is a new version of the package. " "{stata ssc install gmd, replace:Click here to update.}"
        }
        qui drop version_package
        local selected_version = versions in 1   
        qui levelsof versions, local(available_versions) clean
        
        * If user asks for list of versions, print and exit
        if "`version'" == "list" {
            foreach ver of local available_versions {
                di as text "`ver'"
            }
            restore 
            exit 
        }
        * If user requests specific version, validate it exists
        else if "`version'" != "" {
			* Assert version is one word 
			cap assert wordcount("`version'") == 1
			if _rc != 0 {
				local selected_version = versions in 1
				di as err "Version must either be one specific version (`selected_version') or current."
				restore 
				exit 
			}
			
            if `: list version in available_versions' {
                * If version exists, set local to the desired version 
				local selected_version "`version'"
            }
			else if "`version'" == "current" {
				* Use the latest version (already stored in selected_version)
				local selected_version = versions in 1
				di as text "Current version: `selected_version'"
			}
            else {
                di as error "Error: Version `version' does not exist"
                di as text "Available versions: `available_versions'"
                restore
                exit 498
            }
        }
    }
    else {
		
		* The user either doesn't have internet, or the URL is down. 
		cap import delimited using "https://raw.githubusercontent.com/KMueller-Lab/Global-Macro-Database/refs/heads/main/data/helpers/versions.csv", clear varnames(1)
		
		if _rc == 0 {
			* The user has internet, but the AWS is not responding. 
			* Check for updates 
			qui gen year = substr(versions, 1, 4)
			qui gen month = substr(versions, -2, 2)
			qui destring year month, replace
			gsort -year -month
			
			* Check if package is outdated
			local package = version_package in 1 
			if "`package'" != "`package_version'" {
				di as text "There is a new version of the package. " "{stata ssc install gmd, replace:Click here to update.}"
				di `"Please update the package from the GitHub repository and raise an issue if the update does not work at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
			}			
		}
		
		if "`network'" != "" {
			local internet "NaN"
		}
		else {
			local internet "No"
		}
        di as error "Error: Unable to access version information. Check internet connection."
		di as text "Loading local version"
		
		* Now check if the local version exist, use it if it does, otherwise, load it and save it.
		local personal_folder "`c(sysdir_plus)'"
		
		* Check if the dataset is saved locally
		cap confirm file "`personal_folder'g/GMD.dta"
		
		* If it's saved locally, store its path in a local macro
		if _rc == 0 {
			local saved_gmd "yes"
			local gmd_df "`personal_folder'g/GMD.dta"			
		}
		
		* If the dataset is not saved locally, restore and exit
		else {
			di as err "Local version not found"
			restore
			exit 498
		}
       
    }
    restore

	if "`internet'" == "No" {
		
		* Active internet is required to load data from sources
		if "`sources'" == "load" | "`sources'" == "list" {
			di as err "You need access to the internet in order to fetch the sources list"
			di as err "If you have active internet access, specify the option network"  "{stata gmd, network(yes) :gmd, network(yes)}"
			exit 498
		}
		else if "`sources'" != "" {
			di as err "You need access to the internet in order to fetch the `sources' data"
			di as err "If you have active internet access, specify the option network"  "{stata gmd, network(yes) :gmd, network(yes)}"
			exit 498
		}
		
		* Active internet is required to load raw data
		if "`raw'" != "" {
			di as err "You need access to the internet in order to fetch the raw data"
			di as err "If you have active internet access, specify the option network"  "{stata gmd, network(yes) :gmd, network(yes)}"
			exit 498
		}
		
		* Active internet is required to cite sources
		if "`cite'" == "load" {
			di as err "You need access to the internet in order to load the sources to cite"
			di as err "If you have active internet access, specify the option network"  "{stata gmd, network(yes) :gmd, network(yes)}"
			exit 498
		}
		else if "`cite'" != "" {
			di as err "You need access to the internet in order to cite `cite'"
			di as err "If you have active internet access, specify the option network"  "{stata gmd, network(yes) :gmd, network(yes)}"
			exit 498
		}
	}


	
********************************************************************************
* Cite option: Displays or loads BibTeX codes
********************************************************************************

    * Option 1: Load the full bibliography into memory
    if "`cite'" == "load" {
        preserve
        cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/bib_dataframe.csv", clear varnames(1) encoding(utf-8)
        
        * If successful, commit changes (restore, not) and exit
        if _rc == 0 {
            restore, not
            exit
        }
        else {
            di `"Unable to import the list of sources to cite. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore
            exit 498
        }
    }  
    
    * Option 2: Display specific BibTeX code (e.g., gmd, cite(GMD))
    else if "`cite'" != "" {
        preserve
        
		* Open bibliography file 
		qui import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/bib_dataframe.csv", clear varnames(1) encoding(utf-8)
        
		* Assert we are counting only one source
		local cite_count = wordcount("`cite'")
		if `cite_count' != 1 {
			di as err "Only one citation can be retrieved at a time"
			restore
			exit 498
		}
		
		* Assert the source exist 
		qui count if strlower(source) == strlower("`cite'") 
		if `r(N)' == 0 {
			di as err "Source '`cite'' does not exist."
			di as text "To load the list of sources to cite: " "{stata gmd, cite(load):gmd, cite(load)}"
            restore
            exit 498
		}

		* If yes, continue 
		else {
			* Only keep relevant source, write into local 
            qui keep if strlower(source) == strlower("`cite'")
            
            * Get the citation and store in a scalar to preserve quotes
            scalar cit_text = citation[1]
            local p = cit_text
            
            * Insert a pipe (|) before fields (comma followed by space and word=)
            local p = ustrregexra(`"`p'"', ",\s*([a-zA-Z0-9_]+\s*=)", "," + "|" + "  " + "$1")
            
            * Insert a pipe (|) before the final closing bracket
            local p = ustrregexra(`"`p'"', "\}\s*$", "|" + "}")

            * Loop through the string, splitting by pipe (|) to print each field on a new line
            while `"`p'"' != "" {
                local pos = strpos(`"`p'"', "|")
                if `pos' == 0 {
                    noi di as text `"`p'"'
                    local p ""
                }
                else {
                    * Use scalar to avoid quote issues in local expansion
                    scalar tmp_line = substr(`"`p'"', 1, `pos'-1)
                    noi di as text scalar(tmp_line)
                    local p = substr(`"`p'"', `pos'+1, .)
                }
            }
            scalar drop cit_text tmp_line
            restore
            exit
        }		
    }

********************************************************************************
* DATA LOADING BRANCHES
* Crucial: These blocks are mutually exclusive (if/else if) to prevent overwriting.
* They load data but DO NOT EXIT, allowing flow to Country Filtering below.
********************************************************************************	
	
    * --- BRANCH 1: SOURCES (Load specific source data) ---
    if ("`sources'" == "load" | "`sources'" == "list"){
        if "`raw'" != "" di as err "Note: raw option is specified, but this is implicit when using the sources option."
        
        preserve 
        cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/source_list.csv", clear varnames(1) encoding(utf-8) 
        
        if _rc == 0 {
            if "`sources'" == "load" {
                di as text "Imported the list of sources."
                restore, not
                exit 
            }
            else if "`sources'" == "list" {
                qui levelsof source_name, clean loc(sourceloc)
                foreach indsource in `sourceloc' {
                    di as text "`indsource'"
                }
                restore 
                exit
            }
        }
        else {
            di `"Unable to load source list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore
            exit 498
        }
		
		* Restore 
		restore 
    }
    
    * Load a specific source dataset (e.g. sources(IMF_IFS))
    else if  "`sources'" != "" {
        if "`raw'" != "" di as err "Note: raw option is specified, but this is implicit when using the sources option."
        
		* Format some sources correctly: 
		if strlen("`sources'") == 7 & strpos("`sources'", "CS") == 1 {
			local sources = substr("`sources'", -3, 3) + "_" + substr("`sources'", 3, 1) 
		}
		
        local sources       = trim(itrim("`sources'"))
        local sources_num = wordcount("`sources'")
        
        * Enforce single source loading
        if `sources_num' > 1 {
            di as error "Warning: Please specify exactly one source."
            exit 498
        }
        
        preserve
        cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/clean/combined/`sources'.dta", clear
		local res = _rc
		if `res' != 0 {
		
			* Check if the issue is the source name (lowercase for example)
			cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/source_list.csv", clear varnames(1) encoding(utf-8) 
			if _rc != 0 {
				di `"Unable to access variable list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
			}
            else {
				qui count if strlower(source_name) == strlower("`sources'")
				if `r(N)' == 1 {
					* Source exist! 
					qui levelsof source_name if strlower(source_name) == strlower("`sources'"), local(correct_source) clean
					
				}
				else {
					* Source doesn't exist 
					di as err "Invalid source name"
					di as text "To load the list of sources: " "{stata gmd, sources(load):gmd, sources(load)}"
					restore 
					exit 498
				}
			}
            
        }
		
		if `res' == 0 | "`correct_source'" != "" {
            * If user requested specific variables, keep only those + IDs
			if "`correct_source'" != "" {
				local sources = "`correct_source'"
			}
			
			cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/clean/combined/`sources'.dta", clear
			if _rc != 0 {
				di as err "Unable to load data for source '`sources''." 
				di as text "Please check your internet connection or report this issue."
				restore 
				exit 498
			}
			
            if "`anything'" != "" {
                cap noisily confirm var `sources'_`anything'
                if _rc == 0 {
                    local keepvars "ISO3 year `sources'_`anything'"
                    
                    * Check if IDs exist in this specific source file
                    cap confirm variable countryname
                    if _rc == 0 local keepvars "`sources'_`keepvars' countryname"
                    cap confirm variable id
                    if _rc == 0 local keepvars "`keepvars' id"
                    
                    qui keep `keepvars'
					
					* Filter for a country 
					if "`country'" != "" {
						cap qui keep if ISO3 == strupper("`country'")
						if _rc == 0 {
							restore, not 
							exit
						}
						else {
							di as err "Country code not valid, returning data for all countries."	
							di as text "To print the list of countries: " "{stata gmd, country(list):gmd, country(list)}"
							di as text "To load the list of countries: " "{stata gmd, country(load):gmd, country(load)}"
						}
					}
                    restore, not 
					exit 
                }
				
				* If no variable is specified, there is nothing to filter,
				* and we return to the full source dataset 
                else {					
					qui ren `sources'_* *
					qui ds ISO3 year, not
					di as err "This source doesn't have data on `anything'. It has data on `r(varlist)'."
                    restore
                    exit
                }
            }
			
			else {
				restore, not 
				exit 
			}

        }
		
		restore, not 
    }

    * --- BRANCH 2: VARS (Load variable definitions) ---
    else if "`vars'" == "load" {     
        preserve 
        cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/varlist.csv", clear varnames(1) encoding(utf-8)
        if _rc != 0 {
            di `"Unable to access variable list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore 
            exit 498
        }
        restore, not 
        exit
    }
    
    * Print list of variables
    else if "`vars'" == "list" {
        preserve 
        cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/varlist.csv", clear varnames(1) encoding(utf-8)
        if _rc != 0 {
            di `"Unable to access variable list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore 
            exit 498
        }
        
        * Formatting logic for table display
        qui ds
        qui gen varlength = strlen(variable)
        qui gen deflength = strlen(definition)
        qui su varlength 
        local varlength = r(max) + 2
        qui su deflength
        local deflength = r(max) + `varlength' + 2
        
        di as text _newline "Available variables:" _newline
        di as text "{hline 90}"
        di as text "Variable" _col(`varlength') "Definition" _col(`deflength') "Units"
        di as text "{hline 90}"
        
        qui count
        local total = r(N)
        forvalues i = 1/`total' {
            local vname = variable[`i']
            local vdesc = definition[`i']
            local vunits = units[`i']
            di as text "`vname'" _col(`varlength') "`vdesc'" _col(`deflength') "`vunits'"
        }
        di as text "{hline 90}"
        restore 
        exit                
    }
    
    * --- BRANCH 3: RAW (Load raw CSV data) ---
    else if "`raw'" != "" {
        if `word_count' != 1 {
            di as error "Warning: Please specify exactly one variable."
            exit 498
        }
        
        preserve  
        cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/`anything'_`selected_version'.csv", clear case(preserve) varnames(1)
        * If import fails, check if variable exists in main GMD file stored locally to give better error msg
        if _rc != 0 {
            cap import delimited using "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/varlist.csv", clear varnames(1) encoding(utf-8)
            cap confirm variable `anything', exact
            if _rc != 0 {
                di as err "Specified variable is not valid."
                restore
                exit 498
            }
            else {
                di as err "Variable does not have raw data."
                restore
                exit 498
            }        
        }
		else {
			di as text "Loaded raw data on `anything'"
			restore, not
		}
		
    }
	
	* Helper: Load country list
    if "`country'" == "load" {
        preserve 
		local personal_folder "`c(sysdir_plus)'"
        cap use "`personal_folder'g/countrylist.dta", clear 
        if _rc != 0 {
			* Load the remote dataset
			cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/countrylist.dta", clear 
			if _rc == 0 {
				* Check if we have the user's permission to save: 
				if "`fast'" == "yes" {
				di as text "Saving countrylist dataframe locally"
				qui save "`personal_folder'g/countrylist.dta", replace
				}
				else {
					restore, not
					exit
				}
			}
			else {
				di `"Unable to access country list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
				restore 
				exit 
			}           
        }
		restore, not
		exit
    }
	
    * Helper: Display country list
    else if "`country'" == "list" {
        preserve 
		local personal_folder "`c(sysdir_plus)'"
        cap use "`personal_folder'g/countrylist.dta", clear 
        if _rc != 0 {
			* Load the remote dataset
			cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/countrylist.dta", clear 
			if _rc == 0 {
				* Check if we have the user's permission to save: 
				if "`fast'" == "yes" {
				di as text "Saving countrylist dataframe locally"
				qui save "`personal_folder'g/countrylist.dta", replace
				}
				else {
					restore, not
					exit
				}
			}           
        }
        keep countryname ISO3
        di as text _newline "Available countries:" _newline
        di as text "{hline 90}"
        di as text "ISO3 code  " _col(10) "Country name" 
        di as text "{hline 90}"
        qui count
        local total = r(N)
        forvalues i = 1/`total' {
            local iso3 = ISO3[`i']
            local country = countryname[`i']
            di as text "`iso3'    " _col(10) "`country'"
        }
        di as text "{hline 90}"
        restore
        exit
    }
	
	local check_id = strlower("`anything'")
	* Ensure the user did not specify identifying variables 
	if "`check_id'" == "iso3" | "`check_id'" == "year" | "`check_id'" == "id" | "`check_id'" == "countryname" {
		di as err "`anything' is an identifying variable loaded in the dataset, specify common variables"
		di as text "To print the list of variables: " "{stata gmd, vars(list):gmd, vars(list)}"
		di as text "To load the list of variables: " "{stata gmd, vars(load):gmd, vars(load)}"
		exit 498
	}
	
	* Preserve 
	preserve 
	
	* Using the local version 
	if "`gmd_df'" == "" & "`raw'" == "" {
		* Now check if the local version exist, use it if it does, otherwise, load it and save it (if we have the permission).
		local personal_folder "`c(sysdir_plus)'"
		
		* Check if the dataset is saved locally
		cap confirm file "`c(sysdir_plus)'g/GMD_`selected_version'.dta"

		* If it's saved locally, store its path in a local macro
		if _rc == 0 {
			local saved_gmd "yes"
			local gmd_df "`personal_folder'g/GMD_`selected_version'.dta"
			qui use "`gmd_df'", clear 
		}
		* If the dataset is not saved locally, load it and save it locally
		else if "`fast'" == "yes" {		
			cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear 
			if _rc == 0 {
				qui save "`personal_folder'g/GMD_`selected_version'.dta", replace
				qui save "`personal_folder'g/GMD.dta", replace // Load in case the user doesn't have internet 
				di as text "GMD dataset loaded and saved locally in `personal_folder'g."
				local gmd_df "`personal_folder'g/GMD_`selected_version'.dta"
				qui use "`gmd_df'", clear 
			}
			else {
				di `"Unable to load the data. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
				restore 
				exit 498
			}
		}
		
		else {
			cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear 
		}
	}
	
	else if "`gmd_df'" != "" & "`raw'" == "" {
		qui use "`gmd_df'", clear 
	}
	
	restore, not
	
    * --- BRANCH 4: MAIN DATASET ---		
    * Only runs if country is not load/list AND no other data was loaded above
    if "`anything'" != "" & "`raw'" == "" {
	   
			* Opens specified version (default = current version)
			
            cap confirm variable `anything', exact
            if _rc == 0 {
                qui keep ISO3 year id countryname `anything'
                
				* Keep observations after first year with data
				qui egen valid_count = rownonmiss(`anything')
				qui bysort ISO3 (year): drop if sum(valid_count) == 0
				qui drop valid_count
				
            }
            else {  
                * Handle multiple invalid variables
                local invalid_vars ""
                foreach var of local anything {
                    cap confirm variable `var'
                    if _rc != 0 {
                        local invalid_vars "`invalid_vars' `var'"
                    }
                }
                local var_count = wordcount("`invalid_vars'")
				if `var_count' == 1 {
					di as err "`invalid_vars' is not a valid variable code"
				}
				else {
					di as err "`invalid_vars' are not valid variable codes"
				}
				di as text "To print the list of variables: " "{stata gmd, vars(list):gmd, vars(list)}"
				di as text "To load the list of variables: " "{stata gmd, vars(load):gmd, vars(load)}"
                exit 498
            }
    }

********************************************************************************
* Country option (helpers & filtering)
* Applies to whichever dataset is currently loaded in memory
********************************************************************************
    
    * Actual filtering 
    if "`country'" != "" {
        * Clean input string (remove commas, uppercase)
        local country = subinstr("`country'", ",", " ", .)
        local country = trim(itrim(upper("`country'")))
        local countries_num = wordcount("`country'")
        
        * Case: Single country
        if `countries_num' == 1 {
            qui count if ISO3 == "`country'"
            if `r(N)' == 0 {                    
                di as err "Country code is invalid or no data for this country in source."
				di as text "To print the list of countries: " "{stata gmd, country(list):gmd, country(list)}"
				di as text "To load the list of countries: " "{stata gmd, country(load):gmd, country(load)}"
                exit 498
            }
            else {
                qui keep if ISO3 == "`country'"
            }
        }
        * Case: Multiple countries
        else {
            qui gen keep_country = . 
            local invalid_countries ""
            foreach iso of local country {
                qui count if ISO3 == "`iso'"
                if r(N) == 0 {
                    local invalid_countries "`invalid_countries' `iso'"
                }
                else {
                    qui replace keep_country = 1 if ISO3 == "`iso'"
                }                   
            }
            
            * Check if we found any invalid codes
            local invalid_countries = trim(itrim(upper("`invalid_countries'")))
            if "`invalid_countries'" == "" {
                qui keep if keep_country == 1 
                drop keep_country
            }
            else {
				local iso_count = wordcount("`invalid_countries'")
				if `iso_count' == 1 {
					di as err "`invalid_countries' is not a valid ISO3 code"
				}
				else {
					di as err "`invalid_countries' are not valid ISO3 codes"
				}
				di as text "To print the list of countries: " "{stata gmd, country(list):gmd, country(list)}"
				di as text "To load the list of countries: " "{stata gmd, country(load):gmd, country(load)}"
				qui keep if keep_country == 1 
				drop keep_country
                exit 498
            }
        }                    
    }

********************************************************************************
* Display dataset descriptives 
********************************************************************************
    
    * Drop variables that are completely missing in the filtered subset
    cap missings dropvars, force
    qui describe
    
    * Dynamic variable count: Subtract identifiers from total count
    local n_vars = r(k)
    foreach v in ISO3 year id countryname {
        cap confirm variable `v', exact
        if _rc == 0 {
            local n_vars = `n_vars' - 1
        }
    }

    * If no data variables remain, warn user
    if `n_vars' <= 0 { 
        di as err "The database has no data on `anything' for `country'"
        restore
        exit 498
    }
    
    * Print Final Summary
    else {
        qui describe
        if r(N) > 0 {
            
            * Print GMD information and relevant papers to cite 
            di as text "Global Macro Database by Müller, Xu, Lehbib, and Chen (2025)"
            di as text `"Website: {browse "https://www.globalmacrodata.com"}"'
            di as text ""
            di as text "When using these data, please cite:"
            di as text "{stata gmd, cite(GMD):[BibTeX code]} " `"{stata gmd, print(GMD): [APA-style citation]}"'                
            di as text ""
            di as text "When using the gmd Stata command, please further cite:"
            di as text "{stata gmd, cite(lehbib2025gmd):[BibTeX code]} " `"{stata gmd, print(Stata): [APA-style citation]}"'
            di as text ""
			if "`fast'" == "" & "`saved_gmd'" != "yes" & "`raw'" == "" {
				di as text "To save the data locally for faster reloading, use: " "{stata gmd, version(`selected_version') fast(yes):gmd, version(`selected_version') fast(yes)}"
			}
            * -------------------------------------------------

            * Logic for raw/sources data (may lack countryname/id)
            if "`raw'" != "" | "`sources'" != "" {
                di as text "Final dataset: `r(N)' observations of `n_vars' variables"
                if "`version'" != "" di as text "Version: `version'"
                else di as text "Version: `selected_version'"
            }
            
            * Logic for standard GMD data
            else {
                if `n_vars' > 1 di as text "Final dataset: `r(N)' observations for `n_vars' variables"
                else di as text "Final dataset: `r(N)' observations for `n_vars' variable"

                if "`version'" != "" di as text "Version: `version'"
                else di as text "Version: `selected_version'"
            }    
        }
    }
    
end
