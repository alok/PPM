# PPM - Portable Pixmap DSL for Lean 4

A domain-specific language for creating and manipulating PPM images in Lean 4 with custom syntax support and ProofWidgets integration for inline display in the VS Code infoview.

## Features

- **Custom Syntax**: Elegant DSL for defining images inline
- **ProofWidgets Integration**: View images directly in the VS Code infoview
- **Type-Safe Operations**: Dimension-checked image operations
- **Canvas DSL**: Procedural drawing with shapes, gradients, and patterns
- **P3 Import/Export**: Full PPM P3 format support

## Installation

Add to your `lakefile.lean`:

```lean
require PPM from git "https://github.com/alok/PPM" @ "main"
```

## Quick Start

```lean
import PPM

-- Grid syntax with auto-inferred dimensions
def tiny : Img := #ppm {
  | red   green |
  | blue  white |
}

-- Canvas DSL for procedural drawing
def scene : Img := canvas 100×60 {
  fill cyan
  rect 0 40 100 20 green
  circle 75 20 12 yellow
}

-- Display in infoview
#html PPM.display tiny
#html PPM.displayScaled scene 4
```

## Syntax Reference

### Grid Syntax

**Auto-inferred dimensions** (most elegant):
```lean
#ppm {
  | red   green blue |
  | white black gray |
}
```

**Explicit dimensions** (validates pixel count):
```lean
#ppm { 3×2:
  | red   green blue |
  | white black gray |
}
```

### P3 String Parsing

Use `PPM.fromString!` for P3 content:
```lean
def img := PPM.fromString! "P3
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255"
```

### Canvas DSL

```lean
canvas 100×100 {
  fill black           -- background
  rect 10 10 50 50 red -- filled rectangle
  circle 50 50 20 yellow
  ellipse 70 30 15 10 blue
  border 5 5 90 90 2 white
  line 0 0 99 99 green
  hgradient red blue   -- horizontal gradient
  vgradient white black
  checker 8 gray white -- checkerboard
}
```

### Colors

- **Named**: `red`, `green`, `blue`, `white`, `black`, `yellow`, `cyan`, `magenta`, `gray`, `orange`, `purple`, `pink`, `brown`, `navy`, `teal`, `lime`, `aqua`, `maroon`, `olive`, `silver`, `gold`
- **RGB**: `rgb(255, 128, 0)`
- **Hex**: `0xFF8000`
- **Grayscale**: `128` (0-255)

### Image Operators

```lean
img1 ⊕ img2   -- blend (average pixels)
⊖img          -- invert colors
img↔          -- flip horizontal
img↕          -- flip vertical
img1 ⊞ img2   -- place side by side
img1 ⊟ img2   -- stack vertically
```

### Type-Safe Operations

For compile-time dimension checking:
```lean
def a : Image 10 10 := Image.solid (RGB16.ofNats 255 0 0)
def b : Image 10 10 := Image.solid (RGB16.ofNats 0 255 0)
def c : Image 20 10 := a ⊞' b  -- type-safe side-by-side
def d : Image 10 10 := a ⊕' b  -- type-safe blend (same dimensions required)
```

## API Reference

### Types

- `RGB16` - RGB pixel with 16-bit components
- `Img` - Dynamic image with runtime dimensions
- `Image w h` - Type-parameterized image with compile-time dimensions

### Core Functions

```lean
-- Creation
Img.solid : Nat → Nat → RGB16 → Img
Img.ofArray : Nat → Nat → Nat → Array RGB16 → Img

-- Transformations
Img.map : Img → (RGB16 → RGB16) → Img
Img.blend, Img.invert, Img.flipH, Img.flipV
Img.beside, Img.above, Img.scale, Img.crop
Img.tileH, Img.tileV

-- Export
Img.toP3 : Img → String
Img.exportP3 : Img → FilePath → IO Unit
Img.exportPNG : Img → FilePath → IO Unit

-- Display
PPM.display : Img → Html
PPM.displayScaled : Img → Nat → Html
```

## Requirements

- Lean 4 (nightly-2025-11-27 or compatible)
- ProofWidgets4 v0.0.83-pre2

## License

MIT
