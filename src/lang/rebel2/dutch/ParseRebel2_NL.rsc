module lang::rebel2::dutch::ParseRebel2_NL

import lang::rebel2::dutch::Rebel2_NL;
import ParseTree;

start[Module] parseRebel2_NL(loc l) = parse(#start[Module], l);

start[Module] parseRebel2_NL(str src) = parse(#start[Module], src);


type[start[Form]] reflect() = #start[Form];