* Authors: Klara S. Peter and Alina Malkova
** This do file estimates household-level model of loan-taking 

clear
capture cd "C:\Users\kpeter\Dropbox\Credit market\Results\Loan equation"
global origin "C:\Users\kpeter\Dropbox\Credit market\Data"

***********************************************************************
*					Loan equation
***********************************************************************

use "$origin\rlms_credit_workfile.dta", clear

// loan type, before restricting the sample
xtset idind year
recode loantype 3=2
gen floantype=f.loantype
label values floantype loantype

// sample selection
global X1 "age age2 female russian ib0.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
quiet reg fhhloan ib1.empsta cindzsc $X1 if age>=20 & age<60
gen s5=1 if e(sample)==1
keep if s5==1 & inloan==0 // no loan intention

	*** Household head

// head is a random person
set seed 98034
generate random = runiform()
gsort hhid year random
bys hhid year: gen head1=_n
drop random

// head is oldest male
gsort hhid year female -age
bys hhid year: gen head2=_n

// head is highest-earning member
recode gen_inclmo -9 0=.
gsort hhid year -gen_inclmo female -age
bys hhid year: gen head3=_n

sum head*

// Mundlak device
/*
tab empsta, gen(empsta_)
foreach v in schadjC married nmember nage13y lnhhcon cindzsc empsta_2 empsta_3 {	// time-varying variables except for age and year
	gen _t2 = `v' if head1==1
	egen `v'_R=mean(_t2), by(idind)		// means in the remaining periods
	drop _*
}
*/

	*** LOGIT, no unobserved heterogeneity

logit fhhloan ib1.empsta c.cindzsc $X1 if head1==1, cluster(idind)
est save loan_logit, replace

	*** XTLOGIT, with unobserved heterogeneity

xtlogit fhhloan ib1.empsta c.cindzsc $X1 if head1==1, re vce(cluster idind)
est save loan_xtlogit, replace

foreach v of numlist 2/3 {
	xtlogit fhhloan ib1.empsta c.cindzsc $X1 if head`v'==1, re vce(cluster idind)
	est save loan_xtlogit`v', replace
}

	*** MLOGIT, no unobserved heterogeneity

mlogit floantype ib1.empsta c.cindzsc $X1 if head1==1, cluster(idind) base(0)	
est save loan_mlogit, replace

	*** MLOGIT, with unobserved heterogeneity

gsem (1.floantype <- ib1.empsta cindzsc $X1 R1[idind]) ///
	 (2.floantype <- ib1.empsta cindzsc $X1 R2[idind]) if head1==1, ///
	  mlogit vce(cluster idind) vsquish technique(bhhh 20 nr 20)
est save loan_gsem, replace

***********************************************************************
*					Tables 11-12
***********************************************************************

// Full model with CMA index
reg fhhloan cindzsc  // fake column
outreg2 using tables_loan_full.xls, nocons replace 
foreach v in loan_logit loan_xtlogit loan_mlogit loan_gsem {
	est use `v'
	est store `v'
	outreg2 using tables_loan_full.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) nocons eform append
}

// Robustness analysis: definitions of head of household
reg fhhloan cindzsc  // fake column
outreg2 using tables_loan_head.xls, nocons replace 
foreach v in loan_xtlogit loan_xtlogit2 loan_xtlogit3 {
	est use `v'
	est store `v'
	outreg2 using tables_loan_head.xls, addstat(Log Lik, e(ll)) cti(`v') dec(3) keep(i.empsta cindzsc) nocons eform append
}

est use loan_xtlogit
est store loan_xtlogit
estimates esample: if head1==1
margins, dydx(cindzsc) nose


est use loan_gsem
est store loan_gsem
estimates esample: if head1==1
margins, dydx(schadjC) nose

