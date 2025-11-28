import PPM
import ProofWidgets.Component.HtmlDisplay

/-!
# PPM Custom Syntax Demo

Demonstrates the unified, elegant syntax for PPM images in Lean 4.

## Primary Syntax: `#ppm`
- Grid (auto dimensions): `#ppm { | red green | | blue white | }`
- Grid (explicit): `#ppm { 2×2: | red green | | blue white | }`
- P3 string: `PPM.fromString! "P3\n2 2\n255\n..."`

## Canvas: `canvas W×H { commands }`

## Operators: ⊕ ⊖ ↔ ↕ ⊞ ⊟
-/

namespace PPM.Examples.CustomSyntax

open PPM

/-! ## Grid Syntax - Auto-Inferred Dimensions

The most elegant form. Dimensions computed from row structure.
-/

-- 2×2 image with named colors
def tiny : Img := #ppm {
  | red   green |
  | blue  white |
}

-- 3×3 color palette
def palette : Img := #ppm {
  | red    green  blue    |
  | yellow cyan   magenta |
  | white  gray   black   |
}

-- 4×4 with hex colors (0xRRGGBB)
def hexPattern : Img := #ppm {
  | 0xFF0000 0x00FF00 0x0000FF 0xFFFF00 |
  | 0x00FFFF 0xFF00FF 0xFFFFFF 0x000000 |
  | 0x808080 0xFFA500 0x800080 0xFFC0CB |
  | 0x404040 0x800000 0x008000 0x000080 |
}

-- Explicit dimensions (validates pixel count)
def explicit : Img := #ppm {
  3×2:
  | red   green blue   |
  | white black yellow |
}

#eval! tiny.width       -- 2
#eval! palette.width    -- 3
#eval! hexPattern.width -- 4
#eval! explicit.width   -- 3

/-! ## P3 String - Copy-Paste from Files

Use `PPM.fromString!` to parse P3 format directly.
-/

def fromP3 : Img := PPM.fromString! "P3
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255"

def withComments : Img := PPM.fromString! "P3
# A test image with comments
3 2
255
255 0 0   0 255 0   0 0 255
255 255 0   0 255 255   255 0 255"

#eval! fromP3.width      -- 2
#eval! withComments.width -- 3

-- Export back to P3 (round-trip!)
#eval! tiny.toP3

/-! ## Color Types

- Named: red, green, blue, white, black, yellow, cyan, magenta, gray, orange, purple, pink, etc.
- Hex: 0xFF0000 (values > 255 parsed as RGB hex)
- RGB: rgb(255, 128, 0)
- Grayscale: 0-255 (e.g., 128 = gray)
-/

def rgbColors : Img := #ppm {
  | rgb(255, 0, 0)   rgb(0, 255, 0)   rgb(0, 0, 255)   |
  | rgb(255, 255, 0) rgb(0, 255, 255) rgb(255, 0, 255) |
}

def grayscaleImg : Img := #ppm {
  | 0   64  128 |
  | 192 224 255 |
}

def extendedColors : Img := #ppm {
  | red    orange yellow lime  |
  | green  teal   cyan   blue  |
  | navy   purple pink   white |
}

def colorLiteral := color! rgb(255, 128, 64)
#eval colorLiteral

#eval! rgbColors.width      -- 3
#eval! grayscaleImg.width   -- 3
#eval! extendedColors.width -- 4

/-! ## Canvas DSL - Procedural Drawing -/

def solidBlue : Img := canvas 20×20 {
  fill blue
}

def redSquare : Img := canvas 30×30 {
  fill black
  rect 5 5 20 20 red
}

def yellowCircle : Img := canvas 40×40 {
  fill black
  circle 20 20 15 yellow
}

def greenEllipse : Img := canvas 50×30 {
  fill black
  ellipse 25 15 20 10 green
}

def whiteBorder : Img := canvas 40×40 {
  fill black
  border 5 5 30 30 2 white
}

#eval! solidBlue.width     -- 20
#eval! redSquare.width     -- 30
#eval! yellowCircle.width  -- 40

/-! ## Gradients -/

def horizGrad : Img := canvas 100×20 {
  hgradient blue red
}

def vertGrad : Img := canvas 20×100 {
  vgradient white black
}

