{------------------------------------------------------------------------------
    SimpleBmp.idr
------------------------------------------------------------------------------}

||| A small library for writing RGBA32 BMP files.

module SimpleBmp

import Debug.Error

import Data.Bits
import Data.Buffer
import Data.IOArray

import Test.Unit.Assertions

%default total

%language ElabReflection -- for Data.Error.error

-------------------------------------------------------------------------------
--  constants                                                                --
-------------------------------------------------------------------------------

bitmapFileHeaderSize : Bits8
bitmapFileHeaderSize = 14 -- bytes
dibHeaderSize        : Bits8
dibHeaderSize        = 40 -- bytes
dibHeaderSizeInt     : Int
dibHeaderSizeInt     = prim__zextB8_Int dibHeaderSize
||| Pixel array starts immediately after the header. This is equal to the
||| combined bitmap file header + dib header sizes.
pixelArrayOffset     : Bits8
pixelArrayOffset     = bitmapFileHeaderSize + dibHeaderSize
pixelArrayOffsetInt  : Int
pixelArrayOffsetInt  = prim__zextB8_Int pixelArrayOffset
pixelArrayOffsetNat  : Nat
pixelArrayOffsetNat  = (fromIntegerNat . prim__zextInt_BigInt)
  pixelArrayOffsetInt

-------------------------------------------------------------------------------
--  datatypes                                                                --
-------------------------------------------------------------------------------

||| 14 byte bitmap file header + 40 byte DIB header.
public export
record Header where
  constructor MkHeader
  fileSize    : Bits32
  pixelWidth  : Bits16
  pixelHeight : Bits16
  headerData  : IOArray Bits8  -- pixelArrayOffset == 54 bytes

||| Combined header and raw image data. Note image data is stored as BGRA
||| pixels in reverse row order.
public export
record Bmp where
  constructor MkBmp
  header    : Header
  imageData : IOArray Bits8

-------------------------------------------------------------------------------
--  functions                                                                --
-------------------------------------------------------------------------------

--
--  private
--

||| 14 byte bitmap file header + 40 byte dib header + 2 bytes padding = 54 byte
||| header (bytes 0x00-0x37). File size (0x02-0x05) and image width and height
||| (0x12-0x19) fields are uninitialized.
newHeaderRaw : IO (IOArray Bits8)
newHeaderRaw = do
  let header_size = prim__zextB8_Int pixelArrayOffset -- convert to Int
  header <- newArray header_size 0x00 -- 54 zero-initialized bytes
  --
  --  bitmap file header: 14 bytes (0x00-0x0D)
  --
  unsafeWriteArray header 0x00 $ the Bits8 0x42   -- 'B'
  unsafeWriteArray header 0x01 $ the Bits8 0x4D   -- 'M'
  -- 0x02-0x05 to be filled in with file size
  -- 0x06-0x09 reserved left as 0x00
  unsafeWriteArray header 0x0A pixelArrayOffset -- 54 (bytes)
  -- 0x0B-0x0D additional bytes for pixel array offset not needed
  --
  --  dib header: 40 bytes (0x0E-0x35)
  --
  unsafeWriteArray header 0x0E dibHeaderSize    -- 40 (bytes)
  -- 0x0F-0x11 additional bytes for dib header size not needed
  -- 0x12-0x19 to be filled in with image width and height (pixels)
  unsafeWriteArray header 0x1A $ the Bits8 1      -- 1 color plane
  -- 0x1B additional byte for color planes not needed
  unsafeWriteArray header 0x1C $ the Bits8 32     -- 32 bpp
  -- 0x1D additional byte for bpp not needed
  -- 0x1E-0x21 compression method 0 == none
  -- 0x22-0x25 size of raw image data left as dummy value 0 for uncompressed bmps
  unsafeWriteArray header 0x26 $ the Bits8 0x13   -- horizontal resolution (2835)
  unsafeWriteArray header 0x27 $ the Bits8 0x0B   -- (2nd byte)
  -- 0x28-0x29 additional bytes for horizontal resolution not needed
  unsafeWriteArray header 0x2A $ the Bits8 0x13   -- vertical resolution (2835)
  unsafeWriteArray header 0x2B $ the Bits8 0x0B   -- (2nd byte)
  -- 0x2C-0x2D additional bytes for vertical resolution not needed
  -- 0x2E-0x31 number of colors in palette left as 0
  -- 0x32-0x35 number important colors used left as 0
  pure header

