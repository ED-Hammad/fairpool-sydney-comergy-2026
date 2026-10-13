# FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley settlement for the ComErgy benchmark community

Entry to the [ComErgy Community Energy Grand Challenge 2026](https://comergy.com.au/comergy-grand-challenge-2026) (ComErgy 2026: A Community Energy Futures Conference, University of Technology Sydney). Author: Hammad Masood, Khalifa University of Science and Technology, Abu Dhabi.

The nine households of the ComErgy Benchmark Dataset 2026 are operated as one cooperative pool. Each hour, rooftop solar serves all loads first; the fourteen battery modules act as one shared store scheduled by a daily linear programme that plans two days ahead; the grid is used last, and the pooled import never exceeds the peak the community would have had without cooperation. Each household's benefit is measured against the bill it would pay alone with its own solar and battery, so nobody can be worse off. The annual community saving is divided by the Shapley value computed exactly over all 511 coalitions, with one tenth set aside for the two lower-income households, and each household receives a one-page statement. For the benchmark year the pool saves 4,666 AUD, 37.6 % of the stand-alone bills; every household gains between 16 % and 99 % of its own bill; the peak import stays at 28.0 kW.

The full report is in [`docs/FairPoolSydney_ComErgy2026_Report.pdf`](docs/FairPoolSydney_ComErgy2026_Report.pdf).

## How to cite

Masood, H. (2026). FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley settlement for the ComErgy benchmark community (version 1.0.0). GitHub repository, https://github.com/ED-Hammad/fairpool-sydney-comergy-2026. Entry to the ComErgy Community Energy Grand Challenge 2026.

A machine-readable citation is in `CITATION.cff` (GitHub shows a "Cite this repository" button from it).

## Requirements

- MATLAB R2025b (R2023a or later should work; not tested).
- Optimization Toolbox (`linprog`, dual simplex algorithm). No other toolbox.
- About 2 GB of free memory and a desktop CPU; a full run of one scenario takes about 12 minutes, dominated by the 365 daily linear programmes of each of the 511 coalitions.
- The organiser's benchmark workbook, placed in `data/` (see below). No internet access and no other data are needed.

## Folder layout

```
README.md            this file
LICENSE              MIT licence for the code and the inputs workbook
CITATION.cff         citation metadata
.gitignore           excludes run outputs, the benchmark workbook and MATLAB clutter
code/                MATLAB source (entry point gc_main.m)
data/                GC_inputs.xlsx (every parameter with units, ranges, sources and notes) and data/README.md
results/headline/    the headline result tables of the three reported scenarios (CSV)
results/statements/  the nine household statements of the Base scenario (Markdown)
docs/                the report (PDF)
```

Folders written by a run (ignored by git): `results/` run files with a run tag, `results/statements_<tag>/`, `figures/<tag>/`, and the two CSV twins of the benchmark in `data/`.

## Set-up

1. Clone or download the repository:

   ```
   git clone https://github.com/ED-Hammad/fairpool-sydney-comergy-2026.git
   ```

2. Download `ComErgy Benchmark Dataset 2026.xlsx` from the [challenge page](https://comergy.com.au/comergy-grand-challenge-2026) and place it in `data/` with that exact file name. The workbook is not redistributed here (see `data/README.md`).

## Running the model

From a system shell, with the repository root as the current directory:

```
matlab -batch "addpath(fullfile(pwd,'code')); gc_main('full','Base')"
```

From the MATLAB command window, with the repository root as the current folder:

```
addpath(fullfile(pwd,'code')); gc_main('full','Base')
```

Arguments: `mode` is `'full'` (daily linear programme for the pool and all 511 coalitions, cap sweep, sensitivity, statements, figures) or `'quick'` (one minute; self-consumption rule for every coalition, no cap sweep, no sensitivity); `scenario` is a row of sheet Scenarios in `data/GC_inputs.xlsx`: `'Base'`, `'NoGridCharging'`, `'RuleDispatch'` or `'Quick'`.

The three scenarios reported:

```
gc_main('full','Base')              primary result (about 12 minutes)
gc_main('full','NoGridCharging')    safe mode without grid charging (about 17 minutes; the 15 kW cap is reported infeasible)
gc_main('full','RuleDispatch')      lower bound with the simple rule (about 3 minutes)
```

Every run prints its progress and ends with `GC RUN COMPLETE <tag>`. The model is deterministic: the same inputs give the same outputs to the last digit. Every dispatch asserts the hourly energy balance and the state-of-charge bounds.

## Changing the inputs

All 46 parameters beyond the benchmark are in sheet Parameters of `data/GC_inputs.xlsx` (name, value, units, valid range, description, where used, source type, literature value, citation ids, notes). Edit the `value` column; keep the names. A scenario is a row of sheet Scenarios with a semicolon-separated list of overrides, for example `disp.grid_charging=false`. The code reads the workbook at run time and saves a copy of the inputs it used beside the results of each run.

## Outputs of a run

Written to `results/` and `figures/<tag>/` with a run tag `<yyyymmdd_HHMMSS>_<Scenario>`:

| File | Content |
|---|---|
| `hourly_dispatch_<tag>.csv` | 8,760 rows: community load, solar, import, export, charge, discharge, state of charge, prices, illustrative internal price |
| `allocations_<tag>.csv` | per household: bills without assets, stand-alone, Shapley share, solidarity share, recommended gain, same-percentage gain, settled bill, relative saving, nucleolus |
| `coalition_values_<tag>.csv` | the 511 coalitions with members and value |
| `kpi_summary_<tag>.csv` | community indicators for the simple rule, the daily programme and the programme without grid charging |
| `fairness_<tag>.csv` | minimum relative saving, minimum gain, Gini coefficient, individual-rationality flag and maximum core excess for four allocation rules |
| `peak_sweep_<tag>.csv` | community cost and peak at explicit import caps of 25, 20 and 15 kW |
| `tornado_<tag>.csv` | one-at-a-time sensitivity of the saving, the Gini coefficient and the minimum relative saving |
| `inputs_used_<tag>.xlsx` | frozen copy of the inputs workbook |
| `statements_<tag>/member_1.md` to `member_9.md` | one annual statement per household |
| `figures/<tag>/fig01` to `fig07` (PNG) | dispatch weeks, bills, allocation rules, Lorenz curves, cap sweep, import duration curves, tornado |

## Reproducing the tables and figures of the report

| Report item | Source |
|---|---|
| Table 1 (members) | member side table of the benchmark, printed at the start of every run |
| Table 2 and Table A1 (parameters, assumptions) | sheet Parameters and sheet Sources of `data/GC_inputs.xlsx` |
| Table 4 (community indicators) | `kpi_summary` of the three runs (columns lp, lp_nogrid, rule) |
| Table 5 (per-household settlement) | `allocations` of the Base run |
| Table 6 (fairness indicators) | `fairness` of the Base run |
| Tables B1 to B10 (statements) | `statements_<tag>/member_*.md` of the Base run; the energy rows of each statement follow from the hourly data and the stand-alone rule |
| Figure 3 (dispatch weeks) | `fig01_dispatch_weeks.png` |
| Figure 4 (bills) | `fig02_bills.png` |
| Figures 5 and 6 (allocation rules, Lorenz curves) | `fig03_allocation_rules.png`, `fig04_lorenz.png` |
| Figure 7 (import duration curves) | `fig06_import_duration.png` |
| Figure 8 (cost against import cap) | `fig05_peak_cap.png` and `peak_sweep` |
| Figure 9 (tornado) | `fig07_tornado.png` and `tornado` |
| Figures 1 and 2 | drawn schematics, included only in the report |

The headline tables shipped in `results/headline/` are the CSV files above from the final runs of 12 October 2026 (round-trip efficiency 0.95), renamed without the run tag. A fresh `gc_main('full','Base')` reproduces them exactly.

## Method in one paragraph

Solar generation per kilowatt is derived from the benchmark irradiance and temperature (Erbs decomposition, isotropic transposition to a 30 degree north-facing plane, NOCT cell temperature, DC losses and inverter efficiency). Each household's stand-alone bill follows the self-consumption rule of a hybrid inverter. A coalition is dispatched as one customer with one shared store by a linear programme solved each day over a two-day window, with the import capped at the coalition's own uncoordinated peak. The value of each of the 511 coalitions is its saving against the stand-alone bills; the exact Shapley value, a 10 % solidarity share for households below the Greater Sydney median income and a floor at zero give the recommended allocation, checked against the same-percentage rule, the core and the nucleolus. Full equations and sources are in the report.

## Licence

Code and the inputs workbook: MIT License (see `LICENSE`). Report PDF and household statements: Creative Commons Attribution 4.0 International (CC BY 4.0). The benchmark dataset belongs to the ComErgy organisers and is not redistributed.

## Contact

Hammad Masood, Khalifa University of Science and Technology, Abu Dhabi, United Arab Emirates. engr.hammadmasood@gmail.com
