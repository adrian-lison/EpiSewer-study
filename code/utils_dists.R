# This script contains various utility functions for 
# parameterizing, discretizing and drawing from probability distributions.

## Exponentially modified Gaussian ----

remg2 <- function(n, mean = 0, sd = 1, kappa = 1) {
  sigma = sd/sqrt(1+kappa^2)
  lambda <- 1/(kappa*sigma)
  mu = mean - kappa * sigma
  return(emg::remg(n = n, mu = mu, sigma = sigma, lambda = lambda))
}

# truncated
rtemg2 <- function(n, mean = 0, sd = 1, kappa = 1) {
  sigma = sd/sqrt(1+kappa^2)
  lambda <- 1/(kappa*sigma)
  mu = mean - kappa * sigma
  samples <- emg::remg(n = n, mu = mu, sigma = sigma, lambda = lambda)
  while(any(samples<=0)) {
    too_small <- which(samples<=0)
    samples[too_small] <- emg::remg(n = length(too_small), mu = mu, sigma = sigma, lambda = lambda)
  }
  return(samples)
}

## Binomial ----

#' RNG for binomial random variables parameterized by mean and standard deviation.
#' 
#' Note that for small mu, the standard deviation will not be matched exactly
#' since the binomial distribution is discrete.
rbinom2 <- function(n, mean, sd) {
  size = mean + sd^2
  p = mean / size
  return(rbinom(n, size = size, prob = p))
}

#' Get the coefficient of variation from a binomial distribution with size n and
#' probability p
get_cv_binom <- function(n, p) {
  sqrt((1-p)/(n*p))
}

## Gamma ----

#' Get shape of a Gamma distribution given its mean and sd
get_gamma_shape_alternative <- function(gamma_mean, gamma_sd) {
  gamma_shape <- (gamma_mean / gamma_sd)^2
  return(gamma_shape)
}

#' Get rate of a Gamma distribution given its mean and sd
get_gamma_rate_alternative <- function(gamma_mean, gamma_sd) {
  gamma_rate <- gamma_mean / (gamma_sd^2)
  return(gamma_rate)
}

#' Get scale of a Gamma distribution given its mean and sd
get_gamma_scale_alternative <- function(gamma_mean, gamma_sd) {
  return(1 / get_gamma_rate_alternative(gamma_mean, gamma_sd))
}

#' Get mean of a Gamma distribution given its shape and scale
get_gamma_mean_alternative <- function(gamma_shape, gamma_scale) {
  gamma_mean <- gamma_shape * gamma_scale
  return(gamma_mean)
}

#' Get sd of a Gamma distribution given its shape and scale
get_gamma_sd_alternative <- function(gamma_shape, gamma_scale) {
  gamma_sd <- sqrt(gamma_shape) * gamma_scale
  return(gamma_sd)
}


