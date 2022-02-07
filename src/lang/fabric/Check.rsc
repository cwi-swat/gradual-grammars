module lang::fabric::Check

import lang::fabric::AST;
import Message;

/*

Well-formedness:

- unique labels of productions
- levels are numbers consecutively
- aspect grammars only use literals and _ and regulars
- nonterminals/prods references in aspects should exist in base grammar
  in the same level.

*/

