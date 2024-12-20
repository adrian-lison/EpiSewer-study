interval_to_quantile <- function(interval) {
  if(stringr::str_detect(interval, "median")) return(0.5)
  else if (stringr::str_detect(interval, "lower_")) {
    return((1-as.numeric(stringr::str_remove(interval, "lower_")))/2)
  } else {
    return(1-(1-as.numeric(stringr::str_remove(interval, "upper_")))/2)
  }
}

format_interval_quantile <- function(df, keep_cols = c("date"), values_to = "value") {
  setDT(df)
  df[, upper_median := median]
  df_long <- melt(
    df, 
    id.vars = keep_cols, 
    variable.name = "interval", 
    value.name = values_to
  )
  df_long[, quantile := round(sapply(interval, interval_to_quantile), 3)]
  df_long[, upper := str_detect(interval, "upper")]
  df_long[, interval := as.numeric(
    ifelse(str_detect(interval, "median"), 0, str_remove(interval, "lower_|upper_"))
  )]
  # update column order
  setcolorder(df_long, c(keep_cols, "interval", "upper", "quantile", values_to))
  setorderv(df_long, cols = c(keep_cols, c("interval", "upper")))
  return(df_long)
}

prange_diff <- function(x, maxlag = 1){
  pmaxlag <- rep(-Inf, length(x))
  pminlag <- rep(Inf, length(x))
  for (i in 0:maxlag){
    pmaxlag <- pmax(pmaxlag, lag(x, i), na.rm = T)
    pminlag <- pmin(pminlag, lag(x, i), na.rm = T)
  }
  return(pmaxlag-pminlag)
}