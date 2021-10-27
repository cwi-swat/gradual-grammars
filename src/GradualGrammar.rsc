module GradualGrammar

extend lang::std::Layout;

/*

How to compile to Lark

- do modular stuff (remove/override)
- replace literals with defined tokens (with _)
- intersplice with layout symbol (with _)
- generate code.

*/

start syntax Module = "module" Id name Directive* directives Level* levels;

syntax Directive 
  = "import" QName Binding?
  | "layout" Nonterminal "=" Symbol;

syntax QName = {Id "."}+;

syntax Level = @Foldable "level" Nat number Keywords? Remove? Rule*;

syntax Remove = "remove" {Label ","}+;

syntax Literal = @category="StringLiteral" String;

syntax Label = @category="Constant" Id;

syntax Nonterminal = @category="Identifier" Id;

syntax Rule = Nonterminal "=" {Production "|"}+;

syntax Production = Modifier* Label ":" Symbol* Binding?;

syntax Binding = "-\>" Label; 

syntax Modifier 
  = @category="MetaKeyword" "@override"
  | @category="MetaKeyword" "@error";

lexical Id = [_a-zA-Z][_a-zA-Z0-9]* !>> [_a-zA-Z0-9];

syntax Symbol 
  = Nonterminal
  | Literal
  | @category="Variable" Regexp
  | "(" Symbol* ")"
  | "{" Symbol Literal "}" "*"
  | "{" Symbol Literal "}" "+"
  | Symbol "?"
  | Symbol "+"
  | Symbol "*"
  > left alt: Symbol "|" Symbol
  //> left seq: Symbol Symbol
  ;
  
lexical Nat = [0-9]+ !>> [0-9];

lexical String = [\"]![\"]*[\"];


lexical Regexp = "/" RegexpChar* "/";

lexical RegexpChar = ![\\/] | [\\][\\ntbfp/];

 