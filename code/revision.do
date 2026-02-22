* Authors: Klara S. Peter and Alina Malkova
** This do file creates event study figures for employment transitions
** Figure 1: Formal to informal transition
** Figure 2: Informal to formal transition

*******************************************************************************
*                       SETUP
*******************************************************************************

use "$origin\rlms_credit_workfile.dta", clear

*******************************************************************************
*               Figure 1: Formal to Informal Transition
*******************************************************************************

* Define transition: formal (t) to informal (t+1)
gen trans_form_if = 1 if empsta == 1 & fempsta == 2
replace trans_form_if = 0 if empsta == 1 & fempsta == 1

* Create event time variable
gen yearevent = year if trans_form_if == 1
replace yearevent = 0 if yearevent == .

bysort idind (year): egen newvar = max(yearevent)

gen dif = year - newvar
replace dif = . if dif > 14

* Event study regression
eventdd lnhhinc, timevar(dif) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))

*******************************************************************************
*               Figure 2: Informal to Formal Transition
*******************************************************************************

* Define transition: informal (t) to formal (t+1)
gen trans_inform_form = 1 if empsta == 2 & fempsta == 1
replace trans_inform_form = 0 if empsta == 2 & fempsta == 2

* Create event time variable
gen yearevent2 = year if trans_inform_form == 1
replace yearevent2 = 0 if yearevent == .

bysort idind (year): egen newvar2 = max(yearevent)

gen dif2 = year - newvar2
replace dif2 = . if dif2 > 14

* Event study regression
eventdd lnhhinc, timevar(dif2) method(fe) graph_op(ytitle("Log Income") xlabel(-15(5)15))
