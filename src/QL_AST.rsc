module QL_AST


data Form(loc src=|dummy:///|)
  = form(str name, list[Question] questions)
  ;
  
data Question(loc src=|dummy:///|)
  = question(str label, str name, Type \type)
  | computed(str label, str name, Type \type, Expr expr)
  | ifThen(Expr cond, Question then)
  | ifThenElse(Expr cond, Question then, Question els)
  | group(list[Question] questions)
  ;
  
data Type
  = stringType()
  | integerType()
  | booleanType()
  ;
  
data Expr(loc src=|dummy:///|)
  = var(str name)
  | \value(value v)
  | sub(Expr lhs, Expr rhs)
  | add(Expr lhs, Expr rhs)
  | gt(Expr lhs, Expr rhs)
  | not(Expr arg)
  ;