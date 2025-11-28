import Lean
import ProofWidgets.Component.HtmlDisplay
import PPM.Types
import PPM.CustomSyntax
import PPM.Widget

/-!
# Interactive PPM Canvas Widget

Provides an interactive canvas widget with size controls in the infoview.
The widget shows buttons to adjust width/height and displays instructions
for updating the source code.
-/

open Lean ProofWidgets Widget
open PPM

namespace PPM.Interactive

/-- Size marker: size!(100, 100) evaluates to (100, 100) -/
macro "size!" "(" w:num "," h:num ")" : term => `(($w, $h))

/-- Create a canvas from size marker -/
def interactiveCanvas (wh : Nat × Nat) (body : CanvasState → CanvasState) : Img :=
  let (w, h) := wh
  let state := CanvasState.create w h 255
  (body state).toImg

/-- Props for the size control widget -/
structure SizeControlProps where
  /-- Current image width -/
  width : Nat
  /-- Current image height -/
  height : Nat
  deriving ToJson, FromJson, Inhabited

/-- Widget showing size with info -/
@[widget_module]
def SizeControlWidget : Component SizeControlProps where
  javascript := "
import * as React from 'react';
const e = React.createElement;

export default function(props) {
  const [w, setW] = React.useState(props.width);
  const [h, setH] = React.useState(props.height);
  const b = { padding: '2px 6px', margin: '2px', cursor: 'pointer', fontSize: '11px' };
  return e('div', { style: { fontFamily: 'monospace', fontSize: '11px', marginTop: '4px' } },
    e('b', null, w + ' x ' + h + ' '),
    e('span', { style: { color: '#666' } }, '(' + (w * h) + ' pixels) '),
    e('button', { style: b, onClick: () => setW(Math.max(1, w - 10)) }, 'W-'),
    e('button', { style: b, onClick: () => setW(w + 10) }, 'W+'),
    e('button', { style: b, onClick: () => setH(Math.max(1, h - 10)) }, 'H-'),
    e('button', { style: b, onClick: () => setH(h + 10) }, 'H+'),
    (w !== props.width || h !== props.height) &&
      e('span', { style: { marginLeft: '8px', color: '#c00' } },
        'Change size!(' + w + ', ' + h + ') in source')
  );
}
"

/-- Render image as HTML string -/
def imgToHtmlStr (img : Img) (px : Nat := 4) : String := Id.run do
  let arr := img.toArray
  let mut html := "<div style=\"font-size:0;line-height:0\">"
  for row in [0 : img.height] do
    html := html ++ "<div>"
    for col in [0 : img.width] do
      let i := row * img.width + col
      if h : i < arr.size then
        let c := RGB16.to8Bit arr[i] img.maxVal
        html := html ++ "<div style=\"width:" ++ toString px ++ "px;height:" ++ toString px
          ++ "px;background:rgb(" ++ toString c.r.toNat ++ "," ++ toString c.g.toNat
          ++ "," ++ toString c.b.toNat ++ ");display:inline-block\"></div>"
    html := html ++ "</div>"
  html ++ "</div>"

/-- Display image with size controls -/
def displayInteractive (img : Img) : Html :=
  let imgHtml := Img.toHtmlGrid img 4
  .element "div" #[] #[
    imgHtml,
    .ofComponent SizeControlWidget (SizeControlProps.mk img.width img.height) #[]
  ]

end PPM.Interactive
