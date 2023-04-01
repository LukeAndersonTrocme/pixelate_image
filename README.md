```                                                                                                                                                                 
                                                           .---.                                           
_________   _...._     .--.                   __.....__    |   |                     __.....__             
\        |.'      '-.  |__|               .-''         '.  |   |                 .-''         '.           
 \        .'```'.    '..--.              /     .-''"'-.  `.|   |            .|  /     .-''"'-.  `..-,.--.  
  \      |       \     |  |____     ____/     /________\   |   |   __     .' |_/     /________\   |  .-. | 
   |     |        |    |  `.   \  .'    |                  |   |.:--.'. .'     |                  | |  | | 
   |      \      /    .|  | `.  `'    .'\    .-------------|   / |   \ '--.  .-\    .-------------| |  | | 
   |     |\`'-.-'   .' |  |   '.    .'   \    '-.____...---|   `" __ | |  |  |  \    '-.____...---| |  '-  
   |     | '-....-'`   |__|   .'     `.   `.             .'|   |.'.''| |  |  |   `.             .'| |      
  .'     '.                 .'  .'`.   `.   `''-...... -'  '---/ /   | |_ |  '.'   `''-...... -'  | |      
'-----------'             .'   /    `.   `.                    \ \._,\ '/ |   /                   |_|      
                         '----'       '----'                    `--'  `"  `'-'                             
```

A small R script that pixelates images

# parameters

pixelate an image

```
positional arguments:
  input_file            name of input image file
  output_file           base name of output image file

flags:
  -h, --help            show this help message and exit
  -v, --verbose         print stuff

optional arguments:
  -x, --opts            RDS file containing argument values
  -r, --resolution      decrease input image resolution [default: 1000]
  -n, --n               number of gridpoints in each direction
                        [default: 100]
  -g, --gradient_start  color gradient start [default: grey20]
  --gradient_end        color gradient end [default: grey80]
  -b, --breaks          the number of breaks in color scale [default:
                        7]
  --geom                geometry type (raster, polygon, point, ...)
                        [default: raster]
  --height              output image height in inches [default: 7]
  -w, --width           output image width in inches [default: 7]
  -d, --dpi             output image dpi [default: 300]

  ```

# example

default parameters
```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate.jpg
```

# Pixelater
Pixelater is an R package that generates pixelated images from input raster files. It is designed for artists and creative individuals who may not have a deep background in computer science but would like to create unique, pixelated images from their work.

## Installation
Before using Pixelater, you need to install the required libraries. You can do this by running the following code in your R console:

```
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, raster, ggplot2, argparser, gtools, tools)
```

## Overview of arguments
There are two required arguments and several optional arguments:

### Required arguments
```
input_file: Name of the input image file.
output_file: Base name of the output image file.
```
### Optional arguments
```
--verbose: Prints additional information during execution.
--exportRDS: Exports the ggplot object as an RDS file for downstream processing.
--resolution: Decreases the input image resolution (default: 1e3).
--n: Number of grid points in each direction (default: 100).
--gradient_start: Color gradient start (default: "grey20").
--gradient_end: Color gradient end (default: "grey80").
--breaks: Number of breaks in the color scale (default: 7).
--geom: Geometry type for the output image (options: "raster", "polygon", "point"; default: "raster").
--height: Output image height in inches (default: 7).
--width: Output image width in inches (default: 7).
--dpi: Output image dpi (default: 300).
```

## High-level description of functions

The code is organized into a driver script and a set of utility functions:

`driver_script.R`: Handles user arguments and runs the main functions.
`utils.R`: Contains utility functions for generating and saving the pixelated image.

## Key functions
`add_arguments_to_parser`: Adds command line arguments to the parser.
`gplot_data`: Transforms raster data into a data frame for use with ggplot.
`generate_pixelated_image`: Generates the pixelated image based on user arguments.
`create_output_image`: Creates the output image using ggplot.
`save_output_image`: Saves the output image as a file.
`save_ggplot_as_rds`: Saves the ggplot object as an RDS file.
`print_execution_time`: Prints the time taken for the script to execute.
Please refer to the code comments in the driver script and utility functions for more details on how each function works.

![default_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/d3310342796843777fba616d709ee33cb19aee25/misc/R_logo_pixelate.jpg)

custom parameters
```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate_fancy.jpg --n 25 --gradient_start "limegreen" --gradient_end "navyblue"
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/d3310342796843777fba616d709ee33cb19aee25/misc/R_logo_pixelate_fancy.jpg)

```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate_breaks_10.jpg -n 50 --gradient_start "black" --gradient_end "white" --breaks 10
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/ec3c467cd145128bc31d3f9baa10ba1c6024b5ed/misc/R_logo_pixelate_breaks_10.jpg)

```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate_breaks_5.jpg -n 50 --gradient_start "black" --gradient_end "white" --breaks 5
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/ec3c467cd145128bc31d3f9baa10ba1c6024b5ed/misc/R_logo_pixelate_breaks_5.jpg)


```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/r_logo_pix_polygon.jpg --geom "polygon" --breaks 8
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/0c86469e81d6779459fb96def6b124fc214fc3cd/misc/r_logo_pix_polygon.jpg)

```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/r_logo_point.jpg --geom "point" --height 17 --width 17
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/0c86469e81d6779459fb96def6b124fc214fc3cd/misc/r_logo_point.jpg)
