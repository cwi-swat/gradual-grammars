module lang::fabric::demo::QL_3

extend lang::fabric::demo::QL_2;

syntax Question
  = @override=3 ifThen: "if" "(" Expr ")" "{" Question* "}"
  | @error ifThenError: "if" "(" Expr ")" Question;
  

