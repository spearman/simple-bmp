# `SimpleBmp`

> Create and write 32-bit RGBA BMP files.

## Installation

    idris --install package.ipkg

Make the package available to Idris with the flag `-p simple-bmp`.

## Usage

Create a 3x3 pixel BMP, fill with pixel data and write to file:
```idris
import SimpleBmp

main : IO ()
main = do
  bmp <- SimpleBmp.newBmp 3 3
  SimpleBmp.setPixel bmp 0 0 (255,0,0,255)
  SimpleBmp.setPixel bmp 0 1 (0,255,0,255)
  SimpleBmp.setPixel bmp 0 2 (0,0,255,255)
  SimpleBmp.setPixel bmp 1 0 (0,255,255,255)
  SimpleBmp.setPixel bmp 1 1 (255,0,255,255)
  SimpleBmp.setPixel bmp 1 2 (255,255,0,255)
  SimpleBmp.setPixel bmp 2 0 (255,255,255,255)
  SimpleBmp.setPixel bmp 2 1 (127,127,127,255)
  SimpleBmp.setPixel bmp 2 2 (0,0,0,255)
  Just () <- SimpleBmp.writeBmpToFile stdout bmp
    | Nothing => error "write bmp failed"
```
Note that pixel data is stored as BGRA in reverse row order, however functions
that get or set pixels work with tuples in RGBA order.
