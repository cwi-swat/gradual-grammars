module lang::fabric::Compile

import lang::fabric::GradualGrammar;
import lang::fabric::AST;

import IO;
import String;
import List;



/*

Idea: infer keyword translation from formatted examples (canonical/complete/etc.)

- define formatter based on AST: the default one just formats
- but it can be parameterized by helper functions which insert brackets
  and/or meta notation, which allows the text to be generically parsed.
- as a result we get a structure that can be matched against the concrete grammar
  to derive a translated one.
  
Problem: how to "fix" implode in case of reordered things.


*/

loc levelLoc(str name, loc base, str prefix, ALevel l)
  = base[file="<prefix><l.n>.lark"];


void compile(loc l) = compile(load(l));

void compile(start[Module] pt) = compile(implode(pt));

@doc{Compile a gradual grammar to LARK files representing each level}
void compile(AGrammar g) {
  
  println("BASE: <g.base>");
  
  if (g.base != "") {
    // assumes base grammar is in same directory.
    str locale = g.locale;
    println("LOG: compiling grammar aspect with base <g.base>");
    AGrammar base = load(g.src[file=g.base]);
    base = explode(base);
    base = customize(base, g);
    base.prefix += "-<locale>-"; // hack  
    dumpFiles(base);
  }
  else {
	  println("LOG: compiling grammar <g.name> (<g.prefix>)");
	  dumpFiles(explode(g));
  }
  
}

void dumpFiles(AGrammar g) {
  for (int i <- [0..size(g.levels)]) {
    println("LOG: writing level <g.levels[i].n>");
    writeFile(levelLoc(g.name, g.src, g.prefix, g.levels[i]), 
    	toLark(g, g.levels[i]));
  }
}

AGrammar explode(AGrammar g) {
  for (int i <- [0..size(g.levels)]) {
    // this could be more efficient if the previously *merged* level
    // acts as the base of the next level merge.
    
    ALevel current = g.levels[i];
    println("LOG: level <current.n>");
    
    g.levels[i] = merge(g.levels[0..i+1]);
    g.levels[i].n = current.n;
  }
  
  return g;
}




@doc{Desugar separated list constructs}
ALevel normalize(ALevel level) {
  return visit (level) {
    case r:reg(ASymbol arg): {
      if (r.sep != "") {
        if (r.opt) { // {X ","}* -> (X ("," X)*)? 
          insert reg(seq([arg, reg(seq([literal(r.sep), arg]), opt=true, many=true)]),opt=true,many=false);
        }
        else { // {X ","}* -> X ("," X)*
          insert seq([arg, reg(seq([literal(r.sep), arg]), opt=false, many=true)]);
        }
      }
    }
  }
}

list[&T] interleave(&T elt, list[&T] lst) 
  = size(lst) > 0 ? [ lst[i], elt | int i <- [0..size(lst) - 1] ] + [ lst[-1] ] : [];
  
@doc{Interleave layout inbetween all sequences of symbols (requires normalize)}
ALevel interleaveLayout(ASymbol sym, ALevel level) {
  return level;
  return visit (level) {
    case AProd p => p[symbols = interleave(sym, p.symbols)]
    case seq(list[ASymbol] ss) => seq(interleave(sym, ss))
  }
}

@doc{Merge levels into one, observing remove and override}
ALevel merge(list[ALevel] levels) {
  assert size(levels) > 0;
  
  ALevel merged = levels[0];
  for (ALevel l <- levels[1..]) {
    merged = visit (merged) {
      // assumes labels are globally unique, not just per nt
      case ARule r: {
        r.prods = [ p | p <- r.prods, p.label notin l.remove ];
        r.prods = [ p[deprecatedAt =  p.label in l.deprecate ? l.n : -1]  | p <- r.prods ];
        insert r;
      }
    }
  
     for (ARule r <- l.rules) {
       ARule theRule = adefine(r.nt, []);
       
       if (ARule existing <- merged.rules, existing.nt == r.nt) {
         if (r is amodify) { 
            theRule = existing;
         }
         merged.rules = delete(merged.rules, indexOf(merged.rules, existing));  
       }
       
       for (AProd p <- r.prods) {
       
         
         if (p.label in l.deprecate) {
           println("LOG: deprecating <p.label>");
           p.deprecatedAt = l.n;
         }
         
         if (p.override) {
           if (int i <- [0..size(theRule.prods)], AProd x := theRule.prods[i], x.label == p.label) {
             theRule.prods[i] = p;
           }
           else {
             println("WARNING: trying to override non-existing base production labeled <p.label>");
           }
         }
         
  	     theRule.prods += [p];
       }
       
       if (r is amodify) {
         theRule.prods -= [ p2 | AProd p2 <- theRule.prods, AProd p0 <- r.removals, p2.symbols == p0.symbols ];
         theRule.prods -= [ p2 | AProd p2 <- theRule.prods, AProd p0 <- r.moveToEnd, p2.symbols == p0.symbols ];
         theRule.prods += r.moveToEnd;
       }
       
       // add back again.
       if (theRule.prods != []) {
         merged.rules += [theRule];
       }
     }
  }
  return merged;
}

