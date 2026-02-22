* Authors: Klara S. Peter and Alina Malkova
** This do file estimates individual-level model of employment transitions associated with credit market accessibility 


clear
capture cd "C:\Users\kpeter\Dropbox\Credit market\Results"
global origin "C:\Users\kpeter\Dropbox\Credit market\Data"

********************************************************************************
*					Pre-estimation preparation
********************************************************************************

use "$origin\rlms_credit_workfile.dta", clear
rename empsta status
rename fempsta fstatus
global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"

// keep estimation sample
keep if s1==1

// initial conditions
egen wavefirst=min(year) if s1==1, by(idind)  
label var wavefirst "First time R appears in the sample"
foreach v in status {	
	gen _t1 = `v' if year==wavefirst
	egen `v'_ic=mean(_t1), by(idind)	
	label values `v'_ic empsta
	drop _*
}
qui foreach v in schadjC married nmember nage13y lnhhcon {	// time-varying variables except for age and year
	gen _t1 = `v' if year==wavefirst
	egen `v'_1=mean(_t1), by(idind)		// first period
	gen _t2 = `v' if year>wavefirst`i'
	egen `v'_R=mean(_t2), by(idind)		// means in the remaining periods
	drop _*
}

global F "c.cindzsc##ib1.status"

log using margins_hetero_withSE, replace 

est use gsem_wrs
est store gsem_wrs
estimates esample: if s1

	*** Marginal effect of C on sector size 
	
// CONTINUOUS=GDP per capita, earnings, unemployment rate, and CMA index
foreach v in gdpcapR lnwgregR unrate cindzsc {
	capture drop group
	egen group=xtile(`v'), by(year) nq(3)
	foreach i of numlist 2 {
		margins, dydx(cindzsc) predict(outcome(`i'.fstatus)) over(group) 
	}
}

// CATEGORICAL=female and community type
foreach v in  bankcat female {
	capture drop group
	gen group=`v'
	foreach i of numlist 2 {
		margins, dydx(cindzsc) predict(outcome(`i'.fstatus)) over(group) 
	}
}

	*** Mean informal sector

// CONTINUOUS=GDP per capita, earnings, unemployment rate, and CMA index
foreach v in gdpcapR lnwgregR unrate cindzsc {
	capture drop group
	egen group=xtile(`v'), by(year) nq(3)
	foreach i of numlist 2 {
		margins, predict(outcome(`i'.fstatus)) over(group) 
	}
}

// CATEGORICAL=female and community type
foreach v in  bankcat female {
	capture drop group
	gen group=`v'
	foreach i of numlist 2 {
		margins, predict(outcome(`i'.fstatus)) over(group) 
	}
}

log close

