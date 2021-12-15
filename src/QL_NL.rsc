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
  Bool 
  | String 
  | Integer 
  ;

lexical Id =
  (  [0-9 A-Z _ a-z] !<< [A-Z a-z]   [0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]  ) \ Reserved 
  ;

lexical Integer =
  [\-]? [0-9]+ !>> [0-9] 
  ;

keyword Reserved =
  "op" 
  | "tel" 
  | "waar" 
  | "groter" 
  | "bij" 
  | "onwaar" 
  | "dan" 
  | "niet" 
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
  | ifThen: "als"  Expr cond  "dan"  ":"  Question!dummy then  () !>> "anders" 
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
      ( left sub: Expr  "-"  Expr 
      | left add: "tel"  Expr  "op"  "bij"  Expr 
      )
  > left 
      ( left eq: Expr  "=="  Expr 
      | left lt: Expr  "\<"  Expr 
      | left leq: Expr  "\<="  Expr 
      | left gt: Expr  "groter"  "dan"  Expr 
      | left geq: Expr  "\>="  Expr 
      | left neq: Expr  "!="  Expr 
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
  comment: Comment 
  | whitespace: Whitespace 
  ;

lexical Comment =
  @lineComment @category="Comment" "//" ![\n]*$ 
  ;
