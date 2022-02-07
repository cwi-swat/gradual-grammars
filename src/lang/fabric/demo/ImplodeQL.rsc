module lang::fabric::demo::ImplodeQL

import lang::fabric::demo::QL_AST;
import lang::fabric::demo::QL_NL_fabric;
import lang::fabric::Stitch;

import util::Implode;
import ParseTree;


Form implodeQL(Tree t, ASTreorder reorder={}) {
  if (t.prod.def is \start) {
     t = t.args[1];
  }
  return implode(#Form, t, reorder=reorder);
}

Form implodeQL_NL(Tree t) {
  type[start[Form_NL]] nl = lang::fabric::demo::QL_NL_fabric::reflect();
  return implodeQL(t, reorder=fabric2reorder(nl, "NL"));
}


