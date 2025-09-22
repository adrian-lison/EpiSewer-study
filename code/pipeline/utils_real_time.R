create_real_time_pipelines <- function(
    selection_targets_name,
    pipeline_group_name = "real_time",
    base_targets_script_path = here::here("pipelines", "_real_time_base_targets.R"),
    invalidate = FALSE
    ) {
  selection_targets_path <- paste0(selection_targets_name,".R")
  source(here::here("pipelines", selection_targets_path))
  
  for (selection_to_run in names(all_selection_targets)) {
    code_to_run <- quote({
      library(targets)
      library(tarchetypes)
      library(crew)
      source(here::here("pipelines", selection_targets_path_replace))
      selection_targets <- all_selection_targets[[selection_to_run_replace]]
      # target-specific options
      tar_option_set(
        packages = c(
          "dplyr", "tidyr", "readr", "EpiSewer",
          "data.table", "stringr", "targets", "ssh"),
        workspace_on_error = TRUE, controller = crew_controller_local(workers = 4)
      )
      source(base_targets_script_path_replace)
      source(here::here("pipelines", "_real_time.R"))
    }
    )
    
    code_to_run <- do.call(
      substitute, 
      list(code_to_run, list(
        selection_to_run_replace = selection_to_run,
        selection_targets_path_replace = selection_targets_path,
        base_targets_script_path_replace = base_targets_script_path
      ))
    )
    
    pipeline_full_name <- paste0("_", pipeline_group_name, "_", selection_to_run)
    
    tar_helper_raw(path = here::here("pipelines", paste0(pipeline_full_name,".R")), code = code_to_run)
    
    setup_pipeline(pipeline_full_name, invalidate = invalidate)
  }
}

load_EpiSewer_results <- function(pipelines) {
  return(do.call(c, lapply(pipelines, function(pipeline) {
    setup_pipeline(pipeline)
    job_EpiSewer_result <- tar_read(job_EpiSewer_result)
    names(job_EpiSewer_result) <- paste0(pipeline, "_", names(job_EpiSewer_result))
    return(job_EpiSewer_result)
  })))
}

get_data_PCR_agg_select <- function(pipelines) {
  return(do.call(c, lapply(pipelines, function(pipeline) {
    suppressMessages(setup_pipeline(pipeline))
    data_PCR_agg_select <- tar_read(data_PCR_agg_select)
    names(data_PCR_agg_select) <- paste0(pipeline, "_", names(data_PCR_agg_select))
    return(data_PCR_agg_select)
  })))
}

get_data_flow_select <- function(pipelines) {
  return(do.call(c, lapply(pipelines, function(pipeline) {
    suppressMessages(setup_pipeline(pipeline))
    data_flow_select <- tar_read(data_flow_select)
    names(data_flow_select) <- paste0(pipeline, "_", names(data_flow_select))
    return(data_flow_select)
  })))
}

get_R_real_time_list <- function(results_select_list, baseline_select_list, intervals_eval = c(0.8,0.9,0.95), intervals_baseline = seq(0.01, 1, 0.01)) {
  R_base_list <- mapply(function(baseline_select) {
    job_EpiSewer_result[[baseline_select$i[1]]]$summary$R[
      seeding == FALSE, .SD, .SDcols = c(
        "date", "median",
        paste0("lower_",intervals_baseline),
        paste0("upper_",intervals_baseline)
        )
      ] |> 
      format_interval_quantile(keep_cols = c("date"), values_to = "value")
  }, baseline_select = baseline_select_list, SIMPLIFY = FALSE)
  
  R_real_time_list <- mapply(function(results_select) {
    rbindlist(lapply(job_EpiSewer_result[results_select$i], function(x) {
      estimation_date = x$summary$R[type == "estimate", max(date)]
      
      df <- x$summary$R[
        seeding == FALSE, .SD, .SDcols = c(
          "date", "median",
          paste0("lower_",intervals_eval),
          paste0("upper_",intervals_eval)
          )
        ] |> 
        format_interval_quantile(
          keep_cols = c("date"), values_to = "real_time_value"
          )
      
      df[, estimation_date := estimation_date]
      df[, h := date - estimation_date]
    }))}, results_select = results_select_list, SIMPLIFY = FALSE)
  
  R_real_time_list <- lapply(1:length(baseline_select_list), function(i) {
    setorderv(R_base_list[[i]], cols = c("date", "quantile"))
    R_real_time <- merge(R_real_time_list[[i]], R_base_list[[i]][, list(quantiles = list(quantile), values = list(value)), by = "date"], by = "date")
    R_real_time <- unique(R_real_time, by = c("date", "estimation_date", "h", "interval", "quantile"))
    R_real_time[, highest_below := mapply(function(rtv, qntls, vl) {
      if (all(vl <= rtv)) { 1 } else if (vl[1] > rtv) { 0 } else {
        qntls[which(vl > rtv)[1]-1]
      }
    }, rtv = real_time_value, qntls = quantiles, vl = values)]
    
    R_real_time[, lowest_above := mapply(function(rtv, qntls, vl) {
      if (all(vl >= rtv)) { 0 } else if (vl[length(vl)] < rtv) { 1 } else {
        qntls[rev(which(vl < rtv))[1]+1]
      }
    }, rtv = real_time_value, qntls = quantiles, vl = values)]
    R_real_time[, outside := ifelse(upper, 1-highest_below, lowest_above)]
    R_real_time[, quantiles := NULL]
    R_real_time[, values := NULL]
    return(R_real_time)
  })
  return(R_real_time_list)
}

