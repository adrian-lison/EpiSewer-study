# Assumptions ----

get_generation_dist <- function(target, shift_mean = 0, shift_sd = 0) {
  switch(target,
         `SARS-N1` = get_discrete_lognormal(
           unit_mean = 3.0 + shift_mean,
           unit_sd = 1.5 + shift_sd,
           maxX = 8 + shift_mean + 2*shift_sd,
           include_zero = F,
         ),
         `SARS-N2` = get_discrete_lognormal(
           unit_mean = 3.0 + shift_mean,
           unit_sd = 1.5 + shift_sd,
           maxX = 8 + shift_mean + 2*shift_sd,
           include_zero = F,
         ),
         `IAV-M` = get_discrete_gamma_shifted(
           gamma_mean = 2.6 + shift_mean,
           gamma_sd = 1.7 + shift_sd,
           maxX = 12 + shift_mean + 2*shift_sd
         ),
         `IBV-M` = get_discrete_gamma_shifted(
           gamma_mean = 2.6 + shift_mean,
           gamma_sd = 1.7 + shift_sd,
           maxX = 12 + shift_mean + 2*shift_sd
         ),
         `RSV-N` =  get_discrete_gamma_shifted(
           gamma_mean = 7.5 + shift_mean,
           gamma_sd = 2.1 + shift_sd,
           maxX = 14 + shift_mean + 2*shift_sd
         ),
         stop(paste("PCR target", target, "not found."))
  )
}

# This is just a dummy, since we model shedding load distributions indexed by
# date of infection, not by date of symptom onset, i.e. no incubation dist needed
get_incubation_dist <- function(target, shift_mean = 0, shift_sd = 0) {
  switch(target,
         `SARS-N1` = get_discrete_gamma(
           gamma_mean = 0.2 + shift_mean,
           gamma_sd = 0.01 + shift_sd,
           maxX = 1 + shift_mean + 2*shift_sd
         ),
         `SARS-N2` = get_discrete_gamma(
           gamma_mean = 0.2 + shift_mean,
           gamma_sd = 0.01 + shift_sd,
           maxX = 1 + shift_mean + 2*shift_sd
         ),
         `IAV-M` = get_discrete_gamma(
           gamma_mean = 0.2 + shift_mean,
           gamma_sd = 0.01 + shift_sd,
           maxX = 1 + shift_mean + 2*shift_sd
         ),
         `IBV-M` = get_discrete_gamma(
           gamma_mean = 0.2 + shift_mean,
           gamma_sd = 0.01 + shift_sd,
           maxX = 1 + shift_mean + 2*shift_sd
         ),
         `RSV-N` =  get_discrete_gamma(
           gamma_mean = 0.2 + shift_mean,
           gamma_sd = 0.01 + shift_sd,
           maxX = 1 + shift_mean + 2*shift_sd
         ),
         stop(paste("PCR target", target, "not found."))
  )
}


get_shedding_dist <- function(target, shift_mean = 0, shift_cv = 0) {
  switch(target,
         `SARS-N1` = get_discrete_gamma(
           gamma_mean = 12.4 + shift_mean,
           gamma_cv = 0.7 + shift_cv
         ),
         `SARS-N2` = get_discrete_gamma(
           gamma_mean = 12.4 + shift_mean,
           gamma_cv = 0.7 + shift_cv
         ),
         `IAV-M` = get_discrete_gamma(
           gamma_mean = 2.5 + shift_mean,
           gamma_cv = 0.34 + shift_cv
         ),
         `IBV-M` = get_discrete_gamma(
           gamma_mean = 2.5 + shift_mean,
           gamma_cv = 0.34 + shift_cv
         ),
         `RSV-N` =  get_discrete_gamma(
           gamma_mean = 6.7 + shift_mean,
           gamma_cv = 0.35 + shift_cv
         ),
         stop(paste("PCR target", target, "not found."))
  )
}

get_shedding_dist_info_fixed <- function(target, shift_mean = 0, shift_cv = 0) {
  info <- list()
  info$estimate <-  FALSE
  info$shedding_reference <- "symptom_onset"
  
  info$shedding_dist <- get_shedding_dist(target, shift_mean, shift_cv)
  
  return(info)
}

get_shedding_dist_info_estimate <- function(target, shift_mean = 0, shift_cv = 0) {
  info <- list()
  info$estimate <- TRUE
  info$shedding_reference <- "infection"
  
  if (target == "SARS-N1" | target == "SARS-N2") {
    info$shedding_dist_mean_prior_mean = c(9.16, 15.69)
    info$shedding_dist_mean_prior_sd = c(0.83, 0.79)
    info$shedding_dist_cv_prior_mean = c(0.87, 0.53)
    info$shedding_dist_cv_prior_sd = c(0.06, 0.04)
    info$shedding_dist_type <- "gamma"
  } else if (target == "IAV-M" | target == "IBV-M") {
    info$shedding_dist_mean_prior_mean = 2.50
    info$shedding_dist_mean_prior_sd = 0.19
    info$shedding_dist_cv_prior_mean = 0.34
    info$shedding_dist_cv_prior_sd = 0.01
    info$shedding_dist_type <- "gamma"
  } else if (target == "RSV-N") {
    info$shedding_dist_mean_prior_mean <- 6.76
    info$shedding_dist_mean_prior_sd <- 1.17
    info$shedding_dist_cv_prior_mean <- 0.35
    info$shedding_dist_cv_prior_sd <- 0.05
    info$shedding_dist_type <- "gamma"
  } else {
    stop(paste("PCR target", target, "not found."))
  }
  
  return(info)
}

get_load_per_case <- function(wwtp_select, target_select, multiplier = 1, load_per_case_data = NULL) {
  
  reporting_prop <- switch(target_select,
                           `SARS-N1` = 1,
                           `SARS-N2` = 1,
                           `IAV-M` = 1,
                           `IBV-M` = 1,
                           `RSV-N` = 1)
  
  sel <- load_per_case_data |> dplyr::filter(wwtp == wwtp_select, target == target_select)
  if (nrow(sel)==0) {
    stop(paste("Load per case for", wwtp_select, target_select, "not found."))
  } else {
    return(sel$load_per_case[1] * reporting_prop * multiplier)
  }
}