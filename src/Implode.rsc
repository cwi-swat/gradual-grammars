module Implode

import util::Maybe;
import Type;
import ParseTree;
import String;
import Node;
import IO;

&T<:node implode(type[&T<:node] astType, Tree tree) 
  = typeCast(astType, implode(tree, astType.symbol, defs=astType.definitions));


value implode(Tree t, Symbol s, map[Symbol, Production] defs = ()) {
  s = delabel(s);
  switch (s) {
    case \bool(): return "<t>" == "true";
    case \int(): return toInt("<t>");
    case \str(): return "<t>";
    case \list(Symbol k): return [ implode(a, k, defs=defs) | Tree a <- astArgs(t.args) ];
    case \set(Symbol k): return { implode(a, k, defs=defs) | Tree a <- astArgs(t.args) };
    case \tuple(list[Symbol] ks): return implodeToTuple(astArgs(t.args), ks, defs);
    case \adt(_, _): return implodeToCons(t, s, defs);
    case \node(): return implodeToNode(t);
    case \value(): return "<t>";
    default: throw "Unsuported AST type: <s>";
  }
}

node implodeToCons(Tree t, Symbol adt, map[Symbol, Production] defs) {
  assert adt is adt: "No adt given: <adt>";
  
  if (appl(prod(label(str l, sort(str n)), _, _), list[Tree] args) := t) { 
    if (cons(label(l, adt), list[Symbol] kids, list[Symbol] kws, _) <- defs[adt].alternatives) {
      type[value] theType = type(adt, defs);  
      return typeCast(#node, make(theType, l, implodeArgs(astArgs(args), kids, defs), 
        ( "src": t@\loc | label("src", \loc()) <- kws )));
    }  
    throw "Could not find AST constructor for type <n> with name <l>";
  }
  
  throw "Expected a parse tree with a production label, not `<t>`";
}

list[value] implodeArgs(list[Tree] astArgs, list[Symbol] astTypes, map[Symbol, Production] defs) {
  if (size(astArgs) > size(astTypes)) {
    throw "Parse tree has more AST arguments than expected by AST type";
  }
  if (size(astArgs) < size(astTypes)) {
    throw "Parse tree does not have enough AST arguments for AST type";
  }
  
  return [ implode(astArgs[i], astTypes[i], defs=defs) | int i <- [0..size(astArgs)] ];
}


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

value implodeToTuple(list[Tree] astArgs, list[Symbol] syms, map[Symbol, Production] defs) {
   value im(int i, Symbol s) {
     return implode(astArgs[i], s, defs=defs);
   }
   
   switch (syms) {
     case [Symbol s0]: return <im(0, s0)>;
     case [Symbol s0, Symbol s1]: return <im(0, s0), im(1, s1)>;
     case [Symbol s0, Symbol s1, Symbol s2]: return <im(0, s0), im(1, s1), im(2, s2)>;
     case [Symbol s0, Symbol s1, Symbol s2, Symbol s3]: return <im(0, s0), im(1, s1), im(2, s2), im(3, s3)>;
     default: throw "Unsupported tuple arity: <size(syms)>";
   }
}




Symbol delabel(label(_, Symbol s)) = s;
default Symbol delabel(Symbol s) = s;

bool isASTarg(Tree a) = !(a.prod.def is lit || a.prod.def is cilit 
  || a.prod.def is layouts || a.prod.def is empty);

list[Tree] astArgs(list[Tree] args) = [ a | Tree a <- args, isASTarg(a) ];
