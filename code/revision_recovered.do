* Authors: Klara S. Peter and Alina Malkova
** This do file contains extended event study analysis and robustness checks
** Includes: loan-conditional transitions, mechanism tests, skill analysis

*******************************************************************************
*                       SETUP
*******************************************************************************

use "$origin\rlms_credit_workfile.dta", clear

*******************************************************************************
*               Formal to Informal Transition
*******************************************************************************

* Basic transition
gen trans_form_if = 1 if empsta == 1 & fempsta == 2
replace trans_form_if = 0 if empsta == 1 & fempsta == 1

* Transition conditional on getting loan in period t+1
gen trans_form_if_loan = 1 if empsta == 1 & fempsta == 2 & fhhloan == 1
replace trans_form_if_loan = 0 if empsta == 1 & fempsta == 1 & fhhloan == 1

* Create event time variable
gen yearevent = year if trans_form_if == 1
replace yearevent = 0 if yearevent == .

bysort idind (year): egen newvar = max(yearevent)

gen dif = year - newvar
replace dif = . if dif > 14

* Event study
eventdd lnhhinc, timevar(dif) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))

*******************************************************************************
*               Event Study Plots with Confidence Intervals
*******************************************************************************

tsset idind dif
bys dif: egen mean = mean(lnhhinc)
bys dif: egen sd = sd(lnhhinc)

gen upper = mean + sd
gen lower = mean - sd

twoway rcap upper lower dif, lc(blue) || scatter mean dif, mc(red)

*******************************************************************************
*               Informal to Formal Transition
*******************************************************************************

gen trans_inform_form = 1 if empsta == 2 & fempsta == 1
replace trans_inform_form = 0 if empsta == 2 & fempsta == 2

gen formalization_year = year if trans_inform_form == 1
bysort idind (year): egen formalization_firstyear = max(formalization_year)

* Transition conditional on getting loan in period t+1
gen trans_inform_form_loan = 1 if empsta == 2 & fempsta == 1 & fhhloan == 1
replace trans_inform_form_loan = 0 if empsta == 2 & fempsta == 2 & fhhloan == 1

gen yearevent2_loan = year if trans_inform_form_loan == 1
replace yearevent2_loan = 0 if yearevent2_loan == .

bysort idind (year): egen newvar2_loan = max(yearevent2_loan)
gen dif2_loan = year - newvar2_loan
replace dif2_loan = . if dif2_loan > 14

eventdd lnhhinc, timevar(dif2_loan) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))

* Plot with confidence intervals
tsset idind dif2_loan
bys dif2_loan: egen mean2_loan = mean(lnhhinc)
bys dif2_loan: egen sd2_loan = sd(lnhhinc)

gen upper2_loan = mean2_loan + sd2_loan
gen lower2_loan = mean2_loan - sd2_loan

*******************************************************************************
*               Transition Without Loan (Comparison Group)
*******************************************************************************

gen trans_inform_form_noloan = 1 if empsta == 2 & fempsta == 1 & fhhloan == 0
replace trans_inform_form_noloan = 0 if empsta == 2 & fempsta == 2 & fhhloan == 0

gen yearevent2_noloan = year if trans_inform_form_noloan == 1
replace yearevent2_noloan = 0 if yearevent2_noloan == .

bysort idind (year): egen newvar2_noloan = max(yearevent2_noloan)
gen dif2_noloan = year - newvar2_noloan
replace dif2_noloan = . if dif2_noloan > 14

tsset idind dif2_noloan
bys dif2_noloan: egen mean2_noloan = mean(lnhhinc)
bys dif2_noloan: egen sd2_noloan = sd(lnhhinc)

gen upper2_noloan = mean2_noloan + sd2_noloan
gen lower2_noloan = mean2_noloan - sd2_noloan

* Comparison plot: loan vs no-loan
twoway rcap upper2_loan lower2_loan dif2_loan, lc(blue) || ///
       scatter mean2_loan dif2_loan, mc(red) || ///
       rcap upper2_noloan lower2_noloan dif2_noloan, lc(green) || ///
       scatter mean2_noloan dif2_noloan, mc(yellow)

