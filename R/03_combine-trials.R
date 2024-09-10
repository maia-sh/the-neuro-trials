# Combine aact data for trials from different sources for combined table

library(dplyr)
library(here)
library(readr)
source("https://raw.githubusercontent.com/maia-sh/intovalue-data/817c24afa007dbc222cd28fe9b6090c4355ec96e/scripts/functions/duration_days.R")

# Get data
source_1 <- read_csv(here("data", "raw", "the_neuro", "the_neuro-cru-trial-list.csv"))

aact_1 <-
  read_csv(here("data", "processed", "the_neuro", "ctgov-studies.csv")) |>
  left_join(source_1, by = "nct_id") |>
  relocate(source, .after = "nct_id")

aact_2 <-
  read_csv(here("data", "processed", "montreal", "ctgov-studies.csv")) |>
  mutate(source = "registry-org-name-query", .after = "nct_id")

aact_2_only <- anti_join(aact_2, aact_1, by = "nct_id")

query_logs <- loggit::read_logs(here::here("queries.log"))
get_latest_query <- function(query, logs) {
  logs %>%
    filter(log_msg == query) %>%
    arrange(desc(timestamp)) %>%
    slice_head(n = 1) %>%
    pull(timestamp) %>%
    as.Date.character()
}

ctgov_download_date <- get_latest_query("AACT_montreal_neuro", query_logs)

# Prepare trials
studies <-

  bind_rows(aact_1, aact_2_only) |>
  select(-source) |>
  left_join(select(aact_1, nct_id, source), by = "nct_id") |>
  left_join(select(aact_2, nct_id, source), by = "nct_id") |>
  tidyr::unite("source", starts_with("source"), sep = ";", na.rm = TRUE) |>
  relocate(source, .after = "nct_id") |>

mutate(
    registration_year = lubridate::year(registration_date),
    start_year = lubridate::year(start_date),
    completion_year = lubridate::year(completion_date),

    # Registration is prospective if registered in same or prior month to start
    is_prospective =
      (lubridate::floor_date(registration_date, unit = "month") <=
         lubridate::floor_date(start_date, unit = "month")),

    # get registry download date
    registry_download_date = ctgov_download_date,

    # calculate results due date (1 year after primary completion date)
    # Alternative: results_due_date = ymd(primary_completion_date) + years(1)
    results_due_date = ymd(primary_completion_date) + days(365),

    # are summary results due at the time of registry download date?
    results_due = results_due_date < registry_download_date,

    # days from primary completion date to summary results date
    days_pcd_to_summary = duration_days(primary_completion_date, summary_results_date),

    # Whether summary results are reported within 1 year of primary completion
    is_summary_results_1y_pcd = days_pcd_to_summary <= 365*1
  )

write_csv(studies, here("data", "processed", "combined-ctgov-studies.csv"))
