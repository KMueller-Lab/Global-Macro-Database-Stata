*==============================================================================
* Stata Journal submission: gmd command examples
* Author: Mohamed Lehbib
* Date: September 2026
*
* Run from this folder. It holds the submitted gmd.ado and gmd.sthlp and the
* data file GMD_2025_09.dta, so the examples use the submitted version of the
* command and load the pinned data version from this folder without a
* download. Do not reinstall gmd from SSC here: that could replace the version
* under review.
*==============================================================================

capture log close
log using gmd_examples.log, text replace
clear all
set more off
version 15

* The current directory comes before PLUS on the ado-path, so this is the
* submitted gmd.ado; which shows its version line
discard
which gmd

* Packages used by the examples (not needed by gmd itself)
net install binsreg, from(https://raw.githubusercontent.com/nppackages/binsreg/main/stata) replace
ssc install winsor2, replace

*------------------------------------------------------------------------------
* Example 1: Revisiting Okun's Law
*------------------------------------------------------------------------------

* Load unemployment and real GDP data from the pinned 2025_09 version
gmd unemp rGDP, version(2025_09)
return list

* Set panel structure
xtset id year

* Calculate real GDP growth rate
gen rGDP_gr = (rGDP - L.rGDP) / L.rGDP

* Visualize Okun's Law relationship
binsreg unemp rGDP_gr if rGDP_gr < 0.1 & rGDP_gr > -0.1, ///
    xtitle("Real GDP Growth") ///
    ytitle("Unemployment") ///
    scheme(sj)

* Export graph with Stata Journal scheme
graph export okun_law.pdf, replace

*------------------------------------------------------------------------------
* Example 2: Two Eras of Money and Inflation
*------------------------------------------------------------------------------

* Load money supply and inflation data. clear discards the variables created
* in Example 1, as with use, clear.
gmd M2 infl, version(2025_09) clear

* Set panel structure
xtset id year

* Calculate M2 growth rate
gen M2_gr = 100 * ((M2 - L.M2) / L.M2)

* Winsorize at 1st and 99th percentiles
winsor2 infl M2_gr, cut(1 99) replace trim

* Pre-1963 era: Strong money-inflation link
xtreg infl M2_gr if year < 1963, fe cluster(id)

* Post-1963 era: Weakened money-inflation link
xtreg infl M2_gr if year >= 1963, fe cluster(id)

*------------------------------------------------------------------------------
log close
*==============================================================================
