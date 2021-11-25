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


start[Form] testIt(Tree q) {
  type[start[Form]] base = QL::reflect();
  type[start[Form_NL]] fabric = QL_NL_fabric::reflect();
  return unravel(base, fabric, q, "NL");
}

@doc{Transform a parse tree from parsing over a stitched grammar to a parse tree over the base grammar}
&T<:Tree unravel(type[&T<:Tree] base, type[&U<:Tree] fabric, &U pt, str suffix, str placeholder = "X") {
  
  list[Tree] unravel(Production baseProd, Production fabricProd, list[Tree] args) {
    /*
    
     Tree:  vraag leeftijd met "Leeftijd" : getal
     Fabric: "vraag" X_2 "met" X_1 ":" X_3
     Base:  "ask" String "into" Id ":" Type;
  
    */
    
    //println("BASE prod: <baseProd>");
    //println("FABRIC prod: <fabricProd>");
    
    int placeholderIndex(int pos) {
      //println("LOOKING FOR PLACEHOLDER at <pos>");
      int placeholdersSeen = 0;
      for (int i <- [0,2..size(fabricProd.symbols)]) {
         Symbol s = fabricProd.symbols[i];
         //println("SYMBOL @ <i>: <s>");
         
         if (sort(/<placeholder>_<x:[0-9]+>/) := s) {
           placeholdersSeen += 1;
           if (toInt(x) == pos) {
             //println("FOUND indexed placeholder");
             return i;
           }
         } 
         
         if (sort(placeholder) := s) {
           placeholdersSeen += 1;
           if (placeholdersSeen == pos) {
             //println("FOUND lone placeholder");
             return i;
           }
        }
      }
      throw "Could not find placeholder corresponding to <pos>";
    }
    
    list[Tree] newArgs = [];
    
    Tree makeLitTree(Symbol s) {
       list[Symbol] syms = [ \char-class([range(c, c)]) | int c <- chars(s.string) ];
       list[Tree] args = [ char(c) | int c <- chars(s.string) ];
       
       return appl(prod(s, syms, {}), args);
    }
    
    // TODO: we need to merge consecutive layout nodes (?)
    // in case of keyword removal als (x) dan { -> if (x)  { (note the two spaces
    // or maybe we don't...
    
    int i = 0;
    int astPos = 0;
    for (Symbol s <- baseProd.symbols) {
      if (isLiteral(s)) {
        newArgs += [makeLitTree(s)];
      }
      else if (s is layouts) {
        println("LAYOUT: <s> `<args[i]>`");
        newArgs += [args[i]];
      }
      else if (conditional(empty(), set[Condition] _) := s) {
        //println("CONDITIONAL: <s>");
        //println("ARGS[<i>]: <args[i]>");
        //println("ARGS[<i+1>]: `<args[i+1]>`");
        //TODO make this complete;  I don't understand why this works...
        //it looks like a conditional like this does not have an appl a
        newArgs += [args[i]]; 
      }
      else { // AST arg
        println("AST arg: <s>");
        int j = placeholderIndex(astPos + 1);
        println("AST tree: <args[j]>");
        newArgs += [args[j]];
        astPos += 1;
      }
      
      i += 1;
      
    }
    
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

type[&T] stitch(type[&T<:Tree] base, type[&U<:Tree] fabric, str suffix, str placeholder = "X") {
  bdefs = base.definitions;
  fdefs = fabric.definitions;
  
  
  int placeholderPos(Symbol s) {
    if (sort(/<placeholder>_<pos:[0-9]+>/) := s) {
      return toInt(pos); // 1-based
    }
    if (sort(placeholder) := s) {
      return 0; // consecutive
    }
    return -1; // not a placeholder
  }
  
  
  set[Production] weave(set[Production] ps, set[Production] fs) {
    
    list[Symbol] weaveSyms(list[Symbol] bss, list[Symbol] fss) {
      list[Symbol] astArgs = [ s | Symbol s <- bss, !isLiteral(s), !(s is layouts) ];
      int curArg = 0;
      return for (Symbol s <- fss) {
        switch (placeholderPos(s)) {
          case 0: {
            // NB: assumes that all placeholders are consecutive
            // (no mixing of X and X_i)
            append astArgs[curArg];
            curArg += 1;
          }
          
          // Not a placeholder
          case -1: append s;
          
          default: append astArgs[placeholderPos(s) - 1];
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

    case c:choice(s:sort(str nt), set[Production] ps) 
      => choice(s, weave(ps, fdefs[fnt].alternatives))
      when 
        Symbol fnt := sort("<nt>_<suffix>"),
        fnt in fdefs
  } 

} 