get_R_median_real_time_list <- function(results_select_list, baseline_select_list) {

  R_real_time_list <-  mapply(function(baseline_select, results_select) {
    rbindlist(lapply(job_EpiSewer_result[results_select$i], function(x) {
      if (is.null(x$summary)) {
        warning(paste("Empty summary in", x$job$selection$wwtp, x$job$selection$target))
        return(data.table())
      }
      
      baseline_median <- job_EpiSewer_result[[baseline_select$i]]$summary$R[
        seeding == FALSE, .SD, .SDcols = c( "date", "median")
      ]
      
      estimation_date = x$summary$R[type == "estimate", max(date)]
      
      lower_qs <- merge(x$summary$R[
        seeding == FALSE, .SD, .SDcols = patterns("(date|lower_)")
      ], baseline_median, by = "date")
      lower_cols <- names(lower_qs[, .SD, .SDcols = patterns("lower_")])
      lower_qs[, (lower_cols) := lapply(.SD, function(x) x <= median), .SDcols = lower_cols]
      lower_qs[, lower := c("1",stringr::str_remove(lower_cols, "lower_"))[1+rowSums(.SD)], .SDcols = lower_cols]
      
      upper_qs <- merge(x$summary$R[
        seeding == FALSE, .SD, .SDcols = patterns("(date|upper_)")
      ], baseline_median, by = "date")
      upper_cols <- names(upper_qs[, .SD, .SDcols = patterns("upper_")])
      upper_qs[, (upper_cols) := lapply(.SD, function(x) x >= median), .SDcols = upper_cols]
      upper_qs[, upper := c("1",rev(stringr::str_remove(upper_cols, "upper_")))[1+rowSums(.SD)], .SDcols = upper_cols]
      
      smallest_interval <- merge(lower_qs[, c("date", "lower")], upper_qs[, c("date", "upper")], by = "date")
      smallest_interval[, within := pmax(as.numeric(lower), as.numeric(upper))]
      
      smallest_interval[, lower := NULL]
      smallest_interval[, upper := NULL]
      smallest_interval[, estimation_date := estimation_date]
      smallest_interval[, h := date - estimation_date]
      return(smallest_interval)
    }))}, baseline_select = baseline_select_list, results_select = results_select_list, SIMPLIFY = FALSE)
  
  return(R_real_time_list)
}