#' Get PMF of a discretized Gamma distribution
#'
#' @description This function accepts different parameterizations to specify a
#'   discretized Gamma distribution.
#'
#' @param gamma_shape Shape parameter of the Gamma distribution.
#' @param gamma_rate Rate parameter of the Gamma distribution.
#' @param gamma_scale Scale parameter of the Gamma distribution. Can be
#'   specified instead of the rate. Only has an effect if the rate is not
#'   specified.
#' @param gamma_mean Alternative parameterization: Mean of the Gamma
#'   distribution.
#' @param gamma_sd Alternative parameterization: Standard deviation of the Gamma
#'   distribution.
#' @param gamma_cv Alternative parameterization: Coefficient of variation of the
#'   Gamma distribution.
#' @param maxX Right truncation point. All probability mass beyond `maxX` will
#'   be assigned to `maxX`. If `NULL` (default), this is automatically chosen
#'   such that the last bin has less than 0.5% of the probability mass.
#' @param include_zero Should the distribution explicitly cover X=0, or should
#'   X=1 include the probability mass for X=0 too?
#' @param print_params Should the shape and rate parameters be printed?
#'
#' @return A numeric vector representing the PMF of the discretized Gamma
#'   distribution.
#' @export
get_discrete_gamma <- function(gamma_shape,
                               gamma_rate,
                               gamma_scale,
                               gamma_mean,
                               gamma_sd,
                               gamma_cv,
                               maxX = NULL,
                               include_zero = TRUE,
                               print_params = FALSE) {
  if (missing(gamma_shape)) {
    if (missing(gamma_mean) || (missing(gamma_sd) && missing(gamma_cv))) {
      stop("No valid combination of parameters supplied", call. = FALSE)
    }
    if (missing(gamma_sd)) {
      gamma_sd <- gamma_mean * gamma_cv
    }
    gamma_shape <- get_gamma_shape_alternative(gamma_mean, gamma_sd)
  }
  if (missing(gamma_rate)) {
    if (missing(gamma_scale)) {
      if (missing(gamma_mean) || (missing(gamma_sd) && missing(gamma_cv))) {
        stop("No valid combination of parameters supplied", call. = FALSE)
      }
      if (missing(gamma_sd)) {
        gamma_sd <- gamma_mean * gamma_cv
      }
      gamma_rate <- get_gamma_rate_alternative(gamma_mean, gamma_sd)
    } else {
      gamma_rate <- 1 / gamma_scale
    }
  }
  
  # shortest period (combines periods 0 and 1)
  shortest <- pgamma(2, shape = gamma_shape, rate = gamma_rate)
  # longest period (combines all periods >= maxX)
  if (is.null(maxX)) {
    maxX <- which(sapply(1:100, function(maxX) {
      (1 - pgamma(maxX, shape = gamma_shape, rate = gamma_rate)) < 0.005
    }))[1]
    if (is.na(maxX)) {
      maxX <- 100
      cli::cli_inform(c(
        "!" = paste0("Maximum length of distribution was set to 100. ",
                     "The last bin covers ",
                     round(
                       (1 - pgamma(maxX, shape = gamma_shape, rate = gamma_rate)),
                       4
                     ),
                     "% of the probability mass."
        )
      ))
    }
  }
  longest <- (1 - pgamma(maxX, shape = gamma_shape, rate = gamma_rate))
  
  if (include_zero) {
    probs <- c(
      # all except longest (discrete)
      extraDistr::ddgamma(0:(maxX - 1), shape = gamma_shape, rate = gamma_rate),
      longest
    )
  } else {
    probs <- c(
      shortest,
      # all except shortest and longest (discrete)
      extraDistr::ddgamma(2:(maxX - 1), shape = gamma_shape, rate = gamma_rate),
      longest
    )
  }
  
  if (print_params) {
    print(paste("Shape =", gamma_shape, "| Rate =", gamma_rate))
  }
  
  return(probs)
}

#' Get PMF of a discretized shifted Gamma distribution
#'
#' @description This function specifies a discretized shifted Gamma distribution
#'   (shifted such that the minimum is at 1) using a mean and standard deviation
#'   parameterization.
#'
#' @description The shift makes the distribution attractive for modeling
#'   generation time distributions, which are often assumed to have zero
#'   probability mass for a generation time of zero (as this is incompatible
#'   with the renewal equation).
#'
#' @details This code was adapted from EpiEstim, credit to Anne Cori
#'   (a.cori@imperial.ac.uk).
#'
#' @param gamma_mean Mean of the shifted Gamma distribution.
#' @param gamma_sd Standard deviation of the shifted Gamma distribution.
#' @param maxX Right truncation point. All probability mass beyond `maxX` will
#'   be assigned to `maxX`.  If `NULL` (default), this is automatically chosen
#'   such that the last bin has approximately less than 0.5% of the probability
#'   mass.
#'
#' @return A numeric vector representing the PMF of the discretized shifted
#'   Gamma distribution.
#' @export
get_discrete_gamma_shifted <- function(
    gamma_mean, gamma_sd, maxX = NULL) {
  maxX <- 1 + length(get_discrete_gamma(
    gamma_mean = gamma_mean,
    gamma_sd = gamma_sd,
    maxX = maxX
  ))
  k <- 1:maxX
  if (gamma_sd < 0) {
    stop("gamma_sd must be >=0.")
  }
  if (gamma_mean <= 1) {
    stop("gamma_mean must be >1")
  }
  if (maxX < 1) {
    stop("Maximum period must be >=1.")
  }
  a <- ((gamma_mean - 1) / gamma_sd)^2
  b <- gamma_sd^2 / (gamma_mean - 1)
  cdf_gamma <- function(k, a, b) stats::pgamma(k, shape = a, scale = b)
  res <- k * cdf_gamma(k, a, b) + (k - 2) *
    cdf_gamma(k - 2, a, b) - 2 * (k - 1) * cdf_gamma(k - 1, a, b)
  res <- res + a * b * (2 * cdf_gamma(k - 1, a + 1, b) -
                          cdf_gamma(k - 2, a + 1, b) - cdf_gamma(k, a + 1, b))
  res <- sapply(res, function(e) max(0, e))
  res <- res / sum(res)
  return(res)
}


