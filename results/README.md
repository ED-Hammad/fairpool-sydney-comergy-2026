# Results

`headline/<Scenario>/` holds the headline tables of the three reported runs of 12 October 2026 (round-trip efficiency 0.95), renamed without their run tags: `kpi_summary.csv` (community indicators for the simple rule, the daily programme and the programme without grid charging), `allocations.csv` (per-household bills and shares), `fairness.csv` (fairness indicators of four allocation rules), `peak_sweep.csv` (cost against explicit import caps) and `tornado.csv` (sensitivity, Base only).

`statements/` holds the nine household statements of the Base run as the model writes them.

A full run (`gc_main('full','Base')`) regenerates these files, the hourly dispatch, the 511 coalition values, the frozen inputs and the figures, each with a run tag.
