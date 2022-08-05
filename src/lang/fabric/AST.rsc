module lang::fabric::AST

import lang::fabric::GradualGrammar;
import String;
import List;
import ParseTree;
import IO;

data AGrammar(str ws = "", str base = "", str prefix="", str locale="", loc src = |file:///dummy|)
  = agrammar(str name, list[Import] imports, list[ALevel] levels);
  

alias Import = tuple[str name, str binding];

data ALevel(loc src = |file:///dummy|)
  = alevel(int n, list[str] remove, list[str] deprecate, list[ARule] rules);
  
data ARule(loc src = |file:///dummy|)
  = amodify(str nt, list[AProd] prods, list[AProd] removals = [], list[AProd] moveToEnd = [])
  | adefine(str nt, list[AProd] prods)
  ;
  
data AProd(bool error=false, bool override=false, int deprecatedAt = -1, str binding="", int level=-1, loc src = |file:///dummy|)
  = aprod(str label, list[ASymbol] symbols);
  
data ASymbol
  = nonterminal(str name)
  | literal(str lit)
  | regexp(str re)
  | seq(list[ASymbol] symbols)
  | alt(ASymbol lhs, ASymbol rhs)
  | reg(ASymbol arg, str sep="", bool opt=false, bool many=true)
  | placeholder(int pos = -1)
  ;


AGrammar load(loc l) = implode(parse(#start[Module], l));

AGrammar implode(start[Module] pt) {
  ds = [ <"<q>", ""> | (Directive)`import <QName q>` <- pt.top.directives ]
    +[ <"<q>", "<l>"> | (Directive)`import <QName q> -\> <Label l>` <- pt.top.directives ];
  
  ls = [ implode(l) | Level l <- pt.top.levels ];
  
  AGrammar g = agrammar("<pt.top.name>", ds, ls);
  g.src = pt@\loc.top;
  if (d:(Directive)`layout <Nonterminal x> = <Sym s>` <- pt.top.directives) {
    g.ws = "<x>";
    g.levels[0].rules += [adefine("<x>", [aprod("", [implode(s)])], src=d@\loc)];
  }
  if ((Directive)`modifies <String base>` <- pt.top.directives) {
    g.base = "<base>"[1..-1];
  }
  
  if ((Directive)`prefix <String prefix>` <- pt.top.directives) {
    g.prefix = "<prefix>"[1..-1];
  }
  
  if ((Directive)`locale <Id locale>` <- pt.top.directives) {
    g.locale = "<locale>";
  }
  
  return g;
}

ASymbol implode((Sym)`<Nonterminal nt>`)
  = nonterminal("<nt>");
  
ASymbol implode((Sym)`<Literal l>`)
  = literal("<l>");

ASymbol implode((Sym)`<Regexp r>`)
  = regexp("<r>");
  
ASymbol implode((Sym)`(<Sym* ss>)`) 
  = seq([ implode(s) | Sym s <- ss]);

ASymbol implode((Sym)`<Sym s1> | <Sym s2>`) 
  = alt(implode(s1), implode(s2));

ASymbol implode((Sym)`{<Sym s> <Literal l>}*`) 
  = reg(implode(s), sep="<l>", opt=true);
  
ASymbol implode((Sym)`{<Sym s> <Literal l>}+`) 
  = reg(implode(s), sep="<l>", opt=false);
  
ASymbol implode((Sym)`<Sym s>?`) 
  = reg(implode(s), opt=true, many=false);
  
ASymbol implode((Sym)`<Sym s>*`) 
  = reg(implode(s), opt=true, many=true);
  
ASymbol implode((Sym)`<Sym s>+`) 
  = reg(implode(s), opt=false, many=true);
  
  
ASymbol implode((Sym)`_`)
  = placeholder();
  
default ASymbol implode((Sym)`<Placeholder p>`)
  = placeholder(pos = toInt("<p>"[1..]));

default ASymbol implode(Sym s) {
  iprintln(s);
  throw "error";
}
  
ALevel implode(t:(Level)`level <Nat n> remove <{Label ","}+ ls> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ], [], 
       [ implode(r, toInt("<n>")) | Rule r <- rs ], src=n@\loc);

ALevel implode(t:(Level)`level <Nat n> remove <{Label ","}+ ls> deprecate <{Label ","}+ ds> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ], [ "<l>" | Label l <- ds ], 
       [ implode(r, toInt("<n>")) | Rule r <- rs ], src=n@\loc);

ALevel implode(t:(Level)`level <Nat n> deprecate <{Label ","}+ ds> <Rule* rs>`)
  = alevel(toInt("<n>"), [], [ "<l>" | Label l <- ds ], 
       [ implode(r, toInt("<n>")) | Rule r <- rs ], src=n@\loc);

ALevel implode((Level)`level <Nat n> <Rule* rs>`)
  = alevel(toInt("<n>"), [], [], [ implode(r, toInt("<n>")) | Rule r <- rs ],
       src=n@\loc);
  
ARule implode(r:(Rule)`<Nonterminal nt> = <{Prod "|"}+ ps>`, int l)
  = adefine("<nt>", [ implode(p, l) | Prod p <- ps ], src=r@\loc);

ARule implode(r:(Rule)`<Nonterminal nt> += <{Prod "|"}+ ps>`, int l)
  = amodify("<nt>", [ implode(p, l) | Prod p <- ps ], src=r@\loc);

ARule implode(r:(Rule)`<Nonterminal nt> += <{Prod "|"}+ ps> \> <{Prod "|"}+ ps2>`, int l)
  = amodify("<nt>", [ implode(p, l) | Prod p <- ps ], 
      moveToEnd=[ implode(p, l) | Prod p <- ps2 ], src=r@\loc);

ARule implode(r:(Rule)`<Nonterminal nt> += <{Prod "|"}+ ps> -= <{Prod "|"}+ ps2>`, int l)
  = amodify("<nt>", [ implode(p, l) | Prod p <- ps ], 
      removals=[ implode(p, l) | Prod p <- ps2 ], src=r@\loc);


ARule implode(r:(Rule)`<Nonterminal nt> += <{Prod "|"}+ ps> -= <{Prod "|"}+ ps2> \> <{Prod "|"}+ ps3>`, int l)
  = amodify("<nt>", [ implode(p, l) | Prod p <- ps ], 
      removals=[ implode(p, l) | Prod p <- ps2 ], 
      moveToEnd=[ implode(p, l) | Prod p <- ps3 ], src=r@\loc);



AProd implode(p:(Prod)`<Modifier* ms> <Label l>: <Sym* ss>`, int level)
  = implodeProd(ms, "<l>", ss, "", p@\loc, level);
  
AProd implode(p:(Prod)`<Modifier* ms> <Label l>: <Sym* ss> -\> <Label b>`, int level)
  = implodeProd(ms, "<l>", ss, "<b>", p@\loc, level);


AProd implode(p:(Prod)`<Modifier* ms> <Sym* ss> -\> <Label b>`, int level)
  = implodeProd(ms, "", ss, "<b>", p@\loc, level);

AProd implode(p:(Prod)`<Modifier* ms> <Sym* ss>`, int level)
  = implodeProd(ms, "", ss, "", p@\loc, level);
  
AProd implodeProd(Modifier* ms, str l, Sym* ss, str binding, loc src, int level) {
  AProd p = aprod(l, [ implode(s) | Sym s <- ss ] , binding=binding, level=level, src=src);
  if ((Modifier)`@override` <- ms) {
    p.override = true;
  }
  if ((Modifier)`@error` <- ms) {
    p.error = true;
  }
  return p;
}


str toLark(AGrammar g, ALevel l) {
  str s = "";
  for (<str name, str binding> <- g.imports) {
    s += "%import <name>";
    if (binding != "") {
      s += " -\> <binding>";
    }
    s += "\n";
  }
  s += toLark(l);
  return s;
}

str toLark(ALevel l) = intercalate("\n", [ toLark(r) | ARule r <- l.rules ]);


list[AProd] sortProductions(list[AProd] ps) 
  = [ p | AProd p <- ps, !p.error, p.deprecatedAt < 0 ]
  + [ p | AProd p <- ps, p.deprecatedAt >= 0 ]
  + [ p | AProd p <- ps, p.error ];


// amodify is handled in compile.
str toLark(adefine(str nt, list[AProd] prods))
  = "<nt>: <intercalate("\n  | ", [ toLark(p) | AProd p <- sortProductions(prods) ])>\n";


str toLark(p:aprod(str l, list[ASymbol] ss)) {
  str src = "<intercalate(" ", [ toLark(s) | ASymbol s <- ss ])>";
  
  
  str b = p.binding != "" ? p.binding : l;
  if (p.deprecatedAt >= 0) {
    b += "_DEPRECATED_AT_<p.deprecatedAt>";
  }
  if (b != "") {
    src += " -\> <b>";
  }
  if (p.error) {
   src += " // error production";
  }
  
  return src;
}

str toLark(p:placeholder()) {
  if (p.pos > 0) {
    return "_<p.pos>";
  }
  return "_";
}

str toLark(nonterminal(str name)) = name;
str toLark(literal(str lit)) = lit;
str toLark(regexp(str re)) = re;
str toLark(seq(list[ASymbol] symbols)) = "(<intercalate(" ", [ toLark(s) | ASymbol s <- symbols ])>)";
str toLark(alt(ASymbol lhs, ASymbol rhs)) = "<toLark(lhs)> | <toLark(rhs)>";

str toLark(s:reg(ASymbol arg)) {
  str src = toLark(arg);
  if (s.opt, s.many) {
    src += "*";
  }
  if (s.opt, !s.many) {
    src += "?";
  }
  if (!s.opt, s.many) {
    src += "+";
  }
  return src;
}  
  
  
  
  
  
  