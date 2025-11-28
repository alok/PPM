import Lake

open Lake DSL

-- UI widgets for Lean (HTML in infoview, etc.)
require proofwidgets from git "https://github.com/leanprover-community/ProofWidgets4" @ "v0.0.83-pre2"

package PPM where
  version := v!"0.1.0"
  keywords := #["ppm", "image", "graphics", "dsl"]
  description := "A PPM (Portable Pixmap) image DSL for Lean 4 with custom syntax and ProofWidgets integration"
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, true⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`doc.verso, true⟩
  ]

@[default_target]
lean_lib PPM where
  roots := #[`PPM]
