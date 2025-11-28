import Lean
import PPM.Types
import PPM.Parser

/-!
# PPM Custom Syntax DSL

A unified, elegant syntax for defining PPM images in Lean 4.

## Grid Syntax (Primary)

**Auto-inferred dimensions** (most elegant):
```
image {
  | red   green |
  | blue  white |
}
```

**Explicit dimensions** (validates pixel count):
```
image {
  2×2:
  | red   green |
  | blue  white |
}
```

## P3 String (Copy-Paste from Files)
```
image "P3
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255"
```

## Canvas DSL (Procedural Drawing)
```
canvas 100×100 {
  fill black
  rect 10 10 50 50 red
  circle 50 50 20 yellow
}
```

## Colors
- Named: red, green, blue, white, black, yellow, cyan, magenta, gray, orange, purple, pink, etc.
- RGB: `rgb(255, 128, 0)`
- Hex: `0xFF8000`
- Grayscale: `128` (values 0-255)

## Image Operators
- `⊕` blend two images
- `⊖` invert colors (prefix)
- `↔` flip horizontal (postfix)
- `↕` flip vertical (postfix)
- `⊞` place side by side
- `⊟` stack vertically

## Export
- `img.toP3` - convert to P3 string for round-trip
-/

namespace PPM

open Lean
open Lean.Elab
open Lean.Elab.Term

/-! ## Named Colors -/

/-- Named color palette -/
def namedColor : String → RGB16
  | "red"     => RGB16.ofNats 255 0 0
  | "green"   => RGB16.ofNats 0 255 0
  | "blue"    => RGB16.ofNats 0 0 255
  | "white"   => RGB16.ofNats 255 255 255
  | "black"   => RGB16.ofNats 0 0 0
  | "yellow"  => RGB16.ofNats 255 255 0
  | "cyan"    => RGB16.ofNats 0 255 255
  | "magenta" => RGB16.ofNats 255 0 255
  | "gray"    => RGB16.ofNats 128 128 128
  | "grey"    => RGB16.ofNats 128 128 128
  | "orange"  => RGB16.ofNats 255 165 0
  | "purple"  => RGB16.ofNats 128 0 128
  | "pink"    => RGB16.ofNats 255 192 203
  | "brown"   => RGB16.ofNats 139 69 19
  | "navy"    => RGB16.ofNats 0 0 128
  | "teal"    => RGB16.ofNats 0 128 128
  | "lime"    => RGB16.ofNats 0 255 0
  | "aqua"    => RGB16.ofNats 0 255 255
  | "maroon"  => RGB16.ofNats 128 0 0
  | "olive"   => RGB16.ofNats 128 128 0
  | "silver"  => RGB16.ofNats 192 192 192
  | "gold"    => RGB16.ofNats 255 215 0
  | _         => RGB16.ofNats 0 0 0

/-! ## Image Operations -/

namespace Img

/-- Blend two images by averaging pixels (requires same dimensions) -/
def blend (a b : Img) : Img := Id.run do
  if a.width != b.width || a.height != b.height then
    return a
  let mut pixels : Array RGB16 := Array.mkEmpty (a.width * a.height)
  let aArr := a.toArray
  let bArr := b.toArray
  for i in [0 : a.width * a.height] do
    if h : i < aArr.size then
      if h' : i < bArr.size then
        let pa := aArr[i]'h
        let pb := bArr[i]'h'
        let avg := RGB16.ofNats
          ((pa.r.toNat + pb.r.toNat) / 2)
          ((pa.g.toNat + pb.g.toNat) / 2)
          ((pa.b.toNat + pb.b.toNat) / 2)
        pixels := pixels.push avg
  have hLen : pixels.size = a.width * a.height := by sorry
  Img.ofArray a.width a.height a.maxVal pixels a.hMax hLen

/-- Invert all colors -/
def invert (img : Img) : Img :=
  img.map fun px =>
    let maxv := img.maxVal.toUInt16
    { r := maxv - px.r, g := maxv - px.g, b := maxv - px.b }

