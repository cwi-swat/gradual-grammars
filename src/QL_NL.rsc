module QL_NL 
lexical String =
  [\"] StrChar* [\"] 
  ;





syntax Type =
  stringType: "tekst" 
  | integerType: "getal" 
  | booleanType: "waarheidswaarde" 
  ;

lexical Label =
  @category="Constant" label: String 
  ;

syntax Value =
  Integer 
  | String 
  | Bool 
  ;

lexical Id =
  (  [0-9 A-Z _ a-z] !<< [A-Z a-z]   [\- 0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]  ) \ Keywords 
  ;

lexical Integer =
  [\-]? [0-9]+ !>> [0-9] 
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
  ifThenElse: "als"  "("  Expr cond  ")"  Question then  "anders"  Question els 
  | @Foldable group: "{"  Question* questions  "}" 
  | ifThen: "als"  "("  Expr cond  ")"  Question then  () !>> "anders" 
  | computed: Label label  Id var  ":"  Type type  "="  Expr expr 
  | question: "vraag"  Id var  "met"  Label label  ":"  Type type 
  ;

syntax Expr =
  bracket "("  Expr  ")" 
  | var: Id name 
  | \value: Value 
  > not: "!"  Expr 
  > left 
      ( left mul: Expr  "*"  Expr 
      | left div: Expr  "/"  Expr 
      )
  > left 
      ( left add: Expr  "+"  Expr 
      | left sub: Expr  "-"  Expr 
      )
  > non-assoc 
      ( non-assoc geq: Expr  "\>="  Expr 
      | non-assoc gt: Expr  "\>"  Expr 
      | non-assoc leq: Expr  "\<="  Expr 
      | non-assoc lt: Expr  "\<"  Expr 
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

keyword Keywords =
  "waar" 
  | "onwaar" 
  ;

syntax Bool =
  f: "onwaar" 
  | t: "waar" 
  ;
