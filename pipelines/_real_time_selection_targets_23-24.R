# load per case targets ----
load_per_case_targets <- list(
  tar_target(
    load_per_case_file,
    here::here("data", "assumptions", "load_per_case_initial_2023.csv")
  ),
  tar_target(
    load_per_case_data,
    readr::read_csv(load_per_case_file, show_col_types = FALSE)
  )
)

# selection targets ----
all_selection_targets <- list()

## SARS-CoV-2 ----
all_selection_targets[["SARSCoV_23-24_ARA_Werdhoelzli"]] <- list(
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
      from = as.Date("2023-08-28")
      to = c(
        seq.Date(as.Date("2023-09-25"), as.Date("2024-04-29"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_23-24_CDA_Lugano"]] <- list(
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
      from = as.Date("2023-08-14")
      to = c(
        seq.Date(as.Date("2023-09-11"), as.Date("2024-04-29"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_23-24_ARA_Chur"]] <- list(
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
      from = as.Date("2023-08-21")
      to = c(
        seq.Date(as.Date("2023-09-18"), as.Date("2024-04-08"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

## IAV ---
all_selection_targets[["IAV_23-24_ARA_Werdhoelzli"]] <- list(
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
      from = as.Date("2023-11-13")
      to = c(
        seq.Date(as.Date("2023-12-11"), as.Date("2024-06-17"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_23-24_CDA_Lugano"]] <- list(
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
      from = as.Date("2023-10-30")
      to = c(
        seq.Date(as.Date("2023-11-27"), as.Date("2024-06-10"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_23-24_ARA_Chur"]] <- list(
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
      from = as.Date("2023-11-27")
      to = c(
        seq.Date(as.Date("2023-12-25"), as.Date("2024-07-15"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

## RSV ----
all_selection_targets[["RSV_23-24_ARA_Werdhoelzli"]] <- list(
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
      from = as.Date("2023-09-25")
      to = c(
        seq.Date(as.Date("2023-10-23"), as.Date("2024-07-01"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_23-24_CDA_Lugano"]] <- list(
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
      from = as.Date("2023-10-16")
      to = c(
        seq.Date(as.Date("2023-11-13"), as.Date("2024-07-01"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_23-24_ARA_Chur"]] <- list(
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
      from = as.Date("2023-11-13")
      to = c(
        seq.Date(as.Date("2023-12-11"), as.Date("2024-06-24"), by="1 day"),
        as.Date("2024-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)