module lang::fabric::AST

import lang::fabric::GradualGrammar;
import String;
import List;
import ParseTree;

data AGrammar(str ws = "", str base = "", loc src = |file:///dummy|)
  = agrammar(str name, list[Import] imports, list[ALevel] levels);
  

alias Import = tuple[str name, str binding];

data ALevel(loc src = |file:///dummy|)
  = alevel(int n, list[str] remove, list[str] deprecate, list[ARule] rules);
  
data ARule(loc src = |file:///dummy|)
  = arule(str nt, list[AProd] prods)
  ;
  
data AProd(bool error=false, bool override=false, int deprecatedAt = -1, str binding="", loc src = |file:///dummy|)
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
  g.src = pt.src.top;
  if (d:(Directive)`layout <Nonterminal x> = <Sym s>` <- pt.top.directives) {
    g.ws = "<x>";
    g.levels[0].rules += [arule("<x>", [aprod("<x>", [implode(s)])], src=d.src)];
  }
  if ((Directive)`modifies <String base>` <- pt.top.directives) {
    g.base = "<base>"[1..-1];
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
  
ALevel implode(t:(Level)`level <Nat n> remove <{Label ","}+ ls> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ], [], 
       [ implode(r) | Rule r <- rs ], src=n.src);

ALevel implode(t:(Level)`level <Nat n> remove <{Label ","}+ ls> deprecate <{Label ","}+ ds> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ], [ "<l>" | Label l <- ds ], 
       [ implode(r) | Rule r <- rs ], src=n.src);

ALevel implode(t:(Level)`level <Nat n> deprecate <{Label ","}+ ds> <Rule* rs>`)
  = alevel(toInt("<n>"), [], [ "<l>" | Label l <- ds ], 
       [ implode(r) | Rule r <- rs ], src=n.src);

ALevel implode((Level)`level <Nat n> <Rule* rs>`)
  = alevel(toInt("<n>"), [], [], [ implode(r) | Rule r <- rs ],
       src=n.src);
  
ARule implode(r:(Rule)`<Nonterminal nt> = <{Prod "|"}+ ps>`)
  = arule("<nt>", [ implode(p) | Prod p <- ps ], src=r.src);

AProd implode(p:(Prod)`<Modifier* ms> <Label l>: <Sym* ss>`)
  = implodeProd(ms, l, ss, "", p.src);
  
AProd implode(p:(Prod)`<Modifier* ms> <Label l>: <Sym* ss> -\> <Label b>`)
  = implodeProd(ms, l, ss, "<b>", p.src);
  
AProd implodeProd(Modifier* ms, Label l, Sym* ss, str binding, loc src) {
  AProd p = aprod("<l>", [ implode(s) | Sym s <- ss ] , binding=binding);
  if ((Modifier)`@override` <- ms) {
    p.override = true;
  }
  if ((Modifier)`@error` <- ms) {
    p.error = true;
  }
  return p[src=src];
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

// todo: sorting, error prods should be at end
str toLark(arule(str nt, list[AProd] prods))
  = "<nt>: <intercalate("\n\t| ", [ toLark(p) | AProd p <- sortProductions(prods) ])>\n";


str toLark(p:aprod(str l, list[ASymbol] ss)) {
  str src = "<intercalate(" ", [ toLark(s) | ASymbol s <- ss ])>";
  str b = p.binding != "" ? p.binding : l;
  if (p.deprecatedAt >= 0) {
    b += "_DEPRECATED_AT_<p.deprecatedAt>";
  }
  src += " -\> <b>";
  if (p.error) {
   src += " // error production";
  }
  return src;
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
  
  
  
  
  
  