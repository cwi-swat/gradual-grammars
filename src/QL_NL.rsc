module QL_NL

start syntax Form_NL = form: "formulier" X "{" X "}";

syntax Question_NL
  = question: "vraag" X_2 "met" X_1 ":" X_3
  | ifThen: "als" "(" X ")" X  () !>> "anders"
  | ifThenElse: "als" "(" X ")" X "anders" X
  ;
  
syntax Bool_NL = t: "waar" | f: "onwaar";

keyword Keywords_NL = "waar" | "onwaar" ;

syntax Type_NL
  = booleanType: "waarheidswaarde" 
  | stringType: "tekst"
  | integerType: "getal"
  ;
  
type[start[Form_NL]] reflect() = #start[Form_NL];