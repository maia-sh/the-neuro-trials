# Get AACT data for list of trials provided by The Neuro (TheNeuro_registered_clinical_trials.csv)

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

neuro_trials <-
  read_csv(here("data", "raw", "TheNeuro_registered_clinical_trials.csv")) |>
  tidyr::drop_na() |>
  rename(nct_id = clinicaltrials.gov_ID)

trns <- neuro_trials$nct_id

# Specify aact username
AACT_USER <- "respmetrics"


# Download and process AACT data ------------------------------------------

download_aact(ids = trns, dir = dir_raw_org, user = AACT_USER, query = glue("AACT_{org_short}"))
process_aact(dir_raw_org, dir_processed_org, "csv")


# Explore affiliations ----------------------------------------------------
aact <- read_csv(path(dir_processed_org, "ctgov-studies.csv"))
affiliations <- read_csv(path(dir_processed_org, "ctgov-lead-affiliations.csv"))
contacts <- read_csv(path(dir_processed_org, "ctgov-contacts.csv"))
