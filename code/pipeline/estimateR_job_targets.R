## estimateR job ----

source(here::here("code", "ww_estimateR_functions.R"))

estimateR_job_targets <- list(
  tar_target(
    fit_opts_estimateR,
    list(
      list(
        estimateR_seed = 0,
        estimation_window = 3,
        minimum_cumul_incidence = 0,
        n_bootstrap_reps = 50,
        data_points_incl = 42
      )
    )
  ),
  tar_target(
    job_estimateR,
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
      
      shedding_dist <- get_shedding_dist(
        target = data_selection_EpiSewer$target_select,
        shift_mean = sensitivity_shedding[[1]]$shift_mean,
        shift_cv = sensitivity_shedding[[1]]$shift_cv
      )
      
      load_per_case <- get_load_per_case(
        wwtp_select = data_selection_EpiSewer$wwtp_select,
        target_select = data_selection_EpiSewer$target_select,
        multiplier = sensitivity_load_per_case[[1]]$multiplier,
        load_per_case_data
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
          subsampling = subsampling
        )
      )
      
      if (data_handling_opts[[1]]$aggregate_data) {
        selected_measurements <- data_PCR_agg_select |> 
          dplyr::filter(subsampling[[1]]$subsampling_f(date))
      } else {
        selected_measurements <- data_PCR_select |> 
          dplyr::filter(subsampling[[1]]$subsampling_f(date))
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
      
      return(tryCatch(
        {
          ww_res <- list(
            job = estimateR_job(
              measurements_df = selected_measurements,
              flow_df = data_flow_select,
              load_per_case = load_per_case,
              generation_dist = generation_dist,
              incubation_dist = incubation_dist,
              shedding_dist = shedding_dist,
              fit_opts = fit_opts_estimateR[[1]]
            )
          )
          ww_res$job$job_dir <- file.path(basename(tar_path_store()), "results")
          ww_res$job$job_name <- tar_name()
          ww_res$selection <- selection
          ww_res$inputs <- inputs
          return(ww_res)
        },
        error = function(e) {
          return(list(
            error = e,
            job = list(selection = selection),
            inputs = c(inputs, list(
              fit_opts = fit_opts_estimateR
            ))
          ))
        }))
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
      # subsampling
      subsampling,
      # options
      fit_opts,
      data_handling_opts
    ),
    iteration = "list"
  ),
  tar_target(
    jobs_estimateR_valid,
    job_estimateR[sapply(job_estimateR, function(x) !"error" %in% names(x))],
  ),
  tar_target(
    jobs_estimateR_invalid,
    job_estimateR[sapply(job_estimateR, function(x) {
      "error" %in% names(x)
    })],
  ),
  ## estimateR job submission ----
  tar_target(
    job_estimateR_resultpath,
    {
      path <- file.path(
        tar_path_store(), "results", 
        paste0(jobs_estimateR_valid[[1]]$job$job_name, "_1_result.rds")
      )
      if (!file.exists(path)) {
        saveRDS(list(), path)
      }
      return(path)
    },
    pattern = map(jobs_estimateR_valid),
    iteration = "list",
    format = "file"
  ),
  tar_target(
    job_estimateR_result,
    readRDS(job_estimateR_resultpath),
    pattern = map(job_estimateR_resultpath),
    iteration = "list"
  ),
  tar_target(
    job_estimateR_Failed,
    ("error" %in% names(job_estimateR_result)),
    pattern = map(job_estimateR_result),
    iteration = "vector"
  ),
  tar_target(
    job_estimateR_UpToDate,
    {
      if (job_estimateR_Failed) {
        FALSE
      } else {
        identical(
          jobs_estimateR_valid[[1]]$job$checksums,
          job_estimateR_result$job$checksums
        )
      }
    },
    pattern = map(
      jobs_estimateR_valid,
      job_estimateR_result,
      job_estimateR_Failed
    ),
    iteration = "vector"
  )
)
