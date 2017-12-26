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

--
-- fill_image_data
--
||| Fill 3x3 image data with 9 pixels (36 bytes):
|||
|||     R G B
|||     C Y M
|||     W E K
|||
fillImageData : IOArray Bits8 -> IO ()
fillImageData image_data = do
  -- row 3: 0-11
  unsafeWriteArray image_data 0 0xff
  unsafeWriteArray image_data 1 0xff
  unsafeWriteArray image_data 2 0xff
  unsafeWriteArray image_data 3 0xff

  unsafeWriteArray image_data 4 0x7f
  unsafeWriteArray image_data 5 0x7f
  unsafeWriteArray image_data 6 0x7f
  unsafeWriteArray image_data 7 0xff

  unsafeWriteArray image_data 8 0x00
  unsafeWriteArray image_data 9 0x00
  unsafeWriteArray image_data 10 0x00
  unsafeWriteArray image_data 11 0xff
  -- row 2: 12-23
  unsafeWriteArray image_data 12 0xff
  unsafeWriteArray image_data 13 0xff
  unsafeWriteArray image_data 14 0x00
  unsafeWriteArray image_data 15 0x00

  unsafeWriteArray image_data 16 0x00
  unsafeWriteArray image_data 17 0xff
  unsafeWriteArray image_data 18 0xff
  unsafeWriteArray image_data 19 0xff

  unsafeWriteArray image_data 20 0xff
  unsafeWriteArray image_data 21 0x00
  unsafeWriteArray image_data 22 0xff
  unsafeWriteArray image_data 23 0xff
  -- row 1: 24-36
  unsafeWriteArray image_data 24 0x00
  unsafeWriteArray image_data 25 0x00
  unsafeWriteArray image_data 26 0xff
  unsafeWriteArray image_data 27 0xff

  unsafeWriteArray image_data 28 0x00
  unsafeWriteArray image_data 29 0xff
  unsafeWriteArray image_data 30 0x00
  unsafeWriteArray image_data 31 0xff

  unsafeWriteArray image_data 32 0xff
  unsafeWriteArray image_data 33 0x00
  unsafeWriteArray image_data 34 0x00
  unsafeWriteArray image_data 35 0xff
  -- done
  pure ()


-------------------------------------------------------------------------------
--  main                                                                     --
-------------------------------------------------------------------------------
||| Write example bitmap data to `stdout`.
main : IO ()
main = do
  bmp <- SimpleBmp.newBmp 3 3
  fillImageData $ SimpleBmp.Bmp.imageData bmp
  Just () <- SimpleBmp.writeBmpToFile stdout bmp
    | Nothing => error "write bmp failed"
  pure ()
