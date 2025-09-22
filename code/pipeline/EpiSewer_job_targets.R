EpiSewer_job_targets <- list(
  tar_target(
    job_EpiSewer,
    {
      generation_dist <- get_generation_dist(
        target = data_selection_EpiSewer$target_select,
        shift_mean = sensitivity_generation[[1]]$shift_mean,
        shift_sd = sensitivity_generation[[1]]$shift_sd
      )
      
      incubation_dist <- get_incubation_dist(
        target = data_selection_EpiSewer$target_select,
        shift_mean = sensitivity_incubation[[1]]$shift_mean,
        shift_sd = sensitivity_incubation[[1]]$shift_sd
      )
      
      shedding_dist_info <- get_shedding_dist_info(
        target = data_selection_EpiSewer$target_select,
        shift_mean = sensitivity_shedding[[1]]$shift_mean,
        shift_cv = sensitivity_shedding[[1]]$shift_cv
      )
      
      if (shedding_dist_info$shedding_reference == "infection") {
        incubation_dist <- NULL
      }
      if (shedding_dist_info$estimate) {
        shedding_dist <- NULL
        shedding_dist_mean_prior_mean <- shedding_dist_info$shedding_dist_mean_prior_mean
        shedding_dist_mean_prior_sd <- shedding_dist_info$shedding_dist_mean_prior_sd
        shedding_dist_cv_prior_mean <- shedding_dist_info$shedding_dist_cv_prior_mean
        shedding_dist_cv_prior_sd <- shedding_dist_info$shedding_dist_cv_prior_sd
        shedding_dist_type <- shedding_dist_info$shedding_dist_type
      } else {
        shedding_dist <- shedding_dist_info$shedding_dist
        shedding_dist_mean_prior_mean <- NULL
        shedding_dist_mean_prior_sd <- NULL
        shedding_dist_cv_prior_mean <- NULL
        shedding_dist_cv_prior_sd <- NULL
        shedding_dist_type <- NULL
      }
      
      load_per_case <- get_load_per_case(
        wwtp_select = data_selection_EpiSewer$wwtp_select,
        target_select = data_selection_EpiSewer$target_select,
        multiplier = sensitivity_load_per_case[[1]]$multiplier,
        load_per_case_data = load_per_case_data
      )
      
      selection <- c(
        data_selection_EpiSewer,
        list(
          generation_dist = generation_dist,
          sensitivity_generation = sensitivity_generation,
          incubation_dist = incubation_dist,
          sensitivity_incubation = sensitivity_incubation,
          shedding_dist = shedding_dist,
          sensitivity_shedding = sensitivity_shedding,
          load_per_case = load_per_case,
          sensitivity_load_per_case = sensitivity_load_per_case,
          module_measurements = names(module_measurements[1]),
          module_sampling = names(module_sampling[1]),
          module_sewage = names(module_sewage[1]),
          module_shedding = names(module_shedding[1]),
          module_infections = names(module_infections[1]),
          module_forecast = names(module_forecast[1])
        )
      )
      
      if (data_handling_opts[[1]]$aggregate_data) {
        selected_measurements <- data_PCR_agg_select
      } else {
        selected_measurements <- data_PCR_select
      }
      
      if (data_handling_opts[[1]]$remove_outliers) {
        selected_measurements <- selected_measurements |> 
          dplyr::filter(!is_outlier)
      }
      
      inputs <- list(
        PCR_select = data_PCR_select,
        PCR_agg_select = data_PCR_agg_select,
        flow_select = data_flow_select,
        selected_measurements = selected_measurements
      )
      
      ww_assumptions <- EpiSewer::sewer_assumptions(
        generation_dist = generation_dist,
        incubation_dist = incubation_dist,
        shedding_dist = shedding_dist,
        shedding_reference = shedding_dist_info$shedding_reference,
        load_per_case = load_per_case,
        shedding_dist_mean_prior_mean = shedding_dist_mean_prior_mean,
        shedding_dist_mean_prior_sd = shedding_dist_mean_prior_sd,
        shedding_dist_cv_prior_mean = shedding_dist_cv_prior_mean,
        shedding_dist_cv_prior_sd = shedding_dist_cv_prior_sd,
        shedding_dist_type = shedding_dist_type
      )
      
      return(tryCatch(
        {
          ww_res <- EpiSewer::EpiSewer(
            data = EpiSewer::sewer_data(
              measurements = selected_measurements,
              flows = data_flow_select
            ),
            assumptions = ww_assumptions,
            measurements = module_measurements[[1]],
            sampling = module_sampling[[1]],
            sewage = module_sewage[[1]],
            shedding = module_shedding[[1]],
            infections = module_infections[[1]],
            forecast = module_forecast[[1]],
            fit_opts = fit_opts[[1]],
            results_opts = results_opts[[1]],
            run_fit = FALSE
          )
          ww_res$job$job_dir <- file.path(basename(tar_path_store()), "results")
          ww_res$job$job_target_name <- tar_name()
          if (exists("job_EpiSewer_ignore_seed") && job_EpiSewer_ignore_seed) {
            seed_tmp <- ww_res$job$fit_opts$sampler$seed
            ww_res$job$fit_opts$sampler$seed <- 0
          }
          ww_res$job$job_name <- paste0(basename(tar_path_store()),"_EpiSewer_", digest::digest(
            EpiSewer::get_checksums(ww_res$job), algo = "md5"
          ))
          if (exists("job_EpiSewer_ignore_seed") && job_EpiSewer_ignore_seed) {
            ww_res$job$fit_opts$sampler$seed <- seed_tmp
          }
          ww_res$job$selection <- selection
          ww_res$inputs <- inputs
          return(ww_res)
        },
        error = function(e) {
          return(list(
            error = e,
            job = list(selection = selection),
            inputs = c(inputs, list(
              module_measurements = module_measurements,
              module_sampling = module_sampling,
              module_sewage = module_sewage,
              module_shedding = module_shedding,
              module_infections = module_infections,
              module_forecast = module_forecast,
              fit_opts = fit_opts,
              results_opts = results_opts
            ))
          ))
        }
      ))
    },
    pattern = cross(
      # data
      map(
        data_PCR_select,
        data_PCR_agg_select,
        data_flow_select,
        data_selection_EpiSewer
      ),
      # sensitivity analyses
      sensitivity_generation,
      sensitivity_incubation,
      sensitivity_shedding,
      sensitivity_load_per_case,
      # modules
      module_measurements,
      module_sampling,
      module_sewage,
      module_shedding,
      module_infections,
      module_forecast,
      # options
      fit_opts,
      results_opts,
      data_handling_opts
    ),
    iteration = "list"
  ),
  tar_target(
    jobs_EpiSewer_valid,
    job_EpiSewer[sapply(job_EpiSewer, function(x) !"error" %in% names(x))],
    deployment = "main"
  ),
  tar_target(
    jobs_EpiSewer_invalid,
    job_EpiSewer[sapply(job_EpiSewer, function(x) "error" %in% names(x))],
    deployment = "main"
  ),
  tar_target(
    job_EpiSewer_resultpath,
    target_job_resultpath(jobs_EpiSewer_valid[[1]]),
    pattern = map(jobs_EpiSewer_valid),
    iteration = "list",
    format = "file",
    deployment = "main"
  ),
  tar_target(
    job_EpiSewer_result,
    readRDS(job_EpiSewer_resultpath),
    pattern = map(job_EpiSewer_resultpath),
    iteration = "list"
  ),
  tar_target(
    job_EpiSewer_UpToDate,
    target_job_UpToDate(jobs_EpiSewer_valid[[1]]$job, job_EpiSewer_result),
    pattern = map(jobs_EpiSewer_valid, job_EpiSewer_result),
    iteration = "vector",
    deployment = "main"
  ),
  tar_target(
    job_EpiSewer_failed,
    job_EpiSewer_UpToDate && class(job_EpiSewer_result$summary) == "try-error",
    pattern = map(job_EpiSewer_UpToDate, job_EpiSewer_result),
    iteration = "vector",
    deployment = "main"
  ),
  tar_target(
    job_EpiSewer_state,
    target_job_state(job_EpiSewer_result),
    pattern = map(job_EpiSewer_result),
    iteration = "vector",
    deployment = "main"
  )
)
