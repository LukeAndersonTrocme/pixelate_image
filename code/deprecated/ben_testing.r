pacman::p_load(tidyverse, raster, ggplot2, sf, stars, ggpattern, glue)

source("utils.R")

input_file <- "../testing/benBlack.tiff"
output_file <- "../testing/pixelated_benBlack.png"

source("driver_script.R")

pixelate <- TRUE
nx <- 25
ny <- 25
pattern_list <- c("horizontal", "vertical", "left2right", "right2left")
start_density <- 30
density_step_size <- 5
height <- 7
width <- 7
dpi <- 300

process_image(input_file, output_file, pixelate, nx, ny, pattern_list, start_density, density_step_size, height, width, dpi)
