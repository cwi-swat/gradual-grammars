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
  if (g.base != "") {
    // assumes base grammar is in same directory.
    str locale = g.locale;
    println("LOG: compiling fabric grammar with reference <g.base>");
    AGrammar base = load(g.src[file=g.base]);
    base = stitchGrammar(base, g);
    base.prefix += "-<locale>-"; // hack  
    dumpFiles(explode(base));
  }
  else {
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
  AGrammar newG = g;
  newG.levels = [];
  for (int i <- [0..size(g.levels)]) {
    ALevel current = g.levels[i];
    println("LOG: level <current.n>");    
    newG.levels += [merge(g.levels[0..i+1])];
    newG.levels[i].n = current.n;
  }
  
  return newG;
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
  // return visit (level) {
  //   case AProd p => p[symbols = interleave(sym, p.symbols)]
  //   case seq(list[ASymbol] ss) => seq(interleave(sym, ss))
  // }
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
         theRule = existing;
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
         else {
  	       theRule.prods += [p];
         }
      }
       
       // add back again.
       if (theRule.prods != []) {
         merged.rules += [theRule];
       }
     }
  }
  return merged;
}

AGrammar stitchGrammar(AGrammar base, AGrammar fabric) {
  for (int i <- [0..size(base.levels)]) {
    ALevel baseLevel = base.levels[i];

    if (ALevel fabricLevel <- fabric.levels, fabricLevel.n == baseLevel.n) {
      // we have customizations.

      for (int j <- [0..size(baseLevel.rules)]) {
        ARule baseRule = baseLevel.rules[j];
        
        if (ARule fabricRule <- fabricLevel.rules, fabricRule.nt == baseRule.nt) {

          for (int k <- [0..size(baseRule.prods)]) {
            AProd baseProd = baseRule.prods[k];

            if (AProd fabricProd <- fabricRule.prods, fabricProd.label == baseProd.label) {
              baseRule.prods[k] = stitchProds(baseProd, fabricProd);
            }
          }
        }
        
        baseLevel.rules[j] = baseRule;
      }
    }

    base.levels[i] = baseLevel;
  }

  return base;
}

AProd stitchProds(AProd base, AProd fabric) {
  assert fabric.label == base.label;
  
  int astPos = 1;

  ASymbol lookupAST(int pos) {
    int cur = 1;
    for (/ASymbol s <- base.symbols, !(s is literal)) {
      if (cur == pos) {
        return s;
      }
      cur += 1;
    }
    throw "error: ast pos <pos> out of bounds for <base>";
  }
  
  ASymbol lookup(ASymbol s) {
    if (s is placeholder) {
      if (s.pos > 0) {
        return lookupAST(s.pos);
      }
      ASymbol a = lookupAST(astPos);
      astPos += 1;
      return a;
    }
    return s;
  }

  // we modify base to preserve metadata.
  base.symbols = visit (fabric.symbols) {
     case ASymbol s => lookup(s) 
  }

  return base;
}




