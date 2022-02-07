module lang::fabric::demo::Main

import lang::fabric::demo::QL;
import lang::fabric::demo::QL_NL_fabric;

import lang::fabric::Stitch;

import IO;



void main() {
  base = lang::fabric::demo::QL::reflect();
  fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  path = |project://gradual-grammars/src/lang/fabric/demo|;
  writeStitchedGrammar(base, fabric, "NL", path, "QL_NL"); 
  //x = stitch(base, fabric, "NL");
  //
  //g = \grammar({\start(sort("Form"))}, x.definitions);
  //
  //str moduleName = "QL_NL";
  //
  //rsc = grammar2rascal(g, moduleName);
  //println(rsc);
  //
  //writeFile(|project://gradual-grammars/src/lang/fabric/demo/<moduleName>.rsc|, rsc);
}

start[Form] testUnravel(start[Form] f) {
  type[start[Form]] base = lang::fabric::demo::QL::reflect();
  type[start[Form_NL]] fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  return unravel(base, fabric, f, "NL");
}

//tuple[start[Form], int] testItWithTime(start[Form] f) {
//  type[start[Form]] base = QL::reflect();
//  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
//  int t0 = getMilliTime();
//  start[Form] f2 = unravel(base, fabric, f, "NL");
//  int t1 = getMilliTime();
//  return <f2, t1 - t0>;
//}
