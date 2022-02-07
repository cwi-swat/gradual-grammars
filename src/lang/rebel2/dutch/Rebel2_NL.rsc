module lang::rebel2::dutch::Rebel2_NL 
syntax State =
  QualifiedName name 
  | "(*)" 
  ;

lexical StringCharacter =
  "\\" [\" \' \< \> \\ b f n r t] 
  | [\n] [\t \  \u0240 \U001680 \U002000-\U00200A \U00202F \U00205F \U003000]* [\'] 
  | ![\" \' \< \> \\] 
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
  maximal: "maximaal"  Expr expr 
  | finite: "eindig"  "spoor" 
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
  event: Modifier* modifiers  "gebeurtenis"  Id name  "("  {FormalParam ","}* params  ")"  EventBody body 
  ;

syntax Objectives =
  with: "met"  {Objective ","}+ objs 
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
  > functionCall: Id func  "("  {Expr ","}* actuals  ")" 
    | instanceAccess: Expr spc  "["  Id inst  "]" 
    | fieldAccess: Expr  "."  Id 
    | reflTrans: Expr  "."  "*"  Id 
    | trans: Expr  "."  "^"  Id 
    | Lit 
  > nextVal: Expr  "\'" 
  > "-"  Expr 
  > non-assoc 
      ( non-assoc Expr lhs  "%"  Expr rhs 
      )
    | left 
        ( left Expr lhs  "*"  Expr rhs 
        )
    | non-assoc 
        ( non-assoc Expr lhs  "/"  Expr rhs 
        )
  > left 
      ( left Expr lhs  "++"  Expr rhs 
      )
    | left 
        ( left Expr lhs  "+"  Expr rhs 
        )
    | non-assoc 
        ( non-assoc Expr lhs  "-"  Expr rhs 
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
  final: "finale" 
  | internal: "interne" 
  | init: "start" 
  ;

lexical Comment =
  @lineComment @category="Comment" "//" ![\n]*$ 
  ;

lexical UnicodeEscape =
  ascii: "\\" [a] [0-7] [0-9 A-F a-f] 
  | utf32: "\\" [U] ("10" | (  "0"  [0-9 A-F a-f]  )) [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
  | utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
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
  fromIn: Command cmd  Id name  "van"  Id config  "in"  SearchDepth depth  Objectives? objs  Expect? expect  ";" 
  ;

syntax Command =
  run: "doe" 
  | check: "controleer" 
  ;

syntax EventVariant =
  "variant"  Id name  EventVariantBody body 
  ;

keyword Keywords =
  "gebeurtenis" 
  | "neem" 
  | "laatste" 
  | "aan" 
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
  > nonMembership: Expr  "niet-in"  Expr 
    | membership: Expr  "in"  Expr 
    | sync: Expr spc  "."  QualifiedName event  "("  {Expr ","}* params  ")" 
    | inState: Expr expr  "is"  QualifiedName state 
  > Expr  "\>"  Expr 
    | Expr  "\>="  Expr 
    | Expr  "\<="  Expr 
    | Expr  "!="  Expr 
    | Expr  "\<"  Expr 
    | Expr  "="  Expr 
  > right 
      ( right Formula  "&&"  Formula 
      )
    | right 
        ( right Formula  "||"  Formula 
        )
  > non-assoc 
      ( non-assoc ifThenElse: "als"  Formula cond  "dan"  Formula then  "anders"  Formula else 
      )
    | non-assoc 
        ( non-assoc ifThen: "als"  Formula cond  "dan"  Formula 
        )
    | right 
        ( right Formula  "=\>"  Formula 
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
  > next: "volgende"  Formula form 
    | first: "eerste"  Formula form 
    | last: "laatste"  Formula form 
  > alwaysLast: "altijd"  "laatste"  Formula form 
    | eventually: "uiteindelijk"  Formula form 
    | always: "altijd"  Formula form 
    | right 
        ( right until: Formula first  "totdat"  Formula second 
        )
    | right 
        ( right release: Formula first  "laat"  "los"  Formula second 
        )
  ;
