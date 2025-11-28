import Lean
import Lean.Data.Json
import PPM.Types
import ProofWidgets.Component.HtmlDisplay

/-!
# PPM ProofWidgets Integration

Renders `Img` values as HTML grids in the VS Code infoview using ProofWidgets.

## Usage

```lean
def img := #ppm { | red green | | blue white | }

-- Display in infoview
#html PPM.display img

-- Display scaled (4x pixels)
#html PPM.displayScaled img 4
```

## Functions

- `Img.toHtmlGrid`: Convert image to HTML grid
- `PPM.display`: Display image at default scale
- `PPM.displayScaled`: Display image with custom pixel size
-/

open Lean
open ProofWidgets
open Lean.Json

namespace PPM

namespace Img

private def rgbCss (rgb : RGB16) (maxVal : Nat) : String :=
  let c := RGB16.to8Bit rgb maxVal
  s!"rgb({c.r.toNat},{c.g.toNat},{c.b.toNat})"

/-- Render an image as an HTML grid of colored divs. -/
def toHtmlGrid (img : Img) (pixelSize : Nat := 6) : ProofWidgets.Html := Id.run do
  let pxs := img.toArray
  let mut rows : Array ProofWidgets.Html := #[]
  for row in [0 : img.height] do
    let mut rowCells : Array ProofWidgets.Html := #[]
    for col in [0 : img.width] do
      let i := row * img.width + col
      if h : i < pxs.size then
        let px := pxs[i]'h
        let cellStyle : Json :=
          Json.mkObj
            [ ("width", Json.num pixelSize)
            , ("height", Json.num pixelSize)
            , ("backgroundColor", Json.str (rgbCss px img.maxVal))
            , ("display", Json.str "inline-block")
            , ("verticalAlign", Json.str "top")
            ]
        rowCells := rowCells.push <|
          ProofWidgets.Html.element "div" #[("style", cellStyle)] #[]
    -- Wrap each row in a div to force line breaks
    let rowStyle : Json := Json.mkObj
      [ ("fontSize", Json.num 0)
      , ("lineHeight", Json.num 0)
      , ("height", Json.num pixelSize)
      ]
    rows := rows.push <|
      ProofWidgets.Html.element "div" #[("style", rowStyle)] rowCells
  -- Container
  let containerStyle : Json := Json.mkObj
    [ ("display", Json.str "inline-block")
    , ("border", Json.str "1px solid #ccc")
    ]
  ProofWidgets.Html.element "div" #[("style", containerStyle)] rows

/-- Create a widget presentation for an Img value. -/
def imgWidget (img : Img) : ProofWidgets.Html := toHtmlGrid img 8

end Img

/-- Display a PPM image in the infoview. Usage: `#html PPM.display myImage` -/
def display (img : Img) : ProofWidgets.Html := Img.toHtmlGrid img 8

/-- Display a PPM image with custom pixel size. Usage: `#html PPM.displayScaled myImage 12` -/
def displayScaled (img : Img) (pixelSize : Nat := 8) : ProofWidgets.Html := Img.toHtmlGrid img pixelSize

end PPM