*******************************************************************************
*               Basic Event Study for Informal to Formal
*******************************************************************************

gen yearevent2 = year if trans_inform_form == 1
replace yearevent2 = 0 if yearevent == .

bysort idind (year): egen newvar2 = max(yearevent2)

gen dif2 = year - newvar2
replace dif2 = . if dif2 > 14

eventdd lnhhinc, timevar(dif2) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))

tsset idind dif2
bys dif2: egen mean2 = mean(lnhhinc)
bys dif2: egen sd2 = sd(lnhhinc)

gen upper2 = mean2 + sd2
gen lower2 = mean2 - sd2

twoway rcap upper2 lower2 dif2, lc(blue) || scatter mean2 dif2, mc(red) || ///
       rcap upper lower dif, lc(green) || scatter mean dif, mc(yellow)

*******************************************************************************
*               Job Mobility vs Within-Job Formalization
*******************************************************************************

xtset idind year

* Job switch indicator
gen switch_empl = 1 if jb1_tenure <= 1
replace switch_empl = 0 if jb1_tenure > 1

xtset idind year
gen lswitch_empl = l.switch_empl
gen linloan = l.inloan

* Core outcome variables
gen formal_switch = (l.empsta == 2 & empsta == 1)      // Informal to formal transition
gen employer_switch = (switch_empl == 1)               // Changed employer
gen employer_stay = (switch_empl == 0)                 // Stayed with employer

* Pre-loan period indicators
bys idind: egen first_loan = min(year) if hhloan == 1
bys idind: egen loan_year = mean(first_loan)
gen pre_loan = (year > loan_year & !missing(loan_year))
gen will_take_loan = (inloan == 1)

global X1 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global IC "lnearn17 unrate17 pre1992 hhleftjob hhinvolun"

* Triple-diff regression: loan x employer switch
reg formal_switch i.pre_loan##i.will_take_loan##i.employer_switch $X1, cluster(idind)

*******************************************************************************
*               Within-Job vs Between-Job Formalization
*******************************************************************************

xtset idind year
gen within_job_formal = (l.empsta == 2 & empsta == 1 & switch_empl == l.switch_empl)
gen between_job_formal = (l.empsta == 2 & empsta == 1 & switch_empl != l.switch_empl)

* Compare characteristics and outcomes
reg fhhloan within_job_formal between_job_formal $X1, cluster(idind)

*******************************************************************************
*               Wage Premium Analysis: Propensity Score Matching
*******************************************************************************

gen formalized_existing = 1 if switch_empl == 0 & l.empsta == 2 & empsta == 1
replace formalized_existing = 0 if formalized_existing == . & switch_empl == 0 & l.empsta == 2 & empsta == 2

replace gen_status = . if gen_status < 0

* Nearest neighbor matching
nnmatch yDa formalized_existing age age2 female russian educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban okrug, tc(att) m(1)

*******************************************************************************
*               Skill Level Analysis
*******************************************************************************

* Create skill intensity measures
gen high_skill = inlist(jbM_occ1dig, 1, 2)      // Managers and professionals
gen medium_skill = inlist(jbM_occ1dig, 3, 4, 5) // Technical and clerical
gen low_skill = inlist(jbM_occ1dig, 6, 7, 8, 9) // Elementary occupations

gen skill_level = 3 if high_skill == 1
replace skill_level = 2 if medium_skill == 1
replace skill_level = 1 if low_skill == 1

* Triple-diff with skill levels
reg formal_switch i.pre_loan##i.will_take_loan##i.skill_level $X1, cluster(idind)

*******************************************************************************
*               Wage Premium Around Formalization
*******************************************************************************

gen event_time = year - formalization_year
replace event_time = event_time + 13

reghdfe lnhhinc ib13.event_time##i.fhhloan $X1, absorb(idind year) cluster(idind)

margins ib13.event_time, dydx(fhhloan) at(event_time)
marginsplot, recast(connected) ci scheme(s1color) yline(0) xline(0, lc(red)) ///
    xtitle("Event Time") ytitle("Impact on Household Income") ///
    title("Impact of FHH Loan on Household Income", size(small)) ///
    legend(title("Confidence Intervals"))
