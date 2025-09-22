# Utils
library(dplyr)
library(ggplot2)
library(tidyr)

source("code/pipeline/functions_pipeline.R")

get_season <- function(date) {
  if (date >= as.Date("2015-08-01") & date < as.Date("2016-08-01")) {
    return("2015/2016")
  } else if (date >= as.Date("2016-08-01") & date < as.Date("2017-08-01")) {
    return("2016/2017")
  } else if (date >= as.Date("2017-08-01") & date < as.Date("2018-08-01")) {
    return("2017/2018")
  } else if (date >= as.Date("2018-08-01") & date < as.Date("2019-08-01")) {
    return("2018/2019")
  } else if (date >= as.Date("2019-08-01") & date < as.Date("2020-08-01")) {
    return("2019/2020")
  } else if (date >= as.Date("2020-08-01") & date < as.Date("2021-08-01")) {
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

# Influenzanet / Grippenet
influenzanet <- readr::read_csv(here::here("data","sentinella","2025-05-27_ARI_ILI","CH_incidence.csv"))
influenzanet <- influenzanet |> filter(syndrome == "ili.ecdc") |> 
  mutate(datetime = ISOweek::ISOweek2date(
    paste0(stringr::str_sub(yw, 1, 4), "-W", stringr::str_sub(yw, 5, 6), "-1")
    ))

# ARI and ILI consultations
ILI_inc <- rjson::fromJSON(file = here::here("data","sentinella","2025-05-27_ARI_ILI","ILI_incValue.json"))
ILI_inc <- data.frame(
  yearweek=sapply(ILI_inc$values, function(v) ifelse(length(v$x)==0, NA, v$x)),
  ILI_consult_per_100k=sapply(ILI_inc$values, function(v) ifelse(length(v$y)==0, NA, v$y))
)
ILI_inc$datetime <- ISOweek::ISOweek2date(
  paste0(stringr::str_sub(ILI_inc$yearweek, 1, 4), "-W", stringr::str_sub(ILI_inc$yearweek, 5, 6), "-1")
)

ARI_inc <- rjson::fromJSON(file = here::here("data","sentinella","2025-05-27_ARI_ILI","ARI_incValue.json"))
ARI_inc <- data.frame(
  yearweek=sapply(ARI_inc$values, function(v) ifelse(length(v$x)==0, NA, v$x)),
  ARI_consult_per_100k=sapply(ARI_inc$values, function(v) ifelse(length(v$y)==0, NA, v$y))
)
ARI_inc$datetime <- ISOweek::ISOweek2date(
  paste0(stringr::str_sub(ARI_inc$yearweek, 1, 4), "-W", stringr::str_sub(ARI_inc$yearweek, 5, 6), "-1")
  )

ILI_ARI_inc <- full_join(ILI_inc, ARI_inc, by = c("yearweek","datetime")) |> 
  relocate(datetime, .after = yearweek)

ILI_ARI_per_consultation <- ILI_ARI_inc |> 
  select(datetime, ARI_consult_per_100k, ILI_consult_per_100k) |> 
  inner_join(
    influenzanet |> 
      transmute(datetime, influenzanet_inc_per_100k = incidence * 100000),
    by = "datetime") |> 
  mutate(season = sapply(datetime, get_season)) |> 
  group_by(season) |>
  summarize(
    influenzanet_inc_per_100k = sum(influenzanet_inc_per_100k, na.rm = T),
    ARI_consult_per_100k = sum(ARI_consult_per_100k, na.rm = T),
    ILI_consult_per_100k = sum(ILI_consult_per_100k, na.rm = T)
    ) |> 
  mutate(
    factor_ARI = influenzanet_inc_per_100k / ARI_consult_per_100k,
    factor_ILI = influenzanet_inc_per_100k / ILI_consult_per_100k
  )

# Sentinella pathogen tests
resp_sentinella <- readr::read_csv(here::here("data","sentinella","2025_05_27_RESPVIRUSES_sentinella","data.csv"))

resp_sentinella$datetime <- ISOweek::ISOweek2date(paste0(resp_sentinella$temporal, "-1"))

total_samples <- resp_sentinella |> 
  filter(
    georegion == "CH",
    valueCategory == "samples",
    testResult == "all"
    ) |> 
  select(temporal, datetime, n = value)

positive_samples <- resp_sentinella |> 
  filter(
    georegion == "CH",
    valueCategory == "detections",
    testResult_type == "pcr",
    testResult == "positive"
    ) |>
  select(temporal, datetime, pathogen, type, n_positive = value) |> 
  inner_join(total_samples, by = c("temporal","datetime")) |> 
  mutate(proportion = n_positive/n) |> 
  mutate(season = sapply(datetime, get_season)) |> 
  inner_join(
    ILI_ARI_inc |> select(datetime, ARI_consult_per_100k, ILI_consult_per_100k),
    by = "datetime"
    ) |> 
  left_join(
    ILI_ARI_per_consultation |> select(season, factor_ARI, factor_ILI),
    by = "season"
    ) |>
  mutate(
    pathogen_consult_per_100k = ARI_consult_per_100k * proportion,
    pathogen_per_100k = pathogen_consult_per_100k * factor_ILI,
    )

# when do they reach a threshold
positive_samples |> filter(
  datetime >= "2023-08-01", datetime < "2024-08-01",
  pathogen %in% c("sars-cov-2", "influenza", "respiratory_syncytial_virus")) |> 
  select(pathogen, type, datetime, n_positive) |> 
  group_by(pathogen, type) |> 
  arrange(datetime) |> 
  mutate(n_positive_cum = cumsum(n_positive)) |> 
  ggplot(aes(x=datetime, y=n_positive_cum, color = paste(pathogen, type))) +
  geom_line() +
  geom_hline(yintercept = 10) +
  coord_cartesian(ylim = c(0, 20), xlim = as.Date(c(NA, "2024-01-01")))

# Seasonal attack rates
seasonal_attack_rate <- positive_samples |>
  group_by(season, pathogen, type) |> 
  summarize(pathogen_per_season_100k = sum(pathogen_per_100k, na.rm = T)) |> 
  mutate(
    pathogen_per_season_proportion = pathogen_per_season_100k / 100000,
    pathogen_per_season_Switzerland = pathogen_per_season_100k * 8770000/100000
  ) |> 
  arrange(pathogen, type)

seasonal_attack_rate |> filter(
  pathogen %in% c("sars-cov-2", "influenza", "respiratory_syncytial_virus"),
  !(pathogen == "influenza" & type == "all")
) |> select(season, pathogen, type, pathogen_per_season_proportion) |> 
  ggplot(aes(x=season, fill = paste(pathogen, type), y=pathogen_per_season_proportion)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_discrete(name="Pathogen") +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Seasonal attack rate") + xlab("Season") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))

# PLot time series
positive_samples |> filter(
  pathogen %in% c("sars-cov-2", "influenza", "respiratory_syncytial_virus"),
  !(pathogen == "influenza" & type == "all")
) |> 
  ggplot(aes(x=datetime, y=proportion, color = paste(pathogen, type))) +
  geom_step() +
  scale_color_discrete(name="Pathogen") +
  scale_x_date(expand = c(0,0)) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Weekly proportion of all samples") + xlab("Date")

positive_samples |> filter(
  pathogen %in% c("sars-cov-2", "influenza", "respiratory_syncytial_virus"),
  !(pathogen == "influenza" & type == "all")
) |> 
  ggplot(aes(x=datetime, y=pathogen_per_100k, color = paste(pathogen, type))) +
  geom_step() +
  scale_color_discrete(name="Pathogen") +
  scale_x_date(expand = c(0,0)) +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Weekly incidence per 100k") + xlab("Date")

# Create time series for each wwtp
wwtps <- readr::read_csv(
  here::here("data", "ww_data", "wwtp_info.csv"),
  show_col_types = FALSE
) %>%
  select(name, ara_id, population)

pathogen_to_target <- function(pathogen, type) {
  if (pathogen == "sars-cov-2") {
    return("SARS-N1")
  } else if (pathogen == "influenza" && type == "A") {
    return("IAV-M")
  } else if (pathogen == "influenza" && type == "B") {
    return("IBV-M")
  } else if (pathogen == "respiratory_syncytial_virus") {
    return("RSV-N")
  } else {
    stop(paste("Unknown pathogen", pathogen, type))
  }
}

wwtp_incidence <- positive_samples |> filter(
  pathogen %in% c("sars-cov-2", "influenza", "respiratory_syncytial_virus"),
  !(pathogen == "influenza" & type == "all")
) |> 
  select(datetime, pathogen, type, pathogen_per_100k) |> 
  crossing(wwtps |> select(wwtp = name, population)) |> 
  mutate(
    incidence_per_week = pathogen_per_100k * population / 100000,
    target = mapply(pathogen_to_target, pathogen = pathogen, type = type)
    )

wwtp_incidence <- bind_rows(
  wwtp_incidence,
  wwtp_incidence |> filter(target == "SARS-N1") |> mutate(target = "SARS-N2")
)

wwtp_incidence |> 
  filter(wwtp == "STEP Porrentruy") |> 
  ggplot(aes(x=datetime, y=incidence_per_week/7, color = paste(pathogen, type))) +
  geom_step() +
  scale_color_discrete(name="Pathogen") +
  scale_x_date(expand = c(0,0)) +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Daily incidence") + xlab("Date") +
  facet_wrap(~paste(pathogen, type), ncol = 1, scales = "free_y")

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

outlier_df <- readr::read_csv(file.path(here::here("data", "ww_data", "outliers_manual.csv")), show_col_types = FALSE)

ww_data_per_week <- ww_data |> 
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
    first_date_isoweek = ISOweek::ISOweek2date(
      paste0(lubridate::year(date), "-W", formatC(lubridate::isoweek(date), width = 2, format = "d", flag = "0"), "-1")
    )
    ) |> 
  group_by(wwtp, target, first_date_isoweek) |>
  summarize(load = mean(load, na.rm = T))

ww_load_per_case <- ww_data_per_week |> 
  inner_join(wwtp_incidence, by = c("wwtp" = "wwtp", "target" = "target", "first_date_isoweek" = "datetime")) |> 
  mutate(load_per_case = load / (incidence_per_week/7)) |> 
  filter(!is.infinite(load_per_case), load_per_case>0)

mean_load_per_case_initial_2022 <- ww_load_per_case |> 
  filter(first_date_isoweek >= "2022-08-01", first_date_isoweek < "2022-12-01") |> 
  group_by(wwtp, target) |> 
  summarize(load_per_case = median(load_per_case, na.rm = T))

mean_load_per_case_initial_2023 <- ww_load_per_case |> 
  filter(first_date_isoweek >= "2023-08-01", first_date_isoweek < "2023-12-01") |> 
  group_by(wwtp, target) |> 
  summarize(load_per_case = median(load_per_case, na.rm = T))

mean_load_per_case_initial_2024 <- ww_load_per_case |> 
  filter(first_date_isoweek >= "2024-08-01", first_date_isoweek < "2024-12-01") |> 
  group_by(wwtp, target) |> 
  summarize(load_per_case = median(load_per_case, na.rm = T))

mean_load_per_case_since_202208 <- ww_load_per_case |> 
  filter(first_date_isoweek >= "2022-08-01") |> 
  group_by(wwtp, target) |> 
  summarize(load_per_case = median(load_per_case, na.rm = T))

wwtp_select <- "ARA Werdhoelzli"
ww_load_per_case |> 
  filter(wwtp == wwtp_select, target != "MHV") |> 
  ggplot(aes(x = first_date_isoweek, y = load_per_case, color = target)) +
  geom_point() +
  geom_hline(data = mean_load_per_case_initial_2022 |> 
               filter(wwtp == wwtp_select,
                      target != "MHV"), 
             aes(yintercept = load_per_case), linetype = "dashed") +
  geom_hline(data = mean_load_per_case_since_202208 |> 
               filter(wwtp == wwtp_select,
                      target != "MHV"), 
             aes(yintercept = load_per_case), linetype = "dotted") +
  scale_color_discrete(name="Pathogen") +
  scale_x_date(expand = c(0,0)) +
  theme_bw() +
  scale_y_log10() +
  theme(legend.position = "top") +
  ylab("Load per case") + xlab("Date") +
  facet_wrap(~target, ncol = 1, scales = "free_y") +
  coord_cartesian(xlim = c(as.Date("2022-01-01"), NA))

# how much does the initial load_per_case estimate differ from the two year average?
mean_load_per_case_initial_2022 |> 
  inner_join(mean_load_per_case_since_202208, by = c("wwtp", "target")) |> 
  mutate(rel = load_per_case.x/load_per_case.y) |> 
  ggplot(aes(y=rel)) + geom_boxplot(aes(fill = target)) + 
  geom_hline(yintercept = 1, linetype = "dashed") + 
  theme_bw() + coord_cartesian(ylim = c(0.25, 3))

mean_load_per_case_initial_2023 |> 
  inner_join(mean_load_per_case_since_202208, by = c("wwtp", "target")) |> 
  mutate(rel = load_per_case.x/load_per_case.y) |> 
  ggplot(aes(y=rel)) + geom_boxplot(aes(fill = target)) + 
  geom_hline(yintercept = 1, linetype = "dashed") + 
  theme_bw() + coord_cartesian(ylim = c(0.25, 3))

mean_load_per_case_initial_2024 |> 
  inner_join(mean_load_per_case_since_202208, by = c("wwtp", "target")) |> 
  mutate(rel = load_per_case.x/load_per_case.y) |> 
  ggplot(aes(y=rel)) + geom_boxplot(aes(fill = target)) + 
  geom_hline(yintercept = 1, linetype = "dashed") + 
  theme_bw() + coord_cartesian(ylim = c(0.25, 3))

write_csv(mean_load_per_case_since_202208, here::here("data", "assumptions", "load_per_case_since_202208.csv"))
write_csv(mean_load_per_case_initial_2022, here::here("data", "assumptions", "load_per_case_initial_2022.csv"))
write_csv(mean_load_per_case_initial_2023, here::here("data", "assumptions", "load_per_case_initial_2023.csv"))
write_csv(mean_load_per_case_initial_2023, here::here("data", "assumptions", "load_per_case_initial_2024.csv"))

mean_load_per_case_initial_2023 |> 
  ggplot(aes(x = target, y = load_per_case)) +
  geom_point(aes(color = wwtp))

mean_load_per_case_since_202208 |> 
  ggplot(aes(x=target, y=load_per_case)) +
  geom_point(aes(color = wwtp)) +
  theme_bw() +
  scale_y_log10()
