* ==============================================================================
* GMD package
* ==============================================================================
*
* BIB TO DATAFRAME - Convert BibTeX file to CSV
* 
* Description: 
* This Stata script takes a bib file with BibTeX citations and turns them into
* a CSV file with two columns: source (citation key) and citation (flattened entry)
* 
* Created: 
* 2026-01-08
* 
* Author:
* Mohamed Lehbib
* National University of Singapore
* 	
* ==============================================================================

* ==============================================================================
* DEFINE PROGRAM SYNTAX
* ==============================================================================

cap program drop bib_to_df
program define bib_to_df
    syntax using/, SAVing(string) 
    
    * ==============================================================================
    * READ THE BIB FILE
    * ==============================================================================
    
    * Check if file exists
    capture confirm file `"`using'"'
    if _rc != 0 {
        display as error "Error: File not found at `using'"
        exit 601
    }
    
    * Read the entire bib file into memory
    tempname fh
    file open `fh' using `"`using'"', read text
    
    * Initialize locals for parsing
    local full_content ""
    local line_num = 0
    
    * Read all lines and concatenate
    file read `fh' line
    while r(eof) == 0 {
        * Replace tabs with spaces and append
        local line = subinstr(`"`line'"', char(9), " ", .)
        local full_content `"`full_content' `line'"'
        file read `fh' line
    }
    file close `fh'
    
    * ==============================================================================
    * PARSE BIB ENTRIES
    * ==============================================================================
    
    * Create a temporary dataset to store results
    clear
    qui set obs 0
    gen source = ""
    gen citation = ""
    
    * Split content by @ symbol (start of each entry)
    * We need to iterate through and find each entry
    
    * Count approximate number of entries (count @ symbols)
    local content_copy `"`full_content'"'
    local entry_count = 0
    while strpos(`"`content_copy'"', "@") > 0 {
        local pos = strpos(`"`content_copy'"', "@")
        local content_copy = substr(`"`content_copy'"', `pos' + 1, .)
        local entry_count = `entry_count' + 1
    }
    
    display as txt "Found approximately `entry_count' entries"
    
    * Process each entry using fileread for better handling
    * Re-read the file and process entry by entry
    
    tempfile entries_file
    
    file open `fh' using `"`using'"', read text
    
    local current_entry ""
    local in_entry = 0
    local brace_count = 0
    local entry_num = 0
    
    * Create results dataset
    clear
    gen source = ""
    gen citation = ""
    
    file read `fh' line
    while r(eof) == 0 {
        local line = strtrim(`"`line'"')
        
        * Check if this line starts a new entry
        if regexm(`"`line'"', "^@[a-zA-Z]+\{") {
            * If we were already in an entry, save the previous one
            if `in_entry' == 1 & `"`current_entry'"' != "" {
                * Extract citation key from current entry
                local entry_clean = strtrim(`"`current_entry'"')
                
                if regexm(`"`entry_clean'"', "@[a-zA-Z]+\{([^,]+),") {
                    local key = regexs(1)
                    local key = strtrim("`key'")
                    
                    * Flatten entry (replace newlines/multiple spaces with single space)
                    local flat_entry = subinstr(`"`entry_clean'"', char(10), " ", .)
                    local flat_entry = subinstr(`"`flat_entry'"', char(13), " ", .)
                    local flat_entry = stritrim(`"`flat_entry'"')
                    
                    * Add to dataset
                    local entry_num = `entry_num' + 1
                    qui set obs `entry_num'
                    qui replace source = "`key'" in `entry_num'
                    qui replace citation = `"`flat_entry'"' in `entry_num'
                }
            }
            
            * Start new entry
            local current_entry `"`line'"'
            local in_entry = 1
        }
        else if `in_entry' == 1 {
            * Continue building current entry
            local current_entry `"`current_entry' `line'"'
        }
        
        file read `fh' line
    }
    
    * Don't forget the last entry
    if `in_entry' == 1 & `"`current_entry'"' != "" {
        local entry_clean = strtrim(`"`current_entry'"')
        
        if regexm(`"`entry_clean'"', "@[a-zA-Z]+\{([^,]+),") {
            local key = regexs(1)
            local key = strtrim("`key'")
            
            local flat_entry = subinstr(`"`entry_clean'"', char(10), " ", .)
            local flat_entry = subinstr(`"`flat_entry'"', char(13), " ", .)
            local flat_entry = stritrim(`"`flat_entry'"')
            
            local entry_num = `entry_num' + 1
            qui set obs `entry_num'
            qui replace source = "`key'" in `entry_num'
            qui replace citation = `"`flat_entry'"' in `entry_num'
        }
    }
    
    file close `fh'
    
    * ==============================================================================
    * SAVE OUTPUT
    * ==============================================================================
    export delimited using `"`saving'"', replace
    
    
end

bib_to_df using "$datahelpers/bib.bib", saving("$datahelpers/bib_dataframe.csv") 
