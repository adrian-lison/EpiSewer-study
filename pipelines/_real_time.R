# Define custom functions and other global objects.
# This is where you write source(\"R/functions.R\")
# if you keep your functions in external scripts.
source("code/local_config.R")
source("code/utils_dists.R")

source("code/pipeline/utils_pipeline.R")
source("code/pipeline/functions_pipeline.R")
source("code/pipeline/components_pipeline.R")

source("code/pipeline/run_local_pipeline.R")

# user settings
dry_run <- readRDS(file.path(tar_path_store(), "settings/dry_run.rds"))
run_cluster <- readRDS(file.path(tar_path_store(), "settings/run_cluster.rds"))

if (run_cluster) {
  source("code/utils_euler_slurm.R")
  source("code/pipeline/run_cluster_pipeline.R")
}

### run local vs euler ----
if (run_cluster) {
  run_targets <- euler_targets
  euler_up <- !all(is.na(pingr::ping("euler.ethz.ch", count = 2))) 
  if (euler_up) { try(sync_from_euler(target_path = "pipelines")) }
} else {
  run_targets <- local_run_targets[c("EpiSewer")]
}

# pipeline ----
c(
  selection_targets, # need to be defined before running this script
  load_per_case_targets, # need to be defined before running this script
  data_targets,
  subsampling_targets,
  sensitivity_targets,
  modeling_targets,
  option_targets,
  EpiSewer_job_targets,
  run_targets
)
