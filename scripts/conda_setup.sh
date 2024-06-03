#!/bin/bash

# Create a new conda environment with R
conda create -y -n pmc r-essentials r-base

# Activate the new environment
source activate pmc

# Install required R packages
Rscript -e 'options(repos = list(CRAN = "https://cloud.r-project.org/")); install.packages(c("tidyverse", "xml2", "stringr", "parallel", "pbapply"))'

# Save the environment configuration
conda env export > pmc.yaml
