# load per case targets ----
load_per_case_targets <- list(
  tar_target(
    load_per_case_file,
    here::here("data", "assumptions", "load_per_case_initial_2022.csv")
  ),
  tar_target(
    load_per_case_data,
    readr::read_csv(load_per_case_file, show_col_types = FALSE)
  )
)

# selection targets ----
all_selection_targets <- list()

## SARS-CoV-2 ----
all_selection_targets[["SARSCoV_22-23_ARA_Werdhoelzli"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Werdhoelzli")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-08-15")
      to = c(
        seq.Date(as.Date("2022-09-12"), as.Date("2023-06-01"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_22-23_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-11-07") # first measurement
      to = c(
        seq.Date(as.Date("2022-11-28"), as.Date("2023-06-01"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["SARSCoV_22-23_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("SARS-N2")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-12-26")
      to = c(
        seq.Date(as.Date("2023-01-23"), as.Date("2023-06-01"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

# IAV ---
all_selection_targets[["IAV_22-23_ARA_Werdhoelzli"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Werdhoelzli")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-09-14")
      to = c(
        seq.Date(as.Date("2022-10-12"), as.Date("2023-07-24"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_22-23_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-11-07") # first measurement
      to = c(
        seq.Date(as.Date("2022-11-28"), as.Date("2023-06-19"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["IAV_22-23_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("IAV-M")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-11-07") # first measurement
      to = c(
        seq.Date(as.Date("2022-11-28"), as.Date("2023-06-19"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

## RSV ----
all_selection_targets[["RSV_22-23_ARA_Werdhoelzli"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Werdhoelzli")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-08-22")
      to = c(
        seq.Date(as.Date("2022-09-19"), as.Date("2023-06-05"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_22-23_CDA_Lugano"]] <- list(
  tar_target(
    wwtp_select,
    c("CDA Lugano")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-11-07") # first measurement
      to = c(
        seq.Date(as.Date("2022-11-28"), as.Date("2023-07-10"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)

all_selection_targets[["RSV_22-23_ARA_Chur"]] <- list(
  tar_target(
    wwtp_select,
    c("ARA Chur")
  ),
  tar_target(
    assay_select,
    c("respv4")
  ),
  tar_target(
    target_select,
    c("RSV-N")
  ),
  tar_target(
    date_select,
    {
      from = as.Date("2022-11-07") # first measurement
      to = c(
        seq.Date(as.Date("2022-11-28"), as.Date("2023-05-29"), by="1 day"),
        as.Date("2023-08-01")
      )
      mapply(
        function(from, to) c(from = from, to = to), from = from, to = to, SIMPLIFY = FALSE
      )
    }
  )
)