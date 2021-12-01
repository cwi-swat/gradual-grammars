module QL_NL 
lexical String =
  [\"] StrChar* [\"] 
  ;





syntax Type =
  booleanType: "waarheidswaarde" 
  | integerType: "getal" 
  | stringType: "tekst" 
  ;

lexical Label =
  @category="Constant" label: String 
  ;

syntax Value =
  String 
  | Bool 
  | Integer 
  ;

lexical Id =
  (  [0-9 A-Z _ a-z] !<< [A-Z a-z]   [\- 0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]  ) \ Keywords 
  ;


lexical Integer =
  [\-]? [0-9]+ !>> [0-9] 
  ;

keyword Reserved =
  "waar" 
  | "onwaar" 
  ;

syntax Bool =
  t: "waar" 
  | f: "onwaar" 
  ;

lexical StrChar =
  ![\" \\] 
  | [\\] [\" \\ b f n r t] 
  ;

layout Standard  =
  WhitespaceOrComment* !>> [\t-\a0D \  \u0205 \u0240 \U001680 \U00180E \U002000-\U00200A \U002028-\U002029 \U00202F \U00205F \U003000] !>> "//" 
  ;

start syntax Form =
  form: "formulier"  Id name  "{"  Question* questions  "}" 
  ;

syntax Question =
  @Foldable group: "{"  Question* questions  "}" 
  | ifThen: "als"  Expr cond  "dan"  ":"  Question then  () !>> "anders" 
  | question: "vraag"  Id var  "met"  Label label  ":"  Type type 
  | ifThenElse: "als"  Expr cond  "dan"  ":"  Question then  "anders"  Question els 
  | computed: Label label  Id var  ":"  Type type  "="  Expr expr 
  ;

syntax Expr =
  \value: Value 
  | var: Id name 
  | bracket "("  Expr  ")" 
  > not: "niet"  Expr 
  > left 
      ( left div: Expr  "/"  Expr 
      | left mul: Expr  "*"  Expr 
      )
  > left 
      ( left add: Expr  "+"  Expr 
      | left sub: Expr  "-"  Expr 
      )
  > non-assoc 
      ( non-assoc geq: Expr  "\>="  Expr 
      | non-assoc gt: Expr  "\>"  Expr 
      | non-assoc leq: Expr  "\<="  Expr 
      | non-assoc lt: Expr  "groter"  "dan"  Expr 
      | non-assoc eq: Expr  "=="  Expr 
      | non-assoc neq: Expr  "!="  Expr 
      )
  > left 
      ( left and: Expr  "&&"  Expr 
      )
  > left 
      ( left or: Expr  "||"  Expr 
      )
  ;

lexical Whitespace =
  [\t-\a0D \  \u0205 \u0240 \U001680 \U00180E \U002000-\U00200A \U002028-\U002029 \U00202F \U00205F \U003000] 
  ;

lexical WhitespaceOrComment =
  whitespace: Whitespace 
  | comment: Comment 
  ;

lexical Comment =
  @lineComment @category="Comment" "//" ![\n]*$ 
  ;
