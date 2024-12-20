library(targets)
library(tarchetypes)
library(crew)
source(here::here("pipelines", "_real_time_selection_targets_22-23.R"))
selection_targets <- all_selection_targets[["IAV_22-23_ARA_Chur"]]
source(here::here("pipelines", "_real_time.R"))
