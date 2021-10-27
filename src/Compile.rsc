module Compile

import GradualGrammar;
import IO;
import String;
import List;

import AST;


loc levelLoc(str name, loc base, ALevel l)
  = base[file="<name>-<l.n>.lark"];


void compile(loc l) = compile(load(l));

void compile(start[Module] pt) = compile(implode(pt));

@doc{Compile a gradual grammar to LARK files representing each level}
void compile(AGrammar g) {
  
  if (g.base != "") {
    // assumes base grammar is in same directory.
    println("LOG: compiling grammar aspect with base <g.base>");
    AGrammar base = load(g.src[file=g.base]);
    g = customize(base, g);
  }

  println("LOG: compile grammar <g.name>");
  ASymbol ws = nonterminal(g.ws);
  for (int i <- [0..size(g.levels)]) {
    ALevel m = merge(g.levels[0..i+1]);
    m = interleaveLayout(ws, normalize(m));
    println("LOG: compiling level <g.levels[i].n>");
    writeFile(levelLoc(g.name, g.src, g.levels[i]), pp(g, m));
  }
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
      case ARule r => r[prods = [ p | p <- r.prods, p.label notin l.remove ]]
    }
  
     for (ARule r <- l.rules) {
       ARule theRule = arule(r.nt, []);
       if (ARule existing <- merged.rules, existing.nt == r.nt) {
         theRule = existing;
         // temporary removal
         merged.rules = delete(merged.rules, indexOf(merged.rules, existing));
       }
       for (AProd p <- r.prods) {
         if (p.override) {
           // remove the "previous" one
           theRule.prods = [ x | AProd x <- theRule.prods, x.label != p.label ];
         }
         theRule.prods += [p];
       }
       // add back again.
       merged.rules += [theRule];
     }
  }
  return merged;
}

@doc{Customize a base production with a production template}
AProd weave(AProd base, AProd custom) {

  list[ASymbol] weave(list[ASymbol] bs, list[ASymbol] cs) {
    int lastArg = 0;
    list[ASymbol] lst = [];
    for (ASymbol s <- cs) {
      if (s is literal) {
        lst += [s];
      }
      else if (s is placeholder) {
        if (int i <- [lastArg..size(bs)], !(bs[i] is literal)) {
          lst += [bs[i]];
          lastArg = i + 1;
        }
        else {
          println("WARNING: too many placeholders in custom production");
        } 
      }
      else if (reg(seq(list[ASymbol] ss)) := s, reg(seq(list[ASymbol] bss)) := bs[lastArg]) {
        lst += [reg(seq(weave(bss, ss)), sep=s.sep, opt=s.opt, many=s.many)];      
      }
      // todo: do the other nested symbols.
      else {
        println("WARNING: unsupported symbol in customizing production");
      }
    }
    return lst; 
  } 
  
  return aprod(base.label, weave(base.symbols, custom.symbols), 
    error=base.error, override=base.override, binding=base.binding);
}

@doc{Weave production "aspects" into a base grammar}
AGrammar customize(AGrammar base, AGrammar aspect) {
  for (ALevel l <- aspect.levels) {
    if (int i <- [0..size(base.levels)], ALevel bl := base.levels[i], bl.n == l.n) {
      for (ARule r <- l.rules) {
       if (ARule theRule <- bl.rules, theRule.nt == r.nt) {
         bl.rules = delete(bl.rules, indexOf(bl.rules, theRule));
         for (AProd p <- r.prods) {
		   if (int j <- [0..size(theRule.prods)], AProd p2 := theRule.prods[j], p2.label == p.label) {
		     theRule.prods[j] = weave(p2, p);
		   }
		   else {
		     println("WARNING: no production labeled <p.label> in base grammar");           
           }
         }
         // add back again.
         bl.rules += [theRule];
       }
       else {
         println("WARNING: no existing rule for <r.nt> in base grammar");
       }
     }
     base.levels[i] = bl;
    }
    else {
      println("WARNING: no level <l.n> in base grammar."); 
    }
  }
  
  return base[name=aspect.name];
}



