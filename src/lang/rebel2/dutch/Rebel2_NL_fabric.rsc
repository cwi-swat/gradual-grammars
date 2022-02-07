module lang::rebel2::dutch::Rebel2_NL_fabric

start syntax Module_NL
  = modul: X X X
  ;

syntax Import_NL = \import: "importeer" X;

syntax Formula_NL
  = nonMembership: X "niet-in" X
  | ifThenElse: "als" X "dan" X "anders" X
  | ifThen: "als" X "dan" X
  | forAll: "voor" "alle" X "|" X
  | exists: "bestaat" X "|" X
  | on: "wanneer" X X
  | next: "volgende" X
  | first: "eerste" X
  | last: "laatste" X
  | eventually: "uiteindelijk" X
  | always: "altijd" X
  | alwaysLast: "altijd" "laatste" X
  | until: X "totdat" X
  | release: X "laat" "los" X
  | noOp: "noppes" "(" X ")"
  ;
  
syntax Lit_NL
  = none: "niks"
  | this: "deze"
  ;

syntax Type_NL
  = \set: "verzameling" X;
  
keyword Keywords_NL
  = "module"
  	 | "toestanden"
     | "nu" 
	 | "deze" 
	 | "is"
	 | "verzameling"
	 | "voor" | "alle"
	 | "bestaat"
	 | "noppes"
	 | "als"
	 | "dan"
	 | "anders"
	 | "niks"
	 | "falen"
	 | "succes"
	 | "gebeurtenis"
	 | "start"
	 | "finaal"
	 | "neem" | "aan"
	 | "met"
	 | "stel" | "vast"
	 | "feit"
	 | "totdat"
	 | "laat" | "los"
	 | "uiteindelijk"
	 | "altijd" | "laatste"
	 | "volgende"
	 | "minimaal"
	 | "maximaal"
	 | "exact"
	 | "wanneer"
	 | "eerste"
	 | "laatste"
	 | "oneindig"
	 | "eindig"
	 | "spoor"
	 | "controleer"
	 | "doe"
	 | "mocks"
	 ;
	 
syntax Constraint_NL
  = unique: "uniek" X
  ;
  
syntax Event_NL
  = event: X "gebeurtenis" X "(" X ")" X
  ; 
  
syntax Modifier_NL
  = init: "start"
  | final: "finale"
  | internal: "interne"
  ;
  
syntax States_NL
  = states: "toestanden" ":" X
  ;  

syntax Pred_NL
  = pred: "predikaat" X "(" X ")" "=" X ";"
  ;
  
syntax Fact_NL 
  = assume: "neem" "aan" X "=" X ";";
  
syntax TransEvent_NL
  = empty: "leeg";
  
  
syntax Forget_NL
  = forget: "vergeet" X;
  
syntax WithAssignments_NL
  = with: "met" X;
  
syntax Assert_NL
  = \assert: "stel" "vast" X "=" X ";"
  ;
  
syntax Check_NL
  = fromIn: X X "van" X "in" X X X ";"
  ;

syntax Command_NL
  = check: "controleer"
  | run: "doe"
  ;

syntax SearchDepth_NL
  = max: "maximaal" X "stappen"
  | exact: "exact" X "stappen"
  ;
  
syntax Objectives_NL
  = with: "met" X
  ;  
  
syntax Objective_NL
  = minimal: "minimaal" X
  | maximal: "maximaal" X
  | infinite: "oneindig" "spoor"
  | finite: "eindig" "spoor"
  ;
  
syntax Expect_NL
  = expect: "verwacht" X
  ;
  
syntax ExpectResult_NL
  = trace: "spoor"
  | noTrace: "geen" "spoor"
  ;
  

type[start[Module]] reflect() = #start[Module];