rgamma2 <- function(n, mean, cv) {
  sd = cv * mean
  shape = get_gamma_shape_alternative(mean, sd)
  rate = get_gamma_rate_alternative(mean, sd)
  return(rgamma(n = n, shape = shape, rate = rate))
}

# Log-Normal ----

#' Compute mu parameter of Log-Normal from other quantities.
#'
#' @param unit_q5 5% quantile of distribution.
#' @param unit_q95 95% quantile of distribution.
#'
#' @details Currently, only conversion from quantiles is supported, but other
#' alternatives may be added.
#'
#' @return Mu parameter of Log-Normal distribution.
get_lognormal_mu_alternative <- function(unit_mean = NULL, unit_sd = NULL, unit_q5 = NULL, unit_q95 = NULL) {
  if (!is.null(unit_mean) && !is.null(unit_sd)) {
    sigma2 <- log((unit_sd / unit_mean)^2 + 1)
    mu <- log(unit_mean) - sigma2 / 2
  } else if (!is.null(unit_q5) && !is.null(unit_q95)) {
    erfq5 <- erfinv(2*0.05-1)
    erfq95 <- erfinv(2*0.95-1)
    if (unit_q5 > unit_q95) {
      cli::cli_abort(paste(
        "Lower quantile `unit_q5` must not be larger",
        "than upper quantile `unit_q95`."
      ))
    }
    mu = (log(unit_q5)/erfq5 - log(unit_q95)/erfq95) / (1/erfq5 - 1/erfq95)
  } else {
    cli::cli_abort(paste(
      "Either `unit_mean` and `unit_sd` or `unit_q5` and `unit_q95` must be supplied."
    ))
  }
  return(mu)
}

#' Compute sigma parameter of Log-Normal from other quantities.
#'
#' @param mu Mu parameter of Log-Normal distribution.
#' @inheritParams get_lognormal_mu_alternative
#'
#' @details Currently, only conversion from mu + a quantile is supported, but
#'   other alternatives may be added.
#'
#' @return Sigma parameter of Log-Normal distribution.
get_lognormal_sigma_alternative <- function(mu, unit_mean = NULL, unit_sd = NULL,
                                            unit_q5 = NULL, unit_q95 = NULL) {
  if (!is.null(unit_mean) && !is.null(unit_sd)) {
    sigma <- sqrt(log((unit_sd / unit_mean)^2 + 1))
  } else {
    if (is.null(unit_q5) && is.null(unit_q95)) {
      cli::cli_abort(
        "Either `unit_q5` or `unit_q95` must be supplied together with mu."
      )
    }
    if (!is.null(unit_q5) && !is.null(unit_q95)) {
      cli::cli_warn(paste(
        "Both `unit_q5` and `unit_q95` were supplied together with mu,",
        "using only `unit_q95` to compute sigma."
      ))
    }
    if (!is.null(unit_q95)) {
      if (unit_q95 < exp(mu)) {
        cli::cli_abort(
          "Upper quantile `unit_q95` must not be less than exp(mu)."
        )
      }
      sigma = (log(unit_q95) - mu)/(sqrt(2) * erfinv(2*0.95-1))
    } else if (!is.null(unit_q5)) {
      if (unit_q5 > exp(mu)) {
        cli::cli_abort(
          "Lower quantile `unit_q5` must not be greater than exp(mu)."
        )
      }
      sigma = (log(unit_q5) - mu)/(sqrt(2) * erfinv(2*0.05-1))
    }
  }
  return(sigma)
}

