library(targets)
library(tarchetypes)
library(crew)
source(here::here("pipelines", "_real_time_subsampling_selection_targets_23-24.R"))
selection_targets <- all_selection_targets[["IAV_23-24_ARA_Werdhoelzli"]]
tar_option_set(packages = c("dplyr", "tidyr", "readr", "EpiSewer", 
    "data.table", "stringr", "targets", "ssh"), workspace_on_error = TRUE, 
    controller = crew_controller_local(workers = 4))
source("pipelines/_real_time_subsampling_base_targets.R")
source(here::here("pipelines", "_real_time.R"))
