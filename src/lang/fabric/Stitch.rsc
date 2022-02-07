module lang::fabric::Stitch

import Grammar;
import ParseTree;
import Type;
import IO;
import String;
import Set;
import List;

import lang::rascal::format::Grammar;

import util::Maybe;
import util::Benchmark;
import util::Implode;


void writeStitchedGrammar(type[&T<:Tree] base, type[&U<:Tree] fabric, 
 		str suffix, loc path, str modName, str placeholder="X") {
	x = stitch(base, fabric, suffix);
	g = grammar({}, inlineStarts(x.definitions));
	rsc = grammar2rascal(g, modName);
	int i = findLast(modName, "::");
	if (i >= 0) {
		modName = modName[i+2..];
	}
	path.path += "/<modName>.rsc";
	writeFile(path, rsc);
}

map[Symbol, Production] inlineStarts(map[Symbol, Production] defs) {
	for (Symbol s <- defs, s is \start) {
		Symbol arg = s.symbol;
		if (arg in defs) {
		  defs -= (s: defs[s]); // delete vacuous start entry
		  defs[s] = defs[arg][def=s]; // define new one
		  defs -= (arg: defs[arg]); // remove non-start entry
		}
		else {
		  println("WARNING: couldn\'t find definition for <s>");
		}
	}
	return defs;
}

ASTreorder fabric2reorder(type[&T<:Tree] fabric, str locale, str prefix = "X") {
  ASTreorder reorder = {};
  
  int remap(Symbol s, int base) {
    if (sort(/<prefix>_<pos:[0-9]+>/) := s) {
      return toInt(pos) - 1; // the placeholders are 1-based
    }
    return base;
  }
  
  list[Symbol] astSyms(list[Symbol] ss)
    = [ s | Symbol s <- ss, !isLiteral(s), !isLayout(s), !(s is empty) ];
  
  for (Symbol s <- fabric.definitions) {
    for (/prod(label(str l, sort(/^<nt:[a-zA-Z0-9_]+>_<locale>$/)), list[Symbol] syms, _) := fabric.definitions[s]) {
      list[Symbol] as = astSyms(syms);
      reorder += {<nt, l, ( i: remap(as[i], i) | int i <- [0..size(as)] )>};
    }
  }
  return reorder;
}


bool isLiteral(Symbol s) = (lit(_) := s) || (cilit(_) := s); 

bool isLayout(Symbol s) = (s is layouts); 


Tree astAt(list[Tree] args, int i) {
   asts = [ a | Tree a <- args, !isLiteral(a.prod.def), !(a.prod.def is layouts) ];
   return asts[i];
}

