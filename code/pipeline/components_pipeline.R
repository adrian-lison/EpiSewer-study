# functions for subsampling
subsample_wdays_f <- function(wdays_list) {
  f <- function(dates) {
    wdays_df <- bind_rows(lapply(wdays_list, function(wdays) {
      data.frame(wday = wdays, wday_item = paste(wdays, collapse = "|"), wday_index = 1:length(wdays))
    }))
    dates_selection <- data.frame(date = dates) |> 
      mutate(
        wday = lubridate::wday(date, label = T, abbr = F),
        week = lubridate::isoweek(date)
      ) |> 
      inner_join(wdays_df, by = "wday") |> 
      group_by(week, wday_item) |> 
      slice_min(wday_index)
    return(dates %in% dates_selection$date)
  }
  return(f)
}

week_even <- function(dates) {
  ((as.numeric(dates-as.Date("1999-01-04")) %/% 7) %% 2 == 0)
}

week_odd <- function(dates) {
  ((as.numeric(dates-as.Date("1999-01-04")) %/% 7) %% 2 == 1)
}

# Data targets ----
data_targets <- list(
  ## overall selection ----
  data_selection_EpiSewer_all = tar_target(
    data_selection_EpiSewer_all,
    {
      list(
        wwtp_select = wwtp_select,
        assay_select = assay_select,
        target_select = target_select,
        date_select = date_select,
        subsampling = subsampling
      )
    },
    pattern = cross(wwtp_select, assay_select, date_select, target_select, subsampling),
    iteration = "list"
  ),
  data_selection_EpiSewer = tar_target(
    data_selection_EpiSewer,
    data_selection_EpiSewer_all[!data_PCR_duplicated],
    iteration = "list"
  ),
  ## dPCR measurements ----
  file_ww_data = tar_target(
    file_ww_data,
    here::here("data", "ww_data", "dPCR_time_series_until_2025-05-31.csv"),
    format = "file"
  ),
  ww_data = tar_target(
    ww_data,
    readr::read_csv(
      file_ww_data,
      skip = 1,
      col_names = c(
        "wwtp", "date", "target", "dilution",
        "assay", "gc_per_lww", "total_droplets", "replicate_id", 
        "flow", "wwtp_id", "population"
      ),
      col_types = readr::cols(
        date = readr::col_date(format = "%Y-%m-%dT%H:%M:%SZ"),
        gc_per_lww = readr::col_double(),
        flow = readr::col_double()
      ),
      show_col_types = F
    )
  ),
  outlier_df_file = tar_target(
    outlier_df_file,
    file.path(here::here("data", "ww_data", "outliers_manual.csv")),
    format = "file"
  ),
  outlier_df = tar_target(
    outlier_df,
    readr::read_csv(outlier_df_file, show_col_types = FALSE)
  ),
  data_PCR_select_all = tar_target(
    data_PCR_select_all,
    {
    measurements <- ww_data |> dplyr::filter(
      wwtp == wwtp_select,
      assay == assay_select,
      target == target_select,
      date >= date_select[[1]][["from"]], date <= date_select[[1]][["to"]],
      subsampling[[1]]$subsampling_f(date)
    )
    if (nrow(measurements) == 0) {
      warning(paste("Selection", wwtp_select, assay_select, target_select, "has no data."))
      data.table::setDT(measurements)
      return(measurements)
    }
    measurements <- measurements |> 
      dplyr::mutate(gc_per_mlww = gc_per_lww / 1000) |> 
      dplyr::select(target, wwtp, date, gc_per_mlww, dilution, total_droplets) |> 
      dplyr::group_by(target, wwtp, date) |>
      dplyr::mutate(replicate_id = 1:dplyr::n())
    data.table::setDT(measurements)
    measurements[, is_outlier := FALSE]
    measurements <- mark_outlier_manual(
      measurements,
      outlier_df,
      target_col = "target",
      wwtp_col = "wwtp",
      date_col = "date"
    )
    data.table::setDT(measurements)
    measurements[is.na(dilution) & !is.na(gc_per_mlww), dilution := median(measurements$dilution, na.rm = T)]
    measurements[is.na(total_droplets) & !is.na(gc_per_mlww), total_droplets := median(measurements$total_droplets, na.rm = T)]
    return(measurements)
    },
    pattern = cross(wwtp_select, assay_select, date_select, target_select, subsampling),
    iteration = "list"
  ),
  data_PCR_duplicated = tar_target(
    data_PCR_duplicated,
    {
      identifier_df <- bind_rows(lapply(data_PCR_select_all, function(x) {if(nrow(x)==0){data.frame(target=NA)}else{sl <- x |> slice_max(date) |> slice_tail()}}))
      identifier_df$subsampling_id <- sapply(data_selection_EpiSewer_all, function(x) paste(x$subsampling[[1]]$type, x$subsampling[[1]]$subtype, sep = "_"))
      duplicated(identifier_df) | is.na(identifier_df$target)
    }
  ),
  data_PCR_select = tar_target(
    data_PCR_select,
    data_PCR_select_all[!data_PCR_duplicated],
    iteration = "list"
  ),
  data_PCR_agg_select = tar_target(
    data_PCR_agg_select,
    {
      key_cols <- c(
        "target",
        "wwtp",
        "date"
      )
      if (nrow(data_PCR_select)==0){
        return(data.table())
      } else {
        aggregate_replicates_mean(data_PCR_select, key_cols)
      }
    },
    pattern = map(data_PCR_select),
    iteration = "list"
  ),
  data_PCR_plot = tar_target(
    data_PCR_plot,
    EpiSewer::plot_concentration(
      measurements = data_PCR_agg_select, concentration_col = "gc_per_mlww",
      mark_outliers = TRUE, outlier_col = "is_outlier"
    ),
    pattern = map(data_PCR_agg_select),
    iteration = "list"
  ),
  ## flow ----
  data_flow_select_all = tar_target(
    data_flow_select_all,
    ww_data |>
      dplyr::filter(
        wwtp == wwtp_select,
        date >= date_select[[1]][["from"]],
        date <= date_select[[1]][["to"]] + 28 # this allows for up to 4 weeks forecast
      ) |> 
      dplyr::group_by(wwtp, date) |> 
      dplyr::summarize(flow = dplyr::first(flow), .groups = "drop") |> 
      dplyr::mutate(flow = flow * 1000 * 1000) |> 
      dplyr::filter(flow > 0) |> # impute zero flows 
      fill_missing_flow(
        earliest_date = date_select[[1]][["from"]],
        latest_date = date_select[[1]][["to"]] + 28
      ),
    pattern = cross(wwtp_select, assay_select, date_select, target_select, subsampling),
    iteration = "list"
  ),
  data_flow_select = tar_target(
   data_flow_select,
   data_flow_select_all[!data_PCR_duplicated],
   iteration = "list"
  )
)

## EpiSewer_job_targets ----
source("code/pipeline/EpiSewer_job_targets.R")

## estimateR_job_targets ----
if (file.exists("code/pipeline/estimateR_job_targets.R")) {
  source("code/pipeline/estimateR_job_targets.R")
}
