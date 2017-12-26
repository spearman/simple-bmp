# `SimpleBmp`

> Create and write 32-bit RGBA BMP files.

## Usage

Create a 3x3 pixel BMP, fill with pixel data and write to file:
```idris
  bmp <- create_bmp 3 3
  fill_image_data $ image_data bmp
  Just () <- write_bmp stdout bmp | Nothing => error "write bmp failed"
```
where `fill_image_data : IOArray Bits8 -> IO ()` is an `IO` action that sets
individual bytes in the raw pixel array. Note that pixel data is stored as BGRA
in reverse row order.
