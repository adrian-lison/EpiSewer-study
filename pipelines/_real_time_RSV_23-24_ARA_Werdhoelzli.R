library(targets)
library(tarchetypes)
library(crew)
source(here::here("pipelines", "_real_time_selection_targets_23-24.R"))
selection_targets <- all_selection_targets[["RSV_23-24_ARA_Werdhoelzli"]]
source(here::here("pipelines", "_real_time.R"))
