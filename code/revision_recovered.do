

*FORMAL_INFORMAL

gen trans_form_if=1 if empsta==1 & fempsta==2
replace trans_form_if=0 if empsta==1 & fempsta==1

* Transition conditional on getting loan in period t+1
gen trans_form_if_loan=1 if empsta==1 & fempsta==2 & fhhloan==1
replace trans_form_if_loan=0 if empsta==1 & fempsta==1 & fhhloan==1







*Create timevariable
gen yearevent=year if trans_form_if==1
replace yearevent=0 if yearevent==.


bysort idind (year): egen newvar = max(yearevent)


gen dif=year-newvar
replace dif=. if dif>14

eventdd lnhhinc, timevar(dif) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))



tsset idind dif
bys dif: egen mean = mean(lnhhinc)

bys dif: egen sd = sd(lnhhinc)


gen upper = mean + sd 
gen lower = mean - sd 
*set scheme s1color 

twoway rcap upper lower dif, lc(blue) || scatter mean dif, mc(red) 

tsset idind dif2
bys dif2: egen mean2 = mean(lnhhinc)

bys dif2: egen sd2 = sd(lnhhinc)


gen upper2 = mean2 + sd2
gen lower2 = mean2 - sd2 
*set scheme s1color 

twoway rcap upper2 lower2 dif2, lc(blue) || scatter mean2 dif2, mc(red) 

twoway rcap upper2 lower2 dif2, lc(blue) || scatter mean2 dif2, mc(red) || rcap upper lower dif, lc(green) || scatter mean dif, mc(yellow)




*INFORMAL_FORMAL

gen trans_inform_form=1 if empsta==2 & fempsta==1
replace trans_inform_form=0 if empsta==2 & fempsta==2


gen formalization_year=year if  trans_inform_form==1
bysort idind (year): egen formalization_firstyear = max(formalization_year)






* Transition conditional on getting loan in period t+1
gen trans_inform_form_loan=1 if empsta==2 & fempsta==1 & fhhloan==1
replace trans_inform_form_loan=0 if empsta==2 & fempsta==2 & fhhloan==1

gen yearevent2_loan=year if  trans_inform_form_loan==1
replace yearevent2_loan=0 if yearevent2_loan==.

bysort idind (year): egen newvar2_loan = max(yearevent2_loan)
gen dif2_loan=year-newvar2_loan
replace dif2_loan=. if dif2_loan>14

eventdd lnhhinc, timevar(dif2_loan) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))


tsset idind dif2_loan
bys dif2_loan: egen mean2_loan = mean(lnhhinc)

bys dif2_loan: egen sd2_loan = sd(lnhhinc)


gen upper2_loan = mean2_loan + sd2_loan 
gen lower2_loan = mean2_loan - sd2_loan 
*set scheme s1color 

twoway rcap upper2_loan lower2_loan dif2_loan, lc(blue) || scatter mean2_loan dif2_loan, mc(red) || rcap upper2 lower2 dif2, lc(green) || scatter mean2 dif2, mc(yellow)




* Transition conditional on notgetting loan in period t+1
gen trans_inform_form_noloan=1 if empsta==2 & fempsta==1 & fhhloan==0
replace trans_inform_form_noloan=0 if empsta==2 & fempsta==2 & fhhloan==0

gen yearevent2_noloan=year if  trans_inform_form_noloan==1
replace yearevent2_noloan=0 if yearevent2_noloan==.

bysort idind (year): egen newvar2_noloan = max(yearevent2_noloan)
gen dif2_noloan=year-newvar2_noloan
replace dif2_noloan=. if dif2_noloan>14

*eventdd lnhhinc, timevar(dif2_noloan) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))


tsset idind dif2_noloan
bys dif2_noloan: egen mean2_noloan = mean(lnhhinc)

bys dif2_noloan: egen sd2_noloan = sd(lnhhinc)


gen upper2_noloan = mean2_noloan + sd2_noloan 
gen lower2_noloan = mean2_noloan - sd2_noloan 
*set scheme s1color 

