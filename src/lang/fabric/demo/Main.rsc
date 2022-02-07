module lang::fabric::demo::Main

import lang::fabric::demo::QL;
import lang::fabric::demo::ImplodeQL;
import lang::fabric::demo::QL_NL_fabric;
import lang::fabric::demo::ParseQL_NL;

import lang::fabric::Stitch;

import IO;


void main() {
  type[start[Form]] base = lang::fabric::demo::QL::reflect();
  type[start[Form_NL]] fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  
  dutchQL = |project://gradual-grammars/src/lang/fabric/demo/taxform.qlnl|;
  
  pt = parseQL_NL(dutchQL);
  
  println("#### Dutch syntax");
  println(pt);
  
  ptBase = unravel(base, fabric, pt, "NL");
  
  println("\n#### Unraveled (base-)syntax");
  println(ptBase);
  
  println("\n#### Implode from Dutch");
  
  ast = implodeQL_NL(pt);
  
  iprintln(ast);
  
   
}

void stitchDutchQL() {
  base = lang::fabric::demo::QL::reflect();
  fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  path = |project://gradual-grammars/src/lang/fabric/demo|;
  writeStitchedGrammar(base, fabric, "NL", path, "lang::fabric::demo::QL_NL");
}

start[Form] testUnravel(start[Form] f) {
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