def diagGrad : Img := canvas 50×50 {
  dgradient yellow magenta
}

def radialGrad : Img := canvas 60×60 {
  rgradient white blue
}

#eval! horizGrad.width   -- 100
#eval! radialGrad.width  -- 60

/-! ## Patterns -/

def chessBoard : Img := canvas 64×64 {
  checker 8 white black
}

def colorCheck : Img := canvas 48×48 {
  checker 12 red cyan
}

#eval! chessBoard.width  -- 64

/-! ## Complex Scenes -/

def simpleScene : Img := canvas 80×60 {
  fill cyan           -- Sky
  rect 0 40 80 20 green   -- Grass
  circle 60 15 10 yellow  -- Sun
  rect 20 25 25 20 brown  -- House
  rect 28 35 10 10 white  -- Door
}

def nightScene : Img := canvas 100×100 {
  dgradient navy black
  circle 20 20 15 white        -- Moon
  circle 70 70 25 gray         -- Planet
  border 30 30 40 40 2 cyan    -- Frame
}

#eval! simpleScene.width    -- 80
#eval! nightScene.width     -- 100

/-! ## Image Operators -/

-- Invert: ⊖
def invertedPalette := ⊖palette
#eval! invertedPalette.width  -- 3

-- Flip horizontal: ↔
def flippedH := tiny↔
#eval! flippedH.width         -- 2

-- Flip vertical: ↕
def flippedV := tiny↕

-- Blend: ⊕
def blended := tiny ⊕ tiny
#eval! blended.width          -- 2

/-! ## Image Composition -/

-- Side by side: ⊞
def sideBySide := tiny ⊞ tiny ⊞ tiny
#eval! sideBySide.width   -- 6

-- Stack vertically: ⊟
def stacked := tiny ⊟ tiny
#eval! stacked.height     -- 4

-- Grid composition
def grid2x2 := (tiny ⊞ tiny) ⊟ (tiny ⊞ tiny)
#eval! grid2x2.width      -- 4
#eval! grid2x2.height     -- 4

-- Tile functions
def tiledH := Img.tileH tiny 4
def tiledV := Img.tileV tiny 3
#eval! tiledH.width       -- 8
#eval! tiledV.height      -- 6

-- Scale
def scaled := Img.scale tiny 3
#eval! scaled.width       -- 6
#eval! scaled.height      -- 6

-- Crop
def cropped := Img.crop palette 1 1 2 2
#eval! cropped.width      -- 2
#eval! cropped.height     -- 2

/-! ## Complex Example -/

def tiledChecker : Img :=
  let base := canvas 16×16 { checker 4 white black }
  Img.tileH base 4

#eval! tiledChecker.width  -- 64

def complexArt : Img := canvas 120×120 {
  vgradient navy black      -- Dark gradient
  ellipse 60 80 50 30 gray  -- Ground
  rect 50 40 20 40 purple   -- Building
  rect 55 50 4 8 yellow     -- Windows
  rect 61 50 4 8 yellow
  rect 55 62 4 8 yellow
  rect 61 62 4 8 yellow
  circle 90 25 12 white     -- Moon
}

#eval! complexArt.width   -- 120

/-! ## Infoview Display (ProofWidgets)

Use `#html PPM.display img` to view images inline in the infoview.
-/

-- Hover over these to see the images rendered in the infoview!
#html PPM.display tiny
#html PPM.display palette
#html PPM.display hexPattern
#html PPM.displayScaled chessBoard 4
#html PPM.displayScaled complexArt 2

/-! ## Interactive Canvas

Use `size!(w, h)` marker with `interactiveCanvas` for adjustable dimensions.
The widget shows buttons to change size and tells you what to update in source.
-/

open PPM.Interactive in
def adjustableScene := interactiveCanvas size!(60, 40) fun s =>
  s.fillColor (namedColor "cyan")
  |>.drawRect 0 25 60 15 (namedColor "green")
  |>.drawCircle 45 12 8 (namedColor "yellow")

#html PPM.Interactive.displayInteractive adjustableScene

end PPM.Examples.CustomSyntax

/-
Type-Parameterized Images:
For compile-time dimension checking, use the Image w h type from PPM.Types.
Operations like blend/beside/above enforce dimension constraints at compile time.
Convert to dynamic Img with .toImg for display.
-/
