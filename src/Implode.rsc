module Implode

import util::Maybe;
import Type;
import ParseTree;
import String;
import Node;
import IO;

&T<:node implode(type[&T<:node] astType, Tree tree, Maybe[type[Tree]] fabric=nothing()) {
  return typeCast(astType, implode(tree, astType.symbol, defs=astType.definitions));
} 


bool isASTarg(Tree a) = !(a.prod.def is lit || a.prod.def is cilit 
  || a.prod.def is layouts || a.prod.def is empty);

list[Tree] astArgs(list[Tree] args) = [ a | Tree a <- args, isASTarg(a) ];


value implode(Tree t, Symbol s, map[Symbol, Production] defs = ()) {
  s = delabel(s);
  switch (s) {
    case \bool(): return "<t>" == "true";
    case \int(): return toInt("<t>");
    case \str(): return "<t>";
    case \list(Symbol k): return [ implode(a, delabel(k), defs=defs) | Tree a <- astArgs(t.args) ];
    case \set(Symbol k): return { implode(a, delabel(k), defs=defs) | Tree a <- astArgs(t.args) };
    case \adt(_, _): return implodeToCons(t, s, defs);
    case \node(): return implodeToNode(t);
    case \value(): return "<t>";
    default: throw "Unsuported AST type: <s>";
  }
}

node implodeToCons(t:appl(prod(label(str l, sort(str n)), _, _), list[Tree] args), Symbol adt, map[Symbol, Production] defs) {
  assert adt is adt: "No adt given: <adt>";
  
  if (appl(prod(label(str l, sort(str n)), _, _), list[Tree] args) := t) { 
    if (cons(label(l, adt), list[Symbol] kids, list[Symbol] kws, _) <- defs[adt].alternatives) {
      println("KWS: <kws>");
      type[value] theType = type(adt, defs);  
      return typeCast(#node, make(theType, l, implodeArgs(astArgs(args), kids, defs), 
        ( "src": t@\loc | label("src", \loc()) <- kws )));
    }  
    throw "Could not find AST constructor for type <n> with name <l>";
  }
  
  throw "Expected a parse tree with a production label, not `<t>`";
}


Symbol delabel(label(_, Symbol s)) = s;
default Symbol delabel(Symbol s) = s;


value implodeToNode(Tree t) {
   if (appl(prod(label(str l, _), _, _), list[Tree] args) := t) {
     list[Tree] astArgs = astArgs(t.args);
     list[Symbol] astTypes = [ \node() | _ <- astArgs ];
     return makeNode(l, implodeArgs(astArgs, astTypes, ()), keywordParameters=("src": t@\loc));
   }
   if (appl(regular(_), list[Tree] args) := t) {
     return [ implode(a, \node()) | Tree a <- astArgs(args) ];
   }
   return "<t>";
}


list[value] implodeArgs(list[Tree] astArgs, list[Symbol] astTypes, map[Symbol, Production] defs) {
  if (size(astArgs) > size(astTypes)) {
    throw "Parse tree has more AST arguments than expected by AST type
          '  - <astTypes>";
  }
  if (size(astArgs) < size(astTypes)) {
    throw "Parse tree does not have enough AST arguments for AST type";
  }
  
  return [ implode(astArgs[i], astTypes[i], defs=defs) | int i <- [0..size(astArgs)] ];
}
