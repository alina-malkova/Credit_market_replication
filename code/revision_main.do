* Authors: Klara S. Peter and Alina Malkova
** This do file tests for reverse causality bias
** Tests whether banks enter areas when economy is stronger

*******************************************************************************
*                       SETUP
*******************************************************************************

use "$origin\rlms_credit_workfile.dta", clear

rename empsta status
rename fempsta fstatus

global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global F "c.cindzsc##ib1.status"

xtset id year

*******************************************************************************
*               Reverse Causality Tests
*******************************************************************************

* Test: Does anticipated credit access correlate with current labor outcomes?
* Concern: Banks may enter areas/periods when economy is stronger

* Test 1: Lagged credit index predicting informality share
reghdfe infperc l.cindzsc lnpopsite urban unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)

*******************************************************************************
*               Bank Entry Analysis
*******************************************************************************

* Create change variables for bank presence
gen change_sbernum = sbernum - l.sbernum
gen change_bankcap = bankcap - l.bankcap

* Test 2: Regional characteristics predicting Sberbank entry
reghdfe change_sbernum lnpopsite urban unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)

* Test 3: Regional characteristics predicting bank capital changes
reghdfe change_bankcap lnpopsite urban unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)
