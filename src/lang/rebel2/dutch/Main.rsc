module lang::rebel2::dutch::Main

import lang::rebel2::Syntax;
import lang::rebel2::dutch::Rebel2_NL_fabric;
import lang::rebel2::dutch::ParseRebel2_NL;

import lang::fabric::Stitch;

import IO;

void main() {
  type[start[Module]] base = lang::rebel2::Syntax::reflect();
  type[start[Module_NL]] fabric = lang::rebel2::dutch::Rebel2_NL_fabric::reflect();
  
  dutchRebels = [
     |project://gradual-grammars-artifact-sle-2022/src/lang/rebel2/demo/Counter.rebel2_nl|,
     |project://gradual-grammars-artifact-sle-2022/src/lang/rebel2/demo/DoctorsAndRoster.rebel2_nl|
  ];
  
  for (loc dutch <- dutchRebels) {
  
	  pt = parseRebel2_NL(dutch);
	  
	  println("#### Dutch syntax");
	  println(pt);
	  
	  ptBase = unravel(base, fabric, pt, "NL");
	  
	  println("\n#### Unraveled (base-)syntax");
	  println(ptBase);
	  

  }
  
   
}