get_R_median_error_real_time_list <- function(results_select_list, baseline_select_list) {
  
  R_real_time_list <-  mapply(function(baseline_select, results_select) {
    rbindlist(lapply(job_EpiSewer_result[results_select$i], function(x) {
      if (is.null(x$summary)) {
        warning(paste("Empty summary in", x$job$selection$wwtp, x$job$selection$target))
        return(data.table())
      }
      
      baseline_median <- job_EpiSewer_result[[baseline_select$i]]$summary$R[
        seeding == FALSE, .SD, .SDcols = c( "date", "median")
      ]
      setnames(baseline_median, "median", "median_retrospective")
      
      estimation_date = x$summary$R[type == "estimate", max(date)]
      
      real_time_median <- merge(x$summary$R[
        seeding == FALSE, .SD, .SDcols = patterns("(date|median)")
      ], baseline_median, by = "date")
      
      real_time_median[, estimation_date := estimation_date]
      real_time_median[, h := date - estimation_date]
      real_time_median[, median_error := median - median_retrospective]
      real_time_median[, median := NULL]
      real_time_median[, median_retrospective := NULL]
      return(real_time_median)
    }))}, baseline_select = baseline_select_list, results_select = results_select_list, SIMPLIFY = FALSE)
  
  return(R_real_time_list)
}

get_forecasts_list <- function(results_select_list, baseline_select_list, ground_truth_list) {
  lapply(1:length(results_select_list), function(i) {
    results_select <- results_select_list[[i]]
    baseline_select <- baseline_select_list[[i]]
    ground_truth <- ground_truth_list[[i]]
    all_forecasts <- rbindlist(lapply(job_EpiSewer_result[results_select$i], function(res) {
      if (is.null(res$summary)) {
        warning(paste("Empty summary in", res$job$selection$wwtp, res$job$selection$target))
        return(data.table())
      }
      
      estimation_date = res$summary$normalized_concentration[type == "estimate", max(date)]
      
      conc_forecast <- res$summary$normalized_concentration[type == "forecast"]
      setorderv(conc_forecast, cols = "date")
      
      conc_forecast <- conc_forecast[,.SD, .SDcols = !c("mean", "type")] |> 
        format_interval_quantile(
          keep_cols = c("date"), values_to = "predicted"
        )
      
      conc_forecast <- conc_forecast[!(interval == 0 & !upper),]
      
      conc_forecast <- merge(conc_forecast, ground_truth[, c("date", "conc_normalized")], by = "date", all = FALSE)
      conc_forecast[, model := "EpiSewer"]
      conc_forecast[, wwtp := baseline_select$wwtp]
      conc_forecast[, target := baseline_select$target]
      conc_forecast[, estimation_date := estimation_date]
      conc_forecast[, h := date - estimation_date]
      
      return(conc_forecast)
    }))
    
    all_forecasts <- as_forecast_quantile(
      all_forecasts[,.SD, .SDcols = !c("upper")],
      forecast_unit = c("wwtp", "target", "date", "estimation_date", "h"),,
      observed = "conc_normalized",
      predicted = "predicted",
      quantile_level = "quantile"
    )
    return(all_forecasts)
  })
}

get_baseline_list <- function(baseline_select_list, ground_truth_list, all_forecasts_list) {
  lapply(1:length(baseline_select_list), function(i) {
    baseline_select <- baseline_select_list[[i]]
    ground_truth <- ground_truth_list[[i]]
    conc_baseline <- job_EpiSewer_result[[baseline_select$i[1]]]$summary$normalized_concentration[type == "estimate"]
    setorderv(conc_baseline, cols = "date")
    conc_baseline <- conc_baseline[, .SD, .SDcols = !c("mean", "type")] |> 
      format_interval_quantile(
        keep_cols = c("date"), values_to = "predicted"
      )
    conc_baseline <- conc_baseline[!(interval == 0 & !upper),]
    
    all_baseline <- rbindlist(lapply(unique(all_forecasts_list[[i]]$estimation_date), function(estimation_date) {
      conc_baseline <- merge(
        conc_baseline[date > estimation_date & date <= estimation_date+28, ],
        ground_truth[, c("date", "conc_normalized")],
        by = "date", all = FALSE
      )
      conc_baseline[, model := "EpiSewer"]
      conc_baseline[, wwtp := baseline_select$wwtp]
      conc_baseline[, target := baseline_select$target]
      conc_baseline[, estimation_date := estimation_date]
      conc_baseline[, h := date - estimation_date]
      return(conc_baseline)
    }))
    
    all_baseline <- as_forecast_quantile(
      all_baseline[,.SD, .SDcols = !c("upper")],
      forecast_unit = c("wwtp", "target", "date", "estimation_date", "h"),
      observed = "conc_normalized",
      predicted = "predicted",
      quantile_level = "quantile"
    )
    return(all_baseline)
  })
}
