* Author: Klara S. Peter
** This do file extracts vaiables for the project on credit market

clear
cd  "C:\My projects\RLMS\CPC\CPC data\Workfiles\Informal"
global destin "C:\Users\kpeter\Dropbox\Credit market\Data"
global lng    "C:\My projects\RLMS\CPC\CPC data\Longitudinal files"
global regvar "C:\My projects\RLMS\CPC\CPC data\Common regional variables"
global regid  "C:\My projects\RLMS\CPC\CPC data\Workfiles\Regional ids"
global comm   "C:\My projects\RLMS\CPC\CPC data\Community data"

global X "idind hhid year female age age2 okrug ter psu urbsta cpi minwage *stazhimp jbM* curwrk evrwrk jb1_offpay jb1_tenure jb3_worklm*"
use $X using "$lng\indata_wage.dta", clear
drop jbM*P
merge 1:1 idind year using "$lng\indata_allyears.dta", nogen keep(1 3) keepusing(mbyear intdate site fam_marst crd_* unm_* jb1_uleave jb1_invcuts jb1_offrsn jb1_slftyp2 jb1_offwag jb1_worried jb1_confid jb2_secjob jb2_secjob2 gen_inclmo gen_future gen_status)
merge 1:1 idind year using "$lng\indata_edu.dta", nogen keep(1 3) keepusing(sch*C)
merge 1:1 idind year using "$lng\indata_paredu.dta", nogen keep(1 3)  keepusing(educat_*) 	
merge 1:1 idind year using "$lng\indata_socnetworks.dta", nogen keep(1 3) keepusing(job* socnetw)
merge 1:1 idind year using "$lng\indata_migration.dta", nogen keep(1 3) keepusing(birpla russian burban)

// Year-month of interview
g yrmon=mofd(intdate)
format yrmon %tm
label var yrmon "Year-month of interview"

// Marital status
recode fam_marst 1 3 4 5=0 2 6 7=1 -9=., gen(married)
label var married "=1 if married"
drop fam_marst

// Level of education
recode schlevC 0/3=1 4/5=2 6=3 7/8=4, gen(educat_r)
label define educat 1 "[1] Lower than secondary" 2 "[2] Secondary" 3 "[3] Upper vocational" 4 "[4] Higher education"
label values educat_r educat
label var educat_r "Respondent's level of education"

// Employment
note: employed=1 if currently working (incl. temporary absent) and if report not-working but engaged in IEA in last 30 days
gen employed=1 if curwrk==1 | jb3_worklm0==1
replace employed=0 if employed==. & curwrk==0
label var employed "=1 if employed"

// Employment status
note: formal=officially registered employees; informal=unregistered employees+not working at a firm (self-employed and hired by a private person)+engaged in IEA
gen empsta=1 if jbM_workcat==1
replace empsta=2 if jbM_workcat>=2 & jbM_workcat<.
replace empsta=2 if jbM_workcat==. & jb3_worklm0==1 // occasional IEA
replace empsta=3 if employed==0
label define empsta 1 "[1] Formal worker" 2 "[2] Informal worker" 3 "[3] Non-employed"
label values empsta empsta
label var empsta "Employment status, t"

// Disaggregated categories of informal, 2005-2014
label define empsta2 1 "[1] Formal worker"  2 "[2] Informal employee" 3 "[3] Self-employed" 4 "[4] Works for a private person"  5 "[5] Informal-unknown category" ///
	6 "[6] IEA worker regular" 7 "[7] IEA worker occasional" 8 "[8] Non-employed"
gen workcat=1 if empsta==1
replace workcat=2 if empsta==2 & jbM_workcat==2
replace workcat=3 if empsta==2 & jbM_workcat==3 & jb1_slftyp2==1
replace workcat=4 if empsta==2 & jbM_workcat==3 & (jb1_slftyp2>1 & jb1_slftyp2<5)
replace workcat=5 if empsta==2 & jbM_workcat==3 & jb1_slftyp2==.
replace workcat=6 if empsta==2 & (jbM_workcat==4|jbM_workcat==5)
replace workcat=7 if empsta==2 & (jbM_workcat==. & jb3_worklm0==1)
replace workcat=8 if empsta==3
label values workcat empsta2
gen workcat_orig=workcat
replace workcat=. if year<2005 | year>2014
label var workcat "Disaggregated employment status, t"
label var workcat_orig "Disaggregated employment status incl 2015-2016"

