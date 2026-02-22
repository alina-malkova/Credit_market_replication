* Authors: Klara S. Peter and Alina Malkova
** This do file estimates individual-level model of employment transitions with alternative definitions of informality 

clear
capture cd "C:\Users\kpeter\Dropbox\Credit market\Results"
global origin "C:\Users\kpeter\Dropbox\Credit market\Data"

********************************************************************************
*					A. Subcategories of informal workers 
********************************************************************************

// pre-estimation preparation
use "$origin\rlms_credit_workfile.dta", clear
keep if s2==1
label define empsta3 1 "Formal worker"  2 "Informal employee" 3 "Self-employed" 4 "Works for a private person"  6 "IEA worker" 8 "Non-employed"
recode workcat 5=. 7=6 
rename workcat status
label values status empsta3
rename fempsta fstatus

egen wavefirst=min(year), by(idind)  
label var wavefirst "First time R appears in the sample"
foreach v in status {	
	gen _t1 = `v' if year==wavefirst
	egen `v'_ic=mean(_t1), by(idind)	
	label values `v'_ic empsta2
	drop _*
}
foreach v in schadjC married nmember nage13y lnhhcon {	// time-varying variables except for age and year
	gen _t1 = `v' if year==wavefirst
	egen `v'_1=mean(_t1), by(idind)		// first period
	gen _t2 = `v' if year>wavefirst`i'
	egen `v'_R=mean(_t2), by(idind)		// means in the remaining periods
	drop _*
}

// Estimation
capture log close
log using gsem_alt_inform1, replace
global X1 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global F "c.cindzsc##ib1.status"

// Reduced-form
gsem (1.fstatus <- $F $X1 i.wavefirst) ///
     (3.fstatus <- $F $X1 i.wavefirst), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_base_inform1, replace

// WRS estimator
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R3[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_wrs_inform1, replace
log close

// Post-estimation predictions
log using gsem_alt_inform1, append
est use gsem_wrs_inform1
estimates esample: if s2
	* Predicted transition probabilities at C=0
foreach i of numlist 1/3 {
	margins status, nose predict(outcome(`i'.fstatus)) at(cindzsc=0)
}
	* Average marginal effect of C on transition probabilities
foreach i of numlist 1/3 {
	margins status, nose predict(outcome(`i'.fstatus)) dydx(cindzsc)
}
log close

// Table 7: Disaggregated categories of employment status
reg fstatus cindzsc  // fake column
outreg2 using tables_alt_inform1.xls, nocons replace 
foreach v in base wrs {
	est use gsem_`v'_inform1
	est store gsem_`v'_inform1
	outreg2 using tables_alt_inform1.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(c.cindzsc##ib1.status) nocons eform append
}


********************************************************************************
*					B. Informality is based on unofficial pay 
********************************************************************************

// Pre-estimation preparation
use "$origin\rlms_credit_workfile.dta", clear
xtset idind year
rename jb1_offpay status
replace status=4 if year>=2008 & empsta==3 // non-employed
gen fstatus=f.status

// Estimation sample, s5
egen _mis=rowmiss(russian schadjC married lnhhcon)
foreach i in 5 {
	gen s`i'=1 if age>=20 & age<60 & year>2005
	replace s`i'=. if _mis>0 & _mis<.
}
replace s5=. if status==. | fstatus==.						
foreach i in 5 {
	egen _t`i'=total(s`i') if s`i'==1, by(idind) 			// min 2 obs per person, needed to calculate X+
	replace s`i'=. if _t`i'==1
	drop _*
}
keep if s5==1

// Initial conditions
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

// Estimation
capture log close
log using gsem_alt_inform2, replace
global X1 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global F "c.cindzsc##ib1.status"

// Reduced-form
gsem (1.fstatus <- $F $X1 i.wavefirst) ///
     (2.fstatus <- $F $X1 i.wavefirst) ///
     (4.fstatus <- $F $X1 i.wavefirst), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_base_inform2, replace

// WRS estimator
gsem (1.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (2.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R2[idind]) ///
     (4.fstatus <- $F $X1 i.wavefirst ib1.status_ic *_R *_1 R4[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save gsem_wrs_inform2, replace
log close

// Post-estimation predictions
log using gsem_alt_inform2, append
est use gsem_wrs_inform2
estimates esample: if s5
	* Predicted transition probabilities at C=0
foreach i of numlist 1/4 {
	margins status, nose predict(outcome(`i'.fstatus)) at(cindzsc=0)
}
	* Average marginal effect of C on transition probabilities
foreach i of numlist 1/4 {
	margins status, nose predict(outcome(`i'.fstatus)) dydx(cindzsc)
}
log close


// Table A2_2: Employment status based on informal pay
reg fstatus cindzsc  // fake column
outreg2 using tables_alt_inform2.xls, nocons replace 
foreach v in base wrs {
	est use gsem_`v'_inform2
	est store gsem_`v'_inform2
	outreg2 using tables_alt_inform2.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(c.cindzsc##ib1.status) nocons eform append
}


