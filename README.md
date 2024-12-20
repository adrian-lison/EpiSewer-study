# Robust real-time estimation of pathogen transmission dynamics from wastewater

Adrian Lison (1,2)

(1) ETH Zurich, Department of Biosystems Science and Engineering, Zurich, Switzerland\
(2) SIB Swiss Institute of Bioinformatics, Lausanne, Switzerland

## Contents of this repository
*Code version: v1.0.0*

This repository contains the code, data, and analysis scripts of the
study "Robust real-time estimation of pathogen transmission dynamics from wastewater".
The code can be used to reproduce the results and figures in the paper.

The repository is structured as follows:
- **code**: Contains utility functions and scripts.
- **data/assumptions**: Contains assumptions about shedding and generation times of pathogens.
- **data/ww_data**: Contains the real-world wastewater data used in this study.
  See the [data README](data/ww_data/README.md) for details.
- **notebooks**: Contains all analysis scripts in R notebook format.
- **pipelines**: Contains scripts to fit wastewater models in `EpiSewer` using a
  modeling pipeline via the `targets` package.
- **renv**: Contains the configuration of `renv` for the project.

### Setup
The analysis scripts are written as R notebooks and are ideally run in an Rstudio
project. When opening the project, run `renv::restore()` to install all required
R packages (requires the `renv` package).

Note that a 
[development branch of EpiSewer](https://github.com/adrian-lison/EpiSewer/tree/shedding_dist_estimate) 
was used for inference from concentration measurements in this study. To ensure
reproducibility, `renv` will automatically install this version of the package.
A stable version of the package can be found on the  
[main branch of EpiSewer](https://github.com/adrian-lison/EpiSewer).

### Running the pipelines
To rerun the model fitting, the stan inference engine must be installed.
See [the cmdstanr vignette](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
for help.

Note that rerunning all model fits, in particular for the real-time study, will 
require extensive computational resources, ideally a high-performance computing
cluster. The provided `targets` pipeline supports parallelization via the crew package. 