list[Symbol] anchor(list[Symbol] ss, str prefix) {
    // assumes either all placeholders are consecutive or none
    int i = 0;
    return visit (ss) {
      case sort(prefix): {
        i += 1;
        insert(sort("<prefix>_<i>"));
      }
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



Tree makeLitTree(Symbol s) {
   list[Symbol] syms = [ \char-class([range(c, c)]) | int c <- chars(s.string) ];
   list[Tree] args = [ char(c) | int c <- chars(s.string) ];
   
   return appl(prod(s, syms, {}), args);
}



// assumes only numbered placeholders in fabric.
list[Tree] unravel(list[Symbol] ref, list[Symbol] fabric, list[Tree] args, str prefix) {
  if (size(fabric) != size(args)) {
    println("Incompatible fabric prod:");
    println(fabric);
    println("For kid arguments: ");
    for (int i <- [0..size(args)]) {
      println("<i>: <args[i]>");
    }

  }


  assert size(fabric) == size(args);
  
  int cur = 0; // child index in current tree (and fabric production)
  
  void skipLiteralIfAny() {
    if (cur < size(fabric) - 2, isLayout(fabric[cur]), isLiteral(fabric[cur+1])) {
      cur += 2;
    }
  }
  
  Tree nextLayout() {
    while (cur < size(fabric)) {
      if (isLiteral(fabric[cur])) {
        cur += 1;
      }
      else if (isLayout(fabric[cur])) {
        return args[cur];
      }
    }
    return dummyLayout(); // needed if ref needs more layout than available in fabric.
  }
  
  Tree nextAST() {
     while (cur < size(fabric), isLiteral(fabric[cur]) || isLayout(fabric[cur])) {
       cur += 1;
     }
     return args[cur];
  }
  

  int fut = 0; // index in the future (reference) production
  map[int, int] reorder = ( i: 0 | int i <- [0..size(ref)]);
  
  newArgs = while (fut < size(ref)) {
    if (isLiteral(ref[fut])) {
      append makeLitTree(ref[fut]);
      skipLiteralIfAny();
    }
    else if (isLayout(ref[fut])) {
      append nextLayout(); // skipping a potential lit
    }
    else {
      append nextAST(); // skipping consecutive lits and layouts
      reorder[fut] = placeholderPos(fabric[cur], prefix);
      cur += 1;
    }

    fut += 1;   
  }  
  
  return [ reorder[i] > 0 ? astAt(newArgs, reorder[i] - 1) : newArgs[i] | int i <- [0..size(newArgs)] ];
}


@doc{Transform a parse tree from parsing over a stitched grammar to a parse tree over the ref grammar}
&T<:Tree unravel(type[&T<:Tree] ref, type[&U<:Tree] fabric, &U<:Tree pt, str locale, str prefix = "X") {
  
  @memo
  Maybe[tuple[Production, Production]] lookup(str l, str nt) {
    if (/bp:prod(label(l, sort(nt)), _, _) := ref.definitions[sort(nt)], 
        /fp:prod(label(l, sort(/<nt>_<locale>/)), _, _) := fabric.definitions[sort("<nt>_<locale>")]) { 
        return just(<bp, fp>);
    }
    return nothing();
  }

  &T rewrite(&T t) { // todo: locs
    switch (t) {
      case appl(p:prod(\start(_), _, _), list[Tree] args): {
        return appl(p, [ rewrite(a) | Tree a <- args ]);
      }
      case appl(p:regular(_), list[Tree] args): {
        return appl(p, [ rewrite(a) | Tree a <- args ]);
      }
      case appl(p:prod(label(str l, sort(str nt)), _, _), list[Tree] args): {
        args = [ rewrite(a) | Tree a <- args ];
        if (just(<Production bp, Production fp>) := lookup(l, nt)) {
          return appl(bp, unravel(bp.symbols, anchor(fp.symbols, prefix), args, prefix));
        }
        return appl(p, args);
      }
      case appl(p:prod(sort(str nt), _, {_*, \bracket()}), list[Tree] args): {
        args = [ rewrite(a) | Tree a <- args ];
        return appl(p, args);
      }
      default: {
        return t;
      }
    }
  }

  return typeCast(ref, rewrite(pt));

  // return visit (pt) {
  //   case t:appl(prod(s:label(str l, sort(str nt)), _, _), list[Tree] args) 
  //     => appl(bp, unravel(bp.symbols, anchor(fp.symbols, prefix), args, prefix)) // [@\loc=t@\loc]      
  //     when just(Production bp, Production fp) := lookup(l, nt)
  // } 
}



type[&T] stitch(type[&T<:Tree] base, type[&U<:Tree] fabric, str suffix, str placeholder = "X") {
  bdefs = base.definitions;
  fdefs = fabric.definitions;
  
  list[Production] weave(list[Production] ps, set[Production] fs) {
    
    list[Symbol] weaveSyms(list[Symbol] bss, list[Symbol] fss) {
      list[Symbol] astArgs = [ s | Symbol s <- bss, !isLiteral(s), !(s is layouts) ];
      int curArg = 0;
      return for (Symbol s <- fss) {
        switch (placeholderPos(s, placeholder)) {
          case 0: { // NB: assumes that all placeholders are consecutive (no mixing of X and X_i)
            append astArgs[curArg];
            curArg += 1;
          }
          case -1: append s; // Not a placeholder
          
          default: append astArgs[placeholderPos(s, placeholder) - 1];
        } 
      }
    }
    
    Production weave1(Production p) {
      if (prod(label(str l, sort(str nt)), list[Symbol] bss, set[Attr] as) := p
         , str nt2 := "<nt>_<suffix>"
         , f:prod(label(l, sort(nt2)), list[Symbol] ss, _) <- fs) {

        return prod(label(l, sort(nt)), weaveSyms(bss, ss), as); 
      }
      return p; // unchanged
    }
    
    return [ weave1(p) | Production p <- ps ];
  }
  
  return visit (base) {
    // keywords are simply overruled
    case choice(s:keywords(str kw), set[Production] _)
      => choice(s, fdefs[keywords("<kw>_<suffix>")].alternatives)

    case associativity(s:sort(str nt), Associativity a, set[Production] ps) 
      => associativity(s, a, toSet(weave(toList(ps), fdefs[fnt].alternatives)))
      when 
        Symbol fnt := sort("<nt>_<suffix>"),
        fnt in fdefs

    case priority(s:sort(str nt), list[Production] ps) 
      => priority(s, weave(ps, fdefs[fnt].alternatives))
      when 
        Symbol fnt := sort("<nt>_<suffix>"),
        fnt in fdefs
 	
    case choice(s:sort(str nt), set[Production] ps) 
      => choice(s, toSet(weave(toList(ps), fdefs[fnt].alternatives)))
      when 
        Symbol fnt := sort("<nt>_<suffix>"),
        fnt in fdefs
  } 

} 