twoway rcap upper2_loan lower2_loan dif2_loan, lc(blue) || scatter mean2_loan dif2_loan, mc(red) || rcap upper2_noloan lower2_noloan dif2_noloan, lc(green) || scatter mean2_noloan dif2_noloan, mc(yellow)

*Create timevariable
gen yearevent2=year if  trans_inform_form==1
replace yearevent2=0 if yearevent==.


bysort idind (year): egen newvar2 = max(yearevent2)


gen dif2=year-newvar2
replace dif2=. if dif2>14



eventdd lnhhinc, timevar(dif2) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))






*Clarify whether formalization happens within existing jobs or through job transitions


*******************************************************************************
*					Figure 5a: Event-study analysis
*						Share of formal workers in t
*******************************************************************************
xtset idind year
gen switch_empl=1 if jb1_tenure<=1 //switched a job in period t
replace switch_empl=0 if jb1_tenure>1
xtset idind year
gen lswitch_empl=l.switch_empl

gen linloan=l.inloan


	
	
	
	// Core outcome variables
gen formal_switch = (l.empsta==2 & empsta==1)          // Informal to formal transition
gen employer_switch = (switch_empl==1)                 // Changed employer

gen employer_stay = (switch_empl==0)                 // Changed employer




// Generate pre-loan period indicators
bys idind: egen first_loan = min(year) if hhloan==1
bys idind: egen loan_year = mean(first_loan)
gen pre_loan = (year > loan_year & !missing(loan_year))   // Pre-loan period
gen will_take_loan = (inloan==1)                // Will eventually take loan

global X1 "age age2 female russian ib1.educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban intervday ib1.okrug ib1.year"
global IC "lnearn17 unrate17 pre1992 hhleftjob hhinvolun"


// Triple-diff regression
reg formal_switch i.pre_loan##i.will_take_loan##i.employer_switch  $X1  , cluster(idind)
	
	
	
	
	
* Wage Premium Analysis: Matching on Pre-Formalization Characteristics


gen formalized_existing=1 if switch_empl==0 & l.empsta==2 & empsta==1
replace formalized_existing=0 if formalized_existing==. & switch_empl==0 & l.empsta==2 & empsta==2

replace gen_status=. if gen_status<0

* 1. Propensity Score Estimation (using A)
nnmatch yDa formalized_existing age age2 female russian educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban okrug , tc(att) m(1) 
	
	
	

//Testing Contract Change vs Job Mobility Mechanism:

// A. Within-Job Formalization Analysis
xtset idind year
gen within_job_formal = (l.empsta==2 & empsta==1 & switch_empl==l.switch_empl)
gen between_job_formal = (l.empsta==2 & empsta==1 & switch_empl!=l.switch_empl)

// Compare characteristics and outcomes
reg fhhloan within_job_formal between_job_formal $X1, cluster(idind)









Skill Level and Human Capital:

// A. Create skill intensity measures
gen high_skill = inlist(jbM_occ1dig, 1, 2) // Managers and professionals
gen medium_skill = inlist(jbM_occ1dig, 3, 4, 5) // Technical and clerical
gen low_skill = inlist(jbM_occ1dig, 6, 7, 8, 9) // Elementary occupations


gen skill_level=3 if high_skill==1
replace skill_level=2 if medium_skill==1
replace skill_level=1 if low_skill==1

// B. Triple-diff with skill levels
reg formal_switch i.pre_loan##i.will_take_loan##i.skill_level $X1, cluster(idind)










//Wage Premium Analysis:

// A. Wage gains around formalization
gen event_time = year - formalization_year
replace event_time=event_time+13



reghdfe lnhhinc ib13.event_time##i.fhhloan $X1, absorb(idind year) cluster(idind)

