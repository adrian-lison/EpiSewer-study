# Robust real-time estimation of pathogen transmission dynamics from wastewater

Adrian Lison (1,2), 
Rachel E. McLeod (3), 
Jana S. Huisman (4), 
James D. Munday (1,2),
Christoph Ort (3), 
Timothy R. Julian (3,5,6), 
Tanja Stadler (1,2)

(1) ETH Zurich, Department of Biosystems Science and Engineering, Zurich, Switzerland\
(2) SIB Swiss Institute of Bioinformatics, Lausanne, Switzerland\
(3) Eawag, Swiss Federal Institute of Aquatic Science and Technology, 8600 Dubendorf, Switzerland\
(4) Physics of Living Systems, Massachusetts Institute of Technology, Cambridge, MA, USA\
(5) Swiss Tropical and Public Health Institute, 4123 Allschwil, Switzerland\
(6) University of Basel, 4055 Basel, Switzerland

## Contents of this repository
*Code version: v1.1.0*

This repository contains the code, data, and analysis scripts of the
study "Robust real-time estimation of pathogen transmission dynamics from wastewater".
The code can be used to reproduce the results and figures in the paper.

The repository is structured as follows:
- **code**: Contains utility functions and scripts.
- **data/assumptions**: Contains assumptions about shedding and generation times of pathogens.
- **data/ww_data**: Contains the real-world wastewater data used in this study.
  See the [data README](data/ww_data/README.md) for details.
- **data/sentinella**: Contains open data from Swiss sentinella surveillance. 
- **notebooks**: Contains all analysis scripts in R notebook format.
- **pipelines**: Contains scripts to fit wastewater models in `EpiSewer` using a
  modeling pipeline via the `targets` package.
- **renv**: Contains the configuration of `renv` for the project.

### Setup
The analysis scripts are written as R notebooks and are ideally run in an Rstudio
project. When opening the project, run `renv::restore()` to install all required
R packages (requires the `renv` package).

Note that this study used a [development version of EpiSewer](https://github.com/adrian-lison/EpiSewer/tree/develop). To ensure
reproducibility, `renv` will automatically install this version of the package.
The current stable version of the package can be installed from the [main branch of EpiSewer](https://github.com/adrian-lison/EpiSewer).

### Re-running of pipelines
To rerun the model fitting, you must first install the stan inference 
engine, see [the cmdstanr vignette](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
for help.
In particular for the real-time study, rerunning all models will 
require significant computational resources, ideally a high-performance cluster. 
The provided `targets` pipeline supports parallelization via the crew package.