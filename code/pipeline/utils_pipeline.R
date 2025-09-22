here::i_am("code/pipeline/utils_pipeline.R")

library(targets)
library(tarchetypes)
library(crew)

library(ssh)

library(data.table)
library(dplyr)
library(stringr)

## Setup ----

create_new_pipeline <- function(name) {
  # copy file _blueprints.R
  file.copy(
    from = here::here("pipelines/_blueprint.R"),
    to = here::here("pipelines", paste0("_", name, ".R"))
  )
  # copy notebook _blueprints.Rmd
  file.copy(
    from = here::here("notebooks/blueprint.Rmd"),
    to = here::here("notebooks", paste0(name, ".Rmd"))
  )
  setup_pipeline(paste0("_", name))
}

setup_pipeline <- function(targets_proj_name, invalidate = FALSE) {
  if(getwd()!=rprojroot::find_rstudio_root_file()){
    stop("Working directory must be set to project directory.")
  }
  dir.create(file.path("pipelines", targets_proj_name), showWarnings = FALSE)
  dir.create(file.path("pipelines", targets_proj_name, "settings"), showWarnings = FALSE)
  dir.create(file.path("pipelines", targets_proj_name, "results"), showWarnings = FALSE)
  set_project(targets_proj_name)
  set_dryrun()
  set_run_cluster()
  
  if (tar_exist_meta()) {
    if (invalidate) {
      ntargets <- nrow(tar_meta(everything()))
      if (ntargets > 0) {
        tar_invalidate(everything())
        message(paste("Pipeline", targets_proj_name, "set-up successfully (invalidated", ntargets, "targets)."))
      } else {
        message(paste("Pipeline", targets_proj_name, "set-up successfully (invalidated 0 targets)."))
      }
    } else {
      message(paste("Pipeline", targets_proj_name, "set-up successfully."))
    }
  } else {
    message(paste("Pipeline", targets_proj_name, "set-up successfully (not yet run)."))
  }
}

## Pipeline settings ----
set_dryrun <- function(dry_run = NULL) {
  dryrun_path <- file.path(tar_path_store(), "settings", "dry_run.rds")
  if (is.null(dry_run)) {
    if (!file.exists(dryrun_path)) {
      saveRDS(TRUE, dryrun_path)
    }
  } else {
    saveRDS(dry_run, dryrun_path)
  }
}

set_run_cluster <- function(run_cluster = NULL) {
  run_cluster_path <- file.path(tar_path_store(), "settings", "run_cluster.rds")
  if (is.null(run_cluster)) {
    if (!file.exists(run_cluster_path)) {
      saveRDS(TRUE, run_cluster_path)
    }
  } else {
    saveRDS(run_cluster, run_cluster_path)
  }
}

set_project <- function(targets_proj_name){
  if(getwd()!=rprojroot::find_rstudio_root_file()){
    stop("Working directory must be set to project directory.")
  }
  tar_config_set(script = paste0("pipelines/",targets_proj_name,".R"), store = file.path("pipelines", targets_proj_name), project = targets_proj_name)
  Sys.setenv(TAR_PROJECT = targets_proj_name)
}

## Running ----
run_pipeline <- function(..., targets_proj_name = NULL, submit = TRUE, run_cluster = FALSE) {
  if (!is.null(targets_proj_name)) {
    set_project(targets_proj_name)
  }
  message(paste("Running pipeline", tar_path_store()))
  set_dryrun(!submit)
  set_run_cluster(run_cluster)
  tar_make(...)
}

test_jobs_run <- function(joblist, parallel = FALSE) {
  if (parallel) {
    test_run <- parallel::mclapply(joblist, function(job_obj) {
      job_obj$job$fit_opts$sampler$parallel_chains <- 1
      suppressWarnings(
        tryCatch(
          R.utils::withTimeout(EpiSewer::run(job_obj$job),timeout=2),
          error=function(cond) NULL
        )
      )
    }, mc.cores = 8, mc.cleanup = TRUE)
  } else {
    test_run <- list()
    for (i in length(joblist)) {
      job_obj <- joblist[[i]]
      job_obj$job$fit_opts$sampler$parallel_chains <- 1
      test_run[[names(joblist)[i]]] <- suppressWarnings(
        tryCatch(
          R.utils::withTimeout(EpiSewer::run(job_obj$job),timeout=2),
          error=function(cond) NULL
        )
      )
    }
  }
  
  run_successful <- sapply(test_run, function(x) {
    if(is.null(x)) {
      return(FALSE)
    } else {
      return("message" %in% names(x$errors) && x$errors$message == "reached elapsed time limit")
    }
  })
  
  if (all(run_successful)) {
    message("All jobs can run successfully.")
  } else {
    message("The following jobs did not run successfully:")
    print(names(run_successful)[!run_successful])
  }
}


