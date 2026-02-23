source("data/assumptions/epi_params_EpiSewer-study.R")

## shedding info
get_shedding_dist_info <- get_shedding_dist_info_estimate

## sensitivity analyses of assumptions ----
sensitivity_targets <- list(
  sensitivity_generation = tar_target(
    sensitivity_generation,
    list(
      list(shift_mean = 0, shift_sd = 0)
    )
  ),
  sensitivity_incubation = tar_target(
    sensitivity_incubation,
    list(
      list(shift_mean = 0, shift_sd = 0)
    )
  ),
  sensitivity_shedding = tar_target(
    sensitivity_shedding,
    list(
      list(shift_mean = 0, shift_cv = 0)
    )
  ),
  sensitivity_load_per_case = tar_target(
    sensitivity_load_per_case,
    list(
      list(multiplier = 1)
    ),
  )
)

## subsampling ----
subsampling_targets <- list(
  tar_target(
    subsampling,
    list(
      list(
        type = "Every day",
        subtype = "Every day",
        subsampling_f = function(dates) {rep(TRUE,length(dates))}
      )
    )
  )
)

## modeling modules ----
modeling_targets <- list(
  measurements_target = tar_target(
    module_measurements,
    list(
      model_measurements(
        concentrations = concentrations_observe(
          concentration_col = "gc_per_mlww",
          n_averaged_col = "n_reps"
        ),
        noise = noise_estimate_dPCR_params(
          max_partitions_prior_lower = 20000,
          max_partitions_prior_upper = 40000,
          partition_loss_mean_prior_lower = 0.05,
          partition_loss_mean_prior_upper = 0.3,
          partition_loss_variation_prior_lower = 0.5,
          partition_loss_variation_prior_upper = 2,
          partition_loss_max = 0.5,
          volume_scaled_prior_lower = 1e-6,
          volume_scaled_prior_upper = 1e-4,
          prePCR_noise_type = "log-normal"
        ),
        LOD = LOD_estimate_dPCR()
      )
    )
  ),
  sampling_target = tar_target(
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
  sewage_target = tar_target(
    module_sewage,
    list(
      model_sewage(
        flows = flows_observe(),
        residence_dist = residence_dist_assume(residence_dist = c(1))
      )
    )
  ),
  shedding_target = tar_target(
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
  infections_target = tar_target(
    module_infections,
    {
      return(list(
        R_gp = model_infections(
          generation_dist = generation_dist_assume(),
          R = R_estimate_gp(
            length_scale_prior_mu = 7*3,
            length_scale_prior_sigma = 7/2,
            magnitude_prior_mu = 0.125,
            magnitude_prior_sigma = 0.025,
            long_length_scale_prior_mu = 7*4*3,
            long_length_scale_prior_sigma = 7,
            long_magnitude_prior_mu = 0.25,
            long_magnitude_prior_sigma = 0.05,
            matern_nu = 3/2
          ),
          seeding = seeding_estimate_growth(),
          infection_noise =  infection_noise_estimate(
            overdispersion = FALSE
          )
        )
      ))
    }
  ),
  forecast_target = tar_target(
    module_forecast,
    list(
      model_forecast(
        horizon = horizon_assume(horizon = 14),
        damping = damping_none()
      )
    )
  ),
  data_handling_opts_target = tar_target(
    data_handling_opts,
    list(
      list(aggregate_data = TRUE, remove_outliers = FALSE)
    )
  )
)

## sampling options ----
### sampler ----
option_targets <- list(
  fit_opts_target = tar_target(
    fit_opts,
    list(
      set_fit_opts(
        sampler = sampler_stan_mcmc(
          seed = 42,
          chains = 4,
          iter_warmup = 1000,
          iter_sampling = 2500,
          init_pathfinder = TRUE
          )
      )
    )
  ),
  results_opts_target = tar_target(
    results_opts,
    list(
      set_results_opts(
        fitted = FALSE,
        summary_intervals = seq(0.01, 0.99, 0.01),
        samples_ndraws = 10
      )
    )
  ),
  tar_target(
    job_EpiSewer_ignore_seed,
    TRUE
  )
)
