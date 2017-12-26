{------------------------------------------------------------------------------
    Example.idr
------------------------------------------------------------------------------}
|||  Example: creating a 3x3 BMP image and writing to `stdout`.
module Main

import Debug.Error

import Data.IOArray

import SimpleBmp

%default total

%language ElabReflection -- for Data.Error.error

-------------------------------------------------------------------------------
--  main                                                                     --
-------------------------------------------------------------------------------
||| Write example bitmap data to `stdout`.
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
  pure ()
