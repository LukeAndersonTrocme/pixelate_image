#!/bin/bash

# This driver script was written by Luke Anderson-Trocme
# it summarizes the workflow to pixelate and grid-line a set of images

# SETUP
# these variables define the names and locations of files.

# path to "pixelate"
pixel_dir="/Users/luke/Documents/pixelate_image"
# path to input image
input_dir="/Users/luke/Documents/nick_tiff"
# names of CMYK input images
image_names="benCyan benMagenta benYellow benBlack"
# example suffix for output files
suffix="_lowRes_mid"
# using date to organize directories
time_stamp=$(date +"%F")
# path to output images
output_dir=$pixel_dir/benCMYK_${time_stamp}
# make output directory
mkdir -p $output_dir
echo "files are being written to ${output_dir}"

# move to pixelate directory
cd $pixel_dir

# RUN STUFF
# this part loops over a list of images, and runs the pipeline

# for each image in list of images
for image_name in $image_names;
  do echo $image_name ;
  Rscript code/pixelate_image_v0.3.R \
    $input_dir/$image_name \
    $output_dir/${image_name}${suffix}.jpg \
    --gradient_start grey10 \
    --gradient_end grey90 \
    -n 100 \
    -b 8 \
    --geom polygon \
    -e ;
  Rscript code/grid_liner_v0.1.R \
    $output_dir/${image_name}${suffix}.RDS \
    $output_dir/${image_name}${suffix}.svg \
    --pixelate \
    --nx 30 \
    --ny 30 \
    --start_density 1 \
    --density_step_size 0.7;
  done
