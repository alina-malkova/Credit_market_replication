* Author: Klara S. Peter
** This do file extracts vaiables for the project on credit market

clear
cd  "C:\My projects\RLMS\CPC\CPC data\Community data"
global regvar "C:\My projects\RLMS\CPC\CPC data\Common regional variables"
global regid  "C:\My projects\RLMS\CPC\CPC data\Workfiles\Regional ids"

********************************************************************************
* Inflation volatility within year: standard deviations of monthly CPI inflation
********************************************************************************
	
use "$regvar\reg_cpimonthly.dta", clear
recode month 1/3=1 4/6=2 7/9=3 10/12=4, gen(quarter)
gen yrqrt=yq(year, quarter)
format yrqrt %tq

// quarterly inflation
xtset ter yrmon
gen inflation=cpimon-100
gen inflqrt=((1+inflation/100)*(1+l1.inflation/100)*(1+l2.inflation/100)-1)*100 
keep if month==3|month==6|month==9|month==12

xtset ter yrqrt
tsegen inflqrtSD1 = rowsd(L(0/3).inflqrt)
tsegen inflqrtSD2 = rowsd(L(0/3).inflqrt F(1/4).inflqrt)
label var inflqrtSD1 "Volatility of quarterly CPI inflation within 1 year, std. dev"
label var inflqrtSD2 "Volatility of quarterly CPI inflation within 2 years, std. dev"
keep if month==12
keep ter year inflqrtSD*
save "$regvar\inflation_volatility.dta", replace

********************************************************************************
* 				Clean distance measures
********************************************************************************

import excel using bank_distance_clean.xlsx, first clear
keep site year bcat bdistS bdistO
encode bcat, gen(bankcat)
drop bcat
save "commun_bank_dist.dta", replace

********************************************************************************
* 			Credit-related community and regional variables
********************************************************************************

use site year ter psu popsite banka_dist bankcat sberoffice bankscom govtcl cost_oblT cost_oblD ctype dist_obl indic_obl using "commun_constructed.dta", clear

gen bankcap=bankscom*1000/popsite
label var bankcap "Number of banks in community per 1000 population"
gen sbercap=sberoffice*1000/popsite
label var sbercap "Number of Sberbank offices in community per 1000 population"

rename banka_dist bdist_orig
rename bankcat bankcat_orig
gen bdist1_orig=bdist_orig if bankcat_orig==1
replace bdist1_orig=0 if bankcat_orig==2| bankcat_orig==3
label var bdist1_orig "Distance from communities with no bank to the nearest bank, km"

gen bdist2_orig=bdist_orig if bankcat_orig==2
replace bdist2_orig=0 if bankcat_orig==1| bankcat_orig==3
label var bdist2_orig "Distance from communities with Sberbank to the nearest other bank, km"

merge 1:1 site year using commun_bank_dist.dta, nogen
label var bdistS "Distance to the nearest Sberbank office, km"
label var bdistO "Distance to the nearest other bank office, km"
label var bankcat "Bank availability, 3 categories"
tab bankcat, gen(bankcat)
drop bankcat3	// omitted=other banks

foreach v in bdistO bdistS  {
	gen ln`v'=ln(1+`v')
	}
label var lnbdistS "Log distance to the nearest Sberbank office, km"
label var lnbdistO "Log distance to the nearest other bank office, km"

replace popsite=popsite/1000
label var popsite "Community population, in thousands"

gen urban=(ctype<5) if ctype<.
label var urban "=1 if urban"

// add regional variables
global R "gdpgrw popul gdpcapR lngdpcapR unrate lifexp_t lifexp_m"
merge m:1 ter year using "$regvar\reg_common.dta", keep(1 3) nogen keepusing($R)
merge m:1 ter year using "$regvar\reg_credmarket.dta", keep(1 3) nogen
merge m:1 ter year using "$regvar\Credit market\reg_cbr_bank_services.dta", keep(1 3) nogen keepusing(crednum2 credpop2 cbdepinc)
merge m:1 ter year using "$regvar\reg_wages.dta", keep(1 3) nogen keepusing(lnwgregR)
merge m:1 ter year using "$regvar\reg_emp_ownership.dta", keep(1 3) nogen keepusing(sh*)
merge m:1 ter year using "$regvar\reg_informal.dta", keep(1 3) nogen keepusing(infperc)
merge m:1 ter year using "$regvar\inflation_volatility.dta", keep(1 3) nogen 
drop regname rusregion_cb

xtset site year
gen lnsberpop=ln(sberpop)
gen lncredorg=ln(credorg)
label var lnsberpop "Log number of Sberbank offices per 10,000, end year"
label var lncredorg "Log number of credit institutions in region, end year"
order lnsberpop lncredorg, after(sberpop)

save "commun_credit.dta", replace





