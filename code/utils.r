# Load necessary libraries
library(tidyverse)
library(raster)
library(ggplot2)

# Generate pixelated image data from input file
generate_pixelated_image_data <- function(input_file, resolution) {
  input_raster <- raster::raster(input_file)
  
  # Check if the extent is unknown and set it using raster dimensions if necessary
  if (any(is.na(as.vector(extent(input_raster))))) {
    raster_dim <- dim(input_raster)
    extent(input_raster) <- extent(0, raster_dim[2], 0, raster_dim[1])
  }
  
  sampled_raster <- raster::sampleRegular(input_raster, resolution, asRaster = TRUE)
  
  coords <- raster::xyFromCell(sampled_raster, seq_len(raster::ncell(sampled_raster)))
  data <- utils::stack(as.data.frame(raster::getValues(sampled_raster)))
  names(data) <- c('value', 'variable')
  data <- dplyr::as_tibble(data.frame(coords, data))
  
  if (!is.null(levels(sampled_raster))) {
    data <- dplyr::left_join(data, levels(sampled_raster)[[1]], by = c("value" = "ID"))
  }
  data
}

# Generate ggplot image using pixelated image data
generate_ggplot_image <- function(pixelated_image, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width) {
  
  pixelated_image_long <- with(pixelated_image, pixelated_image[rep(1:nrow(pixelated_image), value),])

  if (geom == "raster") {
    output_image <- ggplot(pixelated_image_long, aes(x, y)) +
      stat_density_2d(geom = geom,
                      aes(fill = after_stat(density)),
                      contour = FALSE,
                      n = n) +
      scale_fill_steps(low = gradient_start, high = gradient_end, n.breaks = breaks) +
      guides(fill = "none") +
      theme_classic() +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
    
  } else if (geom == "point") {
    output_image <- ggplot(pixelated_image_long, aes(x, y)) +
      stat_density_2d(geom = geom,
                      aes(size = after_stat(density)),
                      contour = FALSE,
                      n = n) +
      scale_size(trans = 'reverse') +
      guides(size = "none") +
      theme_classic() +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
    
  } else if (geom == "polygon") {
    output_image <- ggplot(pixelated_image_long, aes(x, y)) +
      stat_density2d_filled(n = n,
                            bins = breaks) +
      scale_fill_grey() +
      guides(fill = "none") +
      theme_classic() +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
    
  } else {
    stop("Invalid geom specified. Please choose 'raster', 'point', or 'polygon'.")
  }

  # Save the ggplot as a PNG file
  ggsave(output_image, filename = output_file,
         height = height, width = width, bg = "transparent")
}
