module Stitch

import Grammar;
import ParseTree;
import Type;

import QL;
import QL_NL;

import IO;
import String;

import lang::rascal::format::Grammar;

void main() {
  base = QL::reflect();
  fabric = QL_NL::reflect();
  x = stitch(base, fabric, "NL");
  
  g = \grammar({}, x.definitions);
  
  println(grammar2rascal(g, "bla"));
}


bool isLiteral(Symbol s) = (lit(_) := s) || (cilit(_) := s); //s is lit || s is cilit;


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
    return -1;
  }
  
  
  set[Production] weave(set[Production] ps, set[Production] fs) {
    
    list[Symbol] weaveSyms(list[Symbol] bss, list[Symbol] fss) {
      list[Symbol] astArgs = [ s | Symbol s <- bss, !isLiteral(s), !(s is layouts) ];
      int curArg = 0;
      return for (Symbol s <- fss) {
        switch (placeholderPos(s)) {
          case 0: {
            append astArgs[curArg];
            curArg += 1;
          }
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
    case choice(s:keywords(str kw), set[Production] _)
      => choice(s, fdefs[keywords("<kw>_<suffix>")].alternatives)
    case c:choice(s:sort(str nt), set[Production] ps): {
      Symbol fnt = sort("<nt>_<suffix>");
      if (fnt in fdefs) {
        insert choice(s, weave(ps, fdefs[fnt].alternatives));
      }
    }
  } 

} 

