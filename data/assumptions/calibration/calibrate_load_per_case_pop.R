source("code/pipeline/functions_pipeline.R")

get_season <- function(date) {
  if (date >= as.Date("2020-08-01") & date < as.Date("2021-08-01")) {
    return("2020/2021")
  } else if (date >= as.Date("2021-08-01") & date < as.Date("2022-08-01")) {
    return("2021/2022")
  } else if (date >= as.Date("2022-08-01") & date < as.Date("2023-08-01")) {
    return("2022/2023")
  } else if (date >= as.Date("2023-08-01") & date < as.Date("2024-08-01")) {
    return("2023/2024")
  } else if (date >= as.Date("2024-08-01") & date < as.Date("2025-08-01")) {
    return("2024/2025")
  } else {
    return("other")
  }
}

aggregate_replicates_mean <- function(data_pcr, key_cols) {
  data.table::setDT(data_pcr)
  data_pcr <- data_pcr[
    , .(
      gc_per_mlww = mean(gc_per_mlww, na.rm = T),
      n_reps = .N,
      is_outlier = any(is_outlier, na.rm = T),
      dilution = mean(dilution, na.rm = T),
      total_droplets = mean(total_droplets, na.rm = T),
      flow = mean(flow, na.rm = T)
    ), by = key_cols
  ]
  data.table::setorderv(data_pcr, cols = key_cols)
  return(data_pcr)
}

# Compute load per case for each wwtp and target
ww_data <- readr::read_csv(
  here::here("data", "ww_data", "dPCR_time_series_until_2025-05-31.csv"),
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

outlier_df <- readr::read_csv(file.path(here::here("data", "ww_data", "outliers_manual.csv")), show_col_types = FALSE)

ww_data <- ww_data |> 
  mutate(is_outlier = FALSE) |> 
  mark_outlier_manual(
    outlier_df,
    target_col = "target",
    wwtp_col = "wwtp",
    date_col = "date"
  ) |> 
  mutate(
    gc_per_mlww = gc_per_lww / 1000,
    flow = flow * 1000 * 1000
  ) |> aggregate_replicates_mean(key_cols =  c("target", "wwtp", "date")) |> 
  mutate(
    load = gc_per_mlww * flow,
    season = sapply(date, get_season)
  )


# for each wwtp, target and season, get first date with load > 0
ww_data |> 
  group_by(wwtp, target, season) |> 
  filter(load > 0) |> 
  summarise(first_date = min(date), .groups = "drop") |> 
  mutate(first_date = as.Date(first_date))


count_detect_runs <- function(detect){
  sapply(1:length(detect), function(i) {
    if (all(detect[i:length(detect)])) {
      return(length(detect) - i + 1)
    } else {
      return(which.min(detect[i:length(detect)])[1] - 1)
    }
  })
}

ww_data_triple_detect <- ww_data |> 
  group_by(wwtp, target, season) |> 
  arrange(date) |> 
  mutate(detect = load > 0) |> 
  filter(!is.na(detect)) |> 
  mutate(
    detect_next_n = count_detect_runs(detect),
    avg_next_3 = zoo::rollmean(load, k = 3, fill = NA, align = "left")
  ) |> 
  filter(detect_next_n >= 3) |> 
  group_by(wwtp, target, season) |> 
  slice_min(date) |>
  select(target, wwtp, season, date, detect_next_n, avg_next_3)

# compute load per case by assuming that the average concentration of the first three consecutive non-detects corresponds to 0.01% of the population infected
wwtps <- readr::read_csv(
  here::here("data", "ww_data", "wwtp_info.csv"),
  show_col_types = FALSE
) %>%
  select(name, ara_id, population)

ww_data_triple_detect_loads <- ww_data_triple_detect |> 
  merge(wwtps |> select(name, population), by.x = "wwtp", by.y = "name") |>
  mutate(
    load_per_case = avg_next_3 / (population * 0.01/100)
  ) |> filter(target!="MHV")

write_csv(ww_data_triple_detect_loads |> filter(season == "2022/2023") |> select(wwtp, target, load_per_case), here::here("data", "assumptions", "load_per_case_detect_pop_2022.csv"))
write_csv(ww_data_triple_detect_loads |> filter(season == "2023/2024") |> select(wwtp, target, load_per_case), here::here("data", "assumptions", "load_per_case_detect_pop_2023.csv"))
write_csv(ww_data_triple_detect_loads |> filter(season == "2024/2025") |> select(wwtp, target, load_per_case), here::here("data", "assumptions", "load_per_case_detect_pop_2024.csv"))

# comparison with sentinella-based estimates
mean_load_per_case_initial_2023 <- readr::read_csv(here::here("data", "assumptions", "load_per_case_initial_2023.csv"))

ww_data_triple_detect_loads |> 
  merge(
    mean_load_per_case_initial_2023 |> rename(load_per_case_ari = load_per_case),
    by = c("wwtp", "target")
  ) |> 
  mutate(rel_pop = load_per_case/load_per_case_ari) |> 
  filter(season == "2023/2024", target != "IBV-M") |> 
  View()
