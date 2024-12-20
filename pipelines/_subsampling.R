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
    c("ARA Werdhoelzli")
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

## shedding info
get_shedding_dist_info <- get_shedding_dist_info_estimate

## sensitivity analyses of assumptions ----
sensitivity_targets <- list(
  tar_target(
    sensitivity_generation,
    list(
      list(shift_mean = 0, shift_sd = 0)
    )
  ),
  tar_target(
    sensitivity_incubation,
    list(
      list(shift_mean = 0, shift_sd = 0)
    )
  ),
  tar_target(
    sensitivity_shedding,
    list(
      list(shift_mean = 0, shift_cv = 0)
    )
  ),
  tar_target(
    sensitivity_load_per_case,
    list(
      list(multiplier = 1)
    ),
  )
)

## subsampling ----
source(here::here("pipelines", "_subsampling_weekdays_groups.R"))
subsampling_targets <- subsampling_targets_group_werdhoelzli

## modeling modules ----
modeling_targets <- list(
  tar_target(
    module_measurements,
    list(
      model_measurements(
        concentrations = concentrations_observe(concentration_col = "gc_per_mlww"),
        noise = noise_estimate_dPCR(
          total_partitions_prior_mu = 20000,
          total_partitions_prior_sigma = 5000,
          partition_variation_prior_mu = 0,
          partition_variation_prior_sigma = 0.05,
          volume_scaled_prior_mu = 1.73e-5,
          volume_scaled_prior_sigma = 0.05e-5,
          prePCR_noise_type = "log-normal"
        ),
        LOD = LOD_estimate_dPCR()
      )
    )
  ),
  tar_target(
    module_sampling,
    list(
      model_sampling(
        sample_effects = sample_effects_none(),
        outliers = outliers_estimate(
          gev_prior_mu = 0, gev_prior_sigma = 2e-8, gev_prior_xi = 4
        )
      )
    )
  ),
  tar_target(
    module_sewage,
    list(
      model_sewage(
        flows = flows_observe(),
        residence_dist = residence_dist_assume(residence_dist = c(1))
      )
    )
  ),
  tar_target(
    module_shedding,
    list(
      model_shedding(
        incubation_dist = incubation_dist_assume(),
        shedding_dist = shedding_dist_estimate(),
        load_per_case = load_per_case_assume(),
        load_variation = load_variation_estimate(
          cv_prior_mu = 1,
          cv_prior_sigma = 0
        )
      )
    )
  ),
  tar_target(
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
  ),
  tar_target(
    module_forecast,
    list(
      model_forecast(
        horizon = horizon_none()
      )
    )
  ),
  tar_target(
    data_handling_opts,
    list(list(aggregate_data = TRUE, remove_outliers = FALSE))
  )
)

## sampling options ----
### sampler ----
option_targets <- list(
  tar_target(
    fit_opts,
    list(
      set_fit_opts(
        sampler = sampler_stan_mcmc(
          seed = 42,
          chains = 4,
          iter_warmup = 1000,
          iter_sampling = 1000
        )
      )
    )
  ),
  tar_target(
    results_opts,
    list(
      set_results_opts(
        fitted = FALSE
      )
    )
  )
)

### run local vs euler ----
if (run_cluster) {
  run_targets <- c(euler_targets, local_run_targets[c("estimateR")])
  euler_up <- !all(is.na(pingr::ping("euler.ethz.ch", count = 2))) 
  if (euler_up) { try(sync_from_euler(target_path = "pipelines")) }
} else {
  run_targets <- local_run_targets[c("EpiSewer", "estimateR")]
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
  estimateR_job_targets,
  run_targets
)
