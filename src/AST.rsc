module AST

import GradualGrammar;
import String;
import List;
import ParseTree;

data AGrammar(str ws = "", map[str, str] literals = (), loc src = |file:///dummy|)
  = agrammar(str name, list[Import] imports, list[ALevel] levels);
  

alias Import = tuple[str name, str binding];

data ALevel
  = alevel(int n, list[str] remove, list[ARule] rules);
  
data ARule
  = arule(str nt, list[AProd] prods)
  ;
  
data AProd(bool error=false, bool override=false, str binding="")
  = aprod(str label, list[ASymbol] symbols);
  
data ASymbol
  = nonterminal(str name)
  | literal(str lit)
  | regexp(str re)
  | seq(list[ASymbol] symbols)
  | alt(ASymbol lhs, ASymbol rhs)
  | reg(ASymbol arg, str sep="", bool opt=false, bool many=true)
  ;


AGrammar implode(start[Module] pt) {
  ds = [ <"<q>", ""> | (Directive)`import <QName q>` <- pt.top.directives ]
    +[ <"<q>", "<l>"> | (Directive)`import <QName q> -\> <Label l>` <- pt.top.directives ];
  
  ls = [ implode(l) | Level l <- pt.top.levels ];
  
  AGrammar g = agrammar("<pt.top.name>", ds, ls);
  g.src = pt.src.top;
  if ((Directive)`layout <Nonterminal x> = <Sym s>` <- pt.top.directives) {
    g.ws = "<x>";
    g.levels[0].rules += [arule("<x>", [aprod("<x>", [implode(s)])])];
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
  

ALevel implode((Level)`level <Nat n> remove <{Label ","}+ ls> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ],  [ implode(r) | Rule r <- rs ]);

ALevel implode((Level)`level <Nat n> <Rule* rs>`)
  = alevel(toInt("<n>"), [ ],  [ implode(r) | Rule r <- rs ]);
  
ARule implode((Rule)`<Nonterminal nt> = <{Prod "|"}+ ps>`)
  = arule("<nt>", [ implode(p) | Prod p <- ps ]);

AProd implode((Prod)`<Modifier* ms> <Label l>: <Sym* ss>`)
  = implodeProd(ms, l, ss, "");
  
AProd implode((Prod)`<Modifier* ms> <Label l>: <Sym* ss> -\> <Label b>`)
  = implodeProd(ms, l, ss, "<b>");
  
AProd implodeProd(Modifier* ms, Label l, Sym* ss, str binding) {
  AProd p = aprod("<l>", [ implode(s) | Sym s <- ss ] , binding=binding);
  if ((Modifier)`@override` <- ms) {
    p.override = true;
  }
  if ((Modifier)`@error` <- ms) {
    p.error = true;
  }
  return p;
}


str pp(AGrammar g, ALevel l) {
  str s = "";
  for (<str name, str binding> <- g.imports) {
    s += "%import <name>";
    if (binding != "") {
      s += " -\> <binding>";
    }
    s += "\n";
  }
  s += pp(l);
  return s;
}

str pp(ALevel l) = intercalate("\n", [ pp(r) | ARule r <- l.rules ]);


list[AProd] errorsAtTheEnd(list[AProd] ps) 
  = [ p | AProd p <- ps, !p.error ] + [ p | AProd p <- ps, p.error ];

// todo: sorting, error prods should be at end
str pp(arule(str nt, list[AProd] prods))
  = "<nt>: <intercalate("\n\t| ", [ pp(p) | AProd p <- errorsAtTheEnd(prods) ])>\n";


str pp(p:aprod(str l, list[ASymbol] ss)) {
  str src = "<intercalate(" ", [ pp(s) | ASymbol s <- ss ])>";
  str b = p.binding != "" ? p.binding : p.label;
  src += " -\> <b>";
  if (p.error) {
   src += " // error production";
  }
  return src;
}

str pp(nonterminal(str name)) = name;
str pp(literal(str lit)) = lit;
str pp(regexp(str re)) = re;
str pp(seq(list[ASymbol] symbols)) = "(<intercalate(" ", [ pp(s) | ASymbol s <- symbols ])>)";
str pp(alt(ASymbol lhs, ASymbol rhs)) = "<pp(lhs)> | <pp(rhs)>";

str pp(s:reg(ASymbol arg)) {
  str src = pp(arg);
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
  
  
  
  
  
  