
##################
##################
og_grid_liner <- function(inputRDS, output_file, height, width, pixelate, nx, ny, start_density, density_step_size, pattern_list) {
  gb <- ggplot_build(inputRDS)
  dat <- gb$data[[1]]
  dat$my_group <- paste0(dat$group, dat$subgroup)

  meta_data <- dat %>% distinct(fill, my_group, level) %>% dplyr::rename(id = my_group)

  polys <- SpatialPolygons(lapply(unique(dat$my_group), function(x) {
    pts <- dat[dat$my_group == x,]
    Polygons(list(Polygon(as.matrix(data.frame(x=pts$x, y=pts$y)))), as.character(x))
  }))

  polys_dat <- 
    SpatialPolygonsDataFrame(polys, 
                             data.frame(id=sapply(slot(polys, "polygons"), slot, "ID"),
                                        row.names=sapply(slot(polys, "polygons"), slot, "ID"),
                                        stringsAsFactors=FALSE)) %>% 
    sf::st_as_sf() %>%
    left_join(meta_data, by = "id") %>%
    arrange(level)

  poly <- polys_dat %>% st_as_sf(as_points = FALSE, merge = TRUE) %>% mutate(col = as.numeric(level)) 

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

compare_grid_liner_functions <- function(gg_pixelated_image, height, width, pixelate, nx, ny, start_density, density_step_size, pattern_list) {
  
  cat("Comparing process_grid_liner and og_grid_liner...\n")
  
  # process_grid_liner steps
  gb1 <- ggplot_build(gg_pixelated_image)
  dat1 <- gb1$data[[1]]
  dat1$my_group <- paste0(dat1$group, dat1$subgroup)
  meta_data1 <- create_metadata(dat1)
  polys1 <- generate_spatial_polygons(dat1)
  polys_dat1 <- generate_spatial_polygons_data_frame(polys1, meta_data1)
  poly1 <- polys_dat1 %>% st_as_sf(as_points = FALSE, merge = TRUE) %>% mutate(col = as.numeric(level))
  
  # og_grid_liner steps
  gb2 <- ggplot_build(gg_pixelated_image)
  dat2 <- gb2$data[[1]]
  dat2$my_group <- paste0(dat2$group, dat2$subgroup)
  meta_data2 <- dat2 %>% distinct(fill, my_group, level) %>% dplyr::rename(id = my_group)
  polys2 <- SpatialPolygons(lapply(unique(dat2$my_group), function(x) {
    pts <- dat2[dat2$my_group == x,]
    Polygons(list(Polygon(as.matrix(data.frame(x=pts$x, y=pts$y)))), as.character(x))
  }))
  polys_dat2 <- SpatialPolygonsDataFrame(polys2, 
                                         data.frame(id=sapply(slot(polys2, "polygons"), slot, "ID"),
                                                    row.names=sapply(slot(polys2, "polygons"), slot, "ID"),
                                                    stringsAsFactors=FALSE)) %>% 
    sf::st_as_sf() %>%
    left_join(meta_data2, by = "id") %>%
    arrange(level)
  poly2 <- polys_dat2 %>% st_as_sf(as_points = FALSE, merge = TRUE) %>% mutate(col = as.numeric(level))
  
  # Compare results
  cat("Comparing meta_data...\n")
  print(identical(meta_data1, meta_data2))
  
  cat("Comparing polys...\n")
  print(identical(polys1, polys2))
  
  cat("Comparing polys_dat...\n")
  print(identical(polys_dat1, polys_dat2))
  
  cat("Comparing poly...\n")
  print(identical(poly1, poly2))

  cat("Comparison completed.\n")
}




# Function to generate pattern layers
generate_pattern_layers <- function(poly, start_density, density_step_size, pattern_list) {
  layer_overlap <- list()
  size <- start_density
  j <- 1

  for (layer in unique(poly$col)) {
    pat <- pattern_list[[j]]
    l <- filter(poly, col == layer)
    if (nrow(l) < 1) {
      next
    }

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
    if (j > length(pattern_list)) {
      j <- 1
    }
  }

  do.call(rbind, layer_overlap)
}

# Function to save the final plot
save_final_plot <- function(all_layers, output_file, height, width) {
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