||| Create an initialized header with the given bits-per-pixel and image
||| dimensions.
headerWithSize : (pixel_width : Bits16) -> (pixel_height : Bits16) -> IO Header
headerWithSize pixel_width pixel_height = do
  let width32            = prim__zextB16_B32 pixel_width
  let height32           = prim__zextB16_B32 pixel_height
  let pixel_array_size   = the Bits32 $ 4 * width32 * height32 -- 4 bytes per pixel
  let header_size        = prim__zextB8_B32 pixelArrayOffset
  let file_size          = header_size + pixel_array_size
  -- reversed because values are little-endian, so the least significant
  -- bytes come first
  let file_size_bytes    = reverse $ b32ToBytes file_size
  let pixel_width_bytes  = reverse $ b16ToBytes pixel_width
  let pixel_height_bytes = reverse $ b16ToBytes pixel_height
  header_array <- newHeaderRaw
  -- 0x02-0x05 file size (bytes)
  unsafeWriteArray header_array 0x02 $ index 0 file_size_bytes
  unsafeWriteArray header_array 0x03 $ index 1 file_size_bytes
  unsafeWriteArray header_array 0x04 $ index 2 file_size_bytes
  unsafeWriteArray header_array 0x05 $ index 3 file_size_bytes
  -- 0x12-0x19 to be filled in with image width and height (pixels)
  unsafeWriteArray header_array 0x12 $ index 0 pixel_width_bytes
  unsafeWriteArray header_array 0x13 $ index 1 pixel_width_bytes
  -- 0x14-0x15 unused width bytes
  unsafeWriteArray header_array 0x16 $ index 0 pixel_height_bytes
  unsafeWriteArray header_array 0x17 $ index 1 pixel_height_bytes
  -- 0x18-0x19 unused height bytes
  pure $ MkHeader file_size pixel_width pixel_height header_array

||| Zero-initialized raw image data (4 * width * height bytes)
newImageDataRaw : (pixel_width : Bits16) -> (pixel_height : Bits16)
  -> IO (IOArray Bits8)
newImageDataRaw pixel_width pixel_height = do
  let width32   = prim__zextB16_B32 pixel_width
  let height32  = prim__zextB16_B32 pixel_height
  let bytes     = 4 * width32 * height32
  newArray (prim__zextB32_Int bytes) 0x00

--
--  public
--

||| Byte offset of given row-major pixel coords into the raw image data.
||| Returns `Nothing` if coordinates are out of bounds.
export
pixelOffset : Bmp -> Int -> Int -> Maybe Int
pixelOffset bmp row col =
  if row < 0 || pixel_height <= row || col < 0 || pixel_width <= col
  then Nothing else Just $ 4 * (pixel_width * (pixel_height - row - 1) + col)
where
  pixel_width  : Int
  pixel_width  = (prim__zextB16_Int . pixelWidth . header) bmp
  pixel_height : Int
  pixel_height = (prim__zextB16_Int . pixelHeight . header) bmp

||| Create a new `Bmp` record with the given dimensions. This will contain an
||| initialized `header` and a zero-initialized pixel array in `imageData`.
export
newBmp : (pixel_width : Bits16) -> (pixel_height : Bits16) -> IO Bmp
newBmp pixel_width pixel_height = do
  header     <- headerWithSize  pixel_width pixel_height
  image_data <- newImageDataRaw pixel_width pixel_height
  pure $ MkBmp header image_data

||| Return the RGBA values for the pixel at the given coordinates. Returns
||| `Nothing` if coordinates are outside of the image boundaries. Note that the
||| bytes are not returned in the same order as they are stored, which is BGRA.
export
covering
getPixel : Bmp -> Int -> Int -> IO (Maybe (Bits8, Bits8, Bits8, Bits8))
getPixel bmp@(MkBmp header image_data) row col = do
  let pixel_offset = pixelOffset bmp row col
  if isNothing pixel_offset then pure Nothing
  else do
    let pixel_offset = fromMaybe (error "unreachable") pixel_offset
    pure $ Just (
      !(unsafeReadArray image_data (pixel_offset + 2)), -- R
      !(unsafeReadArray image_data (pixel_offset + 1)), -- G
      !(unsafeReadArray image_data (pixel_offset + 0)), -- B
      !(unsafeReadArray image_data (pixel_offset + 3))  -- A
    )

