*! version 2.0.0 10jan2026 Mohamed Lehbib and Karsten Müller

********************************************************************************
* Initial set up and syntax 
********************************************************************************

cap program drop gmd
program define gmd
    version 15.0

    * Capture the raw command line so we can tell whether save() was specified
    * (syntax cannot distinguish an empty save() from save() being absent).
    local rawcmd `"`0'"'

    * Define syntax with optional arguments for version, country, raw data, etc.
    syntax [anything] [, VErsion(string) COUntry(string) Years(numlist) INCome(string) Raw VARS(string) Sources(string) CITE(string) print(string) Network(string) SAVE(string asis) CLEAR]
    
    * Calculate number of variables 
    local word_count = wordcount("`anything'")

    * --- Parse the save() option ---------------------------------------------
    * save() stores the data locally. Forms:
    *   save()                       save to the current working directory
    *   save(replace)                save to the current working directory, overwrite
    *   save("/full/path")           save to that existing folder
    *   save("/full/path", replace)  save to that folder, overwrite
    local save_specified = 0
    if strpos(lower(`"`rawcmd'"'), "save(") | `"`save'"' != "" {
        local save_specified = 1
    }
    local save_dir ""
    local save_replace = 0
    if `save_specified' {
        local svcontent = trim(`"`save'"')
        if `"`svcontent'"' != "" {
            local cpos = strrpos(`"`svcontent'"', ",")
            local tail = ""
            if `cpos' > 0 {
                local tail = trim(substr(`"`svcontent'"', `cpos' + 1, .))
            }
            if lower(`"`tail'"') == "replace" {
                local save_replace = 1
                local save_dir = trim(substr(`"`svcontent'"', 1, `cpos' - 1))
            }
            else if lower(`"`svcontent'"') == "replace" {
                local save_replace = 1
                local save_dir ""
            }
            else {
                local save_dir `"`svcontent'"'
            }
        }
        * Strip surrounding double quotes from the path, if present
        if substr(`"`save_dir'"', 1, 1) == char(34) & substr(`"`save_dir'"', -1, 1) == char(34) {
            local save_dir = substr(`"`save_dir'"', 2, strlen(`"`save_dir'"') - 2)
        }
    }

    * --- Read the data-directory pointer --------------------------------------
    * A one-line text file in the personal directory holding the full path to
    * the user's chosen data folder. It persists across Stata sessions.
    local pointer "`c(sysdir_personal)'gmd_datadir.txt"
    local datadir ""
    cap confirm file "`pointer'"
    if _rc == 0 {
        tempname pf
        cap file open `pf' using "`pointer'", read text
        if _rc == 0 {
            file read `pf' datadir
            file close `pf'
            local datadir = trim(`"`datadir'"')
        }
    }

    * The current working directory takes precedence over the remembered folder
    * whenever it already holds GMD data. Each project can therefore keep its own
    * copy (and version) of the data next to its do-files.
    local cwdfiles : dir `"`c(pwd)'"' files "GMD_*.dta"
    if `"`cwdfiles'"' != "" {
        local datadir `"`c(pwd)'"'
    }
	
     
********************************************************************************
* Setting package version
********************************************************************************

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
* Protect data in memory
* Refuse to replace unsaved data in memory unless clear is specified, mirroring
* Stata's use/clear convention. Display-only calls (lists, single citations) are
* exempt because they preserve/restore the user's data.
********************************************************************************
    local info_only = 0
    if "`print'" != "" local info_only = 1
    if "`version'" == "list" local info_only = 1
    if "`cite'" != "" & "`cite'" != "load" local info_only = 1
    if "`vars'" == "list" local info_only = 1
    if "`sources'" == "list" local info_only = 1
    if "`country'" == "list" local info_only = 1
    if !`info_only' & "`clear'" == "" & c(changed) == 1 {
        di as err "no; data in memory would be lost"
        di as text "You have unsaved changes in memory. Add the {cmd:clear} option to replace the data, or save your work first."
        exit 4
    }

