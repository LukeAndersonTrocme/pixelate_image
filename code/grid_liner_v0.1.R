#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools, sf, stars)
source("~/Documents/pixelate_image/code/patternfun.R")

start.time <- Sys.time()

# Create a parser
p <- arg_parser("pixelate an image")

# Add command line arguments
p <- add_argument(p, "input_file", help="name of input RDS file")
p <- add_argument(p, "output_file", help="base name of output image files")
p <- add_argument(p, "--verbose", help="print stuff", flag = TRUE)
p <- add_argument(p, "--pixelate", help="pixelate the output image", flag = TRUE)

p <- add_argument(p, "--nx", help="IF PIXELATE: number of pixels on x axis", default=25)
p <- add_argument(p, "--ny", help="IF PIXELATE: number of pixels on y axis", default=25)

p <- add_argument(p, "--start_density", help="starting density of hatching (lower is darker)", default=30)
p <- add_argument(p, "--density_step_size", help="density of hatching step size between layers", default=5)
p <- add_argument(p, "--pattern_list", 
                  help="list of patterns used in output image. see https://rpubs.com/dieghernan/559092 for details", 
                  default= c( "horizontal", "vertical", "left2right", "right2left"))


p <- add_argument(p, "--height", help="output image height in inches", default=7)
p <- add_argument(p, "--width", help="output image width in inches", default=7)
p <- add_argument(p, "--dpi", help="output image dpi", default=300)

# Parse the command line arguments
argv <- parse_args(p)

print("Welcome to Grid Liner, beep boop.")

print(paste("Input file :", argv$input_file))

if (argv$verbose) print(argv)

inputRDS <- readRDS(argv$input_file)
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

poly <- polys_dat %>% st_as_sf(as_points = FALSE, merge = TRUE) %>% mutate(col = as.numeric(level)) 

if(argv$pixelate){
  p.st = stars::st_rasterize(poly["col"], nx = argv$nx, ny = argv$ny)
  poly <- st_as_sf(p.st) %>% group_by(col) %>% summarize(geometry = st_union(geometry))
}
layer_overlap <- list()
size <- argv$start_density
j <- 1

for (layer in unique(poly$col)){
  pat <- argv$pattern_list[[j]]
  print(layer)
  l <- filter(poly, col == layer) 
  if(nrow(l)<1){next}
  
  layer_overlap[[layer]] <-
    sf::st_intersection(l) %>%
    mutate(inside = n.overlaps %% 2 == 0) %>% 
    filter(inside == FALSE) %>%
    patternLayer(., 
                 pattern = pat, 
                 cellsize = size, 
                 mode = "sfc") %>% 
    sf::st_as_sf()
  
  size <- size + argv$density_step_size
  j <- j + 1
  if(j > length(argv$pattern_list)){j<-1}
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
        plot.margin = margin(0,0,0,0),
        panel.background = element_rect(fill = "transparent"),
        plot.background = element_rect(fill = "transparent", color = NA))

ggsave(pl, filename = argv$output_file, bg = "transparent", height = argv$height, width = argv$width)