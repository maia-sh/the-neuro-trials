library(dplyr)
library(here)
library(fs)
library(readr)
# remotes::install_github("maia-sh/aactr")
library(aactr)
library(lubridate)
library(glue)
source("https://raw.githubusercontent.com/maia-sh/intovalue-data/817c24afa007dbc222cd28fe9b6090c4355ec96e/scripts/functions/duration_days.R")


#  Prepare organization ---------------------------------------------------
# NOTE: This script can be run for a single org at a time, so comment out others

org_short <- "montreal"
org_names <- stringr::str_c(org_short,
                            "montréal",
                            sep = "|"
                            )

# Additional set-up -------------------------------------------------------

# Prepare directories
dir_raw_org <- dir_create(here("data", "raw", org_short))
dir_processed_org <- dir_create(here("data", "processed", org_short))

# Specify aact username
AACT_USER <- "respmetrics"

# Get trials "led" by org -------------------------------------------------

affiliations <- get_org_trials(org = org_names, user = AACT_USER)

write_csv(affiliations, glue("{dir_raw_org}/{org_short}-trials-affiliations.csv"))


# Explore affiliations ----------------------------------------------------

unique_sponsor <-
  affiliations |>
  distinct(lead_sponsor) |>
  tidyr::drop_na(lead_sponsor) |>
  arrange(lead_sponsor)

unique_organizations <-
  affiliations |>
  tidyr::pivot_longer(!nct_id, names_to = "affiliation", values_to = "organization") |>
  distinct(organization) |>
  tidyr::drop_na(organization) |>
  arrange(organization)

neuro_organizations <-
  unique_organizations |>
  filter(stringr::str_detect(organization, "(?i)neuro"))

neuro_trials <-
  affiliations |>
  tidyr::pivot_longer(!nct_id, names_to = "affiliation", values_to = "organization") |>
  semi_join(neuro_organizations, by = "organization")

trns <- neuro_trials$nct_id

org_short <- stringr::str_c(org_short,
                            "neuro",
                            sep = "_"
)


# Download and process AACT data ------------------------------------------

download_aact(ids = trns, dir = dir_raw_org, user = AACT_USER, query = glue("AACT_{org_short}"))
process_aact(dir_raw_org, dir_processed_org, "csv")


# Combine AACT and org affiliation info -----------------------------------

aact <- read_csv(path(dir_processed_org, "ctgov-studies.csv"))

studies <-
  affiliations %>%

  # Add org to column names
  rename_with(~stringr::str_c(org_short, ., sep = "_"), -nct_id) %>%
  left_join(aact, ., by = "nct_id") %>%
  mutate(
    registration_year = lubridate::year(registration_date),
    start_year = lubridate::year(start_date),
    completion_year = lubridate::year(completion_date),

    # Registration is prospective if registered in same or prior month to start
    is_prospective =
      (floor_date(registration_date, unit = "month") <=
         floor_date(start_date, unit = "month")),

    # Days from completion date to summary results date
    # TODO: decide if use primary completion date if no completion date
    days_cd_to_summary = duration_days(completion_date, summary_results_date),

    # Whether summary results are reported within 1 year of completion
    is_summary_results_1y = days_cd_to_summary < 365*1
  )

write_csv(studies, glue("{dir_processed_org}/{org_short}-studies.csv"))


# # Filter for eligible trials ----------------------------------------------
#
# # Limit to interventional trials completed in or before 2020 with relevant status
# trials <-
#   studies %>%
#   filter(
#     study_type == "Interventional" &
#       recruitment_status %in% c("Completed" , "Terminated" , "Suspended", "Unknown status") &
#       completion_year < 2021
#   )
#
# write_csv(trials, glue("{dir_processed_org}/{org_short}-trials.csv"))
