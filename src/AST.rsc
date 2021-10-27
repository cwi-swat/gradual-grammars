module AST

import GradualGrammar;
import String;
import List;

data AGrammar(str ws = "", map[str, str] literals = ())
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
  if ((Directive)`layout <Id x> = <Symbol s>` <- pt.top.directives) {
    g.ws = "<x>";
    g.levels[0].rules += [arule("<x>", [aprod("<x>", [implode(s)])])];
  }
  return g;
}

ASymbol implode((Symbol)`<Nonterminal nt>`)
  = nonterminal("<nt>");
  
ASymbol implode((Symbol)`<Literal l>`)
  = literal("<l>");

ASymbol implode((Symbol)`<Regexp r>`)
  = regexp("<r>");
  
ASymbol implode((Symbol)`(<Symbol* ss>)`) 
  = seq([ implode(s) | Symbol s <- ss]);

//ASymbol implode((Symbol)`<Symbol s1> <Symbol s2>`) 
//  = seq(implode(s1), implode(s2));

ASymbol implode((Symbol)`<Symbol s1> | <Symbol s2>`) 
  = alt(implode(s1), implode(s2));

ASymbol implode((Symbol)`{<Symbol s> <Literal l>}*`) 
  = reg(implode(s), sep="<l>", opt=true);
  
ASymbol implode((Symbol)`{<Symbol s> <Literal l>}+`) 
  = reg(implode(s), sep="<l>", opt=false);
  
ASymbol implode((Symbol)`<Symbol s>?`) 
  = reg(implode(s), opt=true, many=false);
  
ASymbol implode((Symbol)`<Symbol s>*`) 
  = reg(implode(s), opt=true, many=true);
  
ASymbol implode((Symbol)`<Symbol s>+`) 
  = reg(implode(s), opt=false, many=true);
  

ALevel implode((Level)`level <Nat n> remove <{Label ","}+ ls> <Rule* rs>`)
  = alevel(toInt("<n>"), [ "<l>" | Label l <- ls ],  [ implode(r) | Rule r <- rs ]);

ALevel implode((Level)`level <Nat n> <Rule* rs>`)
  = alevel(toInt("<n>"), [ ],  [ implode(r) | Rule r <- rs ]);
  
ARule implode((Rule)`<Nonterminal nt> = <{Production "|"}+ ps>`)
  = arule("<nt>", [ implode(p) | Production p <- ps ]);

AProd implode((Production)`<Modifier* ms> <Label l>: <Symbol* ss>`)
  = implodeProd(ms, l, ss, "");
  
AProd implode((Production)`<Modifier* ms> <Label l>: <Symbol* ss> -\> <Label b>`)
  = implodeProd(ms, l, ss, "<b>");
  
AProd implodeProd(Modifier* ms, Label l, Symbol* ss, str binding) {
  AProd p = aprod("<l>", [ implode(s) | Symbol s <- ss ] , binding=binding);
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

// todo: sorting, error prods should be at end
str pp(arule(str nt, list[AProd] prods))
  = "<nt>: <intercalate("\n\t| ", [ pp(p) | AProd p <- prods ])>\n";


str pp(p:aprod(str l, list[ASymbol] ss)) {
  str src = "<intercalate(" ", [ pp(s) | ASymbol s <- ss ])>";
  str b = p.binding != "" ? p.binding : p.label;
  src += " -\> <b>";
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
  
  
  
  
  
  
  