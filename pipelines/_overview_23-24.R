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
    "data.table", "stringr", "targets"),
  workspace_on_error = TRUE#, controller = crew_controller_local(workers = 4)
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
    c("ARA Werdhoelzli", "STEP Aire", "STEP Vidy", "CDA Lugano", 
      "ARA Basel/Prorheno", "ARA Chur", "ARA Buholz", 
      "ARA Altenrhein", "ARA Sensetal", "ARA Region Bern",
      "STEP Porrentruy", "STEP Neuchatel", "ARA Zuchwil", "ARA Schwyz")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("SARS-N2", "IAV-M", "RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2023-08-01")
      to = as.Date("2024-07-31")
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  ),
  tar_target(
    load_per_case_file,
    here::here("data", "assumptions", "load_per_case_initial_2023.csv")
  ),
  tar_target(
    load_per_case_data,
    readr::read_csv(load_per_case_file, show_col_types = FALSE)
  )
)

source(here::here("pipelines", "_real_time_base_targets.R"))

modeling_targets$infections_target = tar_target(
  module_infections,
  {
    return(list(
      R_splines = model_infections(
        generation_dist = generation_dist_assume(),
        R = R_estimate_splines(
          knot_distance_global = 4*7,
          knot_distance_local = 7,
          R_start_prior_mu = 1,
          R_start_prior_sigma = 0.8,
          R_sd_local_prior_sd = 0.05,
          R_sd_global_prior_shape = 1,
          R_sd_global_prior_rate = 1e-2,
          R_sd_global_change_distance = 4*7
        ),
        seeding = seeding_estimate_rw(extend = FALSE),
        infection_noise =  infection_noise_estimate(
          overdispersion = FALSE
        )
      )
    ))
  }
)

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