********************************************************************************
* Reject incompatible option combinations
* years() and income() are post-load filters applied near the end of the
* program. The sources() branch loads a source dataset and exits before those
* filters run, and source/raw data carry neither an income_group column nor the
* panel shape those filters assume. Catch the combination up front so the filter
* is never silently ignored.
********************************************************************************
    if "`sources'" != "" & ("`years'" != "" | "`income'" != "") {
        di as err "years() and income() cannot be combined with sources()."
        di as text "Those filters apply to the main GMD dataset, not the source datasets returned by sources()."
        exit 198
    }
    if "`raw'" != "" & "`income'" != "" {
        di as err "The income() option cannot be combined with raw."
        di as text "income() needs the income_group column, which only the main GMD dataset carries."
        exit 198
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
        local latest_version = versions in 1
        qui levelsof versions, local(available_versions) clean
        
        * If user asks for list of versions, print and exit
        if "`version'" == "list" {
            foreach ver of local available_versions {
                di as text "`ver'"
            }
            di as text ""
            di as text `"For changes between versions, see {browse "https://www.globalmacrodata.com/data#release-notes":the release notes}."'
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
		* (local data lives in the saved data directory recorded by the pointer)
		
		* Check if the dataset is saved locally
		local local_file ""
		local local_version ""
		if `"`datadir'"' != "" {
		    local best = 0
		    local localfiles : dir `"`datadir'"' files "GMD_*.dta"
		    foreach f of local localfiles {
		        local v = subinstr(subinstr(`"`f'"', "GMD_", "", 1), ".dta", "", 1)
		        local vnum = real(subinstr("`v'", "_", "", 1))
		        if `vnum' > `best' {
		            local best = `vnum'
		            local local_version "`v'"
		            local local_file `"`f'"'
		        }
		    }
		}
		if `"`local_file'"' != "" {
		    cap confirm file `"`datadir'/`local_file'"'
		}
		else {
		    cap confirm file `"`datadir'/__gmd_none__.dta"'
		}
		
		* If it's saved locally, store its path in a local macro
		if _rc == 0 {
			local saved_gmd "yes"
			local gmd_df `"`datadir'/`local_file'"'
			local selected_version "`local_version'"			
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
            gmd_unchanged
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
                gmd_unchanged
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
							gmd_unchanged
							exit
						}
						else {
							di as err "Country code not valid, returning data for all countries."	
							di as text "To print the list of countries: " "{stata gmd, country(list):gmd, country(list)}"
							di as text "To load the list of countries: " "{stata gmd, country(load):gmd, country(load)}"
						}
					}
                    restore, not 
                    gmd_unchanged
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
				gmd_unchanged
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
        gmd_unchanged
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
        * Definition prints in full in the LAST column; long ones wrap. The
        * header rule is sized to fit the current window.
        qui ds
        qui gen varlength  = strlen(variable)
        qui gen unitlength = strlen(units)
        qui gen deflength  = strlen(definition)
        qui su varlength
        local varcol = r(max) + 2
        qui su unitlength
        local unitcol = `varcol' + r(max) + 2
        qui su deflength
        local tablewidth = min(`unitcol' + r(max), c(linesize))

        di as text _newline "Available variables:" _newline
        di as text "{hline `tablewidth'}"
        di as text "Variable" _col(`varcol') "Units" _col(`unitcol') "Definition"
        di as text "{hline `tablewidth'}"

        qui count
        local total = r(N)
        forvalues i = 1/`total' {
            local vname  = variable[`i']
            local vunits = units[`i']
            local vdesc  = definition[`i']
            di as text "`vname'" _col(`varcol') "`vunits'" _col(`unitcol') "`vdesc'"
        }
        di as text "{hline `tablewidth'}"
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
        cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/countrylist.dta", clear
        if _rc != 0 {
            di `"Unable to access country list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore
            exit
        }
        restore, not
        gmd_unchanged
        exit
    }

    * Helper: Display country list
    else if "`country'" == "list" {
        preserve
        cap use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/helpers/countrylist.dta", clear
        if _rc != 0 {
            di `"Unable to access country list. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
            restore
            exit
        }
        keep countryname ISO3
        qui gen _namelen = strlen(countryname)
        qui su _namelen
        local cwidth = 12 + r(max)
        qui drop _namelen
        local old_linesize = c(linesize)
        if `cwidth' > `old_linesize' {
            qui set linesize `=min(`cwidth', 255)'
        }
        di as text _newline "Available countries:" _newline
        di as text "{hline `cwidth'}"
        di as text "ISO3 code" _col(12) "Country name"
        di as text "{hline `cwidth'}"
        qui count
        local total = r(N)
        forvalues i = 1/`total' {
            local iso3  = ISO3[`i']
            local cname = countryname[`i']
            di as text "`iso3'" _col(12) "`cname'"
        }
        di as text "{hline `cwidth'}"
        qui set linesize `old_linesize'
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
        * Load the data: save() persists locally; otherwise use the saved copy or download
        if `save_specified' {
            * save(): download the selected version and store it in the chosen folder
            local save_target `"`save_dir'"'
            if `"`save_target'"' == "" {
                local save_target `"`c(pwd)'"'
            }

            * The target folder must already exist
            local dir_exists = 0
            cap mata: st_local("dir_exists", strofreal(direxists(st_local("save_target"))))
            if "`dir_exists'" != "1" {
                di as err `"The folder does not exist: `save_target'"'
                di as text `"Provide a full path to an existing folder, e.g. save("/full/path")."'
                restore
                exit 498
            }

            * Require replace before overwriting an existing file
            local target_file `"`save_target'/GMD_`selected_version'.dta"'
            cap confirm file `"`target_file'"'
            if _rc == 0 & `save_replace' == 0 {
                di as err `"File already exists: `target_file'"'
                di as text `"Add replace to overwrite, e.g. save("`save_target'", replace)."'
                restore
                exit 498
            }

            * Download the selected version
            cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear
            if _rc != 0 {
                di `"Unable to load the data. Please raise an issue at {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata"}."'
                restore
                exit 498
            }

            * Save it and record the directory in the pointer file
            qui save `"`target_file'"', replace
            cap mkdir "`c(sysdir_personal)'"
            tempname pf
            qui file open `pf' using "`pointer'", write replace text
            file write `pf' `"`save_target'"' _n
            file close `pf'
            di as text `"GMD `selected_version' saved to `save_target'."'
            local gmd_df `"`target_file'"'
            local saved_gmd "yes"
        }
        else if `"`datadir'"' != "" {
            * A data directory is remembered: load from it
            if "`version'" != "" {
                * User asked for a specific version
                local target_file `"`datadir'/GMD_`selected_version'.dta"'
                cap confirm file `"`target_file'"'
                if _rc == 0 {
                    di as text "Loading the local version (GMD_`selected_version')."
                    qui use `"`target_file'"', clear
                    local saved_gmd "yes"
                    local gmd_df `"`target_file'"'
                }
                else {
                    di as text `"GMD_`selected_version'.dta not found in `datadir'. Downloading version `selected_version'."'
                    cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear
                }
            }
            else {
                * Default: load the most recent local version
                local best = 0
                local local_version ""
                local local_file ""
                local localfiles : dir `"`datadir'"' files "GMD_*.dta"
                foreach f of local localfiles {
                    local v = subinstr(subinstr(`"`f'"', "GMD_", "", 1), ".dta", "", 1)
                    local vnum = real(subinstr("`v'", "_", "", 1))
                    if `vnum' > `best' {
                        local best = `vnum'
                        local local_version "`v'"
                        local local_file `"`f'"'
                    }
                }
                if `"`local_file'"' != "" {
                    di as text "Loading the local version (GMD_`local_version')."
                    qui use `"`datadir'/`local_file'"', clear
                    local saved_gmd "yes"
                    local gmd_df `"`datadir'/`local_file'"'
                    local selected_version "`local_version'"
                    if "`latest_version'" != "" & `best' > 0 {
                        local latestnum = real(subinstr("`latest_version'", "_", "", 1))
                        if `latestnum' > `best' {
                            di as text "A newer version (GMD_`latest_version') is available."
                            di as text `"Update with: {stata gmd, save("`datadir'"):gmd, save("`datadir'")}"'
                        }
                    }
                }
                else {
                    di as text `"No local GMD data found in `datadir'. Downloading version `selected_version'."'
                    cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear
                }
            }
        }
        else {
            * No saved location: download without persisting
            cap qui use "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_`selected_version'.dta", clear
        }
    }

		else if "`gmd_df'" != "" & "`raw'" == "" {
		qui use "`gmd_df'", clear 
	}

	* The preserve above stays active until every filter below has succeeded.
	* If a filter exits with an error, Stata restores the user's original data
	* automatically, as use would.
	
    * --- BRANCH 4: MAIN DATASET ---		
    * Only runs if country is not load/list AND no other data was loaded above
    if "`anything'" != "" & "`raw'" == "" {
	   
			* Opens specified version (default = current version)
			
            cap confirm variable `anything', exact
            if _rc == 0 {
                if "`income'" != "" {
                    * Retain income_group so the income() filter can run below
                    cap confirm variable income_group, exact
                    if _rc == 0 {
                        qui keep ISO3 year id countryname income_group `anything'
                    }
                    else {
                        qui keep ISO3 year id countryname `anything'
                    }
                }
                else {
                    qui keep ISO3 year id countryname `anything'
                }

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
* Years option (post-load filtering)
* Keeps only the requested years from the loaded panel. Works on the main
* dataset and on raw data, both of which carry a year variable. The numlist is
* already expanded and validated by the syntax command, so bad input (e.g. a
* non-integer or a malformed range) is rejected before reaching this block.
********************************************************************************
    if "`years'" != "" {
        cap confirm variable year, exact
        if _rc != 0 {
            di as err "The years() option requires a year variable, which is not available for the loaded data."
            exit 498
        }

        * Build a keep flag by looping over the requested years
        qui gen byte keep_year = 0
        foreach yr of numlist `years' {
            qui replace keep_year = 1 if year == `yr'
        }

        qui count if keep_year == 1
        if r(N) == 0 {
            di as err "No observations found for the requested year(s): `years'."
            di as text "Load the data without the years() option to see which years are available."
            drop keep_year
            exit 498
        }
        qui keep if keep_year == 1
        qui drop keep_year
    }

