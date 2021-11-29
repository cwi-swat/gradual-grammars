module Stitch

import Grammar;
import ParseTree;
import Type;

import QL;
import QL_NL_fabric;

import IO;
import String;

import lang::rascal::format::Grammar;

void main() {
  base = QL::reflect();
  fabric = QL_NL_fabric::reflect();
  x = stitch(base, fabric, "NL");
  
  g = \grammar({\start(sort("Form"))}, x.definitions);
  
  str moduleName = "QL_NL";
  
  rsc = grammar2rascal(g, moduleName);
  println(rsc);
  
  writeFile(|project://gradual-grammars/src/<moduleName>.rsc|, rsc);
}


bool isLiteral(Symbol s) = (lit(_) := s) || (cilit(_) := s); 


start[Form] testIt(str form) {
  type[start[Form]] base = QL::reflect();
  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
  type[start[Form]] st = stitch(base, fabric, "NL");
  start[Form] f = parse(st, form);
  return unravel(base, fabric, f, "NL");
}

start[Form] testIt(Tree q) {
  type[start[Form]] base = QL::reflect();
  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
  return unravel(base, fabric, q, "NL");
}

Tree astAt(list[Tree] args, int i) {
   asts = [ a | Tree a <- args, !isLiteral(a.prod.def), !(a.prod.def is layouts) ];
   return asts[i];
}

// assumes only numbered placeholders in fabric.
list[Tree] match(list[Symbol] base, list[Symbol] fabric, list[Tree] args, str prefix) {
  assert size(fabric) == size(args);
  
  list[Tree] newArgs = [];
  
  
  list[Symbol] normalizePlaceholders(list[Symbol] ss) {
    int i = 0;
    return visit (fabric) {
      case sort(prefix): {
        i += 1;
        insert(sort("<prefix>_<i>"));
      }
    }
  }
  
  fabric = normalizePlaceholders(fabric);
  println("FABRIC: <fabric>");
  
  map[int, int] reorder = ();
  
  int i = 0;
  int j = 0;
  
  Tree findNextLayout() {
    foundLayout = false;
    lastWasLayout = false;
    Tree theLayout;   

    while (j < size(fabric)) {
      println("ARGS[<j>]: <args[j]>");
    
      if (isLiteral(fabric[j])) {
        println("SKIPPING literal: <args[j]>");
      }
      else if (fabric[j] is layouts) {
        println("ADDING layout: <args[j]>");
        return args[j];
      }
      else {
         break;
	  }         
      j += 1;
    }
    throw "cannot happen";
  }
  
  Tree findNextAST() {
     while (j < size(fabric), isLiteral(fabric[j]) || (fabric[j] is layouts)) {
        println("skipping FABRIC[<j>] = <fabric[j]>");
        j += 1;
     }
     println("FOUND AST: <args[j]>");
     return args[j];
  }
  
  while (i < size(base)) {
    Symbol s = base[i];
    println("#### NEED: <s>");
    reorder[i] = 0; // default init
    
    if (isLiteral(s)) {
      newArgs += [makeLitTree(s)];
    }
    else if (s is layouts) {
      newArgs += findNextLayout();
    }
    else {
      newArgs += findNextAST();
      reorder[i] = placeholderPos(fabric[j], prefix);
      j += 1;
    }

    i += 1;   
  }  
  
  println("REORDER: <reorder>");
  
  Tree lookup(int i) {
    if (reorder[i] > 0) {
      return astAt(newArgs, reorder[i] - 1);
    }
    return newArgs[i];
  }
  
  return [ lookup(i) | int i <- [0..size(newArgs)] ];
}

Tree makeLitTree(Symbol s) {
   list[Symbol] syms = [ \char-class([range(c, c)]) | int c <- chars(s.string) ];
   list[Tree] args = [ char(c) | int c <- chars(s.string) ];
   
   return appl(prod(s, syms, {}), args);
}


@doc{Transform a parse tree from parsing over a stitched grammar to a parse tree over the base grammar}
&T<:Tree unravel(type[&T<:Tree] base, type[&U<:Tree] fabric, &U pt, str suffix, str placeholder = "X") {
  
  list[Tree] unravel(Production baseProd, Production fabricProd, list[Tree] args) {
    /*
    
     Tree:  vraag leeftijd met "Leeftijd" : getal
     Fabric: "vraag" X_2 "met" X_1 ":" X_3
     Base:  "ask" String "into" Id ":" Type;
  
    */
    
    list[Tree] newArgs = match(baseProd.symbols, fabricProd.symbols, args, placeholder);
    
    return newArgs;
  }
  
  return visit (pt) {
    case t:appl(prod(s:label(str l, sort(str nt)), _, _), list[Tree] args) 
      => appl(bp, unravel(bp, fp, args))
      
      // not the most efficient way of looking up prods...
      when /bp:prod(s, _, _) := base.definitions, // NB: syms can be different
          // the template prod with the same label but suffixed sortname
         /fp:prod(label(l, sort(/<nt>_<suffix>/)), _, _) := fabric.definitions  
  } 
}

int placeholderPos(Symbol s, str prefix) {
    if (sort(/<prefix>_<pos:[0-9]+>/) := s) {
      return toInt(pos); // 1-based
    }
    if (sort(prefix) := s) {
      return 0; // consecutive
    }
    return -1; // not a placeholder
}


type[&T] stitch(type[&T<:Tree] base, type[&U<:Tree] fabric, str suffix, str placeholder = "X") {
  bdefs = base.definitions;
  fdefs = fabric.definitions;
  
  
  
  
  set[Production] weave(set[Production] ps, set[Production] fs) {
    
    list[Symbol] weaveSyms(list[Symbol] bss, list[Symbol] fss) {
      list[Symbol] astArgs = [ s | Symbol s <- bss, !isLiteral(s), !(s is layouts) ];
      int curArg = 0;
      return for (Symbol s <- fss) {
        switch (placeholderPos(s, placeholder)) {
          case 0: {
            // NB: assumes that all placeholders are consecutive
            // (no mixing of X and X_i)
            append astArgs[curArg];
            curArg += 1;
          }
          
          // Not a placeholder
          case -1: append s;
          
          default: append astArgs[placeholderPos(s, placeholder) - 1];
        } 
      }
    }
    
    Production weave1(Production p) {
      if (prod(label(str l, sort(str nt)), list[Symbol] bss, set[Attr] as) := p
         , str nt2 := "<nt>_<suffix>"
         , f:prod(label(l, sort(nt2)), list[Symbol] ss, _) <- fs) {

        /* 
          modify f:
          - strip suffix
          - replace placeholders with corresponding AST args
          - use attributes from base
        */
        
        return prod(label(l, sort(nt)), weaveSyms(bss, ss), as); 
      }
      return p; // unchanged
    }
    
    return { weave1(p) | Production p <- ps };
  }
  
  
  return visit (base) {
    // keywords are simply overruled
    case choice(s:keywords(str kw), set[Production] _)
      => choice(s, fdefs[keywords("<kw>_<suffix>")].alternatives)

 	// TODO: add priority etc.
 	//\priority(Symbol def, list[Production] choices) // <5>
     // \associativity(Symbol def, Associativity \assoc, set[Production] alternatives) // <6>
 	
    case c:choice(s:sort(str nt), set[Production] ps) 
      => choice(s, weave(ps, fdefs[fnt].alternatives))
      when 
        Symbol fnt := sort("<nt>_<suffix>"),
        fnt in fdefs
  } 

} 

