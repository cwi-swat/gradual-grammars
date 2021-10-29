module GradualGrammar

extend lang::std::Layout;

/*

Well-formedness:

- unique labels of productions
- levels are numbers consecutively
- aspect grammars only use literals and _ and regulars
- nonterminals/prods references in aspects should exist in base grammar
  in the same level.

*/

start syntax Module = "module" Id name Directive* directives Level* levels;

syntax Directive 
  = "import" QName Binding?
  | "layout" Nonterminal "=" Sym
  | "modifies" String;

syntax QName = {Id "."}+;

syntax Level = @Foldable "level" Nat number Keywords? Remove? Rule*;

syntax Remove = "remove" {Label ","}+;

syntax Literal = @category="StringLiteral" String;

syntax Label = @category="Constant" Id;

syntax Nonterminal = @category="Identifier" Id;

syntax Rule = Nonterminal "=" {Prod "|"}+;

syntax Prod = Modifier* Label ":" Sym* Binding?;

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

syntax Placeholder = "_"[0-9]* !>> [0-9];

lexical Regexp = "/" RegexpChar* "/";

lexical RegexpChar = ![\\/] | [\\][\\ntbfp/];

 