********************************************************************************
* Income-group option (post-load filtering)
* Keeps only countries in the requested World Bank income group(s), read from
* the income_group variable carried by the main dataset. Values in the data are
* "High income", "Upper middle income", "Lower middle income" and "Low income".
********************************************************************************
    if "`income'" != "" {
        cap confirm variable income_group, exact
        if _rc != 0 {
            di as err "The income() option is only available for the main GMD dataset."
            di as text "It cannot be combined with raw or sources data, which carry no income group."
            exit 498
        }

        * Normalise the input: lowercase, collapse the known multi-word phrases
        * into single tokens, turn commas into spaces, then trim. After this each
        * word is a single token that can be mapped to a canonical group value.
        local inc_in = lower(`"`income'"')
        local inc_in : subinstr local inc_in "lower middle income" "lowermiddleincome", all
        local inc_in : subinstr local inc_in "upper middle income" "uppermiddleincome", all
        local inc_in : subinstr local inc_in "lower middle" "lowermiddleincome", all
        local inc_in : subinstr local inc_in "upper middle" "uppermiddleincome", all
        local inc_in : subinstr local inc_in "high income" "highincome", all
        local inc_in : subinstr local inc_in "low income" "lowincome", all
        local inc_in = subinstr(`"`inc_in'"', ",", " ", .)
        local inc_in = trim(itrim(`"`inc_in'"'))

        qui gen byte keep_income = 0
        local invalid_income ""
        foreach tok of local inc_in {
            local cval ""
            if inlist("`tok'", "highincome", "high", "h", "hic", "hi") {
                local cval "High income"
            }
            else if inlist("`tok'", "uppermiddleincome", "um", "umc", "umic", "umi", "upper") {
                local cval "Upper middle income"
            }
            else if inlist("`tok'", "lowermiddleincome", "lm", "lmc", "lmic", "lmi", "lower") {
                local cval "Lower middle income"
            }
            else if inlist("`tok'", "lowincome", "low", "l", "lic", "li") {
                local cval "Low income"
            }

            if "`cval'" != "" {
                qui replace keep_income = 1 if income_group == "`cval'"
            }
            else {
                local invalid_income "`invalid_income' `tok'"
            }
        }

        * Reject unrecognised income groups
        local invalid_income = trim(itrim("`invalid_income'"))
        if "`invalid_income'" != "" {
            di as err "Invalid income group(s): `invalid_income'"
            di as text "Valid groups: High income, Upper middle income, Lower middle income, Low income."
            di as text "Abbreviations are allowed, e.g. H, UM, LM, L (or HIC, UMC, LMC, LIC)."
            drop keep_income
            exit 498
        }

        qui count if keep_income == 1
        if r(N) == 0 {
            di as err "No observations found for the requested income group(s): `income'."
            drop keep_income
            exit 498
        }
        qui keep if keep_income == 1
        qui drop keep_income

        * income_group is a helper column. Drop it when the user requested a
        * specific varlist so the result mirrors a plain variable selection.
        if "`anything'" != "" {
            cap drop income_group
        }
    }

********************************************************************************
* Display dataset descriptives
********************************************************************************
    
    * Drop variables that are completely missing in the filtered subset
    foreach v of varlist _all {
        qui count if !missing(`v')
        if r(N) == 0 {
            drop `v'
        }
    }
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
			if "`saved_gmd'" != "yes" & "`raw'" == "" {
				di as text `"To save the data locally for faster reloading, use: gmd, save("/full/folder/path")"'
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

    * Success: keep the loaded data and do not flag it as unsaved work
    restore, not
    gmd_unchanged

end

********************************************************************************
* Helper: mark the data in memory as unchanged
* gmd builds the returned dataset with keep/drop/import, which sets c(changed).
* The result is a fresh load, not the user's own work, so a subsequent gmd call
* should not demand clear. Saving to a tempfile is the only way to reset the
* flag from within a program.
********************************************************************************
program define gmd_unchanged
    if _N == 0 exit
    tempfile gmd_tmp
    qui save "`gmd_tmp'"
end
