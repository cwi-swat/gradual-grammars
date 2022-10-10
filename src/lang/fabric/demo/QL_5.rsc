module lang::fabric::demo::QL_5

extend lang::fabric::demo::QL_4;

syntax Question = question: "compute" String "as" Id ":" Type "=" Expr;

syntax Expr
  = :not
  > left ( Expr "*" Expr | Expr "/" Expr )
  > left ( Expr "+" Expr | Expr "-" Expr )
  > :lt ;