margins ib13.event_time, dydx(fhhloan) at(event_time)
marginsplot, recast(connected) ci scheme(s1color) yline(0) xline(0, lc(red)) ///
    xlabel(`=e(min_event_time)'(2)`=e(max_event_time)') ///
    xtitle("Event Time") ytitle("Impact on Household Income") ///
    title("Impact of FHH Loan on Household Income", size(small)) legend(title("Confidence Intervals"))

// B. Decomposition of wage gains
oaxaca log_wage [controls] if empsta==1 | empsta==2, by(formal) detail


// Create variables for plotting
matrix b_explained = e(b_explained)
matrix b_unexplained = e(b_unexplained)
matrix V_explained = e(V_explained)
matrix V_unexplained = e(V_unexplained)

// Store in variables
local vars "age age2 female russian educat_p schadjC married nmember nage13y lnhhcon lnpopsite urban"
local n_vars: word count `vars'

clear
set obs `n_vars'
gen varname = ""
gen explained = .
gen unexplained = .
gen se_explained = .
gen se_unexplained = .

// Fill data
local i = 1
foreach var in `vars' {
    replace varname = "`var'" in `i'
    replace explained = b_explained[1,`i']
    replace unexplained = b_unexplained[1,`i']
    replace se_explained = sqrt(V_explained[`i',`i'])
    replace se_unexplained = sqrt(V_unexplained[`i',`i'])
    local i = `i' + 1
}

// Create confidence intervals
gen ci_exp_low = explained - 1.96*se_explained
gen ci_exp_high = explained + 1.96*se_explained
gen ci_unexp_low = unexplained - 1.96*se_unexplained
gen ci_unexp_high = unexplained + 1.96*se_unexplained

// Create combined plot
twoway (rcap ci_exp_low ci_exp_high _n, horizontal lcolor(navy)) ///
       (scatter _n explained, mcolor(navy) msymbol(O)) ///
       (rcap ci_unexp_low ci_unexp_high _n, horizontal lcolor(maroon)) ///
       (scatter _n unexplained, mcolor(maroon) msymbol(S)), ///
       ylabel(1/`n_vars', valuelabel angle(0) labsize(small)) ///
       xlabel(, format(%9.2f)) ///
       yaxis(1) yscale(reverse) ///
       ytitle("") xtitle("Contribution to wage gap") ///
       legend(order(2 4) label(2 "Explained") label(4 "Unexplained")) ///
       xline(0, lpattern(dash) lcolor(gray)) ///
       title("Oaxaca-Blinder Decomposition") ///
       subtitle("Explained and unexplained components") ///
       note("95% confidence intervals shown") ///
       graphregion(color(white))







Worker-Firm Match Quality:

stataCopy// A. Tenure analysis
gen tenure = year - job_start_year
reg formal_switch c.tenure##i.will_take_loan [controls], cluster(idind)

// B. Match specific capital
bys idind employer_id: egen match_wage_growth = (wage - wage[1])/wage[1]
reg formal_switch c.match_wage_growth##i.will_take_loan [controls], cluster(idind)

Selection into Formalization:

stataCopy// A. Propensity score matching
logit formal_switch [worker_characteristics] if loan_eligibility==1
predict ps
psmatch2 loan_take, pscore(ps) outcome(formal)

// B. Heckman selection model
heckman wage formal_switch [controls], select(loan_eligible = z1 z2 z3) cluster(idind)
Key Outcomes to Examine:

Wage trajectories pre/post formalization
Job tenure and stability
Occupation upgrading
Training receipt
Credit access and utilization

Additional Specifications:

For Skill Value Testing:

stataCopy// Test if high-skilled workers are more likely to formalize within jobs
reg within_job_formal i.skill_level##i.will_take_loan [controls], cluster(idind)

// Test if wage premiums differ by skill level
reg log_wage i.formal##i.skill_level [controls], cluster(idind)

For Firm Heterogeneity:

stataCopy// Test if formalization varies by firm size/type
reg formal_switch i.pre_loan##i.will_take_loan##i.firm_size [controls], cluster(idind)

// Test if wage gains vary by firm characteristics
reg log_wage i.formal##i.firm_size [controls], cluster(idind)
This empirical strategy would:

Distinguish between within-job formalization and between-job mobility
Identify the role of worker skills and match-specific capital
Quantify wage premiums and their relationship to formalization
Account for selection into formalization
Examine heterogeneity by worker and firm characteristics

Would you like me to elaborate on any of these methods or suggest additional specifications?
	
	
