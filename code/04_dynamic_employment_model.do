* Authors: Klara S. Peter and Alina Malkova
** This do file estimates individual-level model of employment transitions associated with credit market accessibility 

clear
capture cd "C:\Users\kpeter\Dropbox\Credit market\Results"
global origin "C:\Users\kpeter\Dropbox\Credit market\Data"

***********************************************************************
*					Pre-estimation preparation
***********************************************************************

use "$origin\rlms_credit_workfile.dta", clear

rename empsta status
rename fempsta fstatus
global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global F "c.cindzsc##ib1.status"

xtset idind year
gen fgovtcl=f.govtcl  // SOEs closing during the year of switch
replace dist_obl=0 if indic_obl==1
gen lndist_obl=ln(1+dist_obl)

// keep estimation sample
keep if s1==1
gen formal=(fstatus==1)
reg formal cindzsc $X1 if status==2
xtset idind year

// initial conditions
egen wavefirst=min(year) if s1==1, by(idind)  
label var wavefirst "First time R appears in the sample"
foreach v in status {	
	gen _t1 = `v' if year==wavefirst
	egen `v'_ic=mean(_t1), by(idind)	
	label values `v'_ic empsta
	drop _*
}
foreach v in schadjC married nmember nage13y lnhhcon {	// time-varying variables except for age and year
	gen _t1 = `v' if year==wavefirst
	egen `v'_1=mean(_t1), by(idind)		// first period
	gen _t2 = `v' if year>wavefirst`i'
	egen `v'_R=mean(_t2), by(idind)		// means in the remaining periods
	drop _*
}

est use gsem_base
est store gsem_base
estimates esample: if s1
margins i.status, predict(outcome(1.fstatus)) dydx(cindzsc) nose 
margins i.status, predict(outcome(2.fstatus)) dydx(cindzsc) nose 
margins i.status, predict(outcome(3.fstatus)) dydx(cindzsc) nose

est use gsem_exog
est store gsem_exog
estimates esample: if s1
margins i.status, predict(outcome(1.fstatus)) dydx(cindzsc) nose 
margins i.status, predict(outcome(2.fstatus)) dydx(cindzsc) nose 
margins i.status, predict(outcome(3.fstatus)) dydx(cindzsc) nose

est use gsem_wrs
est store gsem_wrs
estimates esample: if s1

margins i.status, predict(outcome(1.fstatus)) dydx(cindzsc) 
margins i.status, predict(outcome(2.fstatus)) dydx(cindzsc) 
margins i.status, predict(outcome(3.fstatus)) dydx(cindzsc) 

margins i.status, predict(outcome(1.fstatus)) at(cindzsc=0) nose
margins i.status, predict(outcome(2.fstatus)) at(cindzsc=0) nose
margins i.status, predict(outcome(3.fstatus)) at(cindzsc=0) nose

margins i.status, predict(outcome(1.fstatus)) at(cindzsc=1) nose
margins i.status, predict(outcome(1.fstatus)) dydx(cindzsc) nose



xtreg formal cindzsc $X1 if status==2, re
xtreg formal cindzsc $X1 if status==2, fe

// initial conditions
egen wavefirst=min(year) if s1==1, by(idind)  
label var wavefirst "First time R appears in the sample"
foreach v in status {	
	gen _t1 = `v' if year==wavefirst
	egen `v'_ic=mean(_t1), by(idind)	
	label values `v'_ic empsta
	drop _*
}
qui foreach v in schadjC married nmember nage13y lnhhcon lnpopsite urban intervday cindzsc  {	// time-varying variables except for age and year
	gen _t1 = `v' if year==wavefirst
	egen `v'_1=mean(_t1), by(idind)		// first period
	drop _*
}
qui foreach v in schadjC married nmember nage13y lnhhcon lnpopsite urban intervday cindzsc  {	// time-varying variables except for age and year
	gen _t2 = `v' if year>wavefirst`i'
	egen `v'_R=mean(_t2), by(idind)		// means in the remaining periods
	drop _*
}
xtreg formal cindzsc $X1 *_1 *_R i.wavefirst if status==2, re

***********************************************************************
*		Dynamic Multinomial Logit Model of Employment Choice
***********************************************************************

capture log close
log using gsem_aggreg_index, replace
global F "c.cindzsc##ib1.status"

// Reduced-form
gsem (1.fstatus <- $F $X1 i.wavefirst) ///
     (3.fstatus <- $F $X1 i.wavefirst), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_base, replace

// Exogenous IC with random effect
gsem (1.fstatus <- $F $X1 i.wavefirst R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save  gsem_exog, replace

// WRS estimator
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_wrs, replace

// WRS estimator, no plan for taking a loan
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]) if inloan==0, ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_noplan, replace

// WRS estimator, no Moscow
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]) if ter~=1145, ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_nomosc, replace

// WRS estimator, additional controls
global AC "lngdpcapR unrate infldecMA fgovtcl lndist_obl"
gsem (1.fstatus <- $F $X1 $AC i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 $AC i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_addcont, replace

// WRS estimator, all CMA measures separately
global F "ib3.bankcat##ib1.status c.lnbdistS##ib1.status c.lnbdistO##ib1.status c.credpop2##ib1.status"
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_wrs_allmeas, replace

log close

// Heckman estimator
gen status0=status if year==wavefirst
gen shrgov=shrpub+shrmun

capture log close
log using gsem_heck, replace
global F "c.cindzsc##ib1.status"
note: X0 excludes year and first wave effects and interval between interviews
global X0 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban ib1.okrug"
global IC "dlnearn17 shrgov infperc govtcl"
gsem (1.fstatus <- $F $X1 R1[idind], mlogit) ///
	 (3.fstatus <- $F $X1 R2[idind], mlogit) ///
	 (1.status0 <- $IC $X0 R1[idind], mlogit) ///
	 (3.status0 <- $IC $X0 R2[idind], mlogit), ///
	 vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_heck, replace
log close

***********************************************************************
*					Tables 5-6
***********************************************************************

// Table 5: Dynamic Multinomial Logit Model of Employment Choice
global F "c.cindzsc##ib1.status"
reg fstatus $F $X1 i.wavefirst ib1.status_ic *_R *_1
outreg2 using tables_dynemp_main.xls, nocons sum dec(3) replace 
foreach v in  wrs {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_dynemp_main.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) nocons eform append addtext(Federal districts FE, YES, Year FE, YES, First wave FE, YES)
}

// Table 6A: Robustness Analysis of the Dynamic Employment Model
note: attrition-adjusted results are in Step CRM5
reg fstatus cindzsc  // fake column
outreg2 using tables_dynemp_altspec1.xls, nocons replace cti(fake) 
foreach v in base exog heck addcont  {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_dynemp_altspec1.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(c.cindzsc##ib1.status) nocons eform append
}
// Table 6B: Robustness Analysis of the Dynamic Employment Model
note: attrition-adjusted results are in Step CRM5
reg fstatus cindzsc  // fake column
outreg2 using tables_dynemp_altspec2.xls, nocons replace cti(fake) 
foreach v in  nomosc noplan wrs_attr3 {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_dynemp_altspec2.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(c.cindzsc##ib1.status) nocons eform append
}

// Table 8: Different Measures of Credit Market Accessibility
reg fstatus cindzsc  // fake column
outreg2 using tables_dynemp_allmeas.xls, nocons replace cti(fake)
foreach v in wrs_allmeas {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_dynemp_allmeas.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) nocons eform append
}

// Table A2_1: Dynamic Multinomial Logit Model of Employment Choice
reg fstatus cindzsc  // fake column
outreg2 using tables_dynemp_exogheck.xls, nocons replace cti(fake)
foreach v in exog heck {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_dynemp_exogheck.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) nocons eform append addtext(Federal districts FE, YES, Year FE, YES, First wave FE, YES)
}

