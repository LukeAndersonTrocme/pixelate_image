# pixelate_image
A small R script that pixelates images

# usage

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
  --height              output image height in inches [default: 11]
  -w, --width           output image width in inches [default: 8]
  -d, --dpi             output image dpi [default: 300]
  ```