/-- Flip image horizontally -/
def flipH (img : Img) : Img := Id.run do
  let mut pixels : Array RGB16 := Array.mkEmpty (img.width * img.height)
  let arr := img.toArray
  for row in [0 : img.height] do
    for col in [0 : img.width] do
      let srcCol := img.width - 1 - col
      let idx := row * img.width + srcCol
      if h : idx < arr.size then
        pixels := pixels.push (arr[idx]'h)
  have hLen : pixels.size = img.width * img.height := by sorry
  Img.ofArray img.width img.height img.maxVal pixels img.hMax hLen

/-- Flip image vertically -/
def flipV (img : Img) : Img := Id.run do
  let mut pixels : Array RGB16 := Array.mkEmpty (img.width * img.height)
  let arr := img.toArray
  for row in [0 : img.height] do
    let srcRow := img.height - 1 - row
    for col in [0 : img.width] do
      let idx := srcRow * img.width + col
      if h : idx < arr.size then
        pixels := pixels.push (arr[idx]'h)
  have hLen : pixels.size = img.width * img.height := by sorry
  Img.ofArray img.width img.height img.maxVal pixels img.hMax hLen

/-- Place two images side by side -/
def beside (a b : Img) : Img := Id.run do
  let newWidth := a.width + b.width
  let newHeight := max a.height b.height
  let mut pixels : Array RGB16 := Array.mkEmpty (newWidth * newHeight)
  let aArr := a.toArray
  let bArr := b.toArray
  let bg := RGB16.ofNats 0 0 0
  for row in [0 : newHeight] do
    for col in [0 : a.width] do
      if row < a.height then
        let idx := row * a.width + col
        if h : idx < aArr.size then pixels := pixels.push (aArr[idx]'h)
        else pixels := pixels.push bg
      else pixels := pixels.push bg
    for col in [0 : b.width] do
      if row < b.height then
        let idx := row * b.width + col
        if h : idx < bArr.size then pixels := pixels.push (bArr[idx]'h)
        else pixels := pixels.push bg
      else pixels := pixels.push bg
  have hMax : 0 < a.maxVal ∧ a.maxVal ≤ 65535 := a.hMax
  have hLen : pixels.size = newWidth * newHeight := by sorry
  Img.ofArray newWidth newHeight a.maxVal pixels hMax hLen

/-- Stack two images vertically (b below a) -/
def above (a b : Img) : Img := Id.run do
  let newWidth := max a.width b.width
  let newHeight := a.height + b.height
  let mut pixels : Array RGB16 := Array.mkEmpty (newWidth * newHeight)
  let aArr := a.toArray
  let bArr := b.toArray
  let bg := RGB16.ofNats 0 0 0
  for row in [0 : a.height] do
    for col in [0 : newWidth] do
      if col < a.width then
        let idx := row * a.width + col
        if h : idx < aArr.size then pixels := pixels.push (aArr[idx]'h)
        else pixels := pixels.push bg
      else pixels := pixels.push bg
  for row in [0 : b.height] do
    for col in [0 : newWidth] do
      if col < b.width then
        let idx := row * b.width + col
        if h : idx < bArr.size then pixels := pixels.push (bArr[idx]'h)
        else pixels := pixels.push bg
      else pixels := pixels.push bg
  have hMax : 0 < a.maxVal ∧ a.maxVal ≤ 65535 := a.hMax
  have hLen : pixels.size = newWidth * newHeight := by sorry
  Img.ofArray newWidth newHeight a.maxVal pixels hMax hLen

/-- Tile an image n times horizontally -/
def tileH (img : Img) (n : Nat) : Img := Id.run do
  if n == 0 then return img
  let mut result := img
  for _ in [1 : n] do
    result := beside result img
  result

/-- Tile an image n times vertically -/
def tileV (img : Img) (n : Nat) : Img := Id.run do
  if n == 0 then return img
  let mut result := img
  for _ in [1 : n] do
    result := above result img
  result

/-- Crop image to given rectangle -/
def crop (img : Img) (x y w h : Nat) : Img := Id.run do
  let newWidth := min w (img.width - x)
  let newHeight := min h (img.height - y)
  let mut pixels : Array RGB16 := Array.mkEmpty (newWidth * newHeight)
  let arr := img.toArray
  for row in [0 : newHeight] do
    for col in [0 : newWidth] do
      let srcIdx := (y + row) * img.width + (x + col)
      if h : srcIdx < arr.size then
        pixels := pixels.push (arr[srcIdx]'h)
  have hLen : pixels.size = newWidth * newHeight := by sorry
  Img.ofArray newWidth newHeight img.maxVal pixels img.hMax hLen

/-- Scale image by integer factor -/
def scale (img : Img) (factor : Nat) : Img := Id.run do
  if factor == 0 then return img
  let newWidth := img.width * factor
  let newHeight := img.height * factor
  let mut pixels : Array RGB16 := Array.mkEmpty (newWidth * newHeight)
  let arr := img.toArray
  for row in [0 : newHeight] do
    for col in [0 : newWidth] do
      let srcRow := row / factor
      let srcCol := col / factor
      let srcIdx := srcRow * img.width + srcCol
      if h : srcIdx < arr.size then
        pixels := pixels.push (arr[srcIdx]'h)
  have hLen : pixels.size = newWidth * newHeight := by sorry
  Img.ofArray newWidth newHeight img.maxVal pixels img.hMax hLen

/-- Convert image to P3 format string (for export/copy-paste) -/
def toP3 (img : Img) : String := Id.run do
  let mut s := s!"P3\n{img.width} {img.height}\n{img.maxVal}\n"
  let arr := img.toArray
  for row in [0 : img.height] do
    for col in [0 : img.width] do
      let idx := row * img.width + col
      if h : idx < arr.size then
        let px := arr[idx]'h
        s := s ++ s!"{px.r.toNat} {px.g.toNat} {px.b.toNat}"
        if col < img.width - 1 then s := s ++ "  "
      if col == img.width - 1 then s := s ++ "\n"
  s

end Img

/-! ## Canvas State for Procedural Drawing -/

/-- Mutable state for procedural canvas drawing operations -/
structure CanvasState where
  /-- Canvas width in pixels -/
  width : Nat
  /-- Canvas height in pixels -/
  height : Nat
  /-- Maximum color value (typically 255) -/
  maxVal : Nat
  /-- Pixel buffer in row-major order -/
  pixels : Array RGB16

namespace CanvasState

private def makePixelArray (n : Nat) (c : RGB16) : Array RGB16 := Id.run do
  let mut arr : Array RGB16 := Array.mkEmpty n
  for _ in [0 : n] do
    arr := arr.push c
  arr

/-- Create a new canvas with given dimensions and background color -/
def create (w h maxVal : Nat) (bg : RGB16 := RGB16.ofNats 0 0 0) : CanvasState :=
  { width := w, height := h, maxVal := maxVal, pixels := makePixelArray (w * h) bg }

/-- Set a single pixel at (px, py) to color c -/
def putPixel (s : CanvasState) (px py : Nat) (c : RGB16) : CanvasState :=
  if px < s.width && py < s.height then
    let idx := py * s.width + px
    { s with pixels := s.pixels.set! idx c }
  else s

/-- Fill the entire canvas with a single color -/
def fillColor (s : CanvasState) (c : RGB16) : CanvasState :=
  { s with pixels := makePixelArray (s.width * s.height) c }

/-- Draw a filled rectangle at (rx, ry) with size (rw, rh) -/
def drawRect (s : CanvasState) (rx ry rw rh : Nat) (c : RGB16) : CanvasState := Id.run do
  let mut state := s
  for dy in [0 : rh] do
    for dx in [0 : rw] do
      state := state.putPixel (rx + dx) (ry + dy) c
  state

/-- Draw a filled circle centered at (cx, cy) with given radius -/
def drawCircle (s : CanvasState) (cx cy radius : Nat) (c : RGB16) : CanvasState := Id.run do
  let mut state := s
  let r2 := radius * radius
  for dy in [0 : radius * 2 + 1] do
    for dx in [0 : radius * 2 + 1] do
      let px := cx + dx - radius
      let py := cy + dy - radius
      let distX := if dx >= radius then dx - radius else radius - dx
      let distY := if dy >= radius then dy - radius else radius - dy
      if distX * distX + distY * distY <= r2 then
        state := state.putPixel px py c
  state

/-- Draw a filled ellipse centered at (cx, cy) with radii (rx, ry) -/
def drawEllipse (s : CanvasState) (cx cy rx ry : Nat) (c : RGB16) : CanvasState := Id.run do
  let mut state := s
  for dy in [0 : ry * 2 + 1] do
    for dx in [0 : rx * 2 + 1] do
      let px := cx + dx - rx
      let py := cy + dy - ry
      let distX := if dx >= rx then dx - rx else rx - dx
      let distY := if dy >= ry then dy - ry else ry - dy
      if distX * distX * ry * ry + distY * distY * rx * rx <= rx * rx * ry * ry then
        state := state.putPixel px py c
  state

/-- Draw a rectangular border (outline) with given thickness -/
def drawBorder (s : CanvasState) (rx ry rw rh thickness : Nat) (c : RGB16) : CanvasState := Id.run do
  let mut state := s
  for t in [0 : thickness] do
    for dx in [0 : rw] do
      state := state.putPixel (rx + dx) (ry + t) c
      state := state.putPixel (rx + dx) (ry + rh - 1 - t) c
  for t in [0 : thickness] do
    for dy in [0 : rh] do
      state := state.putPixel (rx + t) (ry + dy) c
      state := state.putPixel (rx + rw - 1 - t) (ry + dy) c
  state

/-- Draw a line from (x1, y1) to (x2, y2) using Bresenham's algorithm -/
def drawLine (s : CanvasState) (x1 y1 x2 y2 : Nat) (c : RGB16) : CanvasState := Id.run do
  let mut state := s
  let dx := if x2 >= x1 then x2 - x1 else x1 - x2
  let dy := if y2 >= y1 then y2 - y1 else y1 - y2
  let sx : Int := if x1 < x2 then 1 else -1
  let sy : Int := if y1 < y2 then 1 else -1
  let mut err : Int := dx - dy
  let mut px := x1
  let mut py := y1
  for _ in [0 : dx + dy + 1] do
    state := state.putPixel px py c
    if px == x2 && py == y2 then break
    let e2 := 2 * err
    if e2 > -(dy : Int) then
      err := err - dy
      px := if sx > 0 then px + 1 else px - 1
    if e2 < (dx : Int) then
      err := err + dx
      py := if sy > 0 then py + 1 else py - 1
  state

/-- Fill canvas with a horizontal gradient from c1 (left) to c2 (right) -/
def horizGradient (s : CanvasState) (c1 c2 : RGB16) : CanvasState := Id.run do
  let mut state := s
  for py in [0 : s.height] do
    for px in [0 : s.width] do
      let t := if s.width > 1 then px * 255 / (s.width - 1) else 0
      let r := (c1.r.toNat * (255 - t) + c2.r.toNat * t) / 255
      let g := (c1.g.toNat * (255 - t) + c2.g.toNat * t) / 255
      let b := (c1.b.toNat * (255 - t) + c2.b.toNat * t) / 255
      state := state.putPixel px py (RGB16.ofNats r g b)
  state

/-- Fill canvas with a vertical gradient from c1 (top) to c2 (bottom) -/
def vertGradient (s : CanvasState) (c1 c2 : RGB16) : CanvasState := Id.run do
  let mut state := s
  for py in [0 : s.height] do
    let t := if s.height > 1 then py * 255 / (s.height - 1) else 0
    for px in [0 : s.width] do
      let r := (c1.r.toNat * (255 - t) + c2.r.toNat * t) / 255
      let g := (c1.g.toNat * (255 - t) + c2.g.toNat * t) / 255
      let b := (c1.b.toNat * (255 - t) + c2.b.toNat * t) / 255
      state := state.putPixel px py (RGB16.ofNats r g b)
  state

/-- Fill canvas with a diagonal gradient from c1 (top-left) to c2 (bottom-right) -/
def diagGradient (s : CanvasState) (c1 c2 : RGB16) : CanvasState := Id.run do
  let mut state := s
  let maxDist := s.width + s.height - 2
  for py in [0 : s.height] do
    for px in [0 : s.width] do
      let dist := px + py
      let t := if maxDist > 0 then dist * 255 / maxDist else 0
      let r := (c1.r.toNat * (255 - t) + c2.r.toNat * t) / 255
      let g := (c1.g.toNat * (255 - t) + c2.g.toNat * t) / 255
      let b := (c1.b.toNat * (255 - t) + c2.b.toNat * t) / 255
      state := state.putPixel px py (RGB16.ofNats r g b)
  state

/-- Fill canvas with a radial gradient from c1 (center) to c2 (edges) -/
def radialGradient (s : CanvasState) (c1 c2 : RGB16) : CanvasState := Id.run do
  let mut state := s
  let cx := s.width / 2
  let cy := s.height / 2
  let maxDist := (cx * cx + cy * cy : Nat)
  for py in [0 : s.height] do
    for px in [0 : s.width] do
      let dx := if px >= cx then px - cx else cx - px
      let dy := if py >= cy then py - cy else cy - py
      let dist2 := dx * dx + dy * dy
      let t := if maxDist > 0 then (dist2 * 255 / maxDist).min 255 else 0
      let r := (c1.r.toNat * (255 - t) + c2.r.toNat * t) / 255
      let g := (c1.g.toNat * (255 - t) + c2.g.toNat * t) / 255
      let b := (c1.b.toNat * (255 - t) + c2.b.toNat * t) / 255
      state := state.putPixel px py (RGB16.ofNats r g b)
  state

/-- Fill canvas with a checkerboard pattern of given cell size -/
def checkerboard (s : CanvasState) (cellSize : Nat) (c1 c2 : RGB16) : CanvasState := Id.run do
  let mut state := s
  for py in [0 : s.height] do
    for px in [0 : s.width] do
      let cellX := px / cellSize
      let cellY := py / cellSize
      let color := if (cellX + cellY) % 2 == 0 then c1 else c2
      state := state.putPixel px py color
  state

/-- Convert canvas state to an Img (assumes valid maxVal and pixel count) -/
def toImg (s : CanvasState) : Img :=
  have hMax : 0 < s.maxVal ∧ s.maxVal ≤ 65535 := by sorry
  have hLen : s.pixels.size = s.width * s.height := by sorry
  Img.ofArray s.width s.height s.maxVal s.pixels hMax hLen

end CanvasState

/-! ## Syntax Categories -/

/-- Color specification (rgb, hex, named, or grayscale) -/
declare_syntax_cat ppm_color
/-- A single pixel in the image grid -/
declare_syntax_cat ppm_pixel
/-- A row of pixels delimited by pipes -/
declare_syntax_cat ppm_row
/-- A canvas drawing command -/
declare_syntax_cat ppm_cmd

/-! ## Color Syntax -/

-- RGB: rgb(255, 0, 0)
syntax "rgb(" num "," num "," num ")" : ppm_color
-- Hex: 0xFF0000
syntax num : ppm_color
-- Named colors
syntax "red" : ppm_color
syntax "green" : ppm_color
syntax "blue" : ppm_color
syntax "white" : ppm_color
syntax "black" : ppm_color
syntax "yellow" : ppm_color
syntax "cyan" : ppm_color
syntax "magenta" : ppm_color
syntax "gray" : ppm_color
syntax "grey" : ppm_color
syntax "orange" : ppm_color
syntax "purple" : ppm_color
syntax "pink" : ppm_color
syntax "brown" : ppm_color
syntax "navy" : ppm_color
syntax "teal" : ppm_color
syntax "lime" : ppm_color
syntax "aqua" : ppm_color
syntax "maroon" : ppm_color
syntax "olive" : ppm_color
syntax "silver" : ppm_color
syntax "gold" : ppm_color

/-! ## Row Syntax -/

-- A row of colors: | red green blue |
syntax "|" ppm_color+ "|" : ppm_row

/-! ## Canvas Commands -/

syntax "fill" ppm_color : ppm_cmd
syntax "rect" num num num num ppm_color : ppm_cmd
syntax "circle" num num num ppm_color : ppm_cmd
syntax "ellipse" num num num num ppm_color : ppm_cmd
syntax "border" num num num num num ppm_color : ppm_cmd
syntax "line" num num num num ppm_color : ppm_cmd
syntax "pixel" num num ppm_color : ppm_cmd
syntax "hgradient" ppm_color ppm_color : ppm_cmd
syntax "vgradient" ppm_color ppm_color : ppm_cmd
syntax "dgradient" ppm_color ppm_color : ppm_cmd
syntax "rgradient" ppm_color ppm_color : ppm_cmd
syntax "checker" num ppm_color ppm_color : ppm_cmd

/-! ## Top-Level Syntax -/

-- Grid with explicit dimensions: #ppm { 2×2: | red green | | blue white | }
syntax "#ppm" "{" num "×" num ":" ppm_row* "}" : term
-- Grid with auto-inferred dimensions: #ppm { | red green | | blue white | }
syntax "#ppm" "{" ppm_row+ "}" : term

-- Canvas DSL
syntax "canvas" num "×" num "{" ppm_cmd* "}" : term

-- Color literal
syntax "color!" ppm_color : term

/-! ## Image Operators -/

infixl:65 " ⊕ " => Img.blend
prefix:75 "⊖" => Img.invert
postfix:80 "↔" => Img.flipH
postfix:80 "↕" => Img.flipV
infixl:60 " ⊞ " => Img.beside
infixl:60 " ⊟ " => Img.above

/-! ## Elaborators -/

/-- Elaborate a color to RGB16 term -/
private def elabColor (stx : Syntax) : TermElabM (TSyntax `term) := do
  match stx with
  | `(ppm_color| rgb($r:num, $g:num, $b:num)) =>
    `(RGB16.ofNats $r $g $b)
  | `(ppm_color| $n:num) =>
    -- Could be hex (0xRRGGBB) or grayscale (0-255)
    let val := n.getNat
    if val > 255 then
      -- Treat as hex color
      let r := (val >>> 16) &&& 0xFF
      let g := (val >>> 8) &&& 0xFF
      let b := val &&& 0xFF
      `(RGB16.ofNats $(quote r) $(quote g) $(quote b))
    else
      -- Treat as grayscale
      `(RGB16.ofNats $(quote val) $(quote val) $(quote val))
  | `(ppm_color| red) => `(PPM.namedColor "red")
  | `(ppm_color| green) => `(PPM.namedColor "green")
  | `(ppm_color| blue) => `(PPM.namedColor "blue")
  | `(ppm_color| white) => `(PPM.namedColor "white")
  | `(ppm_color| black) => `(PPM.namedColor "black")
  | `(ppm_color| yellow) => `(PPM.namedColor "yellow")
  | `(ppm_color| cyan) => `(PPM.namedColor "cyan")
  | `(ppm_color| magenta) => `(PPM.namedColor "magenta")
  | `(ppm_color| gray) => `(PPM.namedColor "gray")
  | `(ppm_color| grey) => `(PPM.namedColor "grey")
  | `(ppm_color| orange) => `(PPM.namedColor "orange")
  | `(ppm_color| purple) => `(PPM.namedColor "purple")
  | `(ppm_color| pink) => `(PPM.namedColor "pink")
  | `(ppm_color| brown) => `(PPM.namedColor "brown")
  | `(ppm_color| navy) => `(PPM.namedColor "navy")
  | `(ppm_color| teal) => `(PPM.namedColor "teal")
  | `(ppm_color| lime) => `(PPM.namedColor "lime")
  | `(ppm_color| aqua) => `(PPM.namedColor "aqua")
  | `(ppm_color| maroon) => `(PPM.namedColor "maroon")
  | `(ppm_color| olive) => `(PPM.namedColor "olive")
  | `(ppm_color| silver) => `(PPM.namedColor "silver")
  | `(ppm_color| gold) => `(PPM.namedColor "gold")
  | _ => throwError s!"Unknown color: {stx}"

/-- Elaborate color! syntax -/
elab "color!" c:ppm_color : term => do
  let colorStx ← elabColor c
  elabTerm colorStx none

/-- Elaborate image grid syntax -/
elab "#ppm" "{" w:num "×" h:num ":" rows:ppm_row* "}" : term => do
  let width := w.getNat
  let height := h.getNat

  -- Collect all colors from rows
  let mut allColors : Array (TSyntax `term) := #[]
  for row in rows do
    match row with
    | `(ppm_row| | $colors:ppm_color* |) =>
      for c in colors do
        let colorTerm ← elabColor c
        allColors := allColors.push colorTerm
    | _ => throwError "Invalid row syntax"

  let expectedPixels := width * height
  if allColors.size != expectedPixels then
    throwError s!"Expected {expectedPixels} pixels ({width}×{height}), got {allColors.size}"

  let pixelArray ← `(#[$allColors,*])

  let stx ← `(
    let pixels : Array RGB16 := $pixelArray
    have hLen : pixels.size = $(quote width) * $(quote height) := by sorry
    have hMax : 0 < 255 ∧ 255 ≤ 65535 := by decide
    Img.ofArray $(quote width) $(quote height) 255 pixels hMax hLen
  )
  elabTerm stx none

/-- Elaborate image grid with auto-inferred dimensions -/
elab "#ppm" "{" rows:ppm_row+ "}" : term => do
  -- Collect all colors and track row widths
  let mut allColors : Array (TSyntax `term) := #[]
  let mut rowWidths : Array Nat := #[]

  for row in rows do
    match row with
    | `(ppm_row| | $colors:ppm_color* |) =>
      let rowColors := colors
      rowWidths := rowWidths.push rowColors.size
      for c in rowColors do
        let colorTerm ← elabColor c
        allColors := allColors.push colorTerm
    | _ => throwError "Invalid row syntax"

  -- Validate all rows have same width
  if rowWidths.isEmpty then throwError "Empty image"
  let width := rowWidths[0]!
  for w in rowWidths do
    if w != width then
      throwError s!"Row width mismatch: expected {width}, got {w}"

  let height := rowWidths.size
  let pixelArray ← `(#[$allColors,*])

  let stx ← `(
    let pixels : Array RGB16 := $pixelArray
    have hLen : pixels.size = $(quote width) * $(quote height) := by sorry
    have hMax : 0 < 255 ∧ 255 ≤ 65535 := by decide
    Img.ofArray $(quote width) $(quote height) 255 pixels hMax hLen
  )
  elabTerm stx none

/-- Elaborate canvas syntax -/
elab "canvas" w:num "×" h:num "{" cmds:ppm_cmd* "}" : term => do
  let width := w.getNat
  let height := h.getNat

  let mut cmdTerms : Array (TSyntax `term) := #[]
  for cmd in cmds do
    match cmd with
    | `(ppm_cmd| fill $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.fillColor $colorTerm))
    | `(ppm_cmd| rect $rx:num $ry:num $rw:num $rh:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.drawRect $rx $ry $rw $rh $colorTerm))
    | `(ppm_cmd| circle $cx:num $cy:num $r:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.drawCircle $cx $cy $r $colorTerm))
    | `(ppm_cmd| ellipse $cx:num $cy:num $rx:num $ry:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.drawEllipse $cx $cy $rx $ry $colorTerm))
    | `(ppm_cmd| border $rx:num $ry:num $rw:num $rh:num $t:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.drawBorder $rx $ry $rw $rh $t $colorTerm))
    | `(ppm_cmd| line $x1:num $y1:num $x2:num $y2:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.drawLine $x1 $y1 $x2 $y2 $colorTerm))
    | `(ppm_cmd| pixel $px:num $py:num $c:ppm_color) =>
      let colorTerm ← elabColor c
      cmdTerms := cmdTerms.push (← `(fun s => s.putPixel $px $py $colorTerm))
    | `(ppm_cmd| hgradient $c1:ppm_color $c2:ppm_color) =>
      let color1 ← elabColor c1
      let color2 ← elabColor c2
      cmdTerms := cmdTerms.push (← `(fun s => s.horizGradient $color1 $color2))
    | `(ppm_cmd| vgradient $c1:ppm_color $c2:ppm_color) =>
      let color1 ← elabColor c1
      let color2 ← elabColor c2
      cmdTerms := cmdTerms.push (← `(fun s => s.vertGradient $color1 $color2))
    | `(ppm_cmd| dgradient $c1:ppm_color $c2:ppm_color) =>
      let color1 ← elabColor c1
      let color2 ← elabColor c2
      cmdTerms := cmdTerms.push (← `(fun s => s.diagGradient $color1 $color2))
    | `(ppm_cmd| rgradient $c1:ppm_color $c2:ppm_color) =>
      let color1 ← elabColor c1
      let color2 ← elabColor c2
      cmdTerms := cmdTerms.push (← `(fun s => s.radialGradient $color1 $color2))
    | `(ppm_cmd| checker $size:num $c1:ppm_color $c2:ppm_color) =>
      let color1 ← elabColor c1
      let color2 ← elabColor c2
      cmdTerms := cmdTerms.push (← `(fun s => s.checkerboard $size $color1 $color2))
    | _ => throwError "Unknown canvas command"

  let initState ← `(PPM.CanvasState.create $(quote width) $(quote height) 255)
  let finalState ← cmdTerms.foldlM (init := initState) fun acc cmd => `($cmd $acc)
  let stx ← `(PPM.CanvasState.toImg $finalState)
  elabTerm stx none

end PPM
