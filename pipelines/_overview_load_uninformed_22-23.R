# Define custom functions and other global objects.
# This is where you write source(\"R/functions.R\")
# if you keep your functions in external scripts.
source("code/local_config.R")
source("code/utils_dists.R")

source("code/pipeline/utils_pipeline.R")
source("code/pipeline/functions_pipeline.R")
source("code/pipeline/components_pipeline.R")
source("data/assumptions/epi_params_EpiSewer-study.R")

source("code/pipeline/run_local_pipeline.R")

# target-specific options
tar_option_set(
  packages = c(
    "dplyr", "tidyr", "readr", "EpiSewer",
    "data.table", "stringr", "targets", "ssh"),
  workspace_on_error = TRUE, controller = crew_controller_local(workers = 4)
  )

# user settings
dry_run <- readRDS(file.path(tar_path_store(), "settings/dry_run.rds"))
run_cluster <- readRDS(file.path(tar_path_store(), "settings/run_cluster.rds"))

if (run_cluster) {
  source("code/utils_euler_slurm.R")
  source("code/pipeline/run_cluster_pipeline.R")
}

## selections ----
selection_targets <- list(
  tar_target(
    wwtp_select,
    c("ARA Werdhoelzli", "STEP Aire", "CDA Lugano",
      "ARA Chur", "ARA Altenrhein", "ARA Sensetal")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("SARS-N2", "IAV-M", "RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-08-01")
      to = as.Date("2023-07-31")
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  ),
  tar_target(
    load_per_case_file,
    here::here("data", "assumptions", "load_per_case_detect_pop_2022.csv")
  ),
  tar_target(
    load_per_case_data,
    readr::read_csv(load_per_case_file, show_col_types = FALSE)
  )
)

source(here::here("pipelines", "_real_time_base_targets.R"))

option_targets$results_opts_target <- tar_target(
  results_opts,
  list(
    set_results_opts(
      fitted = FALSE,
      summary_intervals = c(0.5, 0.95),
      samples_ndraws = 1000
    )
  )
)

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
  selection_targets,
  data_targets,
  subsampling_targets,
  sensitivity_targets,
  modeling_targets,
  option_targets,
  EpiSewer_job_targets,
  run_targets
)
