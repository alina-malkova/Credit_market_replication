* Authors: Klara S. Peter and Alina Malkova
** This do file creates descriptive figures
cd "~\Dropbox\Credit market"

*******************************************************************************
* 					Table 1: Trends in Employment Status
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
keep if year>2005 & age>=20 & age<60
recode year 2006=2006 2008=2008 2010=2010 2012=2012 2014=2014 2016=2016 *=., gen(yearselect)

// baseline categories (formal, informal, non-employed)
tab empsta yearselect, col nof 
tab empsta yearselect
tab empsta
tab empsta if empsta<3		// share of informal sector

// official vs unofficial pay
tab jb1_offpay yearselect, col nof 
tab jb1_offpay yearselect
tab jb1_offpay

// categories of informal
recode workcat_orig 7=6
tab workcat_orig yearselect, col nof 
tab workcat_orig yearselect
tab workcat_orig if year<2015


*******************************************************************************
* 					Table 2: Sample construction
*					Statistics reported in the text
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
keep if year>2005 & age>=20 & age<60

// sample selection criteria
gen s=1 if year>2005 & age>=20 & age<60  // age 20-59, 2006-2016
tab s // 115,521 obs

replace s=. if empsta==.	// missing employment status in t
tab s // 109,957 obs

replace s=. if fempsta==. 	// missing employment status in t+1
tab s // 80,461 obs

sum russian schadjC married lnhhcon fhhloan if s==1 // missing covariates
egen mis=rowmiss(russian schadjC married lnhhcon)
replace s=. if mis>0 & mis<.
tab s  // 80,268 obs

egen T=total(s) if s==1, by(idind) // min 2 obs per person, needed to calculate X+
replace s=. if T==1
tab s // 76,452 obs
drop mis T

compare s s1
drop s

// interval between interviews
tab intervmon

// number of adults
egen numadults=group(idind) if s1==1
sum numadults

// year of entry
egen wavefirst=min(year) if s1==1, by(idind)
label var wavefirst "First time R appears in the sample"
tab wavefirst

