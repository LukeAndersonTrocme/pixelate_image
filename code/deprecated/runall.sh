#!/bin/bash

# Change the directory to the location of the driver script and utils.R
cd /Users/luke/Documents/pixelate_image/code

# Check if required R libraries are installed
echo "Checking if required R libraries are installed..."
Rscript -e 'if (!require("pacman")) install.packages("pacman"); pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools)' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Required R libraries are installed."
else
    echo "Error: Failed to install required R libraries. Please check your R installation and try again."
    exit 1
fi

# Run the driver script with the specified input file
Rscript driver_script.R \
../testing/benBlack \
../testing/benBlack_pixelated.png
