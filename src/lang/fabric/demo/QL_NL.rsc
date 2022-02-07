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
  String 
  | Bool 
  | Integer 
  ;

lexical Id =
  (  [0-9 A-Z _ a-z] !<< [A-Z a-z]   [0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]  ) \ Reserved 
  ;

lexical Integer =
  [\-]? [0-9]+ !>> [0-9] 
  ;

keyword Reserved =
  "waar" 
  | "tel" 
  | "groter" 
  | "bij" 
  | "op" 
  | "onwaar" 
  | "dan" 
  | "niet" 
  ;

syntax Bool =
  f: "onwaar" 
  | t: "waar" 
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
  ifThenElse: "als"  Expr cond  "dan"  ":"  Question then  "anders"  Question els 
  | @Foldable group: "{"  Question* questions  "}" 
  | ifThen: "als"  Expr cond  "dan"  ":"  Question!dummy then  () !>> "anders" 
  | computed: Label label  Id var  ":"  Type type  "="  Expr expr 
  | question: "vraag"  Id var  "met"  Label label  ":"  Type type 
  ;

syntax Expr =
  bracket "("  Expr  ")" 
  | var: Id name 
  | \value: Value 
  > not: "niet"  Expr 
  > left 
      ( left mul: Expr  "*"  Expr 
      | left div: Expr  "/"  Expr 
      )
  > left 
      ( left sub: Expr  "-"  Expr 
      | left add: "tel"  Expr  "op"  "bij"  Expr 
      )
  > left 
      ( left gt: Expr  "groter"  "dan"  Expr 
      | left lt: Expr  "\<"  Expr 
      | left leq: Expr  "\<="  Expr 
      | left geq: Expr  "\>="  Expr 
      | left neq: Expr  "!="  Expr 
      | left eq: Expr  "=="  Expr 
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
