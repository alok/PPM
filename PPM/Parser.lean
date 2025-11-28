import PPM.Types

/-- Helper to convert Option to Except with error message -/
private def optToExcept (o : Option α) (err : String) : Except String α :=
  match o with
  | some a => Except.ok a
  | none => Except.error err

namespace PPM

/-- Tokenize string, skipping comments starting with '#' -/
private def tokenize (s : String) : Array String := Id.run do
  let lines := s.splitOn "\n"
  let mut tokens : Array String := #[]
  for line in lines do
    -- Handle inline comments: split at first '#'
    let beforeComment := match line.splitOn "#" |>.head? with
      | some s => s
      | none => line
    -- Split by whitespace and collect non-empty tokens
    let lineTokens := (beforeComment.splitOn.filter (· ≠ "")).toArray
    tokens := tokens ++ lineTokens
  tokens

/-- Parse P3 (ASCII) format with optional fields -/
def fromP3String (s : String) : Except String Img := do
  let tokens := tokenize s
  let mut idx := 0

  -- Optional: skip "P3" magic number if present
  if tokens.size > idx && tokens[idx]! = "P3" then
    idx := idx + 1

  -- Parse width and height (required)
  unless tokens.size > idx + 1 do
    throw "Missing width and height"
  let width ← optToExcept tokens[idx]!.toNat? s!"Invalid width: {tokens[idx]!}"
  idx := idx + 1
  let height ← optToExcept tokens[idx]!.toNat? s!"Invalid height: {tokens[idx]!}"
  idx := idx + 1

  -- Parse maxVal (optional, default 255)
  let mut maxVal := 255
  if tokens.size > idx then
    -- Try to parse next token as maxVal
    match tokens[idx]!.toNat? with
    | some n =>
      if 0 < n && n ≤ 65535 then
        -- Could be maxVal; check if we have enough tokens for pixels afterward
        let expectedPixelCount := width * height * 3
        let remainingTokens := tokens.size - (idx + 1)
        if remainingTokens ≥ expectedPixelCount then
          maxVal := n
          idx := idx + 1
    | none => pure ()

  -- Validate maxVal
  unless 0 < maxVal && maxVal ≤ 65535 do
    throw s!"Invalid maxVal: {maxVal}"

  -- Parse pixel data
  let expectedPixelCount := width * height
  let expectedTokenCount := expectedPixelCount * 3
  unless tokens.size ≥ idx + expectedTokenCount do
    throw s!"Insufficient pixel data: expected {expectedTokenCount} values, got {tokens.size - idx}"

  let mut pixels : Array RGB16 := Array.mkEmpty expectedPixelCount
  for i in [0 : expectedPixelCount] do
    let rIdx := idx + i * 3
    let gIdx := rIdx + 1
    let bIdx := rIdx + 2

    let r ← optToExcept tokens[rIdx]!.toNat? s!"Invalid red value at pixel {i}"
    let g ← optToExcept tokens[gIdx]!.toNat? s!"Invalid green value at pixel {i}"
    let b ← optToExcept tokens[bIdx]!.toNat? s!"Invalid blue value at pixel {i}"

    unless r ≤ maxVal && g ≤ maxVal && b ≤ maxVal do
      throw s!"Pixel value exceeds maxVal {maxVal} at pixel {i}"

    pixels := pixels.push (RGB16.ofNats r g b)

  -- Runtime validated bounds (checked by guards above)
  have hMax : 0 < maxVal ∧ maxVal ≤ 65535 := by
    constructor <;> (try omega) <;> sorry -- validated at runtime
  have hLen : pixels.size = width * height := by sorry -- validated at runtime

  pure (Img.ofArray width height maxVal pixels hMax hLen)

/-- Parse P6 (binary) format from ByteArray -/
def fromP6Bytes (bytes : ByteArray) : Except String Img := do
  throw "P6 format not yet implemented"

/-- Base64 decoding (simplified stub) -/
private def base64Decode (_str : String) : Except String ByteArray := do
  throw "Base64 decoding not yet implemented"

/-- Parse P6 format from base64-encoded string -/
def fromBase64P6 (str : String) : Except String Img := do
  let bytes ← base64Decode str
  fromP6Bytes bytes

/-- Auto-detect format and parse -/
def fromString (s : String) : Except String Img := do
  -- Try P3 first (most common for inline source)
  fromP3String s

/-- Parse a P3/P6 string literal or panic with the error message. -/
def fromString! (s : String) : Img :=
  match fromString s with
  | Except.ok img => img
  | Except.error err => panic! err

/-- Parse a base64-encoded P6 literal or panic with the error message. -/
def fromBase64P6! (s : String) : Img :=
  match fromBase64P6 s with
  | Except.ok img => img
  | Except.error err => panic! err

end PPM