// Work experience
gen exp=stazhimp if stazhimp>=0
label var exp "Actual work experience in years"

gen exp2=exp^2/100
label var exp2 "Actual work experience squared /100"
replace age2=age2/100
label var age2 "Age squared /100"
drop stazhimp

// Secondary employment
recode jb2_secjob -9=.
gen numjobs=1 if curwrk==1 & jb2_secjob<.
replace numjobs=numjobs+1 if jb2_secjob==1
replace numjobs=numjobs+1 if jb2_secjob==0 & jb2_secjob==1
replace numjobs=1 if curwrk==0 & jb3_worklm==1
replace numjobs=numjobs+1 if curwrk==1 & jb3_worklm==1
tab numjobs employed, mis

recode numjobs 2/3=1 1=0, gen(secjob)
label var secjob "=1 if has a secondary job"
drop numjobs jb2_secjob* jb3_worklm 

// not concerned about the likelihood of job loss, 1998-2016, 1-5 excludes IEA
rename jb1_worried jb1_noconcern
label define noconcern 1 "[1] Very concerned" 2 "[2] A little concerned" 3 "[3] Neutral" 4 "[4] Not very concerned" 5 "[5] Not concerned at all"
label values jb1_noconcern noconcern

// confident in finding a job if laid off, 1998-2016, only 2=unreg employees
label define confid 1 "[1] Fully uncertain" 2 "[2] Fairly uncertain" 3 "[3] Neutral" 4 "[4] Fairly certain" 5 "[5] Fully certain"
foreach v in jb1_confid {
	replace `v'=6-`v'
	label values `v' confid
}
// expectation about future
label define future 1 "[1] Much worse" 2 "[2] Somewhat worse" 3 "[3] Nothing will change" 4 "[4] Somewhat better" 5 "[5] Much better"
recode gen_future -9=.
replace gen_future=6-gen_future
label values gen_future future

drop if year<2002
order idind hhid year intdate yrmon female age age2 married okrug ter psu urbsta cpi curwrk employed empsta workcat* secjob exp exp2 jbM* jb1* gen*

// Regional earnings at age 17 and 18
preserve
use "$regvar\reg_wages.dta", clear
gen lnearn17=lnwgregR-ln(1000) // in thousands rubles
gen _t=lnearn17 if ter==9008
egen _m=mean(_t), by(year)
gen dlnearn17=lnearn17-_m
keep ter year *lnearn17
rename year year17
label var year17 "Year at age 17"
label var lnearn17 "Log real earnings at age 17, thousand rubles, 2016 prices"
label var dlnearn17 "Log real earnings relative to Russian mean at age 17"
save temp_lnearn17.dta, replace
restore

gen year17=mbyear+17
merge m:1 ter year17 using "temp_lnearn17.dta", keep(1 3) nogen keepusing(*lnearn17)
save "$destin\rlms_credit.dta", replace
erase temp_lnearn17.dta

********************************************************************************
*					Create workfile
********************************************************************************

use "$destin\rlms_credit.dta", clear
merge m:1 hhid year using "$lng\hhdata_allyears.dta", keep(1 3) nogen keepusing(hs_rent hs_mvalue fin_savleft crd_* fin_modebt* fin_crdebt* fin_todebt* blm_f13_11 blm_f13_12)
merge m:1 hhid year using "$lng\hhdata_vars.dta", keep(1 3) nogen keepusing(hhpanelA yDa c fin_* giv_* gft_*)
merge m:1 hhid year using "$lng\hhroster_vars", keep(1 3) nogen keepusing(nmember nage13y)
xtset idind year

	*** Household-level variables

gen nadults=nmember-nage13y
label var nadults "Number of adults in household, 14+"

// Debt
recode fin_todebtd -9=., gen(hasdebt)
label var hasdebt "=1 if HH has a debt"
gen lndebt=ln(1+fin_todebtsM*cpi/1000)
label var lndebt "Log of real HH debt, thousand rubles, 2016 prices"

// HH income and consumption
gen lnhhinc=ln(1+yDa/1000)
label var lnhhinc "Log of real disposable HH income, thousand rubles, 2016 prices"
gen lnhhcon=ln(c/1000)
label var lnhhcon "Log of real expenditures on non-durables, thousand rubles, 2016 prices"

// Loan
recode crd_takcre -9=., gen(hhloan)
label values hhloan yesno
label var hhloan "Any hh member took a loan last 12m"
gen fhhloan=f.hhloan
label var fhhloan "Any hh member took a loan last 12m, t+1"

label define loancat 0 "[0] No loan" 1 "[1] Only formal loan" 2 "[2] Only informal loan"  3 "[3] Mixed"
foreach v in mo cr {
	recode fin_`v'debtd -9=.
	gen _`v'=0 if fin_`v'debtd==0												// no debt
	replace _`v'=1 if fin_`v'debtd==1 & l.fin_`v'debtd==0						// switched from no debt to debt last 12m
	replace _`v'=0 if _`v'==. & fin_`v'debtsM<=l.fin_`v'debtsM & l.fin_`v'debtsM<.	// decrease in debt last 12m
	replace _`v'=1 if _`v'==. & fin_`v'debtsM> l.fin_`v'debtsM &   fin_`v'debtsM<.	// increase in debt last 12m
}
gen loan12m=0  if _mo==0 & _cr==0
replace loan12m=1 if _mo==0 & _cr==1
replace loan12m=2 if _mo==1 & _cr==0
replace loan12m=3 if _mo==1 & _cr==1
replace loan12m=. if year==2006 		// missing change in 2006 because the type of debt is not available in 2005
label values loan12m loancat
label var loan12m "Formal-informal loan loan based on change in debt last 12m"
note: too many missing values due to attrition

