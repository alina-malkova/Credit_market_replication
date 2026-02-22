* Authors: Klara S. Peter and Alina Malkova
** This do file performs polic simulations for the main definition of informality 

clear
capture cd "~\Dropbox\Credit market\Revised paper 2023\Results"
global origin "~\Dropbox\Credit market\Data"

***********************************************************************
*					Pre-estimation preparation
***********************************************************************

use "$origin\rlms_credit_workfile.dta", clear

rename empsta status
rename fempsta fstatus
global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"

// keep estimation sample
keep if s1==1

// initial conditions
egen wavefirst=min(year), by(idind)  
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

***********************************************************************
*				Policy simulation with bank distance
***********************************************************************

capture log close
log using gsem_simul1_se, replace

// Policy 1: open a Sberbank office if no banks within 10 km
global F1 "c.lnbdistS##ib1.status"
gsem (1.fstatus <- $F1 $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F1 $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save simul1_policy1, replace
local beg=ln(10)
local end=0
foreach i of numlist 1/2 {
	margins, predict(outcome(`i'.fstatus)) at(lnbdistS=(`beg' `end')) saving(simul1_policy1_`i', replace) 
}

// Policy 2: open a bank office other than Sberbank if no banks within 10 km
global F2 "c.lnbdistO##ib1.status"
gsem (1.fstatus <- $F2 $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F2 $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save simul1_policy2, replace
local beg=ln(10)
local end=0
foreach i of numlist 1/2 {
	margins, predict(outcome(`i'.fstatus)) at(lnbdistO=(`beg' `end')) saving(simul1_policy2_`i', replace)   
}

// Policy 3: open a second bank office
global F3 "ib1.status##c.lnbdistS##c.lnbdistO"
gsem (1.fstatus <- $F3 $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F3 $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save simul1_policy3, replace
local beg=ln(10)
local end=0
foreach i of numlist 1/2 {
	margins, predict(outcome(`i'.fstatus)) at(lnbdistO=(`beg' `end') lnbdistS=0) saving(simul1_policy3_`i', replace)  
}

// Policy 4: increase the number of bank offices from 2 per 10,000 to 3 per 10,000
global F4 "c.credpop2##ib1.status"
gsem (1.fstatus <- $F4 $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F4 $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save simul1_policy4, replace
sum credpop2, d
local beg=0.2
local end=0.3
foreach i of numlist 1/2 {
	margins, predict(outcome(`i'.fstatus)) at(credpop2=(`beg' `end')) saving(simul1_policy4_`i', replace)  
}

log close

/*
***********************************************************************
*					Policy simulation with index
***********************************************************************

capture log close
log using gsem_policy_cindzsc_se, replace
global F "c.cindzsc##ib1.status"

// Figure: Sector size
est use gsem_wrs
est store gsem_wrs
foreach i of numlist 1/3 {
	est restore gsem_wrs
	estimates esample: if s1
	margins, predict(outcome(`i'.fstatus)) at(cindzsc=(-3(1)2)) saving(margins_cindzsc`i', replace) 
}
combomarginsplot margins_cindzsc1 margins_cindzsc2 margins_cindzsc3, labels("Formal" "Informal" "No job") ///
	xtitle("Credit accessibility index", size(medlarge)) xlab(-3(1)2) ///
	ytitle("Predicted probability", size(medlarge)) ylab(0(0.1)0.7) title("") ///
	legend(region(lstyle(none)) rows(1)) graphregion(color(white)) saving(margins_cindzsc_se, replace)

// transition probabilities at cindzsc=0
est restore gsem_wrs
estimates esample: if s1
foreach i of numlist 1/3 {
	margins status, predict(outcome(`i'.fstatus)) at(cindzsc=0) nose  // no SE
}

// dydx on transition probabilities
foreach i of numlist 1/3 {
	margins status, predict(outcome(`i'.fstatus)) dydx(cindzsc) nose  // no SE
}

// dydx on sector size
foreach i of numlist 1/3 {
	margins, predict(outcome(`i'.fstatus)) dydx(cindzsc) nose  // no SE
}
log close
*/
	
// how to retrieve margins
*est use margins_cindzsc, number(2)
*est store margins_cindzsc
*est replay margins_cindzsc






