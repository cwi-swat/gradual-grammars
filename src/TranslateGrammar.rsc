module TranslateGrammar


import Grammar;

/*

Motivation

- LWB: batteries included
- In Rascal customary to build language processors on top of concrete syntax trees
  and not ASTs
- this preserves a high-fidelity link to the source text and provides access to comments etc.
  further, it helps preserving layout  in program transformations that require so (e.g., refactorings)
- example: concrete matching vs ast based matching
- this poses a challenge for translation, however: all the patterns would not work anymore

Plan:

- take a reference grammar (via #NT)
- apply renaming/reordering aspect (map[str label,str pattern])
- write to file with as Rascal grammar (via format);

Then:

- parse over translated grammar
- use same translation aspect to transform parse-tree to obtain pt over reference grammar 
  (keep source locations!)
- this way old stuff can keep on working.


   Prog                      NL-Prog
    |                           |
    v                           v
Ref grammar -> (weave) -> NL grammar
    |                           |   
    v                           v
    PT <----- (unweave) <----- NL-PT
    |
    v
Compile etc.

*/

