# ------------------ ARA Werdhoelzli group ----
# here, either Monday and Wednesday, or Tuesday and Thursday are skipped

subsampling_targets_group_werdhoelzli <- list(
  tar_target(
    subsampling,
    list(
      list(
        type = "5 days per week",
        subtype = "(Monday|Tuesday)+(Wednesday|Thursday)+Friday+Saturday+Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), c("Wednesday", "Thursday"), "Friday", "Saturday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday)+(Wednesday|Thursday)+Friday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), c("Wednesday", "Thursday"), "Friday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday)+(Wednesday|Thursday)+Saturday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), c("Wednesday", "Thursday"), "Saturday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday)+(Wednesday|Thursday)+Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), c("Wednesday", "Thursday"), "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday) + Friday + Saturday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), "Friday", "Saturday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Wednesday|Thursday) + Friday + Saturday",
        subsampling_f = subsample_wdays_f(
          list(c("Wednesday", "Thursday"), "Friday", "Saturday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday) + Friday + Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), "Friday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Wednesday|Thursday) + Friday + Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Wednesday", "Thursday"), "Friday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Monday|Tuesday) + Saturday + Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Monday", "Tuesday"), "Saturday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Wednesday|Thursday) + Saturday + Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Wednesday", "Thursday"), "Saturday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Friday + Saturday + Sunday",
        subsampling_f = subsample_wdays_f(
          list("Friday", "Saturday", "Sunday")
        )
      ),
      list(
        type = "1 day per week",
        subtype = "(Monday|Tuesday)",
        subsampling_f = subsample_wdays_f(list(c("Monday", "Tuesday")))
      ),
      list(
        type = "1 day per week",
        subtype = "(Tuesday|Wednesday)",
        subsampling_f = subsample_wdays_f(list(c("Tuesday", "Wednesday")))
      ),
      list(
        type = "1 day per week",
        subtype = "(Wednesday|Thursday)",
        subsampling_f = subsample_wdays_f(list(c("Wednesday", "Thursday")))
      ),
      list(
        type = "1 day per week",
        subtype = "Friday",
        subsampling_f = subsample_wdays_f(list("Friday"))
      ),
      list(
        type = "1 day per week",
        subtype = "Saturday",
        subsampling_f = subsample_wdays_f(list("Saturday"))
      ),
      list(
        type = "1 day per week",
        subtype = "Sunday",
        subsampling_f = subsample_wdays_f(list("Sunday"))
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Monday|Tuesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Monday", "Tuesday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Monday|Tuesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Monday", "Tuesday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Tuesday|Wednesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Tuesday", "Wednesday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Tuesday|Wednesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Tuesday", "Wednesday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Wednesday|Thursday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Wednesday", "Thursday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Wednesday|Thursday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Wednesday", "Thursday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Friday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Friday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Friday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Friday"))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Saturday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Saturday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Saturday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Saturday"))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Sunday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Sunday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Sunday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Sunday"))(dates) & week_odd(dates)
        }
      )
    )
  )
)

# ------------------ STEP Aire group ----
# here, either Wednesday and Friday, or Thursday and Saturday are skipped

subsampling_targets_group_aire <- list(
  tar_target(
    subsampling,
    list(
      list(
        type = "5 days per week",
        subtype = "Monday+Tuesday+(Wednesday|Thursday)+(Friday|Saturday)+Sunday",
        subsampling_f = subsample_wdays_f(
          list("Monday", "Tuesday", c("Wednesday", "Thursday"), c("Friday", "Saturday"), "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Monday+(Wednesday|Thursday)+(Friday|Saturday)",
        subsampling_f = subsample_wdays_f(
          list("Monday", c("Wednesday", "Thursday"), c("Friday", "Saturday"))
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Tuesday+(Wednesday|Thursday)+(Friday|Saturday)",
        subsampling_f = subsample_wdays_f(
          list("Tuesday", c("Wednesday", "Thursday"), c("Friday", "Saturday"))
        )
      ),
      list(
        type = "3 days per week",
        subtype = "(Wednesday|Thursday)+(Friday|Saturday)+Sunday",
        subsampling_f = subsample_wdays_f(
          list(c("Wednesday", "Thursday"), c("Friday", "Saturday"), "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Tuesday+(Friday|Saturday)+Sunday",
        subsampling_f = subsample_wdays_f(
          list("Tuesday", c("Friday", "Saturday"), "Sunday")
        )
      ), 
      list(
        type = "3 days per week",
        subtype = "Tuesday+(Wednesday|Thursday)+Sunday",
        subsampling_f = subsample_wdays_f(
          list("Tuesday", c("Wednesday", "Thursday"), "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Monday+Tuesday+(Wednesday|Thursday)",
        subsampling_f = subsample_wdays_f(
          list("Monday", "Tuesday", c("Wednesday", "Thursday"))
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Monday+Tuesday+(Friday|Saturday)",
        subsampling_f = subsample_wdays_f(
          list("Monday", "Tuesday", c("Friday", "Saturday"))
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Monday+Tuesday+Sunday",
        subsampling_f = subsample_wdays_f(
          list("Monday", "Tuesday", "Sunday")
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Sunday+Monday+(Wednesday|Thursday)",
        subsampling_f = subsample_wdays_f(
          list("Sunday", "Monday", c("Wednesday", "Thursday"))
        )
      ),
      list(
        type = "3 days per week",
        subtype = "Sunday+Monday+(Friday|Saturday)",
        subsampling_f = subsample_wdays_f(
          list("Sunday", "Monday", c("Friday", "Saturday"))
        )
      ),
      list(
        type = "1 day per week",
        subtype = "Monday",
        subsampling_f = subsample_wdays_f(list("Monday"))
      ),
      list(
        type = "1 day per week",
        subtype = "Tuesday",
        subsampling_f = subsample_wdays_f(list("Tuesday"))
      ),
      list(
        type = "1 day per week",
        subtype = "(Wednesday|Thursday)",
        subsampling_f = subsample_wdays_f(list(c("Wednesday", "Thursday")))
      ),
      list(
        type = "1 day per week",
        subtype = "(Thursday|Friday)",
        subsampling_f = subsample_wdays_f(list(c("Thursday", "Friday")))
      ),
      list(
        type = "1 day per week",
        subtype = "(Friday|Saturday)",
        subsampling_f = subsample_wdays_f(list(c("Friday", "Saturday")))
      ),
      list(
        type = "1 day per week",
        subtype = "Sunday",
        subsampling_f = subsample_wdays_f(list("Sunday"))
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Monday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Monday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Monday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Monday"))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Tuesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Tuesday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Tuesday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Tuesday"))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Wednesday|Thursday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Wednesday", "Thursday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Wednesday|Thursday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Wednesday", "Thursday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Thursday|Friday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Thursday", "Friday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Thursday|Friday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Thursday", "Friday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Friday|Saturday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Friday", "Saturday")))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Friday|Saturday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list(c("Friday", "Saturday")))(dates) & week_odd(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Sunday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Sunday"))(dates) & week_even(dates)
        }
      ),
      list(
        type = "1 day per 2 weeks",
        subtype = "Other Sunday",
        subsampling_f = function(dates) {
          subsample_wdays_f(list("Sunday"))(dates) & week_odd(dates)
        }
      )
    )
  )
)

# ------------------ CDA Lugano group ----
# here, either Tuesday and Thursday, or Wednesday and Friday are skipped