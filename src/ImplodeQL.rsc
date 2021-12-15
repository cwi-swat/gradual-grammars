module ImplodeQL

import QL_AST;
import Implode;
import ParseTree;


// todo: deal with start symbol
Form implode(Tree t) = implode(#Form, t);