#' Get PMF of a discretized lognormal distribution
#'
#' This function accepts both log-scale and unit-scale parameters to specify a
#' discretized lognormal distribution.
#'
#' @param meanlog Log scale mean (location of lognormal).
#' @param sdlog Log scale standard deviation (scale of lognormal).
#' @param unit_mean Alternative parameterization: unit/natural scale mean.
#' @param unit_sd Alternative parameterization: unit/natural scale sd.
#' @param unit_cv Alternative parameterization: unit/natural scale coefficient
#'   of variation.
#' @param maxX Right truncation point. All probability mass beyond `maxX` will
#'   be assigned to `maxX`. If `NULL` (default), this is automatically chosen
#'   such that the last bin has less than 0.5% of the probability mass.
#' @param include_zero Should the distribution explicitly cover X=0, or should
#'   X=1 include the probability mass for X=0 too?
#' @param print_params Should the log-level parameters be printed?
#'
#' @return A numeric vector representing the PMF of the discretized lognormal.
#' @export
get_discrete_lognormal <- function(
    meanlog, sdlog, unit_mean = NULL, unit_sd = NULL, unit_cv = NULL, maxX = NULL, include_zero = TRUE,
    print_params = FALSE) {
  if (!is.null(unit_mean) && (!is.null(unit_sd) || !is.null(unit_cv))) {
    if (is.null(unit_sd)) {
      unit_sd <- unit_mean * unit_cv
    }
    sigma2 <- log((unit_sd / unit_mean)^2 + 1)
    meanlog <- log(unit_mean) - sigma2 / 2
    sdlog <- sqrt(sigma2)
  }
  # shortest period (combines periods 0 and 1)
  shortest <- plnorm(2, meanlog = meanlog, sdlog = sdlog)
  # longest period (combines all periods >= maxX)
  if (is.null(maxX)) {
    maxX <- which(sapply(1:100, function(maxX) {
      (1 - plnorm(maxX, meanlog = meanlog, sdlog = sdlog)) < 0.005
    }))[1]
    if (is.na(maxX)) {
      maxX <- 100
      cli::cli_inform(c(
        "!" = paste0("Maximum length of distribution was set to 100. ",
                     "The last bin covers ",
                     round(
                       (1 - plnorm(maxX, meanlog = meanlog, sdlog = sdlog)),
                       4
                     ),
                     "of the probability mass."
        )
      ))
    }
  }
  longest <- (1 - plnorm(maxX, meanlog = meanlog, sdlog = sdlog))
  
  if (include_zero) {
    # all except longest (discrete)
    probs <- c(
      sapply(0:(maxX - 1), function(x) {
        plnorm(
          x + 1,
          meanlog = meanlog, sdlog = sdlog
        ) -
          plnorm(x, meanlog = meanlog, sdlog = sdlog)
      }),
      longest
    )
  } else {
    probs <- c(
      shortest,
      # all except shortest and longest (discrete)
      sapply(2:(maxX - 1), function(x) {
        plnorm(
          x + 1,
          meanlog = meanlog, sdlog = sdlog
        ) -
          plnorm(x, meanlog = meanlog, sdlog = sdlog)
      }),
      longest
    )
  }
  
  if (print_params) {
    print(paste("meanlog =", meanlog, "| sdlog =", sdlog))
  }
  
  return(probs)
}

rlnorm3 <- function(n, mean, cv) {
  sigma2 = log(1 + cv^2);
  mu = log(mean) - sigma2/2;
  return(rlnorm(n, meanlog = mu, sd = sqrt(sigma2)))
}

# Approximation for MGF of the Log-Normal distribution by Assmussen et al. 
# obtained by replacing t with -i*t in the characteristic function
expL <- function(theta, mu, sigma2) {
  W_result <- pracma::lambertWp(-theta * sigma2 * exp(mu))
  return(exp(-(W_result^2+2*W_result)/(2*sigma2)) * 1/sqrt(1+W_result))
}

# Approximation of the MGF of the Log-Normal distribution through numerical integration
expL_int <- function(theta, mu, sigma2) {
  int_f <- function(x) 1 / (x * sqrt(sigma2) * sqrt(2 * pi)) * exp(-(log(x) - mu)^2 / (2 * sigma2) + theta * x)
  # can also alternatively be written as:
  # int_f <- int_f <- function(x) exp(theta*x) * dlnorm(x, mu, sqrt(sigma2))
  return(integrate(int_f, lower = 0, upper = Inf)$value)
}

## Helper functions ----
check_dist <- function(dist, name = "probability distribution") {
  if (!is.numeric(dist)) {
    rlang::abort(paste("Supplied", name, "is not a numeric vector."))
  }
  if (any(dist < 0)) {
    rlang::abort(paste(
      "Supplied", name, "has negative entries.",
      "All probabilities must be positive."
    ))
  }
  if (sum(dist) != 1) {
    rlang::warn(paste(
      "Supplied", name, "does not sum to 1.",
      "EpiSewer will normalize the probabilities such that they sum to 1.\n"
    ))
    dist <- dist / sum(dist)
  }
  return(dist)
}

#' Get the mean of a discrete distribution
#'
#' @param dist Discrete distribution represented as numeric vector
#' @param include_zero If `TRUE` (default), the vector index starts at zero.
#'   Otherwise, it starts at 1.
#'
#' @return Mean of the discrete distribution
#' @keywords internal
dist_mean <- function(dist, include_zero = TRUE) {
  if (include_zero) {
    mean <- sum((0:(length(dist) - 1)) * dist)
  } else {
    mean <- sum((1:(length(dist))) * dist)
  }
  return(mean)
}
