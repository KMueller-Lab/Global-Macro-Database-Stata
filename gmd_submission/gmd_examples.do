*==============================================================================
* Stata Journal submission: gmd command examples
* Author: Mohamed Lehbib
* Date: January 2026
*==============================================================================

capture log close
log using gmd_examples.log, text replace

* Install required packages
ssc install missings, replace
ssc install gmd, replace
net install binsreg, from(https://raw.githubusercontent.com/nppackages/binsreg/master/stata) replace
ssc install winsor2, replace

*------------------------------------------------------------------------------
* Example 1: Revisiting Okun's Law
*------------------------------------------------------------------------------

* Download unemployment and real GDP data
gmd unemp rGDP, version(2025_09)

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

* Download money supply and inflation data
gmd M2 infl, version(2025_09)

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
