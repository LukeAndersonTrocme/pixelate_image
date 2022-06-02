#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools)

start.time <- Sys.time()

# Create a parser
p <- arg_parser("pixelate an image")

# Add command line arguments
p <- add_argument(p, "input_file", help="name of input RDS file")
p <- add_argument(p, "output_file", help="base name of output image files")
p <- add_argument(p, "--verbose", help="print stuff", flag = TRUE)
p <- add_argument(p, "--no_directory", help="use flag if no new folder is needed", flag = TRUE)
p <- add_argument(p, "--increment", help="incrementally superimpose layers", flag = TRUE)
p <- add_argument(p, "--line_width", help="line width of polygons", default=1)
p <- add_argument(p, "--height", help="output image height in inches", default=7)
p <- add_argument(p, "--width", help="output image width in inches", default=7)
p <- add_argument(p, "--dpi", help="output image dpi", default=300)

# Parse the command line arguments
argv <- parse_args(p)

print("Welcome to Separate Layers, beep boop.")

print(paste("Input file :", argv$input_file))

if (argv$verbose) print(argv)

inputRDS <- readRDS(argv$input_file)

if (!argv$no_directory){
  path = tools::file_path_sans_ext(argv$output_file)
  print("creating a new folder to contain output images")
  print(path)
  dir.create(file.path(path), showWarnings = FALSE)
  setwd(file.path(path))
  argv$output_file <- basename(argv$output_file)
}


# build the plot w/o plotting it
gb <- ggplot_build(inputRDS)
dat <- gb$data[[1]]
# rename groups
dat$my_group <- paste0(dat$group,dat$subgroup)

# prep metadata
meta_data <- dat %>% distinct(fill, my_group, level) %>% dplyr::rename(id = my_group)

# make some polygons!
SpatialPolygons(lapply(unique(dat$my_group), function(x) {
  pts <- dat[dat$my_group == x,]
  Polygons(list(Polygon(as.matrix(data.frame(x=pts$x, y=pts$y)))), as.character(x))
})) -> polys

# make a SPDF (add more data to it if you need to)
polys_dat <- 
  SpatialPolygonsDataFrame(polys, 
                           data.frame(id=sapply(slot(polys, "polygons"), slot, "ID"),
                                      row.names=sapply(slot(polys, "polygons"), slot, "ID"),
                                      stringsAsFactors=FALSE)) %>% 
  sf::st_as_sf() %>%
  left_join(meta_data, by = "id") %>%
  arrange(level)

layer_overlap <- list()
for (layer in unique(polys_dat$fill)){
  layer_overlap[[layer]] <-
    polys_dat %>% 
    filter(fill == layer) %>%
    sf::st_intersection(.) %>%
    mutate(inside = n.overlaps %% 2 == 0)
}
all_layers <- do.call(rbind, layer_overlap)


if(!argv$increment){
  for (layer in unique(polys_dat$fill)){
    layer_plot <-
      ggplot() +
      # computationally wasteful, but ensures identical image dimensions
      geom_sf(data = all_layers, 
              aes(geometry=geometry),fill = alpha("white", 0), size = 0) +
      geom_sf(data = layer_overlap[[layer]], 
              aes(geometry=geometry, fill = as.factor(inside)), size = argv$line_width, color = "black")+
      scale_fill_manual(values = c("black",alpha("white", 0)))+
      guides(fill="none")+
      theme_classic() +
      theme(axis.line = element_blank(),
            axis.text = element_blank(),
            axis.title = element_blank(),
            axis.ticks = element_blank(),
            legend.position = "bottom",
            legend.direction = "horizontal")
    
    base = tools::file_path_sans_ext(argv$output_file)
    layer_filename = paste0(base,"_",layer,".jpg")
    ggsave(layer_plot, filename = layer_filename, 
           height = argv$height, width = argv$width)
  }
}

if(argv$increment){
  increment_layers <- list()
  j <- 1
  for (layer in unique(polys_dat$fill)){
    
    increment_layers[[layer]] <- layer_overlap[[layer]]
    new_layers <- do.call(rbind, increment_layers)
    
    layer_plot <-
      ggplot() +
      # computationally wasteful, but ensures identical image dimensions
      geom_sf(data = all_layers, 
              aes(geometry=geometry), fill = alpha("white", 0), size = 0) +
      geom_sf(data = new_layers, 
              aes(geometry=geometry, fill = as.factor(inside)), size = argv$line_width, color = "black")+
      scale_fill_manual(values = c("black",alpha("white", 0)))+
      guides(fill="none")+
      theme_classic() +
      theme(axis.line = element_blank(),
            axis.text = element_blank(),
            axis.title = element_blank(),
            axis.ticks = element_blank(),
            legend.position = "bottom",
            legend.direction = "horizontal")
    
    base = tools::file_path_sans_ext(argv$output_file)
    layer_filename = paste0(base,"_",layer,"_increment_",j,".jpg")
    ggsave(layer_plot, filename = layer_filename, 
           height = argv$height, width = argv$width)
    j <- j + 1
  }
}

print(paste("Output files are saved with the basename :", argv$output_file))

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)