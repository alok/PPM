import Std
import PPM.Types

open System

namespace PPM

namespace Img

/-- Render the image as an ASCII P3 PPM string. -/
def toP3String (img : Img) : String := Id.run do
  let header :=
    s!"P3\n{img.width} {img.height}\n{img.maxVal}\n"
  let mut s := header
  let arr := img.toArray
  for row in [0 : img.height] do
    for col in [0 : img.width] do
      let idx := row * img.width + col
      if h : idx < arr.size then
        let px := arr[idx]'h
        -- Write values in the image's native range (0..maxVal)
        s := s ++ s!"{px.r.toNat} {px.g.toNat} {px.b.toNat}"
        if col + 1 < img.width then
          s := s ++ "   "
    s := s ++ "\n"
  s

/-- Write the image to an ASCII P3 PPM file at `path`. -/
def exportP3 (img : Img) (path : FilePath) : IO Unit := do
  IO.FS.writeFile path (toP3String img)

/--
Write the image to a temporary `.ppm` next to `destPNG` and attempt to convert
it to PNG using a system tool if available. Tries `magick` then `sips`.
Falls back to leaving the `.ppm` if conversion fails.
-/
def exportPNG (img : Img) (destPNG : FilePath) : IO Unit := do
  let dir := destPNG.parent.getD "."
  let base := destPNG.fileName.getD "image"
  let tmpPPM := (dir / s!"{base}.tmp.ppm")
  -- Ensure directory exists
  IO.FS.createDirAll dir
  exportP3 img tmpPPM
  let tryCmd (cmd : String) (args : List String) : IO Bool := do
    let p ← IO.Process.spawn { cmd, args := args.toArray, stdout := .piped, stderr := .piped }
    let out ← p.wait
    pure (out == 0)
  let pngOk ←
    (do
      -- ImageMagick
      let ok ← tryCmd "magick" [tmpPPM.toString, destPNG.toString]
      if ok then pure true else
        -- macOS `sips`
        tryCmd "sips" ["-s", "format", "png", tmpPPM.toString, "--out", destPNG.toString])
    <|> pure false
  -- Clean up tmp ppm if we managed to convert
  if pngOk then
    try IO.FS.removeFile tmpPPM catch _ => pure ()
  else
    pure ()

end Img

end PPM
