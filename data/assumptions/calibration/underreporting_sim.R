wwtp_incidence_sim <- wwtp_incidence |> 
  filter(
    wwtp == "ARA Werdhoelzli", target == "IAV-M",
    datetime >= "2023-08-01", datetime <= "2024-07-31"
  )

wwtp_incidence_sim <- bind_rows(
  wwtp_incidence_sim |> mutate(
    reporting_proportion = 1,
    type = "baseline"
    ),
  wwtp_incidence_sim |> mutate(
    type = "underreporting",
    reporting_proportion = ifelse(datetime >= "2023-12-24", 0.5, 1),
    incidence_per_week = reporting_proportion * incidence_per_week
    )
)

reporting_palette <- c("baseline" = "black", "underreporting" = "#0072B5FF")
date_lim <- as.Date(c("2023-10-30", "2024-04-15"))

# simple plot of the reporting proportion over time
plot_underrep_proportion <- wwtp_incidence_sim |> 
  ggplot(aes(x=datetime, y=reporting_proportion, color = type)) +
  geom_vline(xintercept = as.Date("2023-12-24"), linetype = "dashed", color = "grey") +
  geom_step(linewidth = 1) +
  scale_x_date(expand = c(0,0)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_color_manual(name = "Reporting scenario", values = reporting_palette) +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Reported proportion") + xlab("Date") +
  coord_cartesian(xlim = date_lim, ylim = c(0,1))

# incidence plot
plot_underrep_incidence <- wwtp_incidence_sim |> 
  ggplot(aes(x=datetime, y=incidence_per_week/7, color = type)) +
  geom_vline(xintercept = as.Date("2023-12-24"), linetype = "dashed", color = "grey") +
  geom_step() +
  scale_x_date(expand = c(0,0)) +
  scale_color_manual(name = "Reporting scenario", values = reporting_palette) +
  theme_bw() +
  theme(legend.position = "top") +
  ylab("Reported incidence") + xlab("Date") +
  coord_cartesian(xlim = date_lim)

ww_load_per_case_sim <- bind_rows(
  ww_load_per_case |> mutate(
    reporting_proportion = 1,
    type = "baseline"
  ),
  ww_load_per_case |> mutate(
    type = "underreporting",
    reporting_proportion = ifelse(first_date_isoweek >= "2023-12-24", 0.5, 1),
    load_per_case = load_per_case / reporting_proportion
  )
) |> filter(
  wwtp == "ARA Werdhoelzli", target == "IAV-M"
)

mean_load_per_case_sim <- ww_load_per_case_sim |> 
  filter(first_date_isoweek >= "2023-08-01", first_date_isoweek < "2024-07-31") |> 
  group_by(wwtp, target, type) |> 
  summarize(load_per_case = median(load_per_case, na.rm = T))

plot_underrep_load_per_case <- ww_load_per_case_sim |> 
  filter(
    first_date_isoweek >= "2023-08-01", first_date_isoweek <= "2024-07-31"
    ) |> 
  ggplot(aes(x = first_date_isoweek, y = load_per_case, color = type)) +
  geom_vline(xintercept = as.Date("2023-12-24"), linetype = "dashed", color = "grey") +
  geom_point(shape = 4) +
  geom_hline(data = mean_load_per_case_sim, 
             aes(yintercept = load_per_case, color = type), linetype = "dashed", linewidth = 1) +
  scale_x_date(expand = c(0,0)) +
  theme_bw() +
  scale_y_log10() +
  scale_color_manual(name = "Reporting scenario", values = reporting_palette) +
  theme(legend.position = "top") +
  ylab("Load per infection") + xlab("Date") +
  coord_cartesian(xlim = c(as.Date("2023-08-01"), NA), ylim = c(1e9, 1e11)) +
  coord_cartesian(xlim = date_lim)

# save simulated version with underreporting
write_csv(
  mean_load_per_case_sim |> filter(type == "underreporting"),
  here::here("data", "assumptions", "load_per_case_2023_sim_underreporting.csv")
  )