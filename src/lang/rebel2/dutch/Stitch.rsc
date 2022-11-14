module lang::rebel2::dutch::Stitch

import lang::rebel2::dutch::Rebel2_NL_fabric;
import lang::rebel2::Syntax;

import lang::fabric::Stitch;

void stitchDutchRebel2() {
  base = lang::rebel2::Syntax::reflect();
  fabric = lang::rebel2::dutch::Rebel2_NL_fabric::reflect();
  path = |project://gradual-grammars-artifact-sle-2022/src/lang/rebel2/dutch|;
  writeStitchedGrammar(base, fabric, "NL", path, "lang::rebel2::dutch::Rebel2_NL");
}
