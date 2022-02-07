module lang::fabric::demo::Main

import lang::fabric::demo::QL;
import lang::fabric::demo::QL_NL_fabric;

import lang::fabrci::Stitch;

import Grammar;
import IO;

import lang::rascal::format::Grammar;


void main() {
  base = lang::fabric::demo::QL::reflect();
  fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  x = stitch(base, fabric, "NL");
  
  g = \grammar({\start(sort("Form"))}, x.definitions);
  
  str moduleName = "QL_NL";
  
  rsc = grammar2rascal(g, moduleName);
  println(rsc);
  
  writeFile(|project://gradual-grammars/src/<moduleName>.rsc|, rsc);
}

start[Form] testUnravel(start[Form] f) {
  type[start[Form]] base = QL::reflect();
  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
  return unravel(base, fabric, f, "NL");
}

tuple[start[Form], int] testItWithTime(start[Form] f) {
  type[start[Form]] base = QL::reflect();
  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
  int t0 = getMilliTime();
  start[Form] f2 = unravel(base, fabric, f, "NL");
  int t1 = getMilliTime();
  return <f2, t1 - t0>;
}
