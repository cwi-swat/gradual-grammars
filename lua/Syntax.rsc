@license{
  Copyright (c) 2009-2011 CWI and HvA
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
/*****************************************************************************/
/*!
* Lua is a light-weight embeddable scripting language. This Lua grammar is
* constructed from the specification provided in the Lua 5.2 Reference Manual
* by Roberto Ierusalimschy, Luiz Henrique de Figueiredo, Waldemar Celes
* http://www.lua.org/manual/5.2/
* @package      lang::lua
* @file         Syntax.rsc
* @brief        Defines the Lua 5.2 Syntax
* @contributor  Riemer van Rozen - rozen@cwi.nl - HvA - CREATE-IT, CWI
* @date         June 1st 2012
* @note         Compiler/Assembler: Rascal MPL.
*/
/*****************************************************************************/
module Syntax

/******************************************************************************
 * Lua Statements
 ******************************************************************************/
//Lua programs conists of statement blocks (also called chunks).
start syntax Block
  = chunk: Stat* stats RStat? opt_ret;

syntax RStat
 = s_ret:  "return" {Exp ","}* exp;

//Lua statements are limited to the following constructs.
syntax Stat
  = s_empty:   ";"
  //| s_return:  "return" {Exp ","}* exps //A block can end in a return statement
  | s_assign:  {Var ","}+ vars "=" {Exp ","}+ exps
  | s_call:    PrefixExp pe (":" Id opt_name)? Args args
               /*this:*/ () !>> "(" /*prevents ambiguity*/
  | s_label:   "::" Id name "::"
  | s_break:   "break"
  | s_goto:    "goto" Id name
  | s_block:   "do" Block b "end"
  | s_while:   "while" Exp e "do" Block b "end"
  | s_repeat:  "repeat" Block b "until" Exp e
  | s_if:      "if" Exp e1 "then" Block b1 
               ("elseif" Exp "then" Block)* elif
               ("else" /*(this:*/ !>> "if" /*prevents ambiguity)*/ Block b2)?
               "end"
  | s_for:     "for" Id name "=" Exp e1 "," Exp e2 ("," Exp e3)?
               "do" Block b "end"
  | s_foreach: "for" {Id ","}+ names "in" {Exp ","}+ exps
               "do" Block b "end"
  | s_fun:     "function" {Id "."}+ name_pre  (":" Id name_suf)?
                "(" ParList pars ")" Block b "end"
  | s_lfun:    "local" "function" Id name "(" ParList pars")" Block b "end"
  | s_local:   "local" {Id ","}+ names ("=" {Exp ","}+ exps)?;

/******************************************************************************
 * Lua Expressions
 ******************************************************************************/
syntax Exp
  = @category="Constant" e_nil:   "nil"
  | @category="Constant" e_false: "false"
  | @category="Constant" e_true:  "true"
  | @category="Constant" e_num:   INT val
  | @category="Constant" e_str:   "\"" STRING val "\""
  | e_dots:  "..."
  | e_fun:   "function" "(" ParList pars ")" Block b "end"
  | e_pre: PrefixExp e
  | e_table: TableConstructor t
  > right e_pow:  Exp "^" Exp   //Arithmetic Exponent Binary Expression
  > e_not:        "not" Exp     //Logical Not Unary Expression
  | e_len:        "#" Exp       //String Length Unary Expression
  | e_unm:        "-" Exp       //Arithmetic Negation Unary Expression
  > left
    ( left e_mul: Exp "*" Exp   //Arithmetic Multiply Binary Expression
    | left e_div: Exp "/" Exp   //Arithmetic Divide Binary Expression
    | left e_mod: Exp "%" Exp   //Arithmetic Modulo Binary Expression
    )
  > left
    ( left e_add: Exp "+" Exp   //Arithmetic Plus Binary Expression
    | left e_sub: Exp "-" Exp   //Arithmetic Minus Binary Expression
    )
  > right e_app:  Exp ".." Exp  //String Append Binary Expression
  > left
    ( left e_lt:  Exp "\<" Exp  //Relational Less Than Binary Expression
    | left e_gt:  Exp "\>" Exp  //Relational Greater Than Binary Expression
    | left e_le:  Exp "\<=" Exp //Relational Less-Equals Binary Expression
    | left e_ge:  Exp "\>=" Exp //Relational Greater-Equals Binary Expression
    | left e_neq: Exp "~=" Exp  //Relational Not-Equals Binary Expression
    | left e_eq:  Exp "==" Exp  //Relational Equals Binary Expression 
    )
  > left e_and:   Exp "and" Exp //Logical And Binary Expression
  > left e_or:    Exp "or" Exp; //Logical Or Binary Expression
   
syntax PrefixExp
  = e_var:  Var v
  | e_call: PrefixExp pe (":" Id opt_name)? Args args
  | e_override: "(" Exp e ")";
   
syntax Var
  = v_name: Id name
  | v_index: PrefixExp pe "[" Exp e "]"
  | v_dot: PrefixExp pe "." Id name;

/******************************************************************************
 * Arguments and Parameters
 ******************************************************************************/
syntax Args
  = a_args: "(" {Exp ","}* exps ")"
  | a_table: TableConstructor t
  | a_string: "\"" STRING "\"";

syntax ParList
  = p_list: {Id ","}+ names ("," "...")? varargs
  | p_none: "..."? varargs;
  
/******************************************************************************
 * Lua Table Constructors
 ******************************************************************************/ 
syntax TableConstructor
  = table: "{" {Field FieldSep?}* fields "}"; //field separators are optional

syntax Field
  = n_field: Id "=" Exp
  | e_field: "[" Exp "]" "=" Exp
  | i_field: Exp;

syntax FieldSep
  = "," | ";";
  
/******************************************************************************
 * Identifiers
 ******************************************************************************/  
syntax Id
  = id: NAME name;
  
/******************************************************************************
 * Lua Lexicals
 ******************************************************************************/
keyword Keyword
 = "and" | "break" | "do" | "else" | "elseif" | "end" | "false" | "for"
 | "function" | "goto" | "if" | "in" | "nil" | "not" | "or" | "repeat"
 | "return" | "then" | "true" | "until" | "while";

lexical NAME
  = @category="Variable" ([a-zA-Z_] [a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;

//Number represents real (double-precision floating-point) numbers.
//(It is easy to build Lua interpreters that use other internal
//representations for numbers such as single-precision float or long integers;
//see file luaconf.h.) 
lexical INT
  = [0-9]+ ("." [0-9]+)?; //FIXME: double-precision floating-point

lexical STRING
  = ![\"]*;

layout Layout
  = WhitespaceAndComment* !>> [\ \t\n\r] !>> "--" !>> "--[[";

lexical WhitespaceAndComment 
   = @category="Comment" [\ \t\n\r]
   | @category="Comment" [\-] [\-] !>> "[[" ![\n]* $
   | @category="Comment" [\-] [\-] [\[] [\[] CommentBodyChar* [\]] [\]];

lexical CommentBodyChar
   = ![\]]            //not a closing bracket
   | [\]] !>> [\]];   //a closing bracket not followed by another one

public start[Block] lua_parse(str luaString, loc luaFile) = 
  parse(#start[Block], luaString, luaFile);
  
public start[Block] lua_parse(loc luaFile) = 
  parse(#start[Block], luaFile);