replace blm_f13_11=0 if blm_f13_11==. & hhloan==0 
gen loan30d=0  if blm_f13_12==0 & blm_f13_11==0
replace loan30d=1 if blm_f13_12==0 & blm_f13_11==1
replace loan30d=2 if blm_f13_12==1 & blm_f13_11==0
replace loan30d=3 if blm_f13_12==1 & blm_f13_11==1
label values loan30d loancat
label var loan30d "Formal-informal loan based on borrowing last 30 days"
*drop fin_* blm_* _*

// Type of loan
label define loantype 0 "[0] No loan" 1 "[1] Mortgage, car, and education loan" 2 "[2] Consumer credit from the bank" 3 "[3] Credit from the store/company"
gen loantype=1 if crd_mortg==1 | crd_auto==1 | crd_educ==1
replace loantype=2 if loantype==. & crd_consu==1
replace loantype=3 if loantype==. & (crd_purch==1 | crd_serv==1)
replace loantype=0 if loantype==. & hhloan==0
label values loantype loantype
label var loantype "Type of loan"
tab year loantype , mis

	*** Individual-level variables

// Plan for loan
recode crd_bormon -9=., gen(inloan)
label var inloan "Plan for loan, t"
recode crd_bncard -9=. // bank card

// Any other HH member (20-59) is placed on involunary leave or subjected to involuntary cuts in pay or hours
gen jb1_involun=1 if jb1_uleave==1 | jb1_invcuts==1
replace jb1_involun=0 if jb1_uleave==0 & jb1_invcuts==0
replace jb1_involun=. if age<20 | age>59
foreach v in involun {
	egen _t2=total(jb1_`v'), by(hhid year)
	gen hh`v'=_t2 if jb1_`v'~=1
	replace hh`v'=_t2-1 if jb1_`v'==1
	recode hh`v' 1/10=1
	drop _*
}
label var hhinvolun "=1 if other HH members placed on involunary leave or subjected to involuntary cuts in pay or hours last 12m"
drop jb1_involun
/*
// Any other HH member (20-59) left a job
gen _t1=1 if (year-unm_yrleft)<=1 & unm_yrleft<3000 & age>=20 & age<60
egen _t2=total(_t1), by(hhid year)
gen hhleftjob=_t2 if _t1~=1
replace hhleftjob=_t2-1 if _t1==1
recode hhleftjob 1/4=1
label var hhleftjob "=1 if other HH members left a job last 12 months"
tab year hhleftjob, row
drop _* 
*/
drop jb1_uleave jb1_invcuts unm*

// Interval between interviews
xtset idind year
gen intervday=f.intdate-intdate
gen intervmon=round(intervday/30, 1)
label var intervday "Interval between interviews t+1 and t, in days"
label var intervmon "Interval between interviews, in months"

// Re-define labor force status
/* 3 options:
	1. exclude OLF; use 3 categories: formal, informal, unemployed
	2. exclude disabled, retirees, and housewifes from OLF; use 4 categories: formal, informal, unemployed, OLF
	3. exclude disabled, retirees, and housewifes from OLF; combine the rest with unemployed; use 3 categories: formal, informal, non-employed
	4. exclude respondents who do not want to find a job from OLF; combine the rest with unemployed; use 3 categories: formal, informal, non-employed
replace lfstatus=. if lfstatus==4 // option#1
replace lfstatus=. if lfstatus==4 & (gen_status==3 | gen_status==4 | gen_status==7) // option#3: exclude disabled, retirees, and housewifes from OLF
replace lfstatus=. if lfstatus==4 & unm_wantjb==0	// option # 4
recode lfstatus 4=3
label values lfstatus empsta

gen lfstatus=1 if empsta==1
replace lfstatus=2 if empsta==2
replace lfstatus=3 if employed==0 & unm_looklm==1
replace lfstatus=4 if employed==0 & (unm_looklm==0 | unm_wantjb==0)
replace lfstatus=4 if employed==0 & (unm_looklm==. | unm_looklm==-9)  & unm_lookwk==99999996  // does not look for a job
label define lfstatus 1 "[1] Formal worker"  2 "[2] Informal worker" 3 "[3] Unemployed" 4 "[4] Out of labor force"
label values lfstatus lfstatus
label var lfstatus "Labor force status, t"
*/

// Community and regional variables
merge m:1 site year using "$comm\commun_credit.dta", keep(1 3) nogen 
gen lnpopsite=ln(popsite)
label var lnpopsite "Log of community population"
// Mortgage rate at the time of interview
*merge m:1 ter yrmon using "$regvar\reg_loans_monthly.dta", keep(1 3) keepusing(morgrateQC morgrateYC) nogen  // 2017m1 is missing in using data, OK

// Estimation sample
xtset idind year
gen fempsta=f.empsta
label values fempsta empsta
label var fempsta "Employment status, t+1"
egen _mis=rowmiss(russian schadjC married lnhhcon)
forvalues i=1/4 {
	gen s`i'=1 if age>=20 & age<60
	replace s`i'=. if _mis>0 & _mis<.
}
replace s1=. if empsta==. | fempsta==. | year<2006						
replace s2=. if (workcat==. | workcat==5) | fempsta==. | year<2006		// disaggregated categories
forvalues i=1/2 {
	egen _t`i'=total(s`i') if s`i'==1, by(idind) 			// min 2 obs per person, needed to calculate X+
	replace s`i'=. if _t`i'==1
	drop _*
}

	*** Community credit accessibility index

gen yearselect=1 if year>2004 & year<2016

// Index based on z-score
foreach v in bankcat credpop2  { 
	egen st_`v'=std(`v') if yearselect==1 // N(0,1)
	}
foreach v in lnbdistS lnbdistO {
	egen st_`v'=std(`v') if yearselect==1 // N(0,1)
	replace st_`v'=- st_`v'
	}
egen _score1=rowmean(st_bankcat st_lnbdistS st_lnbdistO st_credpop2)
egen cindzsc=std(_score1)
label var cindzsc "Credit accessibility index, z-score" 
drop st_* _*

// Index based on PCA
global Z "bankcat lnbdistS lnbdistO credpop2"  
pca $Z if yearselect==1
predict _pca1 if e(sample)==1    // first component
egen cindpca=std(-_pca1) 		 // reverse
label var cindpca "Credit accessibility index, pca" 
drop _* yearselect

save "$destin\rlms_credit_workfile.dta", replace



