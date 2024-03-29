module lang::fabric::demo::QL_NL_fabric

start syntax Form_NL = form: "formulier" X "{" X "}";

syntax Question_NL
  = question: "vraag" X_2 "met" X_1 ":" X_3
  | ifThen: "als" X "dan" ":" X  () !>> "anders"
  | ifThenElse: "als" X "dan" ":" X "anders" X;
  
syntax Bool_NL = t: "waar" | f: "onwaar";

keyword Reserved_NL = "waar" | "onwaar" | "tel" | "bij" | "groter" | "dan" | "niet" | "op";

syntax Type_NL
  = booleanType: "waarheidswaarde" 
  | stringType: "tekst"
  | integerType: "getal";
  
syntax Expr_NL
  = not: "niet" X
  | gt: X "groter" "dan" X
  | add: X "opgeteld" "bij" X 
  ;  
  
type[start[Form_NL]] reflect() = #start[Form_NL];