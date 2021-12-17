module Implode

import util::Maybe;
import Type;
import ParseTree;
import String;
import Node;
import IO;
import Map;
import Exception;

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
    case \value(): return implodeToNode(t);
    default: throw ImplodeException("Unsuported AST type: <s>", t@\loc);
  }
}

list[&T] applyRemapping(list[&T] args, map[int, int] remap) 
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
      
      // reorder the AST types according to their expected order in the syntax
      if (<n, l, map[int, int] remap> <- reorder) {
        kids = applyRemapping(kids, remap);
      }  
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
   
   if (appl(prod(_, _, {_*, \bracket()}), list[Tree] args) := t) {
  	return implodeToNode(args[2]);
  }
   
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


