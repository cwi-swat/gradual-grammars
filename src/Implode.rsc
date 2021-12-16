module Implode

import util::Maybe;
import Type;
import ParseTree;
import String;
import Node;
import IO;
import Map;
import Exception;


/*
 * For testing
 */
 
 
layout Space = [\ ]* !>> [\ ];
 
start syntax Prog
 = prog: Stat*;
 
syntax Stat
  = assign: Id ":=" Expr
  | group: "{" Stat* "}"
  | parallel: "{|" Stat* "|}"
  ;

syntax Expr
  = boolean: Bool
  | integer: Int
  | var: Id
  | pair: "(" Expr "," Expr ")"
  | bracket "(" Expr ")"
  | left add: Expr "+" Expr
  > quote: "quote" Expr
  ;

lexical Id = [a-z]+ !>> [a-z] \ Reserved;

keyword Reserved = "true" | "false";

lexical Int = [0-9]+ !>> [0-9];

syntax Bool = "true" | "false";

data AProg = prog(list[AStat] stats);

data AStat
  = assign(str var, AExpr expr)
  | group(list[AStat] stats)
  | parallel(set[AStat] sstats)
  ;

data AExpr
  = boolean(bool b)
  | integer(int n)
  | var(str s)
  | quote(node t)
  | add(AExpr lhs, AExpr rhs)
  ;


test bool testLexicalBool() = implode(#AExpr, (Expr)`true`, adtPrefix="A") == boolean(true);

test bool testLexicalInt() = implode(#AExpr, (Expr)`42`, adtPrefix="A") == integer(42);

test bool testLexicalStr() = implode(#AExpr, (Expr)`x`, adtPrefix="A") == var("x");

test bool testUntypedNode() = implode(#AExpr, (Expr)`quote 42 + 42`, adtPrefix="A") == quote("add"("integer"("42"), "integer"("42")));

alias ASTreorder = rel[str nt, str label, map[int, int] reorder];

data Exception
  = ImplodeException(str message, loc l);


&T<:node implode(type[&T<:node] astType, Tree tree, ASTreorder reorder = {}, str adtPrefix = "") 
  = typeCast(astType, implode(tree, astType.symbol,
       defs=astType.definitions, reorder=reorder, adtPrefix=adtPrefix));


value implode(Tree t, Symbol s, map[Symbol, Production] defs = (), ASTreorder reorder = {}, str adtPrefix="") {
  s = delabel(s);
  switch (s) {
    case \bool(): return "<t>" == "true";
    case \int(): return toInt("<t>");
    case \str(): return "<t>";
    case \list(Symbol k): return [ implode(a, k, defs=defs, reorder=reorder, adtPrefix=adtPrefix) | Tree a <- astArgs(t.args) ];
    case \set(Symbol k): return { implode(a, k, defs=defs, reorder=reorder, adtPrefix=adtPrefix) | Tree a <- astArgs(t.args) };
    case \adt(_, _): return implodeToCons(t, s, defs, reorder, adtPrefix);
    case \node(): return implodeToNode(t);
    case \value(): return "<t>";
    default: throw ImplodeException("Unsuported AST type: <s>", t@\loc);
  }
}

list[value] applyRemapping(list[value] args, map[int, int] remap) 
  = [ args[remap[i]] | int i <- [0..size(args)] ];
   
Symbol unprefixAdt(str prefix, adt(/<prefix><n:.*>$/, l:_)) = adt(n, l);    
   
node implodeToCons(Tree t, Symbol adt, map[Symbol, Production] defs, ASTreorder reorder, str adtPrefix) {
  assert adt is adt: "No adt given: <adt>";
  
  
  if (appl(prod(_, _, {_*, \bracket()}), list[Tree] args) := t) {
  	return implodeToCons(args[2], adt, defs, reorder, adtPrefix);
  }
  
  
  if (appl(prod(label(str l, sort(str n)), _, _), list[Tree] args) := t) { 
    assert unprefixAdt(adtPrefix, adt).name == n: "Provided adt does not have the same name (<adt.name>) as the nonterminal <n>";
     
    if (cons(label(l, adt), list[Symbol] kids, list[Symbol] kws, _) <- defs[adt].alternatives) {
        
      list[value] impArgs = implodeArgs(astArgs(args), kids, defs, reorder, adtPrefix);
      
      // this if is essential because reordering is opt-in
      // the fabric does not have to reorder everything.
      if (<n, l, map[int, int] remap> <- reorder) {
        impArgs = applyRemapping(impArgs, remap);
      } 
      
      type[value] theType = type(adt, defs);  
      return typeCast(#node, make(theType, l, impArgs, 
        ( "src": t@\loc | label("src", \loc()) <- kws )));
    }  
    throw ImplodeException("Could not find AST constructor for type <n> with name <l>", t@\loc);
  }
  
  throw ImplodeException("Expected a parse tree with a production label, not `<t>`", t@\loc);
}

list[value] implodeArgs(list[Tree] astArgs, list[Symbol] astTypes, map[Symbol, Production] defs, ASTreorder reorder, str adtPrefix) {
  if (size(astArgs) != size(astTypes)) {
    throw ImplodeException("Arity mismatch (tree: <size(astArgs)>, cons: <size(astTypes)>)", astArgs[0]@\loc);
  }
  
  return [ implode(astArgs[i], astTypes[i], defs=defs, reorder=reorder, adtPrefix=adtPrefix) | int i <- [0..size(astArgs)] ];
}


value implodeToNode(Tree t) {
   // as soon as we go into node, we drop the definitions,
   // and stay "untyped": all lexicals will be strings. 
   if (appl(prod(label(str l, _), _, _), list[Tree] args) := t) {
     list[Tree] astArgs = astArgs(t.args);
     list[Symbol] astTypes = [ \node() | _ <- astArgs ];
     return makeNode(l, implodeArgs(astArgs, astTypes, (), {}, "")); //, keywordParameters=("src": t@\loc));
   }
   if (appl(regular(_), list[Tree] args) := t) {
     return [ implode(a, \node()) | Tree a <- astArgs(args) ];
   }
   return "<t>";
}





Symbol delabel(label(_, Symbol s)) = s;
default Symbol delabel(Symbol s) = s;

bool isASTarg(Tree a) = !(a.prod.def is lit || a.prod.def is cilit 
  || a.prod.def is layouts || a.prod.def is empty);

list[Tree] astArgs(list[Tree] args) = [ a | Tree a <- args, isASTarg(a) ];


