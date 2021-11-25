module QL_Leveled

syntax Form = form: "form" Id Question*;

syntax Question = question: "ask" String "into" Id ":" Type;

syntax Type = \bool: "boolean";


// level 2

syntax Question = ifThen: "if" "(" OrExpr ")" Question;

syntax OrExpr = or: AndExpr "||" OrExpr | and: AndExpr;
   
syntax AndExpr = and: Primary "&&" AndExpr | prim: Primary;

syntax Primary = ref: Id | boolean: Bool;

syntax Bool = \true: "true" | \false: "false";


// level 3

syntax Question
  = @override=3 ifThen: "if" "(" OrExpr ")" "{" Question* "}"
  | @error ifThenError: "if" "(" OrExpr ")" Question
  ;
  
