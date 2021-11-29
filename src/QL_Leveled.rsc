module QL_Leveled

// Level 1

extend lang::std::Layout;

lexical Id = [A-Za-z][A-Za-z0-9_]* !>> [A-Za-z0-9_] \ Reserved; 

lexical String = [\"]![\"]* [\"];

keyword Reserved = ;

syntax Form = form: "form" Id Question*;

syntax Question = question: "ask" String "into" Id ":" Type;

syntax Type = \bool: "boolean";


// level 2

syntax Question = ifThen: "if" "(" Expr ")" Question;

syntax Expr 
  = \bool: Bool | var: Id | bracket "(" Expr ")"
  | not: "!" Expr
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr; 
   
syntax Bool = \true: "true" | \false: "false";

keyword Reserved = "true" | "false";

// level 3

syntax Question
  = @override=3 ifThen: "if" "(" Expr ")" "{" Question* "}"
  | @error ifThenError: "if" "(" Expr ")" Question;
  
// level 4

lexical Int = [0-9]+ !>> [0-9];
  
syntax Type = \int: "integer";
  
syntax Expr
  = :not
  > non-assoc ( lt: Expr "\<" Expr | leq: Expr "\<=" Expr
    | geq: Expr "\>=" Expr | gt: Expr "\>" Expr
    | eq: Expr "==" Expr | neq: Expr "!=" Expr )
  > :and ;
  
// Level 5
  
syntax Question = question: "compute" String "as" Id ":" Type "=" Expr;

syntax Expr
  = :not
  > left ( Expr "*" Expr | Expr "/" Expr )
  > left ( Expr "+" Expr | Expr "-" Expr )
  > :lt ;

  