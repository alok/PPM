/-!
# PPM Core Types

This module defines the core types for PPM image representation:

- `RGB16`: A pixel with 16-bit RGB components (0-65535)
- `Img`: Dynamic image with runtime dimensions
- `Image w h`: Type-parameterized image with compile-time dimension checking
-/

/-- RGB pixel with 16-bit components to support full PPM range (0 to 65535) -/
structure RGB16 where
  /-- Red component (0-65535) -/
  r : UInt16
  /-- Green component (0-65535) -/
  g : UInt16
  /-- Blue component (0-65535) -/
  b : UInt16
  deriving Repr, BEq, Inhabited

namespace RGB16

/-- Create RGB16 from natural numbers -/
def ofNats (r g b : Nat) : RGB16 :=
  { r := r.toUInt16, g := g.toUInt16, b := b.toUInt16 }

/-- Scale RGB16 values to 8-bit range for display -/
def to8Bit (rgb : RGB16) (maxVal : Nat) : RGB16 :=
  if maxVal ≤ 255 then rgb
  else
    let scale := 255.0 / maxVal.toFloat
    { r := (rgb.r.toNat.toFloat * scale).toUInt16
    , g := (rgb.g.toNat.toFloat * scale).toUInt16
    , b := (rgb.b.toNat.toFloat * scale).toUInt16 }

end RGB16

/-- PPM image with statically verified dimensions via Vector -/
structure Img where
  /-- Image width in pixels -/
  width : Nat
  /-- Image height in pixels -/
  height : Nat
  /-- Maximum color value, must be in range (1 to 65535) -/
  maxVal : Nat
  /-- Proof that maxVal is valid -/
  hMax : 0 < maxVal ∧ maxVal ≤ 65535
  /-- Pixel data in row-major order -/
  pixels : Vector RGB16 (width * height)
  deriving Repr

instance : Inhabited Img where
  default :=
    { width := 0
    , height := 0
    , maxVal := 1
    , hMax := by exact ⟨by decide, by decide⟩
    , pixels := ⟨Array.mkEmpty 0, by simp⟩ }

namespace Img

/-- Helper lemma for row-major indexing bounds -/
theorem rowMajorBound (width height row col : Nat)
    (hRow : row < height) (hCol : col < width) (_hWidth : 0 < width) :
    row * width + col < width * height := by
  calc row * width + col
    < row * width + width := Nat.add_lt_add_left hCol _
    _ = (row + 1) * width := by grind +ring
    _ ≤ height * width := Nat.mul_le_mul_right _ (Nat.succ_le_of_lt hRow)
    _ = width * height := Nat.mul_comm _ _

/-- Get pixel at row and col using Fin indices for safety -/
def get (img : Img) (row : Fin img.height) (col : Fin img.width) : RGB16 :=
  img.pixels.get ⟨row.val * img.width + col.val,
    rowMajorBound img.width img.height row.val col.val row.isLt col.isLt (Nat.zero_lt_of_lt col.isLt)⟩

/-- Set pixel at row and col -/
def set (img : Img) (row : Fin img.height) (col : Fin img.width) (rgb : RGB16) : Img :=
  let idx := row.val * img.width + col.val
  let hBound : idx < img.width * img.height :=
    rowMajorBound img.width img.height row.val col.val row.isLt col.isLt (Nat.zero_lt_of_lt col.isLt)
  let finIdx : Fin (img.width * img.height) := ⟨idx, hBound⟩
  { img with pixels := img.pixels.set finIdx rgb }

/-- Convert pixel Vector to Array for I/O operations -/
def toArray (img : Img) : Array RGB16 :=
  img.pixels.toArray

/-- Create image from array with bounds checking -/
def ofArray (width height maxVal : Nat) (pixels : Array RGB16)
    (hMax : 0 < maxVal ∧ maxVal ≤ 65535)
    (hLen : pixels.size = width * height) : Img :=
  { width, height, maxVal, hMax, pixels := ⟨pixels, hLen⟩ }

/-- Create a solid-color image -/
def solid (width height : Nat) (rgb : RGB16) (maxVal : Nat := 255)
    (hMax : 0 < maxVal ∧ maxVal ≤ 65535 := by decide) : Img :=
  { width, height, maxVal, hMax
  , pixels := Vector.range (width * height) |>.map (fun _ => rgb) }

/-- Map a function over all pixels -/
def map (img : Img) (f : RGB16 → RGB16) : Img :=
  { img with pixels := img.pixels.map f }

/-- Map with row/col indices -/
def mapIdx (img : Img) (f : Fin img.height → Fin img.width → RGB16 → RGB16) : Img :=
  let pixels := Vector.ofFn fun i =>
    let row := i / img.width
    let col := i % img.width
    if hR : row < img.height then
      if hC : col < img.width then
        f ⟨row, hR⟩ ⟨col, hC⟩ (img.pixels.get i)
      else img.pixels.get i
    else img.pixels.get i
  { img with pixels }

