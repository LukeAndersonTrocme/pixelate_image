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
         height = height, width = width, dpi = dpi, bg = "transparent")

  return(output_image)
}

# Function to process the input ggplot object and save the output image
process_image <- function(input_tiff, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width, dpi) {
  pixelated_image <- generate_pixelated_image_data(input_tiff, resolution)
  gg_pixelated_image <- generate_ggplot_image(pixelated_image, output_file, geom, resolution, n, breaks, gradient_start, gradient_end, height, width)
  
  return(gg_pixelated_image)
}






###########
## GRID  ##
## LINER ##
###########

# Function to create metadata
create_metadata <- function(dat) {
  dat %>%
    distinct(fill, my_group, level) %>%
    dplyr::rename(id = my_group)
}

# Function to generate SpatialPolygons
generate_spatial_polygons <- function(dat) {
  SpatialPolygons(lapply(unique(dat$my_group), function(x) {
    pts <- dat[dat$my_group == x,]
    Polygons(list(Polygon(as.matrix(data.frame(x = pts$x, y = pts$y)))), as.character(x))
  }))
}

# Function to generate SpatialPolygonsDataFrame
generate_spatial_polygons_data_frame <- function(polys, meta_data) {
  SpatialPolygonsDataFrame(polys,
                           data.frame(id = sapply(slot(polys, "polygons"), slot, "ID"),
                                      row.names = sapply(slot(polys, "polygons"), slot, "ID"),
                                      stringsAsFactors = FALSE)) %>%
    sf::st_as_sf() %>%
    left_join(meta_data, by = "id") %>%
    arrange(level)
}

process_grid_liner <- function(gg_pixelated_image, output_file, height, width, pixelate=FALSE, nx, ny, start_density, density_step_size, pattern_list) {
  gb <- ggplot_build(gg_pixelated_image)
  dat <- gb$data[[1]]
  dat$my_group <- paste0(dat$group, dat$subgroup)

  meta_data <- create_metadata(dat)
  polys <- generate_spatial_polygons(dat)
  polys_dat <- generate_spatial_polygons_data_frame(polys, meta_data)
  poly <- polys_dat %>% st_as_sf(as_points = FALSE, merge = TRUE) %>% mutate(col = as.numeric(level))

  og_plotter(poly, output_file, height, width, pixelate, nx, ny, start_density, density_step_size, pattern_list)
}

og_plotter <- function(poly, output_file, height, width, pixelate, nx, ny, start_density, density_step_size, pattern_list) {
  if (pixelate) {
    p.st = stars::st_rasterize(poly["col"], nx = nx, ny = ny)
    poly <- st_as_sf(p.st) %>% group_by(col) %>% summarize(geometry = st_union(geometry))
  }
  layer_overlap <- list()
  size <- start_density
  j <- 1

  for (layer in unique(poly$col)) {
    pat <- pattern_list[[j]]
    l <- filter(poly, col == layer) 
    if(nrow(l) < 1) {next}
    
    layer_overlap[[layer]] <-
      sf::st_intersection(l) %>%
      mutate(inside = n.overlaps %% 2 == 0) %>% 
      filter(inside == FALSE) %>%
      patternLayer(., 
                   pattern = pat, 
                   cellsize = size, 
                   mode = "sfc") %>% 
      sf::st_as_sf()
    
    size <- size + density_step_size
    j <- j + 1
    if(j > length(pattern_list)) {j <- 1}
  }
  all_layers <- do.call(rbind, layer_overlap)

  pl <-
    ggplot() + 
    geom_sf(data = all_layers) +
    theme_classic() +
    theme(axis.line = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          axis.ticks = element_blank(),
          plot.margin = margin(0, 0, 0, 0),
          panel.background = element_rect(fill = "transparent"),
          plot.background = element_rect(fill = "transparent", color = NA))

  ggsave(pl, filename = output_file, bg = "transparent", height = height, width = width)
}