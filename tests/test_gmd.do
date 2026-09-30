* Smoke tests for the gmd package. Run from the repository root:
*   stata-mp -b do tests/test_gmd.do   (log: test_gmd.log in the root)
* Uses a scratch PERSONAL dir so the real gmd_datadir.txt pointer is untouched.
* The full dataset is downloaded only by the save() tests (three times in
* total); every other main-dataset call reads the saved local copy.
clear all
set more off
set linesize 120

local root : pwd
adopath ++ "`root'/stata"
local scratch "`root'/tests/_scratch"
cap mkdir "`scratch'"
cap mkdir "`scratch'/personal"
cap mkdir "`scratch'/data"
cap mkdir "`scratch'/proj"
sysdir set PERSONAL "`scratch'/personal"
cap erase "`scratch'/personal/gmd_datadir.txt"
foreach d in data proj {
    local datafiles : dir "`scratch'/`d'" files "*.dta"
    foreach f of local datafiles {
        erase "`scratch'/`d'/`f'"
    }
}

program define check
    args cond msg
    if `cond' di as text "PASS: `msg'"
    else {
        di as err "FAIL: `msg'"
        global fails = $fails + 1
    }
end
global fails 0

* ---- info-only calls (small helper files only) ----
di _n "=== version(list)"
gmd, version(list)
di _n "=== vars(list)"
gmd, vars(list)
di _n "=== country(list)"
gmd, country(list)
di _n "=== sources(list)"
gmd, sources(list)
di _n "=== cite(GMD)"
gmd, cite(GMD)
di _n "=== cite() leaves user scalars alone"
scalar cit_text = 42
scalar tmp_line = 7
gmd, cite(GMD)
check `=scalar(cit_text)==42 & scalar(tmp_line)==7' "user scalars survive cite()"
scalar drop cit_text tmp_line
di _n "=== print(GMD)"
gmd, print(GMD)

* ---- save(): the only full downloads in this suite ----
di _n "=== save() to nonexistent folder: expect error (no download)"
cap noi gmd, save("`scratch'/nope")
check `=_rc==498' "save() to missing folder rejected"

di _n "=== save() to folder (download 1)"
gmd, save("`scratch'/data")
local saved : dir "`scratch'/data" files "GMD_*.dta"
di `"saved files: `saved'"'
local nsaved : word count `saved'
check `=`nsaved'>0' "GMD_<version>.dta written"
check `=c(changed)==0' "data flagged unchanged after save()"
cap confirm file "`scratch'/personal/gmd_datadir.txt"
check `=_rc==0' "pointer file written"
type "`scratch'/personal/gmd_datadir.txt"

di _n "=== save() again without replace: expect error (no download)"
cap noi gmd, save("`scratch'/data")
check `=_rc==498' "overwrite without replace rejected"

di _n "=== save () with a space and a relative path, replace (download 2)"
cd "`scratch'"
gmd, save ("data", replace)
cd "`root'"
check `=_rc==0' "overwrite with replace ok"
tempname pf
file open `pf' using "`scratch'/personal/gmd_datadir.txt", read text
file read `pf' ptr
file close `pf'
check `="`ptr'"=="`scratch'/data"' "relative save() path remembered as an absolute path"

di _n "=== save(replace) in pwd for an older version (download 3)"
cd "`scratch'/data"
gmd, version(2025_09) save(replace)
cap confirm file "`scratch'/data/GMD_2025_09.dta"
check `=_rc==0' "save(replace) writes GMD_2025_09.dta in pwd"
cd "`root'"

* ---- everything below loads from the local copies ----
di _n "=== gmd nGDP, country(USA) years(2000/2005)"
gmd nGDP, country(USA) years(2000/2005)
check `=_N==6' "6 obs for USA 2000-2005"
check `=c(changed)==0' "data flagged unchanged after load"

