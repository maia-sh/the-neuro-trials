
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Trials at The Neuro (Montreal Neurological Institute-Hospital)

Latest AACT query: 2023-11-11

``` r
trials <- readr::read_csv(here::here("data", "processed", "combined-ctgov-studies.csv"))
#> Rows: 179 Columns: 26
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr  (9): nct_id, source, study_type, phase, recruitment_status, title, allo...
#> dbl  (6): enrollment, registration_year, start_year, completion_year, days_c...
#> lgl  (5): has_summary_results, is_multicentric, is_prospective, is_summary_r...
#> dttm (3): start_date, completion_date, primary_completion_date
#> date (3): last_update_submitted_date, registration_date, summary_results_date
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

“combined-ctgov-studies.csv” contains 179 ClinicalTrials.gov
registrations.
