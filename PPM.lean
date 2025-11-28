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

## Modules

- {lit}`PPM.Types`: Core types ({name}`RGB16`, {name}`Img`)
- {lit}`PPM.Parser`: P3 format parser
- {lit}`PPM.CustomSyntax`: Grid and canvas DSL syntax
- {lit}`PPM.Export`: File export (P3, PNG)
- {lit}`PPM.Widget`: ProofWidgets HTML display
-/