* ---- clear protection ----
gen x = 1
di _n "=== clear protection: expect error"
cap noi gmd nGDP, country(USA) years(2000/2005)
check `=_rc==4' "refuses to overwrite changed data (rc 4)"
cap noi gmd, vars(list)
check `=_rc==0' "info-only call allowed with changed data"
gmd nGDP, country(USA) years(2000/2005) clear
check `=_rc==0' "clear option proceeds"
gmd pop, country(USA) years(2000/2005)
check `=_rc==0' "second gmd call needs no clear after a plain gmd load"
gmd, vars(load)
gmd, cite(load)
gmd, sources(load)
gmd, country(load)
gmd, sources(IMF_WEO)
gmd nGDP, raw country(USA)
gmd nGDP, country(USA)
check `=_rc==0' "load/list helpers and raw/sources do not leave the changed flag set"

* ---- income filter ----
di _n "=== income filter"
gmd nGDP, income(H) years(2010)
check `=_N>0' "income(H) returns rows"
cap confirm var income_group
check `=_rc!=0' "income_group dropped when varlist given"
gmd, income("Low income") years(2015)
qui count if income_group != "Low income"
check `=r(N)==0' "income(Low income) full load keeps only Low income"

* ---- error paths ----
di _n "=== error paths"
cap noi gmd nGDP, sources(IMF_IFS) years(2000)
check `=_rc==198' "sources()+years() rejected"
cap noi gmd, sources(IMF_IFS) version(2025_09)
check `=_rc==198' "sources()+version() rejected"
cap noi gmd nGDP, raw income(H)
check `=_rc==198' "raw+income() rejected"
cap noi gmd notavar
check `=_rc==498' "invalid variable rejected"
cap noi gmd nGDP, country(ZZZ)
check `=_rc==498' "invalid country rejected"
check `=c(changed)==0' "failed filter restores previous data unchanged"
cap noi gmd nGDP, years(1000)
check `=_rc==498' "no observations for years() rejected"
cap noi gmd nGDP, version(1999_01)
check `=_rc==498' "invalid version rejected"

* ---- local versions ----
di _n "=== reload from pointer"
gmd nGDP, country(FRA)
check `=_N>0' "loaded from local copy"
di _n "=== specific version from local dir"
gmd nGDP, version(2025_09) country(DEU)
check `=_N>0' "version(2025_09) from local dir"

di _n "=== cwd with only an old version: expect local load + newer-version notice"
copy "`scratch'/data/GMD_2025_09.dta" "`scratch'/proj/GMD_2025_09.dta", replace
cd "`scratch'/proj"
gmd nGDP, country(ITA)
check `=_N>0' "loaded from cwd copy"
check `=c(changed)==0' "cwd load leaves data unchanged"
cd "`root'"

* ---- raw / sources ----
di _n "=== raw"
gmd nGDP, raw country(USA) years(2000/2001)
check `=_N==2' "raw USA 2000-2001"
di _n "=== sources(IMF_WEO) nGDP"
gmd nGDP, sources(IMF_WEO) country(USA)
check `=_N>0' "sources(IMF_WEO) nGDP USA"

* ---- stored results and reported version ----
di _n "=== stored results"
gmd nGDP pop, version(2025_09) country(USA) years(2000/2001)
check `="`r(version)'"=="2025_09"' "r(version) is the loaded version"
check `=r(N)==2 & r(k)==6' "r(N) and r(k)"
check `="`r(varlist)'"=="nGDP pop"' "r(varlist) lists the data variables"
check `="`r(origin)'"=="local"' "r(origin) is local for a saved copy"
gmd nGDP, version(current) country(USA) years(2000)
check `=regexm("`r(version)'", "^[0-9][0-9][0-9][0-9]_[0-9][0-9]$")' "version(current) resolves to YYYY_MM"
gmd nGDP, raw version(2025_09) country(USA) years(2000)
check `="`r(version)'"=="2025_09" & "`r(origin)'"=="download"' "raw returns r(version), origin download"

