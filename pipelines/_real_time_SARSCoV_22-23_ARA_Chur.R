library(targets)
library(tarchetypes)
library(crew)
source(here::here("pipelines", "_real_time_selection_targets_22-23.R"))
selection_targets <- all_selection_targets[["SARSCoV_22-23_ARA_Chur"]]
tar_option_set(packages = c("dplyr", "tidyr", "readr", "EpiSewer", 
    "data.table", "stringr", "targets", "ssh"), workspace_on_error = TRUE, 
    controller = crew_controller_local(workers = 4))
source("/Users/alison/Documents/dev/wastewater-generative/pipelines/_real_time_base_targets.R")
source(here::here("pipelines", "_real_time.R"))