/*

Pseudo code

(assume all placeholders have 1-based suffixes

symbols1 
symbols2


weave(Prod p1, Prod p2) {
  assert p1.label == p2.label;
  
  list[Symbol] astKids = [ s | Symbol s <- p1.symbols, !(s is literal) ];
  
  Symbol lookup(Symbol s) {
    if (s is placeholder) 
      return astKids[s.pos - 1];
    return s;
  }

  p2.symbols = [ lookup(s) | Symbol s <- p2.symbols ];
  return p2;
}


*/


bool isGroupOfLiterals(seq(list[ASymbol] ss))
  = ( true | it && isGroupOfLiterals(s) | ASymbol s <- ss );
  
bool isGroupOfLiterals(alt(ASymbol s1, ASymbol s2))
  = isGroupOfLiterals(s1) && isGroupOfLiterals(s2);
  
bool isGroupOfLiterals(literal(_)) = true;

default bool isGroupOfLiterals(ASymbol _) = false;

@doc{Customize a base production with a production template}
AProd weave(AProd base, AProd custom) {
  // a "map" from fysical pos in base, to placeholder pos in custom.
  lrel[int, int] reorder = [];
  
  list[ASymbol] weave(list[ASymbol] bs, list[ASymbol] cs) {
  	if (size(bs) != size(cs)) {
  	  println("WARNING: wrong arity of custom prod <toLark(custom)>; skipped.");
  	  return bs;
  	}
  
    list[ASymbol] lst = [];
    for (int i <- [0..size(cs)]) {
      ASymbol s = cs[i];
      
      if (s is placeholder) {
        reorder += [<i, s.pos - 1>];
        lst += [bs[i]];
      }
      else {
        lst += [s];
      }
      
    }
  
    return lst; 
  } 

  // NB: weave has side-effects in reorder map.
  AProd result = aprod(base.label, weave(base.symbols, custom.symbols), 
    error=base.error, override=base.override, binding=base.binding);
  
   // TODO: check that no pos is out of bounds and all pos are used and unique

   // let's say there's a placeholder _2 at index 0
   // this means that i have to find the second AST arg
   // in the original production (let's say at index i)
   // and put it at index 0;
  
  // map[int, ASymbol] baseASTpos = ();
  // astPos = 1; // NB: one based!
  // for (ASymbol s <- base.symbols) {
  //   if (!(s is literal)) {
  //     baseASTpos[astPos] = s;
  //     astPos += 1;
  //   } 
  // }
  // 
  // int i = 0;   
  // for (ASymbol s <- custom.symbols) {
  //   if (s is placeholder, s.pos > 0) {
  //     if (s.pos notin baseASTpos) {
  //       println("WARNING: position <s.pos> placeholder could not be found in base production");
  //     }
  //     else {
  //       result.symbols[i] = baseASTpos[s.pos];
  //     }
  //   }
  //   i += 1;
  // }
  // 
  //result.label = result.label +
  //  intercalate("", [ "_<s.pos>" | ASymbol s <- custom.symbols
  //                      , s is placeholder, s.pos > 0 ]);
  
  return result;
  
}

@doc{Weave production "aspects" into a base grammar}
AGrammar customize(AGrammar base, AGrammar aspect) {
  for (int i <- [0..size(base.levels)]) {
    ALevel bl = base.levels[i];
    println("LOG: weaving level: <bl.n>");
    
    set[str] done = {};
    
    
    // walk down the aspect levels.
      
    for (int j <- [i+1..0]) { //ALevel l <- aspect.levels, l.n <= bl.n) {
      
      // todo: we should not apply a customization
      // if a later level (say 12 ) has new production
      // for the current considered nonterminal
      // but no customization *at* that level (i.c. 12).
      if (ALevel l <- aspect.levels, l.n == j) {
        
        // notin done ensures that later customizations
        // take preference over earlier ones.
        for (ARule r <- l.rules, r.nt notin done) {
           done += {r.nt};
           
	       if (ARule theRule <- bl.rules, theRule.nt == r.nt) {
	         bl.rules = delete(bl.rules, indexOf(bl.rules, theRule));
	         int k = 0;
	         while (k < size(r.prods), k < size(theRule.prods)) {
	           theRule.prods[k] = weave(theRule.prods[k], r.prods[k]);
	           k += 1;
	         }
	         if (k < size(r.prods)) {
			     println("WARNING: no production at pos <k> in base grammar");           
	         }
	         // it add back again.
	         bl.rules += [theRule];
	       }
	       else {
	         println("WARNING: no existing rule for <r.nt> in base grammar");
	       }
	     }
	   }
    }
    
    base.levels[i] = bl;
  }
  
  return base[name=aspect.name];
}



