-- Core types: RGB16, Img, Image w h
import PPM.Types

-- P3 parser
import PPM.Parser

-- Main DSL: image {...}, canvas WxH {...}, operators
import PPM.CustomSyntax

-- File export (P3, PNG)
import PPM.Export

-- ProofWidgets HTML display
import PPM.Widget

-- Interactive canvas widget
import PPM.InteractiveWidget

/-!
# PPM - Portable Pixmap DSL for Lean 4

A domain-specific language for creating and manipulating PPM images in Lean 4
with custom syntax support and ProofWidgets integration for inline display.

## Quick Start

```lean
import PPM

-- Grid syntax (auto dimensions)
def myImage : Img := #ppm {
  | red   green |
  | blue  white |
}

-- Display in infoview
#html PPM.display myImage
```
-/
