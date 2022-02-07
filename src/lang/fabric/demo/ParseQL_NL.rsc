module lang::fabric::demo::ParseQL_NL

import lang::fabric::demo::QL_NL;
import ParseTree;

start[Form] parseQL_NL(loc l) = parse(#start[Form], l);

start[Form] parseQL_NL(str src) = parse(#start[Form], src);


type[start[Form]] reflect() = #start[Form];