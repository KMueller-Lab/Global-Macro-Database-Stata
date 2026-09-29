* Offline tests for the gmd package. Run from the repository root:
*   stata-mp -b do tests/test_gmd_offline.do   (log: test_gmd_offline.log)
* Internet access is switched off from inside Stata by pointing the HTTP proxy
* at a closed local port. Stata records proxy settings as permanent
* preferences, so the original values are saved first and always restored at
* the end; every command in between runs under capture so the do-file cannot
* stop before the reset.
* Needs GMD_2025_09.dta in tests/_scratch/data: run tests/test_gmd.do first.
clear all
set more off
set linesize 120

local root : pwd
adopath ++ "`root'/stata"
local scratch "`root'/tests/_scratch"
cap mkdir "`scratch'/personal"
cap mkdir "`scratch'/offline"
sysdir set PERSONAL "`scratch'/personal"
cap erase "`scratch'/personal/gmd_datadir.txt"

program define check
    args cond msg
    if `cond' di as text "PASS: `msg'"
    else {
        di as err "FAIL: `msg'"
        global fails = $fails + 1
    }
end
global fails 0

* Two versions side by side. The 2026_06 file is a marked copy of 2025_09, so
* the test can tell which file was loaded without a second download.
confirm file "`scratch'/data/GMD_2025_09.dta"
use "`scratch'/data/GMD_2025_09.dta", clear
qui save "`scratch'/offline/GMD_2025_09.dta", replace
char _dta[gmd_test_marker] "fake_2026_06"
qui save "`scratch'/offline/GMD_2026_06.dta", replace

* Signed files, built the way a signed release would be: a stamped and signed
* copy (2026_03), the same file under another version's name (2025_08), and a
* copy edited after signing (2026_01).
use "`scratch'/data/GMD_2025_09.dta", clear
char _dta[gmd_version] "2026_03"
label data "Global Macro Database, version 2026_03"
qui datasignature set, reset
qui save "`scratch'/offline/GMD_2026_03.dta", replace
qui save "`scratch'/offline/GMD_2025_08.dta", replace
char _dta[gmd_version] "2026_01"
qui replace year = year + 1 in 1
qui save "`scratch'/offline/GMD_2026_01.dta", replace
clear

local old_proxy "`c(httpproxy)'"
local old_host  "`c(httpproxyhost)'"
local old_port  "`c(httpproxyport)'"
cd "`scratch'/offline"
set httpproxyhost "127.0.0.1"
set httpproxyport 9
set httpproxy on

di _n "=== offline: pinned version stored locally"
cap noi gmd nGDP, version(2025_09) country(USA) years(2000)
check `=_rc==0 & "`r(version)'"=="2025_09"' "pinned local version loads offline"
check `="`: char _dta[gmd_test_marker]'"==""' "the 2025_09 file was loaded, not the newer one"

di _n "=== offline: pinned version not stored locally"
cap noi gmd nGDP, version(2025_12) country(USA) years(2000)
check `=_rc==498' "pinned version absent locally is an error, never replaced"
check `="`: char _dta[gmd_test_marker]'"==""' "previous data left in place"

di _n "=== offline: no version pinned"
cap noi gmd nGDP, country(USA) years(2000)
check `=_rc==0 & "`r(version)'"=="2026_06"' "most recent local version loads offline"
check `="`: char _dta[gmd_test_marker]'"=="fake_2026_06"' "the newest file was loaded"
cap noi gmd nGDP, version(current) country(USA) years(2000)
check `=_rc==0 & "`r(version)'"=="2026_06"' "version(current) reports the loaded version"

di _n "=== release stamp and data signature"
cap noi gmd, version(2026_03)
check `=_rc==0 & r(verified)==1 & "`r(datasignature)'"!=""' "signed release verifies"
cap datasignature confirm
check `=_rc==0' "full signed load keeps a valid signature"
cap noi gmd nGDP, version(2026_03) country(USA)
check `=_rc==0 & "`: char _dta[datasignature_si]'"==""' "filtered result carries no stale signature"
cap noi gmd nGDP, version(2026_01) country(USA)
check `=_rc==498' "file edited after signing is rejected"
cap noi gmd nGDP, version(2025_08) country(USA)
check `=_rc==498' "file renamed to another version is rejected"
cap noi gmd nGDP, version(2025_09) country(USA)
check `=_rc==0 & r(verified)==0 & "`r(datasignature)'"!=""' "unsigned release loads, signature still returned"

di _n "=== offline: calls that need the server"
cap noi gmd, version(list)
check `=_rc==498' "version(list) offline is an error and loads nothing"
cap noi gmd nGDP, raw version(2025_09)
check `=_rc==498' "raw offline rejected"
cap noi gmd, sources(IMF_WEO)
check `=_rc==498' "sources() offline rejected"
cap noi gmd, version(2025_12) save()
check `=_rc==498' "save() offline rejected"

* ---- always restore the proxy settings ----
cap noi set httpproxy `old_proxy'
cap noi set httpproxyhost "`old_host'"
cap noi set httpproxyport `old_port'
cap noi cd "`root'"
query network

di _n "=== SUMMARY: $fails failures"
if $fails > 0 exit 1