// formal-informal income gap
gen lnwgusu=ln(jbM_wgusuC)
foreach v in lnwgusu lnhhinc {
	reg `v' i.empsta if s1==1
}

// HH members per HH
gen t=1
egen T=total(t) if s1==1, by(hhid year)
tab T
drop t T

// Loan type at the HH level
use "Data\rlms_credit_workfile.dta", clear
keep if year>2005 & age>=20 & age<60
label define loantype2 0 "[0] No loan" 1 "[1] Mortgage" 2 "[2] Car loan" 3 "[3] Education loan" 4 "[4] Consumer credit from the bank" 5 "[5] Credit from the store/company"
gen loantype2=1 if crd_mortg==1 
replace loantype2=2 if loantype2==. & crd_auto==1
replace loantype2=3 if loantype2==. & crd_educ==1
replace loantype2=4 if loantype2==. & crd_consu==1
replace loantype2=5 if loantype2==. & (crd_purch==1 | crd_serv==1)
replace loantype2=0 if loantype2==. & hhloan==0
label values loantype2 loantype2
label var loantype2 "Type of loan"
collapse loantype2 hhloan, by(hhid year)
label values loantype2 loantype2
tab loantype2
tab loantype2 if hhloan==1

*******************************************************************************
*					Figure 2: Trend in borrowing
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
drop if year<2006
collapse hhloan, by(hhid year)
tab year, sum(hhloan)

foreach v in hhloan {
   gen `v'_mean=.
   gen `v'_lb=.
   gen `v'_ub=.
		foreach y of numlist 2006/2016 {
			ci means `v' if year==`y'
			gen _s1_`y'=r(mean)
			gen _s2_`y'=r(lb)
			gen _s3_`y'=r(ub)
			replace `v'_mean=_s1_`y' if year==`y'
			replace `v'_lb=_s2_`y' if year==`y'
			replace `v'_ub=_s3_`y' if year==`y'
			drop _s*
			}
}
   
collapse hhloan_*, by(year)
sort year
twoway 	(line hhloan_mean year, msymbol(s) lcolor(navy) mcolor(navy) lwidth(thick) lp(solid))  ///
		(line hhloan_lb year, msymbol(i) lcolor(gs12) lp(solid))  ///
		(line hhloan_ub year, msymbol(i) lcolor(gs12) lp(solid)), ///
		xtitle("Year", size(medlarge)) ytitle("Share of households", size(medlarge)) xlab(2006(2)2016) ylab(0.1(0.05)0.3) /// 
		legend(off) graphregion(color(white)) ///
		saving("Results\FIG2_trend_borrowing.gph", replace)

*******************************************************************************
*						Table 3: Summary statistics
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear

tab educat_p, gen(educat_p_)
gen c00=c/1000
global X2 "age female russian educat_p_1 educat_p_2 educat_p_3 educat_p_4 schadjC married nmember nage13y c00 popsite urban intervday"

tabstat $X2 if s1==1, by(empsta) save stat(mean)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix M=F1',I1',N1'
tabstat $X2 if s1==1, by(empsta) save stat(sd)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix SD=F1',I1',N1'
matrix SUM=M,SD
matrix list SUM
tab empsta if s1==1
foreach v in $X2 {
	*reg `v' i.empsta if s1==1
}

egen wavefirst=min(year) if s1==1, by(idind)
label var wavefirst "First time R appears in the sample"
gen shrgov=shrpub+shrmun
global IC "dlnearn17 shrgov infperc govtcl"
tabstat $IC if s1==1 & year==wavefirst, by(empsta) save stat(mean)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix M=F1',I1',N1'
tabstat $IC if s1==1 & year==wavefirst, by(empsta) save stat(sd)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix SD=F1',I1',N1'
matrix SUM=M,SD
matrix list SUM
tab empsta if s1==1 & year==wavefirst

foreach v in $IC {
	reg `v' i.empsta if s1==1 & year==wavefirst
}

gen bankcat3=(bankcat==3) if bankcat<.
global C "cindzsc bankcat1 bankcat2 bankcat3 bdistS bdistO credpop2"
tabstat $C if s1==1, by(empsta) save stat(mean)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix M=F1',I1',N1'
tabstat $C if s1==1, by(empsta) save stat(sd)
matrix F1=r(Stat1)
matrix I1=r(Stat2)
matrix N1=r(Stat3)
matrix SD=F1',I1',N1'
matrix SUM=M,SD
matrix list SUM
foreach v in $C {
	reg `v' i.empsta if s1==1
}
tab empsta if s1==1


// in text
tabstat inloan if s1==1, by(empsta) stat(mean sd)
tabstat inloan if s1==1, by(empsta) stat(n)
foreach v in inloan {
	*reg `v' i.empsta if s1==1
}

*******************************************************************************
*					Figure 3: Bank presence
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
keep if year>2004
gen bdist1=bdistS if bankcat==1
gen bdist2=bdistO if bankcat<3

foreach v in bdist1 bdist2 credpop2 {
   gen `v'_mean=.
   gen `v'_lb=.
   gen `v'_ub=.
		foreach y of numlist 2005/2016 {
			ci means `v' if year==`y' 
			gen _s1_`y'=r(mean)
			gen _s2_`y'=r(lb)
			gen _s3_`y'=r(ub)
			replace `v'_mean=_s1_`y' if year==`y'
			replace `v'_lb=_s2_`y' if year==`y'
			replace `v'_ub=_s3_`y' if year==`y'
			drop _s*
			}
}
   
collapse *_mean *_lb *_ub, by(year)

// Panel A: Distance to the nearest bank at the community-level
sort year
twoway 	(line bdist1_mean year, lcolor(navy) lwidth(thick) lp(solid))  ///
		(line bdist1_lb year, lcolor(gs14) lp(solid))  ///
		(line bdist1_ub year, lcolor(gs14) lp(solid)) ///
		(line bdist2_mean year, lcolor(cranberry) lwidth(thick) lp(solid))  ///
		(line bdist2_lb year, lcolor(gs14) lp(solid))  ///
		(line bdist2_ub year, lcolor(gs14) lp(solid)), ///
		xlab(2005(2)2016) ylab(10(5)40, nogrid) xtitle("Year", size(medlarge)) ytitle("Distance to the nearest bank, km", size(medlarge)) ///
		text(32 2009 "Other bank", place(n) box margin(l+4 t+1 b+1 r+4) bcolor(none) color(cranberry*1.2)) ///
		text(22 2009 "Sberbank", place(n) box margin(l+4 t+1 b+1 r+4) bcolor(none) color(navy*1.2)) ///
		legend(off) graphregion(color(white)) subtitle("A.", size(medlarge)) saving("Results\FIG3_panelA.gph", replace)

// Panel C: Number of bank offices per 1000 population (no space to report)
sort year
twoway 	(line credpop2_mean year, lcolor(navy) lwidth(thick) lp(solid)),  ///
		xlab(2005(2)2016) ylab(, nogrid) xtitle("Year", size(medlarge)) ytitle("Number of bank offices per 1000", size(medlarge)) ///
		legend(off) graphregion(color(white)) subtitle("C.", size(medlarge)) saving("Results\FIG3_panelC.gph", replace)

// Panel B: Region-level scatter plot
use "Data\rlms_credit_workfile.dta", clear
keep if year>2005 & year<2016
collapse hhloan bdistS bdistO, by(ter year)

gen bdist1=ln(bdistS)
gen bdist2=ln(bdistO)

foreach v in hhloan bdist1 bdist2 {
	format `v' %2.1f
}
label var hhloan "Share of loan taking households"
label var bdist1 "Distance to the nearest Sberbank office, log km"
label var bdist2 "Distance to the nearest other bank office, log km"

sort hhloan
twoway (scatter bdist1 hhloan, mcolor(navy*.6) m(circle) msize(small)) (lfit bdist1 hhloan, lp(solid) lcolor(navy) lwidth(thick))  ///
	   (scatter bdist2 hhloan, mcolor(cranberry*.6) m(circle) msize(small)) (lfit bdist2 hhloan, lp(solid) lcolor(cranberry) lwidth(thick)),  ///
	   xlabel(0(0.1)0.4) ylabel(, nogrid) xtitle(, size(medlarge)) ytitle("Distance to the nearest bank, log km", size(medlarge)) scheme(tufte) legend(off) ///
	   subtitle("B.", size(medlarge)) ///
       text(0.5 0.44 "Sberbank", place(n) box margin(l+4 t+1 b+1 r+4) bcolor(none) color(navy*1.2)) ///
	   text(1.08 0.44 "Other bank", place(n) box margin(l+4 t+1 b+1 r+4) bcolor(none) color(cranberry*1.2)) 	   ///
	   saving("Results\FIG3_panelB.gph", replace)

graph combine "Results\FIG3_panelA.gph" "Results\FIG3_panelB.gph", ///
	imargin(0 0 0) scheme(tufte) col(2) colfirst saving("Results\FIG3_distance.gph", replace) ysize(6) xsize(12)
graph export "Results\FIG3_distance.jpg"

*******************************************************************************
* Table 4: Average Transition Probabilities for Borrowers and Non-Borrowers 
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
keep if year>2005 & age>=20 & age<60

tab empsta fempsta if fhhloan==1 & s1==1, row nol
tab empsta fempsta if fhhloan==0 & s1==1, row nol

recode workcat 7=6
tab workcat fempsta if fhhloan==1 & year<2014 & workcat~=5 & s1==1, row nol 
tab workcat fempsta if fhhloan==0 & year<2014 & workcat~=5 & s1==1, row nol

*******************************************************************************
*					Figure 4a: Event-study analysis
*						Share of formal workers in t
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
gen age3=age^3
gen age4=age^4

// job switch
xtset idind year
gen job_switch=1 if l.empsta==2 & empsta==1						    	// informal->formal 
replace job_switch=0 if job_switch==. & l.empsta<.  & empsta==1			// any active->formal
label var job_switch "Share of formal in t moved from informal in t-1"

// first year a loan is taken by an employed (observed in the data)
egen _t1=min(year) if hhloan==1 & l.empsta<3, by(idind)
egen fyear=mean(_t1), by(idind)
label var fyear "First year when the loan is taken"
drop _*

// LPM model
gen timeline=year-fyear+5 // timeline=5 is the time of taking a loan
replace timeline=. if timeline<0
tab timeline, mis
label var timeline "# years before or after taking a loan, centered at 5"
reg job_switch ib5.timeline age age2 age3 age4 i.year 

// predicted probability of job switching
mat b=e(b)					// matrix of all coefficients
mat b2 = b[1...,17..35]		// coefficients on other covariates
matrix list b2
mat accum Cov = age age2 age3 age4 i.year  if e(sample)==1, means(M2)  // matrix of means
mat list M2					
matrix xb=M2'*b2
matrix trace=trace(xb)
matrix list trace			// predicted probability of job switching at time of taking a loan, timeline=5
local jshat0=trace[1,1]

mat b1 = b[1...,1..16]		// coefficients on timeline
matrix bT=b1'
svmat bT, names(jshat)
replace jshat=jshat+`jshat0'
label var jshat "Predicted probability"

// Figure 4a: Fraction of informal in t-1 becoming formal in t
gen time=_n-6 if jshat<.
replace time=. if time>5
label var time "# years before or after taking a loan"
sort time
twoway (line jshat time, lwidth(medthick)) (scatter jshat time, msize(medim) mcolor(black)) ///
	(scatter jshat time if time==0, msize(vhuge) mcolor(cranberry) mlwidth(medthick) msymbol(Oh)), /// 
	xlabel(-5(1)5) xline(0,lp(dash) lcolor(cranberry)) legend(off) graphregion(color(white))  ///
	xtitle(, size(medlarge)) ytitle("" size(medlarge)) title("A.Share of formal workers in {it:t}") subtitle("{it:Transition: Informal t-1 -> Formal t}") 	///
	saving("Results\FIG4_panelA.gph", replace)

*******************************************************************************
*					Figure 4b: Event-study analysis
*					Share of informal workers in t-1
*******************************************************************************

use "Data\rlms_credit_workfile.dta", clear
gen age3=age^3
gen age4=age^4

// job switch
xtset idind year
gen job_switch=1 if l.empsta==2 & empsta==1							// informal->formal 
replace job_switch=0 if job_switch==. & l.empsta==2 & empsta<.  	// informal->informal/non-employed
label var job_switch "Probability of switching informal->formal"

// first year a loan is taken by an employed (observed in the data)
egen _t1=min(year) if hhloan==1 & l.empsta<3, by(idind)
egen fyear=mean(_t1), by(idind)
label var fyear "First year when the loan is taken"
drop _*

// LPM model
gen timeline=year-fyear+6 // timeline=5 is the year of taking a loan
replace timeline=. if timeline<0
tab timeline, mis
label var timeline "# years before or after taking a loan, centered at 5"
reg job_switch ib5.timeline age age2 age3 age4 i.year 

// predicted probability of job switching
mat b=e(b)					// matrix of all coefficients
mat b2 = b[1...,18..36]		// coefficients on other covariates
matrix list b2
mat accum Cov = age age2 age3 age4 i.year  if e(sample)==1, means(M2)  // matrix of means
mat list M2					
matrix xb=M2'*b2
matrix trace=trace(xb)
matrix list trace			// predicted probability of job switching at time of taking a loan, timeline=5
local jshat0=trace[1,1]

mat b1 = b[1...,1..17]		// coefficients on timeline
matrix bT=b1'
svmat bT, names(jshat)
replace jshat=jshat+`jshat0'
replace jshat=0 if jshat<0  // perfect failure for t=+1; no person switching
label var jshat "Predicted probability"

// Figure 4b: Fraction of informal in t-1 becoming formal in t
gen time=_n-6 if jshat<.
replace time=. if time>5
label var time "# years before or after taking a loan"
sort time
twoway (line jshat time, lwidth(medthick)) (scatter jshat time, msize(medim) mcolor(black)) ///
	(scatter jshat time if time==0, msize(vhuge) mcolor(cranberry) mlwidth(medthick) msymbol(Oh)), /// 
	xlabel(-5(1)5) xline(0,lp(dash) lcolor(cranberry)) legend(off) graphregion(color(white))  ///
	xtitle(, size(medlarge)) ytitle("" size(medlarge)) title("B.Share of informal workers in {it:t}-1") subtitle("{it:Transition: Informal t-1 -> Formal t}") 	///
	saving("Results\FIG4_panelB.gph", replace)
* another way
*twoway (scatter jshat time) (lowess jshat time if time<0, bwidth(1)) (lowess jshat time if time>0, bwidth(1)), xlabel(-5(1)10) 
*twoway (scatter jshat time) (lfit jshat time if time<0) (lfit jshat time if time>0), xlabel(-5(1)10) 

// combine two figures
graph combine "Results\FIG4_panelA.gph" "Results\FIG4_panelB.gph", ///
	imargin(0 0 0) scheme(tufte) col(2) colfirst saving("Results\FIG4_event_study.gph", replace) ysize(6) xsize(12)

	
