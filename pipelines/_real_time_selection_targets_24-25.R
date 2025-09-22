# load per case targets ----
load_per_case_targets <- list(
  tar_target(
    load_per_case_file,
    here::here("data", "assumptions", "load_per_case_initial_2024.csv")
  ),
  tar_target(
    load_per_case_data,
    readr::read_csv(load_per_case_file, show_col_types = FALSE)
  )
)

# selection targets ----
all_selection_targets <- list()

## SARS-CoV-2 ----
all_selection_targets[["SARSCoV_24-25_ARA_Werdhoelzli"]] <- list(
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
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-08-19")
      to = c(
        seq.Date(as.Date("2024-09-16"), as.Date("2025-04-14"), by="1 day"),
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_24-25_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-08-12")
      to = c(
        seq.Date(as.Date("2024-09-09"), as.Date("2025-04-07"), by="1 day"),
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_24-25_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-08-12")
      to = c(
        seq.Date(as.Date("2024-09-09"), as.Date("2025-04-14"), by="1 day"),
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

## IAV ---
all_selection_targets[["IAV_24-25_ARA_Werdhoelzli"]] <- list(
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
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-10-21")
      to = c(
        seq.Date(as.Date("2024-11-18"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_24-25_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-10-21")
      to = c(
        seq.Date(as.Date("2024-11-18"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_24-25_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-11-11")
      to = c(
        seq.Date(as.Date("2024-12-09"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

## RSV ----
all_selection_targets[["RSV_24-25_ARA_Werdhoelzli"]] <- list(
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
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-09-23")
      to = c(
        seq.Date(as.Date("2024-10-21"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_24-25_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-10-21")
      to = c(
        seq.Date(as.Date("2024-11-18"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_24-25_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv6")
  ),
  tar_target(
    target_select,
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2024-10-21")
      to = c(
        seq.Date(as.Date("2024-11-18"), as.Date("2025-05-31")-14, by="1 day"), # until 2 weeks (forecasting horizon) before end of data
        as.Date("2025-05-31")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)