run_job_local <- function(job_target) {
  job_target$fit_opts$model$model_folder <- "stan"
  job_target$fit_opts$model$package <- "EpiSewer"
  return(run(job_target))
}

submit_single_job <- function(job, job_name, W = "24:00:00", mem = 3000, temp = 5000){
  job$job_name <- job_name
  job$job_dir <- file.path("single_runs", "results")
  job$fit_opts$model$model_folder <- "code/stan"
  job$fit_opts$model$package <- NULL
  start_job_euler(job, W = W, mem = mem, temp = temp)
}

load_single_job_result <- function(job_name){
  res_path <- file.path("pipelines", "single_runs", "results", paste0(job_name, "_1_result.rds"))
  if (!file.exists(res_path)) {
    stop("Result file does not exist.")
  }
  return(readRDS(res_path))
}

## Inspection ----

load_jobenv <- function(...) {
  temp_env <- new.env()
  tar_workspace(..., packages = FALSE, source = FALSE, envir = temp_env)
  return(temp_env)
}

get_outdated_jobs <- function(targets_proj_name = NULL) {
  if (!is.null(targets_proj_name)) {
    set_project(targets_proj_name)
  } else {
    message(paste("Getting outdated jobs for", tar_path_store()))
  }
  all_jobs <- stringr::str_extract(list.files(
    file.path(tar_path_store(), "results"), pattern = "_result.rds"
  ), pattern = , "job_EpiSewer_.*(?=_\\d+_result.rds)")
  current_jobs <- (tar_meta(job_EpiSewer, fields = c("children"))$children[1])[[1]]
  outdated_jobs <- all_jobs[sapply(all_jobs, function(x) !(x %in% current_jobs))]
  return(outdated_jobs)
}

get_job_result <- function(jobname) {
  approach <- stringr::str_extract(jobname, pattern = "(EpiSewer)|(estimateR)")
  if (is.na(approach)) stop("Approach must be either EpiSewer or estimateR.")
  tarindex <- which(tar_read_raw(paste0("job_",approach,"_submission"))$name == jobname)
  return(tar_read_raw(paste0("job_",approach,"_result"), branches = tarindex)[[1]])
}

## target helpers ----
target_job_resultpath <- function(jobtarget){
  path <- file.path(
    tar_path_store(), "results", 
    paste0(jobtarget$job$job_name, "_1_result.rds")
  )
  if (!file.exists(path)) {
    saveRDS(list(), path)
  }
  return(path)
}

target_job_state <- function(job_result){
  if (length(job_result)==0) {
    return("unknown")
  } else {
    if (length(job_result$summary)!=0) {
      return("successful")
    } else {
      return("failed")
    }
  }
}

target_recently_queued <- function(job_UpToDate, job_state, euler_up){
  if (all(job_UpToDate) && all(sapply(job_state, function(x) x=="successful"))) {
    return(NA)
  } else {
    if(!euler_up) return(NA)
    try(return(get_queued_euler()), silent = TRUE)
    return(NA)
  }
}

target_job_UpToDate <- function(job, job_result){
  if (length(job_result)==0) {
    return(FALSE)
  } else {
    inclusion_items <- c(
      "data", "fit_opts", "results_opts", "metainfo"
    )
    exclusion_items <- c("fit_opts$model", "fit_opts$sampler$seed")
    return(
      identical(
        exclude_from_list(job[inclusion_items], exclusion_items),
        exclude_from_list(job_result$job[inclusion_items], exclusion_items),
        ignore.environment = TRUE
      )
    ) 
  }
}

## Housekeeping ----

