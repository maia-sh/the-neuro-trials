# Get AACT data for: lists of trials provided by The Neuro(TheNeuro_registered_clinical_trials.csv; CRU trials_12Sep2023.xlsx)

library(dplyr)
library(here)
library(fs)
library(readr)
# remotes::install_github("maia-sh/aactr")
library(aactr)
library(lubridate)
library(glue)

org_short <- "the_neuro"

# Prepare directories
dir_raw_org <- dir_create(here("data", "raw", org_short))
dir_processed_org <- dir_create(here("data", "processed", org_short))

# Read in various files listing trials provided by the neuro
neuro_trial_list_1 <-
  read_csv(here("data", "raw", "TheNeuro_registered_clinical_trials.csv")) |>
  mutate(source = "TheNeuro_registered_clinical_trials.csv") |>
  tidyr::drop_na() |>
  rename(nct_id = clinicaltrials.gov_ID)

neuro_trial_list_2 <-
  readxl::read_excel(here("data", "raw", "CRU trials_12Sep2023.xlsx")) |>
  mutate(source = "CRU trials_12Sep2023.xlsx") |>
  tidyr::drop_na(`Study Identifier`) |>
  filter(stringr::str_detect(`Study Identifier`, "NCT")) |>
  rename(nct_id = `Study Identifier`)

neuro_trial_list <-
  full_join(neuro_trial_list_1, neuro_trial_list_2, by = "nct_id") |>
  tidyr::unite("source", starts_with("source"), sep = ";", na.rm = TRUE) |>
  select(nct_id, source)

write_csv(neuro_trial_list, glue("{dir_raw_org}/{org_short}-cru-trial-list.csv"))

# Download and process AACT data ------------------------------------------

trns <- neuro_trial_list$nct_id

# Specify aact username
AACT_USER <- "respmetrics"

download_aact(ids = trns, dir = dir_raw_org, user = AACT_USER, query = glue("AACT_{org_short}"))
process_aact(dir_raw_org, dir_processed_org, "csv")


# Explore affiliations ----------------------------------------------------
aact <- read_csv(path(dir_processed_org, "ctgov-studies.csv"))
affiliations <- read_csv(path(dir_processed_org, "ctgov-lead-affiliations.csv"))
contacts <- read_csv(path(dir_processed_org, "ctgov-contacts.csv"))
