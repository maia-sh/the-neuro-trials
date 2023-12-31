library(dplyr)
library(here)
library(fs)
library(readr)
# remotes::install_github("maia-sh/aactr")
library(aactr)
library(lubridate)
library(glue)


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