prune_results <- function(approach = "EpiSewer", remove_all_jobfiles = FALSE, remove_all_outputs = FALSE, ask = TRUE) {
  
  all_results <- list.files(
    file.path(tar_path_store(), "results"), pattern = paste0(approach, "_.+_result.rds$"), full.names = TRUE
  )
  all_jobfiles <- list.files(
    file.path(tar_path_store(), "results"), pattern = paste0("_.+.rds$")
  )
  all_jobfiles <- all_jobfiles[stringr::str_detect(all_jobfiles, "_result", negate = TRUE)]
  
  all_outputs <- list.files(
    file.path(tar_path_store(), "results"), pattern = "_.+.out$", full.names = TRUE
  )
  
  current_jobs <- sapply(tar_read(job_EpiSewer), function(x) x$job$job_name)
  current_jobfiles <- list.files(file.path(tar_path_store(), "results"),
                                 pattern = paste0("(", paste(paste0(current_jobs, ".rds"), collapse = "|"), ")"))
  current_results <- tar_read_raw(paste0("job_", approach, "_resultpath"))
  current_resultnames <- stringr::str_remove(sapply(current_results, basename),"_\\d_result.rds")
  current_outputs <- all_outputs[str_detect(all_outputs, pattern = paste0("(", paste(current_resultnames, collapse = "|"), ")"))]
  
  if (ask) {
    cat("Job files to remove:\n")
    if (remove_all_jobfiles) {
      files_to_remove <- file.path(tar_path_store(), "results", all_jobfiles)
      jobfiles_removed <- sum(file.exists(files_to_remove))
    } else {
      files_to_remove <- file.path(tar_path_store(), "results", setdiff(all_jobfiles, current_jobfiles))
      jobfiles_removed <- sum(file.exists(files_to_remove))
    }
    if (length(files_to_remove)==0) {
      print("None")
    } else {
      print(files_to_remove)
    }
    
    cat("Results to remove:\n")
    results_to_remove <- setdiff(all_results, current_results)
    if (length(results_to_remove) > 0) {
      print(results_to_remove)
      results_removed <- sum(file.exists(results_to_remove))
    } else {
      print("None")
      results_removed <- 0
    }
    
    cat("Outputs to remove:\n")
    if (remove_all_outputs) {
      outputs_to_remove <- all_outputs
      outputs_removed <- sum(file.exists(outputs_to_remove))
    } else {
      outputs_to_remove <- setdiff(all_outputs, current_outputs)
      outputs_removed <- sum(file.exists(outputs_to_remove))
    }
    if (length(outputs_to_remove)==0) {
      print("None")
    } else {
      print(outputs_to_remove)
    }
    print(paste("This operation would remove", jobfiles_removed, "job files,", results_removed, "result files and", outputs_removed, "output files."))
    print(paste("This would leave", ifelse(remove_all_jobfiles,0,length(current_jobfiles)), "job files,",
                length(current_results), "result files and", ifelse(remove_all_outputs,0,length(current_outputs)), "output files."))
    response <- readline(prompt = "Do you want to proceed? (y/n): ")
  } else {
    response <- "y"
  }
  
  if (tolower(response) == "y") {
    if (remove_all_jobfiles) {
      jobfiles_removed <- sum(file.remove(file.path(tar_path_store(), "results", all_jobfiles)))
    } else {
      jobfiles_removed <- sum(file.remove(file.path(tar_path_store(), "results", setdiff(all_jobfiles, current_jobfiles))))
    }
    
    results_removed <- sum(file.remove(setdiff(all_results, current_results)))
    
    if (remove_all_outputs) {
      outputs_removed <- sum(file.remove(all_outputs))
    } else {
      outputs_removed <- sum(file.remove(setdiff(all_outputs, current_outputs)))
    }
    print(paste("Removed", jobfiles_removed, "job files,", results_removed, "result files and", outputs_removed, "output files."))
    print(paste("This leaves", ifelse(remove_all_jobfiles,0,length(current_jobfiles)), "job files,",
                length(current_results), "result files and", ifelse(remove_all_outputs,0,length(current_outputs)), "output files."))
  }
}

remove_job_result <- function(jobname, from_cluster = FALSE) {
  result_filename <- paste0(jobname, "_1_result.rds")
  if (from_cluster) {
    session <- ssh::ssh_connect(URL_EULER_USER)
    ssh::ssh_exec_wait(session, str_glue("rm -r {PATH_EULER_JOBS}/{basename(tar_path_store())}/results/{result_filename}"))
  }
  file.remove(file.path(tar_path_store(), "results", result_filename))
}

## General utils ----

#' @title Exclude items from a nested list
#' 
#' @description Exclude items and subitems from a list by going through the nested list hierarchy.
#'
#' @param l The list
#' @param items_to_exclude A character vector of items to exclude, where multiple levels are indicated using the $ operator, e.g. 'a$b$c'
#'
#' @return The list with the items excluded
#' 
#' @details Note that it is assumed that the names of the list elements are unique at each level.
#' 
#' @examples
#' test_list <- list(a = 1, b = list(c = 2, d = 3))
#' exclude_from_list(test_list, c("a", "b$c"))
exclude_from_list <- function(l, items_to_exclude) {
  items_to_exclude <- strsplit(items_to_exclude, "\\$")
  for (item in items_to_exclude) {
    if (length(item) == 1) {
      l <- l[!names(l) %in% item]
    } else {
      l[[item[1]]] <- exclude_from_list(l[[item[1]]], item[2])
    }
  }
  return(l)
}
