module lang::fabric::GradualGrammar

extend lang::std::Layout;

start syntax Module = "module" Id name Directive* directives Level* levels;

syntax Directive 
  = "import" QName Binding?
  | "layout" Nonterminal "=" Sym
  | "modifies" String;

syntax QName = {Id "."}+;

syntax Level = @Foldable "level" Nat number Remove? Deprecate? Rule* rules;

syntax Remove = "remove" {Label ","}+;

syntax Deprecate = "deprecate" {Label ","}+;

syntax Literal = @category="StringLiteral" String;

syntax Label = @category="Constant" Id;

syntax Nonterminal = @category="Identifier" Id;

syntax Rule = Nonterminal nt "=" {Prod "|"}+ prods;

syntax Prod 
  = Modifier* Label label ":" Sym!alt* syms Binding?
  | Modifier* Sym!alt* syms Binding?;

syntax Binding = "-\>" Label; 

syntax Modifier 
  = @category="MetaKeyword" "@override"
  | @category="MetaKeyword" "@error";

lexical Id 
  = [_][a-zA-Z][_a-zA-Z0-9]* !>> [_a-zA-Z0-9]
  | [a-zA-Z][_a-zA-Z0-9]* !>> [_a-zA-Z0-9]
  ;

syntax Sym 
  = Nonterminal
  | Placeholder
  | Literal
  | @category="Variable" Regexp
  | "(" Sym* ")"
  | "{" Sym Literal "}" "*"
  | "{" Sym Literal "}" "+"
  | Sym "?"
  | Sym "+"
  | Sym "*"
  > left alt: Sym "|" Sym
  //> left seq: Sym Sym
  ;
  
lexical Nat = [0-9]+ !>> [0-9];

lexical String = [\"]![\"]*[\"];

syntax Placeholder = "_" !>> [a-zA-Z] [0-9]* !>> [0-9];

lexical Regexp = "/" RegexpChar* "/";

lexical RegexpChar = ![\\/] | [\\][\\ntbrfp/];

 