end Img

/-! ## Type-Parameterized Image

`Image w h` carries dimensions at the type level for compile-time safety.
-/

/-- PPM image with type-level dimensions for compile-time size checking -/
structure Image (width height : Nat) where
  /-- Maximum color value, must be in range (1 to 65535) -/
  maxVal : Nat
  /-- Proof that maxVal is valid -/
  hMax : 0 < maxVal ∧ maxVal ≤ 65535
  /-- Pixel data in row-major order -/
  pixels : Vector RGB16 (width * height)
  deriving Repr

namespace Image

/-- Create a solid-color image -/
def solid (rgb : RGB16) (maxVal : Nat := 255)
    (hMax : 0 < maxVal ∧ maxVal ≤ 65535 := by decide) : Image w h :=
  { maxVal, hMax, pixels := Vector.range (w * h) |>.map (fun _ => rgb) }

/-- Create from array with compile-time dimension check -/
def ofArray (pixels : Array RGB16) (maxVal : Nat := 255)
    (hMax : 0 < maxVal ∧ maxVal ≤ 65535 := by decide)
    (hLen : pixels.size = w * h := by native_decide) : Image w h :=
  { maxVal, hMax, pixels := ⟨pixels, hLen⟩ }

/-- Get pixel at (row, col) -/
def get (img : Image w h) (row : Fin h) (col : Fin w) : RGB16 :=
  img.pixels.get ⟨row.val * w + col.val,
    Img.rowMajorBound w h row.val col.val row.isLt col.isLt (Nat.zero_lt_of_lt col.isLt)⟩

/-- Set pixel at (row, col) -/
def set (img : Image w h) (row : Fin h) (col : Fin w) (rgb : RGB16) : Image w h :=
  let idx := row.val * w + col.val
  let hBound := Img.rowMajorBound w h row.val col.val row.isLt col.isLt (Nat.zero_lt_of_lt col.isLt)
  { img with pixels := img.pixels.set (Fin.mk idx hBound) rgb }

/-- Map a function over all pixels -/
def map (img : Image w h) (f : RGB16 → RGB16) : Image w h :=
  { img with pixels := img.pixels.map f }

/-- Convert to dynamic Img -/
def toImg (img : Image w h) : Img :=
  { width := w, height := h, maxVal := img.maxVal, hMax := img.hMax, pixels := img.pixels }

/-- Convert from dynamic Img (requires dimension proof) -/
def fromImg (img : Img) (hw : img.width = w) (hh : img.height = h) : Image w h :=
  { maxVal := img.maxVal
  , hMax := img.hMax
  , pixels := hw ▸ hh ▸ img.pixels }

/-- Place two images side by side (type-safe!) -/
def beside (a : Image w₁ h) (b : Image w₂ h) : Image (w₁ + w₂) h :=
  let pixels := Vector.ofFn fun (i : Fin ((w₁ + w₂) * h)) =>
    let row := i.val / (w₁ + w₂)
    let col := i.val % (w₁ + w₂)
    if col < w₁ then
      let srcIdx := row * w₁ + col
      if h : srcIdx < w₁ * h then a.pixels.get ⟨srcIdx, h⟩ else default
    else
      let srcIdx := row * w₂ + (col - w₁)
      if h : srcIdx < w₂ * h then b.pixels.get ⟨srcIdx, h⟩ else default
  { maxVal := a.maxVal, hMax := a.hMax, pixels }

/-- Stack two images vertically (type-safe!) -/
def above (a : Image w h₁) (b : Image w h₂) : Image w (h₁ + h₂) :=
  let pixels := Vector.ofFn fun (i : Fin (w * (h₁ + h₂))) =>
    if i.val < w * h₁ then
      if h : i.val < w * h₁ then a.pixels.get ⟨i.val, h⟩ else default
    else
      let srcIdx := i.val - w * h₁
      if h : srcIdx < w * h₂ then b.pixels.get ⟨srcIdx, h⟩ else default
  { maxVal := a.maxVal, hMax := a.hMax, pixels }

/-- Blend two same-size images (compile-time dimension matching!) -/
def blend (a b : Image w h) : Image w h :=
  let pixels := Vector.ofFn fun (i : Fin (w * h)) =>
    let pa := a.pixels.get i
    let pb := b.pixels.get i
    RGB16.ofNats
      ((pa.r.toNat + pb.r.toNat) / 2)
      ((pa.g.toNat + pb.g.toNat) / 2)
      ((pa.b.toNat + pb.b.toNat) / 2)
  { maxVal := a.maxVal, hMax := a.hMax, pixels }

end Image

/-- Type-safe side-by-side composition (requires same height) -/
infixl:60 " ⊞' " => Image.beside
/-- Type-safe vertical stacking (requires same width) -/
infixl:60 " ⊟' " => Image.above
/-- Type-safe blending (requires same dimensions) -/
infixl:65 " ⊕' " => Image.blend
