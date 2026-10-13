# Data folder

## GC_inputs.xlsx (included)

Every parameter of the model in one workbook, read by `code/gc_config.m` at run time:

- **README**: purpose, how the code reads the workbook, units.
- **Parameters**: 46 rows with name, value, units, valid range, category, description, where it is used, source type, literature value or range, citation ids and notes.
- **Scenarios**: Base, NoGridCharging, RuleDispatch and Quick, each as a list of parameter overrides.
- **Sources**: the references behind every value (ids S1 to S41, matching the report's reference list).

Edit the `value` column of sheet Parameters to change a parameter; add a row to sheet Scenarios to define a new case.

## ComErgy Benchmark Dataset 2026.xlsx (not included)

The organiser's benchmark workbook is the only data source of the model. It is not redistributed in this repository because the challenge material does not state a redistribution licence. Obtain it from the ComErgy Grand Challenge 2026 page, https://comergy.com.au/comergy-grand-challenge-2026, and place it in this folder with its original file name:

```
data/ComErgy Benchmark Dataset 2026.xlsx
```

The code reads the sheet `ComErgy Benchmark Dataset 2026` (hourly rows A3:M8762 and the member side table P9:T17). On the first run `gc_load_data.m` writes two CSV twins beside it (`benchmark_hourly_2021.csv`, `members.csv`); they are ignored by git.
