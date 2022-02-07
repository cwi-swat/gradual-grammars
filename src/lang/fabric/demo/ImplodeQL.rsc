module lang::fabric::demo::ImplodeQL

import lang::fabric::demo::QL_AST;
import util::Implode;
import ParseTree;
import lang::fabric::demo::QL_NL_fabric;
import lang::fabric::Stitch;
import IO;


// todo: deal with start symbol
Form implode(Tree t, ASTreorder reorder={}) 
  = implode(#Form, t, reorder=reorder);

void testIt(Tree t) {
  type[start[Form_NL]] nl = QL_NL_fabric::reflect();
  reorder = fabric2reorder(nl, "NL");
  ast = implode(t, reorder=reorder);
  iprintln(ast);
}

