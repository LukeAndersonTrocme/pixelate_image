#!/usr/bin/env Rscript

# Load packages and source files
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools, sf, stars)
source("utils.R")
source("patternfun.R")

# Function to process the input ggplot object and save the output image
process_image <- function(input_tiff, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi) {
  
  pixelated_image <- generate_pixelated_image_data(input_tiff, resolution)

  generate_ggplot_image(pixelated_image, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width)
}

# Example usage (replace with Shiny app inputs)
geom <- "raster"
resolution <- 10000
n <- 100
breaks <- 8
gradient_start <- "white"
gradient_end <- "black"
height <- 7
width <- 7
dpi <- 300

# List all TIFF files in the ../testing/ directory
input_files <- list.files("../testing/", pattern = "ben.*\\.tiff$", full.names = TRUE)

# Loop through the input files and process each file
for (input_file in input_files) {
  output_file <- paste0(tools::file_path_sans_ext(input_file), "_output.png")
  
  cat("Processing", input_file, "...\n")
  process_image(input_file, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi)
  cat("Finished processing", input_file, "\n")
}