* ---- case-insensitive input and wildcards ----
di _n "=== case-insensitive input"
gmd ngdp CPI Pop, version(2025_09) country(usa) years(2000)
check `="`r(varlist)'"=="nGDP CPI pop"' "variable names resolved up to case"
gmd *_gdp, version(2025_09) country(USA) years(2000)
cap confirm variable CA_GDP exports_GDP, exact
check `=_rc==0' "wildcard *_gdp expands"
cap noi gmd unem, version(2025_09)
check `=_rc==498' "abbreviation unem rejected"
cap noi gmd nGDP notavar, version(2025_09)
check `=_rc==498' "one invalid name among valid ones rejected"
gmd nGDP, version(Current) country(USA) years(2000)
check `=_rc==0' "version(Current) accepted"
cap noi gmd, country(LIST)
check `=_rc==0 & c(changed)==0' "country(LIST) lists without loading"
cap noi gmd, version(LIST)
check `=_rc==0' "version(LIST) accepted"
cap noi gmd nGDP, vars(banana)
check `=_rc==198' "unknown vars() argument rejected"
cap noi gmd nGDP, version(2025_09 2025_12)
check `=_rc==198' "multi-word version() returns an error code"

* ---- sources(): country filter, several variables, names ----
di _n "=== sources() fixes"
gmd, sources(imf_weo) country(usa fra)
local rsources "`r(sources)'"
qui levelsof ISO3, local(isos) clean
check `="`isos'"=="FRA USA"' "sources() without varlist honours country() with several codes"
check `="`rsources'"=="IMF_WEO"' "r(sources) holds the corrected source name"
gmd ngdp POP, sources(IMF_WEO) country(USA)
cap confirm variable IMF_WEO_nGDP IMF_WEO_pop, exact
check `=_rc==0 & c(k)==4' "sources() accepts several variables, up to case"
cap noi gmd nGDP, sources(IMF_WEO) country(ZZZ)
check `=_rc==498' "sources() invalid country rejected"
cap noi gmd nGDP, sources(IMF_WEO) country(USA ZZZ)
check `=_rc==498' "sources() one invalid country among several rejected"
cap noi gmd nGDP banana, sources(IMF_WEO)
check `=_rc==498' "sources() invalid variable returns an error code"
gmd nGDP, sources(cs1_usa)
cap confirm variable CS1_nGDP, exact
check `=_rc==0' "sources(cs1_usa) with a variable"
gmd CPI, sources(CS10_ITA)
cap confirm variable CS10_CPI, exact
check `=_rc==0 & c(k)==3' "sources(CS10_ITA) with a variable: two-digit slot"
gmd, sources(cs10_ita)
check `=_N>0 & "`r(sources)'"=="CS10_ITA"' "sources(cs10_ita) loads ITA_10"
gmd, sources(ITA_10)
check `=_N>0' "sources(ITA_10), the file name, still loads"
gmd m3_gdp, sources(ARG_1)
cap confirm variable CS1_M3_GDP, exact
check `=_rc==0 & c(k)==3' "sources(ARG_1), the file name, with a variable"
gmd infl, sources(BIS_CPI) country(USA)
cap confirm variable BIS_infl, exact
check `=_rc==0' "source whose variables use another prefix"

* ---- raw: name lookup and restore on error ----
di _n "=== raw fixes"
gmd ngdp, raw country(USA) years(2000)
check `=_N==1' "raw variable resolved up to case"
cap noi gmd banana, raw
check `=_rc==498' "raw invalid variable rejected"
gmd pop, version(2025_09) country(USA) years(2000)
cap noi gmd nGDP, raw country(ZZZ)
cap confirm variable pop, exact
check `=_rc==0 & _N==1' "failed raw filter restores the previous data"

* ---- load helpers ----
gmd, country(load)
check `=_N>0' "country(load)"
gmd, vars(load)
check `=_N>0' "vars(load)"
gmd, cite(load)
check `=_N>0' "cite(load)"
gmd, sources(load)
check `=_N>0' "sources(load)"

di _n "=== SUMMARY: $fails failures"
if $fails > 0 exit 1
