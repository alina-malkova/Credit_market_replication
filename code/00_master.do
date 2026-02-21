/*******************************************************************************
* MASTER DO-FILE: Labor Informality and Credit Market
* Journal of Comparative Economics
*
* Description: This master file runs all analysis do-files in sequence
*              to replicate the results in the paper.
*
* Data required: RLMS-HSE (Russia Longitudinal Monitoring Survey), 2006-2016
*                Available from: https://www.hse.ru/en/rlms/
*
* Instructions:
*   1. Set the global macro $origin to your data directory
*   2. Run this file: do "00_master.do"
*
*******************************************************************************/

clear all
set more off
set matsize 11000
capture log close

* =============================================================================
* SETUP: Set your data directory path here
* =============================================================================

global origin "C:\Data\RLMS"  // <-- MODIFY THIS PATH

* Output directory for results
global output "$origin\output"
capture mkdir "$output"

* Log file
log using "$output\replication_log.txt", text replace

* =============================================================================
* INSTALL REQUIRED PACKAGES (run once)
* =============================================================================

/*
ssc install eventdd
ssc install reghdfe
ssc install ftools
ssc install oaxaca
ssc install estout
*/

* =============================================================================
* STEP 1: Community and Regional Variables
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 1: Community and Regional Variables"
display "=" * 70

do "01_community_regional_vars.do"

* =============================================================================
* STEP 2: Extract Variables for Credit Project
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 2: Extract Variables"
display "=" * 70

do "02_extract_variables.do"

* =============================================================================
* STEP 3: Summary Statistics (Table 1)
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 3: Summary Statistics"
display "=" * 70

do "03_summary_statistics.do"

* =============================================================================
* STEP 4: Dynamic Employment Model (Tables 2-3)
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 4: Dynamic Employment Model"
display "=" * 70

do "04_dynamic_employment_model.do"

* =============================================================================
* STEP 5: Adjustment for Attrition
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 5: Attrition Adjustment"
display "=" * 70

do "05_attrition_adjustment.do"

* =============================================================================
* STEP 6: Alternative Definitions of Informality
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 6: Alternative Informality Definitions"
display "=" * 70

do "06_alt_informality_definitions.do"

* =============================================================================
* STEP 7: Policy Simulation (Table 6)
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 7: Policy Simulation"
display "=" * 70

do "07_policy_simulation.do"

* =============================================================================
* STEP 8: Heterogeneity of Response (Table 5)
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 8: Heterogeneity Analysis"
display "=" * 70

do "08_heterogeneity.do"

* =============================================================================
* STEP 9: Loan Equation (Table 4)
* =============================================================================

display _newline(2)
display "=" * 70
display "STEP 9: Loan Equation"
display "=" * 70

do "09_loan_equation.do"

* =============================================================================
* REVISION: Event Study and Additional Analyses (Figures 1-2)
* =============================================================================

display _newline(2)
display "=" * 70
display "REVISION: Event Study Analyses"
display "=" * 70

do "revision.do"

* =============================================================================
* COMPLETION
* =============================================================================

display _newline(2)
display "=" * 70
display "REPLICATION COMPLETE"
display "=" * 70
display "Results saved to: $output"

log close

* End of master do-file
