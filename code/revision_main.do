use "$origin\rlms_credit_workfile.dta", clear

rename empsta status
rename fempsta fstatus
global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global F "c.cindzsc##ib1.status"

* Reverse casuality bias

* anticipated access to credit leads to an improvement in labor market outcomes today (reverse causality bias). 
* It is also plausible that banks enter areas/periods when the economy is stronger, which correlates with more formality. 

xtset id year


reghdfe infperc l.cindzsc  lnpopsite urban  unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)

gen change_sbernum=sbernum-l.sbernum
gen change_bankcap=bankcap-l.bankcap



reghdfe change_sbernum  lnpopsite urban  unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)
reghdfe change_bankcap  lnpopsite urban  unrate gdpgrw shrpub lnwgregR cbdepinc morgrateR, absorb(i.year i.ter)
