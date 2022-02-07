module lang::rebel2::dutch::Rebel2_NL 
syntax State =
  QualifiedName name 
  | "(*)" 
  ;

lexical StringCharacter =
  UnicodeEscape 
  | [\n] [\t \  \u0240 \U001680 \U002000-\U00200A \U00202F \U00205F \U003000]* [\'] 
  | "\\" [\" \' \< \> \\ b f n r t] 
  | ![\" \' \< \> \\] 
  ;

syntax TransEvent =
  QualifiedName event \ "empty" 
  | empty: "leeg" 
  | wildcard: "*" 
  ;

syntax Mocks =
  "mocks"  Type concrete 
  ;

syntax Pred =
  pred: "predikaat"  Id name  "("  {FormalParam ","}* params  ")"  "="  Formula form  ";" 
  ;

syntax Pre =
  "pre"  ":"  {Formula ","}* formulas  ";" 
  ;

syntax Import =
  \import: "importeer"  QualifiedName module 
  ;

syntax Fields =
  {Field ","}+ fields  ";" 
  ;

syntax Objective =
  finite: "eindig"  "spoor" 
  | maximal: "maximaal"  Expr expr 
  | minimal: "minimaal"  Expr expr 
  | infinite: "oneindig"  "spoor" 
  ;

syntax Expect =
  expect: "verwacht"  ExpectResult 
  ;

syntax InnerStates =
  "["  {Id ","}+ states  "]" 
  ;



syntax Spec =
  "spec"  Id name  Instances? instances  Fields? fields  Constraints? constraints  Event* events  Pred* preds  Fact* facts  States? states 
  ;

syntax SearchDepth =
  exact: "exact"  Int steps  "stappen" 
  | max: "maximaal"  Int steps  "stappen" 
  ;



syntax Type =
  \set: "verzameling"  TypeName tp 
  | TypeName tp 
  | "?"  TypeName tp 
  ;

start syntax Module =
  modul: ModuleId module  Import* imports  Part+ parts 
  ;

syntax Field =
  Id name  ":"  Type tipe 
  ;

syntax Event =
  Modifier* modifiers  "event"  Id name  "("  {FormalParam ","}* params  ")"  EventBody body 
  ;

syntax Objectives =
  with: "with"  {Objective ","}+ objs 
  ;

syntax Constraint =
  unique: "uniek"  {Id ","}+ fields 
  ;

lexical StringConstant =
  @category="Constant" "\"" StringCharacter* "\"" 
  ;

syntax EventBody =
  Pre? pre  Post? post  EventVariant* variants 
  ;

syntax StateBlock =
  InnerStates? inner  Transition* trans 
  ;

lexical QuasiQualifiedName =
  [0-: A-Z _ a-z] !<< (  [A-Z _ a-z]  [0-9 A-Z _ a-z]*  (  [:]  [:]  [0-9 A-Z _ a-z]  )* !>> [0-9 A-Z _ a-z]  )  \ Keywords 
  ;

syntax Instances =
  "["  {Instance ","}+ instances  "]" 
  ;

syntax FormalParam =
  Id name  ":"  Type tipe 
  ;

lexical Id =
  [0-9 A-Z _ a-z] !<< (  [A-Z _ a-z]  [0-9 A-Z _ a-z]* !>> [0-9 A-Z _ a-z]  ) \ Keywords  
  ;

syntax Part =
  Check chk 
  | "$$PART$$" 
  | Spec spc 
  | Config cfg 
  | Assert asrt 
  ;

syntax Expr =
  brackets: "("  Expr  ")" 
  > var: Id 
    | "|"  Expr  "|" 
  > reflTrans: Expr  "."  "*"  Id 
    | instanceAccess: Expr spc  "["  Id inst  "]" 
    | functionCall: Id func  "("  {Expr ","}* actuals  ")" 
    | fieldAccess: Expr  "."  Id 
    | trans: Expr  "."  "^"  Id 
    | Lit 
  > nextVal: Expr  "\'" 
  > "-"  Expr 
  > non-assoc 
      ( non-assoc Expr lhs  "/"  Expr rhs 
      )
    | left 
        ( left Expr lhs  "*"  Expr rhs 
        )
    | non-assoc 
        ( non-assoc Expr lhs  "%"  Expr rhs 
        )
  > non-assoc 
      ( non-assoc Expr lhs  "-"  Expr rhs 
      )
    | left 
        ( left Expr lhs  "++"  Expr rhs 
        )
    | left 
        ( left Expr lhs  "+"  Expr rhs 
        )
  > "{"  Decl d  "|"  Formula form  "}" 
  ;

syntax Transition =
  Id super  "{"  StateBlock child  "}" 
  | State from  "-\>"  State to  ":"  {TransEvent ","}+ events  ";" 
  ;

lexical Whitespace =
  [\t-\a0D \  \u0205 \u0240 \U001680 \U00180E \U002000-\U00200A \U002028-\U002029 \U00202F \U00205F \U003000] 
  ;

syntax Instance =
  Id  "*" 
  | Id 
  ;

syntax Lit =
  Int 
  | StringConstant 
  | this: "deze" 
  | none: "niks" 
  | setLit: "{"  {Expr ","}* elems  "}" 
  ;

lexical WhitespaceOrComment =
  comment: Comment 
  | whitespace: Whitespace 
  ;

syntax Modifier =
  internal: "interne" 
  | final: "finaal" 
  | init: "start" 
  ;

lexical Comment =
  @lineComment @category="Comment" "//" ![\n]*$ 
  ;

lexical UnicodeEscape =
  ascii: "\\" [a] [0-7] [0-9 A-F a-f] 
  | utf32: "\\" [U] ((  "0"  [0-9 A-F a-f]  ) | "10") [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
  | utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
  ;

syntax Constraints =
  {Constraint ","}+ constraints  ";" 
  ;

syntax ExpectResult =
  trace: "spoor" 
  | noTrace: "geen"  "spoor" 
  ;

syntax InstanceSetup =
  {Id ","}+ labels  ":"  Type spec  Mocks? mocks  Forget? forget  InState? inState  WithAssignments? assignments 
  | Id label  WithAssignments assignments 
  ;

syntax Check =
  fromIn: Command cmd  Id name  "from"  Id config  "in"  SearchDepth depth  Objectives? objs  Expect? expect  ";" 
  ;

syntax Command =
  run: "doe" 
  | check: "controleer" 
  ;

syntax EventVariant =
  "variant"  Id name  EventVariantBody body 
  ;

keyword Keywords =
  "aan" 
  | "gebeurtenis" 
  | "neem" 
  | "laatste" 
  | "verzameling" 
  | "als" 
  | "controleer" 
  | "oneindig" 
  | "feit" 
  | "los" 
  | "spoor" 
  | "laat" 
  | "niks" 
  | "start" 
  | "finaal" 
  | "anders" 
  | "mocks" 
  | "nu" 
  | "met" 
  | "maximaal" 
  | "minimaal" 
  | "wanneer" 
  | "eerste" 
  | "altijd" 
  | "doe" 
  | "is" 
  | "stel" 
  | "volgende" 
  | "alle" 
  | "exact" 
  | "vast" 
  | "voor" 
  | "succes" 
  | "module" 
  | "toestanden" 
  | "eindig" 
  | "noppes" 
  | "uiteindelijk" 
  | "bestaat" 
  | "dan" 
  | "totdat" 
  | "falen" 
  | "deze" 
  ;

syntax Decl =
  {Id ","}+ vars  ":"  Expr expr 
  ;

lexical TypeName =
  @category="Type" [0-9 A-Z _ a-z] !<< [A-Z]  [0-9 A-Z _ a-z]* \ Keywords !>> [0-9 A-Z _ a-z] 
  ;

syntax Forget =
  forget: "vergeet"  {Id ","}+ fields 
  ;

syntax Assignment =
  Id fieldName  "="  Expr val 
  ;

syntax EventVariantBody =
  Pre? pre  Post? post 
  ;

syntax InState =
  "is"  State state 
  ;

syntax Fact =
  assume: "neem"  "aan"  Id name  "="  Formula form  ";" 
  ;

syntax WithAssignments =
  with: "met"  {Assignment ","}+ assignments 
  ;

syntax Post =
  "post"  ":"  {Formula ","}* formulas  ";" 
  ;

syntax Config =
  "config"  Id name  "="  {InstanceSetup ","}+ instances  ";" 
  ;

syntax States =
  states: "toestanden"  ":"  StateBlock root 
  ;

layout Standard  =
  WhitespaceOrComment* !>> [\t-\a0D \  \u0205 \u0240 \U001680 \U00180E \U002000-\U00200A \U002028-\U002029 \U00202F \U00205F \U003000] !>> "//" 
  ;

syntax ModuleId =
  "module"  QualifiedName name 
  ;

syntax QualifiedName =
  {Id "::"}+ names !>> "::" 
  ;

lexical Int =
  @category="Constant" [0-9] !<< [0-9]+ !>> [0-9]  
  ;

syntax Assert =
  \assert: "stel"  "vast"  Id name  "="  Formula form  ";" 
  ;

syntax Formula =
  noOp: "noppes"  "("  Expr spc  ")" 
  ;

syntax Formula =
  brackets: "("  Formula  ")" 
  > "!"  Formula form 
  > membership: Expr  "in"  Expr 
    | nonMembership: Expr  "niet-in"  Expr 
    | sync: Expr spc  "."  QualifiedName event  "("  {Expr ","}* params  ")" 
    | inState: Expr expr  "is"  QualifiedName state 
  > Expr  "\<="  Expr 
    | Expr  "\>="  Expr 
    | Expr  "!="  Expr 
    | Expr  "\<"  Expr 
    | Expr  "="  Expr 
    | Expr  "\>"  Expr 
  > right 
      ( right Formula  "||"  Formula 
      )
    | right 
        ( right Formula  "&&"  Formula 
        )
  > right 
      ( right Formula  "=\>"  Formula 
      )
    | non-assoc 
        ( non-assoc ifThen: "als"  Formula cond  "dan"  Formula 
        )
    | non-assoc 
        ( non-assoc ifThenElse: "als"  Formula cond  "dan"  Formula then  "anders"  Formula else 
        )
    | right 
        ( right Formula  "\<=\>"  Formula 
        )
  > forAll: "voor"  "alle"  {Decl ","}+  "|"  Formula 
    | exists: "bestaat"  {Decl ","}+  "|"  Formula 
  ;

syntax Formula =
  non-assoc 
    ( non-assoc ifThenElse: "als"  Formula cond  "dan"  Formula then  "anders"  Formula else 
    )
  > on: "wanneer"  TransEvent event  Expr var 
  > last: "laatste"  Formula form 
    | first: "eerste"  Formula form 
    | next: "volgende"  Formula form 
  > right 
      ( right until: Formula first  "totdat"  Formula second 
      )
    | eventually: "uiteindelijk"  Formula form 
    | always: "altijd"  Formula form 
    | alwaysLast: "altijd"  "laatste"  Formula form 
    | right 
        ( right release: Formula first  "laat"  "los"  Formula second 
        )
  ;
