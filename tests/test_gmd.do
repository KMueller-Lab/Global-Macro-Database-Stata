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

di _n "=== save() with replace (download 2)"
gmd, save("`scratch'/data", replace)
check `=_rc==0' "overwrite with replace ok"

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
