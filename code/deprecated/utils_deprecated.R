add_arguments_to_parser <- function(p) {
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
  p
}

gplot_data <- function(x, maxpixels = 50000)  {
  x <- raster::sampleRegular(x, maxpixels, asRaster = TRUE)
  coords <- raster::xyFromCell(x, seq_len(raster::ncell(x)))
  dat <- utils::stack(as.data.frame(raster::getValues(x))) 
  names(dat) <- c('value', 'variable')
  dat <- dplyr::as_tibble(data.frame(coords, dat))
  
  if (!is.null(levels(x))) {
    dat <- dplyr::left_join(dat, levels(x)[[1]], by = c("value" = "ID"))
  }
  dat
}

generate_pixelated_image <- function(argv) {
input <- raster::raster(argv$input_file) %>% gplot_data(maxpixels = argv$resolution)
input_long_format <- with(input, input[rep(1:nrow(input), value),])
create_output_image(input_long_format, argv)
}

create_output_image <- function(input_long_format, argv) {
ggplot(input_long_format, aes(x, y)) +
stat_density_2d(geom = argv$geom,
aes(fill = after_stat(density), size = after_stat(density)),
contour = FALSE,
n = argv$n) +
scale_fill_steps(low = argv$gradient_start, high = argv$gradient_end, n.breaks = argv$breaks) +
scale_size(trans = 'reverse') +
guides(fill = "none", size = "none") +
theme_classic() +
theme_void() +
theme(plot.margin = margin(0,0,0,0),
panel.background = element_rect(fill = "transparent"),
plot.background = element_rect(fill = "transparent", color = NA))
}

save_output_image <- function(output_image, argv) {
ggsave(output_image, filename = argv$output_file, height = argv$height, width = argv$width, dpi = argv$dpi, bg = "transparent")
}

save_ggplot_as_rds <- function(output_image, argv) {
if (argv$exportRDS) {
rds_filename <- paste0(tools::file_path_sans_ext(argv$output_file), ".RDS")
print(paste("Saving ggplot object here :", rds_filename))
saveRDS(output_image, file = rds_filename)
}
}