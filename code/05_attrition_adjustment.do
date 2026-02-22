* Authors: Klara S. Peter and Alina Malkova
** This do file estimates individual-level model of employment transitions associated adjusted for attrition 

clear
capture cd "C:\Users\kpeter\Dropbox\Credit market\Results"
global origin "C:\Users\kpeter\Dropbox\Credit market\Data"

/* 3 types of exit:
- exit from the estimation sample
- exit from the survey next year
- final exit from the survey
*/
/*
********************************************************************************
*					Exit from the estimation sample
********************************************************************************

	*** Pre-estimation preparation
	
use "$origin\rlms_credit_workfile.dta", clear
xtset idind year
rename empsta status
rename fempsta fstatus
replace fstatus=4 if fstatus==.	& year<2016		// exited from the estimation sample
tab status fstatus, mis

// Estimation sample
egen _mis=rowmiss(russian schadjC married lnhhcon)
foreach i in 5 {
	gen s`i'=1 if age>=20 & age<60 & year>2005
	replace s`i'=. if _mis>0 & _mis<.
}
replace s5=. if status==. | fstatus==.						
foreach i in 5 {
	egen _t`i'=total(s`i') if s`i'==1, by(idind) 	// min 2 obs per person, needed to calculate X+
	replace s`i'=. if _t`i'==1
	drop _*
}
keep if s5==1
tab s5
tab status fstatus, mis

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

// WRS estimator with exit from the estimation sample 
capture log close
log using gsem_wrs_attr1, replace
sum cindzsc
local sd=r(sd)
local mean=r(mean)
local sum=r(sd)+r(mean)
global F "c.cindzsc##ib1.status"
global X2 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban ib1.okrug ib1.year" // intervday has to be excluded
gsem (1.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R3[idind]) ///
     (4.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R4[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20) 
est save gsem_wrs_attr1, replace
foreach i of numlist 1/4 {
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`mean')
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`sum')
}
log close

********************************************************************************
*					Exit from the survey next year
********************************************************************************

	*** Pre-estimation preparation
	
use "$origin\rlms_credit_workfile.dta", clear
xtset idind year
rename empsta status
rename fempsta fstatus
replace fstatus=4 if fstatus==.	& f.idind==. & year<2016	// exited from the survey next year
tab status fstatus, mis

// Estimation sample
egen _mis=rowmiss(russian schadjC married lnhhcon)
foreach i in 5 {
	gen s`i'=1 if age>=20 & age<60 & year>2005
	replace s`i'=. if _mis>0 & _mis<.
}
replace s5=. if status==. | fstatus==.						
foreach i in 5 {
	egen _t`i'=total(s`i') if s`i'==1, by(idind) 	// min 2 obs per person, needed to calculate X+
	replace s`i'=. if _t`i'==1
	drop _*
}
keep if s5==1
tab s5

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

// WRS estimator with the survey exit next year

capture log close
log using gsem_wrs_attr2, replace
sum cindzsc
local sd=r(sd)
local mean=r(mean)
local sum=r(sd)+r(mean)
global F "c.cindzsc##ib1.status"
global X2 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban ib1.okrug ib1.year" // intervday has to be excluded
gsem (1.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R3[idind]) ///
     (4.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R4[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20) 
est save gsem_wrs_attr2, replace
foreach i of numlist 1/4 {
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`mean')
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`sum')
}
log close
*/
********************************************************************************
*					Final exit from the survey 
********************************************************************************

	*** Pre-estimation preparation
	
use "$origin\rlms_credit_workfile.dta", clear
xtset idind year
rename empsta status
rename fempsta fstatus
egen lastyear=max(year), by(idind) // last year surveyed
replace fstatus=4 if fstatus==.	& lastyear==year & year<2016	// exited from the last survey
tab status fstatus, mis

// Estimation sample
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
tab s5

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

// WRS estimator with the final exit from the survey

capture log close
log using gsem_wrs_attr3, replace
sum cindzsc
local sd=r(sd)
local mean=r(mean)
local sum=r(sd)+r(mean)
global F "c.cindzsc##ib1.status"
global X2 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban ib1.okrug ib1.year" // intervday has to be excluded
gsem (1.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R1[idind]) ///
     (3.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R3[idind]) ///
     (4.fstatus <- $F $X2 i.wavefirst ib1.status_ic *_R *_1 R4[idind]), ///
	 mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20) 
est save gsem_wrs_attr3, replace
foreach i of numlist 1/4 {
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`mean')
	margins status, predict(outcome(`i'.fstatus)) nose at(cindzsc=`sum')
}
log close

********************************************************************************
*								Table 
********************************************************************************

reg fstatus cindzsc  // fake column
outreg2 using tables_attrition.xls, nocons replace 
foreach v in wrs_attr1 wrs_attr2 wrs_attr3 {
	est use gsem_`v'
	est store gsem_`v'
	outreg2 using tables_attrition.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(c.cindzsc##ib1.status) nocons eform append
}

