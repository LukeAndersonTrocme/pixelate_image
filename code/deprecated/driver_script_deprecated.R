#!/usr/bin/env Rscript

# Load required libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools)

source("utils.R")

# Create a parser
p <- arg_parser("Pixelate an image")

# Add command line arguments
p <- add_argument(p, "input_file", help = "Name of input image file")
p <- add_argument(p, "output_file", help = "Base name of output image file")
p <- add_argument(p, "--verbose", help = "Print stuff", flag = TRUE)
p <- add_argument(p, "--exportRDS", help = "Export ggplot as RDS for downstream processing", flag = TRUE)
p <- add_argument(p, "--resolution", help = "Decrease input image resolution", default = 1e3)
p <- add_argument(p, "--n", help = "Number of gridpoints in each direction", default = 100)
p <- add_argument(p, "--gradient_start", help = "Color gradient start", default = "grey20")
p <- add_argument(p, "--gradient_end", help = "Color gradient end", default = "grey80")
p <- add_argument(p, "--breaks", help = "The number of breaks in color scale", default = 7)
p <- add_argument(p, "--geom", help = "Geometry type (raster, polygon, point, ...)", default = "raster")
p <- add_argument(p, "--height", help = "Output image height in inches", default = 7)
p <- add_argument(p, "--width", help = "Output image width in inches", default = 7)
p <- add_argument(p, "--dpi", help = "Output image dpi", default = 300)


# Parse the command line arguments
argv <- parse_args(p)

print("Welcome to Pixelater, beep boop.")
print(paste("Input file :", argv$input_file))
if (argv$verbose) print(argv)

# Generate pixelated image
output_image <- generate_pixelated_image(argv)

# Save the output image
save_output_image(output_image, argv)

# Save ggplot object as RDS if requested
save_ggplot_as_rds(output_image, argv)