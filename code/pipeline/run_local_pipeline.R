# Local run targets ----
local_run_targets <- list(
  EpiSewer = tar_target(
    job_EpiSewer_submission,
    target_job_submission_local(
      job = jobs_EpiSewer_valid[[1]]$job,
      job_result = job_EpiSewer_result,
      job_UpToDate = job_EpiSewer_UpToDate,
      job_failed = job_EpiSewer_failed,
      job_state = job_EpiSewer_state,
      local_submit = !dry_run,
      result_path = job_EpiSewer_resultpath
    ),
    pattern = map(
      jobs_EpiSewer_valid,
      job_EpiSewer_result,
      job_EpiSewer_resultpath,
      job_EpiSewer_UpToDate,
      job_EpiSewer_failed,
      job_EpiSewer_state
    ),
    #cue = tar_cue(mode = "always"),
    iteration = "vector",
    deployment = "main"
  ),
  estimateR = tar_target(
    job_estimateR_submission,
    {
      job <- jobs_estimateR_valid[[1]]$job
      job$selection <- jobs_estimateR_valid[[1]]$selection
      if (job_estimateR_UpToDate) {
        return(data.frame(
          name = job$job_name,
          submission = tar_name(),
          time = lubridate::now(),
          exists = length(job_estimateR_result)!=0,
          up_to_date = TRUE,
          failed = FALSE,
          needs_run = FALSE,
          submitted = FALSE
        ))
      } else {
        do_submit <- !dry_run
        if (do_submit) {
          tryCatch(
            {
              R_result <- job$run()
              jobres <- list(
                job = job,
                summary = list(R = R_result)
              )
              saveRDS(jobres, job_estimateR_resultpath)
            },
            error = function(e) {
              jobres <- list(
                job = job,
                error = e
              )
              saveRDS(jobres, job_estimateR_resultpath)
            }
          )
        }
        return(data.frame(
          name = job$job_name,
          submission = tar_name(),
          time = lubridate::now(),
          exists = length(job_estimateR_result)!=0,
          up_to_date = FALSE,
          failed = job_estimateR_Failed,
          needs_run = TRUE,
          submitted = do_submit
        ))
      }
    },
    pattern = map(
      jobs_estimateR_valid,
      job_estimateR_resultpath,
      job_estimateR_result,
      job_estimateR_UpToDate,
      job_estimateR_Failed
    ),
    #cue = tar_cue(mode = "always"),
    iteration = "vector"
  )
)

target_job_submission_local <- function(job, job_result, job_UpToDate,
                                        job_failed, job_state, local_submit,
                                        result_path){
  if (job_UpToDate && job_state=="successful") {
    return(data.frame(
      tar_name = job$job_target_name,
      name = job$job_name,
      submission = tar_name(),
      time = lubridate::now(),
      exists = length(job_result)!=0,
      up_to_date = TRUE,
      result = !job_failed,
      needs_run = FALSE,
      submitted = FALSE
    ))
  } else {
    if (local_submit) {
      job_res <- EpiSewer::run(job)
      saveRDS(job_res, result_path)
    }
    return(data.frame(
      tar_name = job$job_target_name,
      name = job$job_name,
      submission = tar_name(),
      time = lubridate::now(),
      exists = length(job_result)!=0,
      up_to_date = FALSE,
      result = NA,
      queued = FALSE,
      needs_run = TRUE,
      submitted = local_submit
    ))
  }
}
