module lang::rebel2::SpecSyntax

import lang::rebel2::CommonSyntax;

syntax Part 
  = Spec spc
  ;

syntax Spec = "spec" Id name Instances? instances Fields? fields Constraints? constraints Event* events Pred* preds Fact* facts States? states;

syntax Instances
  = "[" {Instance ","}+ instances "]"
  ;
  
syntax Instance 
  = Id 
  | Id "*"
  ;

syntax Fields
  = {Field ","}+ fields ";"
  ;

syntax Field
  = Id name ":" Type tipe
  ;
  
syntax Constraints
  = {Constraint ","}+ constraints ";"
  ;
  
syntax Constraint
  =  unique: "unique" {Id ","}+ fields
  ;
  
syntax Event
  = Modifier* modifiers "event" Id name "(" {FormalParam ","}* params ")" EventBody body 
  ;

syntax Modifier
  = init: "init"
  | final: "final"
  | internal: "internal"
  ;
  
syntax FormalParam
  = Id name ":" Type tipe
  ;
  
syntax EventBody
  = Pre? pre Post? post EventVariant* variants
  ;
    
syntax Pre
  = "pre" ":" {Formula ","}* formulas ";"
  ;

syntax Post
  = "post" ":" {Formula ","}* formulas ";"
  ;

syntax EventVariant
  = "variant" Id name EventVariantBody body
  ;  

syntax EventVariantBody
  = Pre? pre Post? post
  ; 

syntax Pred = "pred" Id name "(" {FormalParam ","}* params ")"  "=" Formula form ";";

syntax Fact = assume: "assume" Id name "=" Formula form ";";
  
syntax States
  = "states" ":" StateBlock root
  ;
  
syntax StateBlock
  = InnerStates? inner Transition* trans
  ;  
  
syntax Transition
  = State from "-\>" State to ":" {TransEvent ","}+ events ";"
  | Id super "{" StateBlock child "}"
  ;

syntax InnerStates
  = "[" {Id ","}+ states "]"
  ;
  
syntax State
  = QualifiedName name
  //= QuasiQualifiedName name
  | "(*)"
  ;
  
syntax TransEvent 
  = QualifiedName event \ "empty"
  | empty: "empty"
  ;  
 
syntax Lit
  = this: "this"
  ; 
 
keyword Keywords = "spec"
                 | "failure" 
                 | "success" 
                 | "event" 
                 | "pre" 
                 | "post"
                 | "init"
                 | "final"
                 | "states"
                 | "enum"
                 | "variant"
                 | "noOp"
                 | "func"
                 | "assume"
                 ;
 