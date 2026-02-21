# Replication Package: Labor Informality and Credit Market

## Paper Information

**Title:** Labor Informality and Credit Market
**Authors:** [Author names]
**Journal:** Journal of Comparative Economics
**Year:** 2025

## Overview

This replication package contains the Stata do-files required to reproduce all tables and figures in the paper. The analysis examines how credit market accessibility influences the transition of workers from informal to formal employment in Russia.

## Data

The analysis uses **RLMS-HSE** (Russia Longitudinal Monitoring Survey - Higher School of Economics), 2006-2016.

**Data availability:** The RLMS-HSE data is publicly available from the [RLMS-HSE website](https://www.hse.ru/en/rlms/).

**Main dataset required:**
- `rlms_credit_workfile.dta` - Panel dataset with individual, household, and community-level variables

## Software Requirements

- **Stata 15** or higher
- Required Stata packages:
  - `gsem` - Generalized structural equation modeling
  - `eventdd` - Event study analysis
  - `reghdfe` - Linear regression with high-dimensional fixed effects
  - `margins` - Marginal effects
  - `oaxaca` - Blinder-Oaxaca decomposition

To install required packages:
```stata
ssc install eventdd
ssc install reghdfe
ssc install oaxaca
```

## File Structure

```
code/
├── 00_master.do                    # Master file to run all analyses
├── 01_community_regional_vars.do   # Community and regional variables
├── 02_extract_variables.do         # Extract variables for credit project
├── 03_summary_statistics.do        # Summary statistics (Table 1)
├── 04_dynamic_employment_model.do  # Dynamic multinomial logit (Tables 2-3)
├── 05_attrition_adjustment.do      # Attrition adjustment
├── 06_alt_informality_definitions.do # Alternative informality definitions
├── 07_policy_simulation.do         # Policy simulations (Table 6)
├── 08_heterogeneity.do             # Heterogeneity analysis (Table 5)
├── 09_loan_equation.do             # Loan probability model (Table 4)
├── revision.do                     # Event study and additional analyses
└── revision_main.do                # Main revision analyses
```

## Instructions

### Setup

1. Download the RLMS-HSE data from the official website
2. Set the global macro `$origin` to your data directory path:

```stata
global origin "path/to/your/data"
```

### Running the Analysis

To replicate all results, run the master do-file:

```stata
do "code/00_master.do"
```

Or run individual do-files in order (01 through 09).

## Tables and Figures

| Output | Do-file | Description |
|--------|---------|-------------|
| Table 1 | 03_summary_statistics.do | Summary statistics |
| Table 2 | 04_dynamic_employment_model.do | Dynamic multinomial logit - main results |
| Table 3 | 04_dynamic_employment_model.do | Marginal effects |
| Table 4 | 09_loan_equation.do | Loan probability model |
| Table 5 | 08_heterogeneity.do | Heterogeneity of response |
| Table 6 | 07_policy_simulation.do | Policy simulation |
| Figure 1 | revision.do | Event study - formal to informal transition |
| Figure 2 | revision.do | Event study - informal to formal transition |

## Key Variables

- **Dependent variable:** Employment status (formal / informal / non-employed)
- **Credit market accessibility:** Composite index from bank presence, distance to Sberbank, distance to other banks, regional bank branches per capita
- **Informality definitions:**
  - Registration-based (unregistered employees, self-employed)
  - Tax-based ("envelope earnings")

## Contact

For questions about the replication package, please contact:
[Contact information]

## License

[Specify license]
