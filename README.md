# pixelate_image
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
  --height              output image height in inches [default: 7]
  -w, --width           output image width in inches [default: 7]
  -d, --dpi             output image dpi [default: 300]
  ```

# example

default parameters
```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate.jpg
```
![default_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/d3310342796843777fba616d709ee33cb19aee25/misc/R_logo_pixelate.jpg)

custom parameters
```
Rscript code/pixelate_image_v0.2.R misc/R_logo.png misc/R_logo_pixelate_fancy.jpg --n 25 --gradient_start "limegreen" --gradient_end "navyblue"
```
![fancy_pixelate](https://github.com/LukeAndersonTrocme/pixelate_image/blob/d3310342796843777fba616d709ee33cb19aee25/misc/R_logo_pixelate_fancy.jpg)
