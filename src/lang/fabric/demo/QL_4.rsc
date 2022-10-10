module lang::fabric::demo::QL_4

extend lang::fabric::demo::QL_3;

lexical Int = [0-9]+ !>> [0-9];
  
syntax Type = \int: "integer";
  
syntax Expr
  = :not
  > non-assoc ( lt: Expr "\<" Expr | leq: Expr "\<=" Expr
    | geq: Expr "\>=" Expr | gt: Expr "\>" Expr
    | eq: Expr "==" Expr | neq: Expr "!=" Expr )
  > :and ;