||| Write RGBA values into the pixel at the given coordinates. Returns
||| `Nothing` if coordinates are outside of the image boundaries. Note that the
||| byte arguments are not in the same order as they are stored, which is BGRA.
export
covering
setPixel : Bmp -> Int -> Int -> (Bits8, Bits8, Bits8, Bits8) -> IO (Maybe ())
setPixel bmp@(MkBmp header image_data) row col (r, g, b, a) = do
  let pixel_offset = pixelOffset bmp row col
  if isNothing pixel_offset then pure Nothing
  else do
    let pixel_offset = fromMaybe (error "unreachable") pixel_offset
    unsafeWriteArray image_data (pixel_offset + 2) r -- R
    unsafeWriteArray image_data (pixel_offset + 1) g -- G
    unsafeWriteArray image_data (pixel_offset + 0) b -- B
    unsafeWriteArray image_data (pixel_offset + 3) a -- A
    pure $ Just ()

||| Writes `Bmp` to file.
export
writeBmpToFile : File -> Bmp -> IO (Maybe ())
writeBmpToFile file bmp = do
  let file_size  = prim__zextB32_Int $ (fileSize . header) bmp
  let image_size = (fromIntegerNat . prim__zextInt_BigInt) $
    file_size - pixelArrayOffsetInt
  Just buffer <- newBuffer file_size | Nothing => pure Nothing
  for_ (take pixelArrayOffsetNat $ iterate (+1) 0)
    (\i => setByte buffer i !(unsafeReadArray ((headerData . header) bmp) i))
  for_ (take image_size $ iterate (+1) 0)
    (\i => setByte buffer (pixelArrayOffsetInt + i)
      !(unsafeReadArray (imageData bmp) i))
  _ <- writeBufferToFile file buffer file_size
  pure $ Just ()

-------------------------------------------------------------------------------
--  tests                                                                    --
-------------------------------------------------------------------------------

export
test : IO ()
test = do
  bmp <- newBmp 3 3
  assertEquals (pixelOffset bmp 0 0) (Just 24)
  assertEquals (pixelOffset bmp 0 1) (Just 28)
  assertEquals (pixelOffset bmp 0 2) (Just 32)
  assertEquals (pixelOffset bmp 1 0) (Just 12)
  assertEquals (pixelOffset bmp 1 1) (Just 16)
  assertEquals (pixelOffset bmp 1 2) (Just 20)
  assertEquals (pixelOffset bmp 2 0) (Just 0)
  assertEquals (pixelOffset bmp 2 1) (Just 4)
  assertEquals (pixelOffset bmp 2 2) (Just 8)
  assertNothing !(setPixel bmp (-1) (-1) (0x63, 0x62, 0x61, 0x64))
  assertJust !(setPixel bmp 0 0 (0x63, 0x62, 0x61, 0x64))
  assertJust !(setPixel bmp 0 1 (0x2E, 0x2E, 0x2E, 0x2E))
  assertJust !(setPixel bmp 0 2 (0x2E, 0x2E, 0x2E, 0x0A))
  assertJust !(setPixel bmp 1 0 (0x2E, 0x2E, 0x2E, 0x2E))
  assertJust !(setPixel bmp 1 1 (0x2E, 0x2E, 0x2E, 0x2E))
  assertJust !(setPixel bmp 1 2 (0x2E, 0x2E, 0x2E, 0x0A))
  assertJust !(setPixel bmp 2 0 (0x2E, 0x2E, 0x2E, 0x2E))
  assertJust !(setPixel bmp 2 1 (0x2E, 0x2E, 0x2E, 0x2E))
  assertJust !(setPixel bmp 2 2 (0x7A, 0x79, 0x78, 0x0A))
  assertNothing !(setPixel bmp 3 3 (0x63, 0x62, 0x61, 0x64))
  assertJust !(writeBmpToFile stderr bmp)
  pure ()
