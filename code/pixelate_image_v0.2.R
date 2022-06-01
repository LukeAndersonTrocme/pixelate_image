#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, raster, ggplot2, argparser)

start.time <- Sys.time()

# Create a parser
p <- arg_parser("pixelate an image")

# Add command line arguments
p <- add_argument(p, "input_file", help="name of input image file")
p <- add_argument(p, "output_file", help="base name of output image file")
p <- add_argument(p, "--verbose", help="print stuff", flag = TRUE)
p <- add_argument(p, "--resolution", help="decrease input image resolution", default=1e3)
p <- add_argument(p, "--n", help="number of gridpoints in each direction", default= 100)
p <- add_argument(p, "--gradient_start", help="color gradient start", default="grey20")
p <- add_argument(p, "--gradient_end", help="color gradient end", default="grey80")
p <- add_argument(p, "--height", help="output image height in inches", default=7)
p <- add_argument(p, "--width", help="output image width in inches", default=7)
p <- add_argument(p, "--dpi", help="output image dpi", default=300)

# Parse the command line arguments
argv <- parse_args(p)

print("Welcome to Pixelate, beep boop.")

print(paste("The input file you are using is :", argv$input_file))

print("For more info use --verbose, beep boop.")

if (argv$verbose) print(argv)

#' Transform raster as data.frame to be later used with ggplot
#' Modified from rasterVis::gplot

gplot_data <- function(x, maxpixels = 50000)  {
  x <- raster::sampleRegular(x, maxpixels, asRaster = TRUE)
  coords <- raster::xyFromCell(x, seq_len(raster::ncell(x)))
  ## Extract values
  dat <- utils::stack(as.data.frame(raster::getValues(x))) 
  names(dat) <- c('value', 'variable')
  
  dat <- dplyr::as_tibble(data.frame(coords, dat))
  
  if (!is.null(levels(x))) {
    dat <- dplyr::left_join(dat, levels(x)[[1]], 
                            by = c("value" = "ID"))
  }
  dat
}

input <- raster::raster(argv$input_file) %>% 
  gplot_data(., maxpixels = argv$resolution)

input_long_format <- with(input, input[rep(1:nrow(input), value),])

output_image <- 
  input_long_format %>%
  ggplot(., aes(x, y)) +
  stat_density_2d(
    geom = "raster",
    aes(fill = after_stat(density)),
    contour = FALSE,
    n = argv$n
  ) + 
  scale_fill_gradient(low = argv$gradient_start, 
                      high = argv$gradient_end) +
  guides(fill = "none") +
  theme_classic() +
  theme(axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank())

ggsave(output_image, filename = argv$output_file, 
       height = argv$height, width = argv$width)

print(paste("The output file is saved here :", argv$output_file))

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)