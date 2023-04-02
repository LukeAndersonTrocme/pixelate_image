#!/usr/bin/env Rscript

# Load packages and source files
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, gtools, tools, sf, stars, parallel)
source("utils.R")
source("patternfun.R")

# Set the number of cores to use for parallel processing (default is 4)
n_cores <- 4

# Function to process each file in parallel
process_files <- function(input_tiff, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi, pixelate, nx, ny, start_density, density_step_size, pattern_list) {
  
  output_file_image <- paste0(tools::file_path_sans_ext(input_tiff), "_output_image.png")
  output_file_grid_liner <- paste0(tools::file_path_sans_ext(input_tiff), "_output_grid_liner.png")
  
  cat("Processing", input_tiff, "...\n")

  gg_pixelated_image <- process_image(input_tiff, output_file_image, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi)
  
  ggsave(gg_pixelated_image, filename = output_file_image,
         height = height, width = width, bg = "transparent", dpi = dpi)

  process_grid_liner(gg_pixelated_image, output_file_grid_liner, height, width, pixelate, nx, ny, start_density, density_step_size, pattern_list)
  cat("Finished processing", input_tiff, "\n")
}

# List all TIFF files in the ../testing/ directory
input_files <- list.files("../testing/input/", pattern = "ben.*\\.tiff$", full.names = TRUE)

# Example usage (replace with Shiny app inputs)
geom <- "polygon" # "raster" or "point" or "polygon"
resolution <- 10000
n <- 100
breaks <- 8
gradient_start <- "white"
gradient_end <- "black"
height <- 7
width <- 7
dpi <- 300
pixelate <- FALSE
nx <- 100
ny <- 100
start_density <- 10
density_step_size <- 5
pattern_list <- c( "horizontal", "vertical", "left2right", "right2left")

# Use mclapply to process the files in parallel
mclapply(input_files, process_files, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi, pixelate, nx, ny, start_density, density_step_size, pattern_list, mc.cores = n_cores)