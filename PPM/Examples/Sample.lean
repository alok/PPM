import PPM
-- import ProofWidgets.Component.HtmlDisplay  -- TODO: Fix ProofWidgets compatibility

namespace PPM.Examples

open PPM

/-- Solid color image created programmatically. -/
def solidRed : Img :=
  Img.solid 10 10 (RGB16.ofNats 255 0 0)

/-- Another solid color for testing. -/
def solidGreen : Img :=
  Img.solid 5 5 (RGB16.ofNats 0 255 0)

/-- Gradient image using `mapIdx` to visualize coordinates. -/
def gradient : Img := Id.run do
  let base := Img.solid 256 256 (RGB16.ofNats 0 0 0)
  base.mapIdx fun row col _ =>
    RGB16.ofNats col.val row.val 128

/-- Simple 2×2 test image using P3 format. -/
def small : Img := (PPM.fromString "
P3
# A simple 2x2 image
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255
").toOption.get!

/-- Test image without magic number. -/
def noMagic : Img := (PPM.fromString "
# No P3 magic number
2 2
255
255 255 255   0 0 0
128 128 128   64 64 64
").toOption.get!

/-- Test image with implicit maxVal (255). -/
def defaultMaxVal : Img := (PPM.fromString "
2 2
255 0 0   0 255 0
0 0 255   255 255 0
").toOption.get!

/-- Small 2×2 inline PPM image. Comments are supported.
    Uses multi-line string literals. -/
def inlineSmall : Img := PPM.fromString! "
P3
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255
"

/-- Inline image that includes a comment line in the PPM payload. -/
def inlineWithComment : Img := PPM.fromString! "
P3
# single pixel comment
1 1
255
255 255 255
"

-- Test basic operations for programmatic images.
#eval! solidRed.width  -- Should be 10
#eval! solidRed.height -- Should be 10
#eval! solidRed.maxVal -- Should be 255

-- Test basic operations for parsed images.
#eval! small.width  -- Should be 2
#eval! small.height -- Should be 2
#eval! small.maxVal -- Should be 255

-- Test pixel access.
-- Note: Using explicit proofs since small dimensions are runtime values
#eval! small.get ⟨0, by native_decide⟩ ⟨0, by native_decide⟩  -- Should be red
#eval! small.get ⟨0, by native_decide⟩ ⟨1, by native_decide⟩  -- Should be green
#eval! small.get ⟨1, by native_decide⟩ ⟨0, by native_decide⟩  -- Should be blue
#eval! small.get ⟨1, by native_decide⟩ ⟨1, by native_decide⟩  -- Should be white

-- Type-check a few inline constructions.
#check PPM.fromString "
# Comment line
2 2
255 0 0   0 255 0
0 0 255   255 255 0
"
#check inlineSmall.width
#check inlineSmall.height
#check inlineSmall.maxVal
#check inlineWithComment.maxVal

-- Preview in Infoview using ProofWidgets' HtmlDisplay.
-- You can adjust the pixel size (last arg) for a larger view.
-- #html (PPM.Img.toHtmlGrid small 16)  -- TODO: Fix ProofWidgets compatibility

end PPM.Examples
