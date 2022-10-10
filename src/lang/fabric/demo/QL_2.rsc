module lang::fabric::demo::QL_2

extend lang::fabric::demo::QL_1;

// level 2

syntax Question = ifThen: "if" "(" Expr ")" Question;

syntax Expr 
  = \bool: Bool | var: Id | bracket "(" Expr ")"
  | not: "!" Expr
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr; 
   
syntax Bool = \true: "true" | \false: "false";

keyword Reserved = "true" | "false";