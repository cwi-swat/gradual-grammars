module lang::rebel2::dutch::Rebel2_NL 
syntax State =
  QualifiedName name 
  | "(*)" 
  ;

lexical StringCharacter =
  ![\" \' \< \> \\] 
  | [\n] [\t \  \u0240 \U001680 \U002000-\U00200A \U00202F \U00205F \U003000]* [\'] 
  | "\\" [\" \' \< \> \\ b f n r t] 
  | UnicodeEscape 
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
  "pred"  Id name  "("  {FormalParam ","}* params  ")"  "="  Formula form  ";" 
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
  minimal: "minimaal"  Expr expr 
  | finite: "eindig"  "spoor" 
  | maximal: "maximaal"  Expr expr 
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
  "?"  TypeName tp 
  | TypeName tp 
  | \set: "verzameling"  TypeName tp 
  ;

start syntax Module =
  ModuleId module  Import* imports  Part+ parts 
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
  Assert asrt 
  | "$$PART$$" 
  | Spec spc 
  | Check chk 
  | Config cfg 
  ;

syntax Expr =
  brackets: "("  Expr  ")" 
  > var: Id 
    | "|"  Expr  "|" 
  > Lit 
    | instanceAccess: Expr spc  "["  Id inst  "]" 
    | functionCall: Id func  "("  {Expr ","}* actuals  ")" 
    | trans: Expr  "."  "^"  Id 
    | fieldAccess: Expr  "."  Id 
    | reflTrans: Expr  "."  "*"  Id 
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
  whitespace: Whitespace 
  | comment: Comment 
  ;

syntax Modifier =
  init: "start" 
  | internal: "intern" 
  | final: "finaal" 
  ;

lexical Comment =
  @lineComment @category="Comment" "//" ![\n]*$ 
  ;

lexical UnicodeEscape =
  utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
  | utf32: "\\" [U] ("10" | (  "0"  [0-9 A-F a-f]  )) [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
  | ascii: "\\" [a] [0-7] [0-9 A-F a-f] 
  ;

syntax Constraints =
  {Constraint ","}+ constraints  ";" 
  ;

syntax ExpectResult =
  noTrace: "geen"  "spoor" 
  | trace: "spoor" 
  ;

syntax InstanceSetup =
  {Id ","}+ labels  ":"  Type spec  Mocks? mocks  Forget? forget  InState? inState  WithAssignments? assignments 
  | Id label  WithAssignments assignments 
  ;

syntax Check =
  fromIn: Command cmd  Id name  "from"  Id config  "in"  SearchDepth depth  Objectives? objs  Expect? expect  ";" 
  ;

syntax Command =
  run: "draai" 
  | check: "controleer" 
  ;

syntax EventVariant =
  "variant"  Id name  EventVariantBody body 
  ;

keyword Keywords =
  "module" 
  | "gebeurtenis" 
  | "draai" 
  | "neem" 
  | "laatste" 
  | "aan" 
  | "verzameling" 
  | "als" 
  | "controleer" 
  | "is" 
  | "oneindig" 
  | "succes" 
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
  | "stel" 
  | "volgende" 
  | "alle" 
  | "exact" 
  | "vast" 
  | "voor" 
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
  "states"  ":"  StateBlock root 
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
  > sync: Expr spc  "."  QualifiedName event  "("  {Expr ","}* params  ")" 
    | nonMembership: Expr  "niet-in"  Expr 
    | membership: Expr  "in"  Expr 
    | inState: Expr expr  "is"  QualifiedName state 
  > Expr  "\>="  Expr 
    | Expr  "\<="  Expr 
    | Expr  "!="  Expr 
    | Expr  "\<"  Expr 
    | Expr  "="  Expr 
    | Expr  "\>"  Expr 
  > right 
      ( right Formula  "&&"  Formula 
      )
    | right 
        ( right Formula  "||"  Formula 
        )
  > right 
      ( right Formula  "\<=\>"  Formula 
      )
    | non-assoc 
        ( non-assoc ifThen: "als"  Formula cond  "dan"  Formula 
        )
    | non-assoc 
        ( non-assoc ifThenElse: "als"  Formula cond  "dan"  Formula then  "anders"  Formula else 
        )
    | right 
        ( right Formula  "=\>"  Formula 
        )
  > exists: "bestaat"  {Decl ","}+  "|"  Formula 
    | forAll: "voor"  "alle"  {Decl ","}+  "|"  Formula 
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
      ( right release: Formula first  "laat"  "los"  Formula second 
      )
    | eventually: "uiteindelijk"  Formula form 
    | always: "altijd"  Formula form 
    | alwaysLast: "altijd"  "laatste"  Formula form 
    | right 
        ( right until: Formula first  "totdat"  Formula second 
        )
  ;
