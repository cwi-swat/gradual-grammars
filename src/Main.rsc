module Main

import Compile;

public loc HEDY = |project://gradual-grammars/src/hedy.gradgram|;

public loc HEDY_NL = |project://gradual-grammars/src/hedy-nl.gradgram|;

void compileAll() {
    compile(HEDY);
    compile(HEDY_NL);
}
