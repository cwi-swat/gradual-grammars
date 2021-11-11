
module VSCode

import util::LanguageServer;
import ParseTree;
import GradualGrammar;
import Compile;
import util::Reflective;

import IO;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[Module], input, src);
    }),
    lenses(myLenses),
    executor(myCommands)
};

data Command
  = compileGG(start[Module] program);

rel[loc,Command] myLenses(start[Module] input) = {<input@\loc, compileGG(input, title="Compile")>};


void myCommands(compileGG(start[Module] input)) {
    compile(input);
}

void main() {
    registerLanguage(
        language(
            pathConfig(srcs = [|std:///|, |project://gradual-grammars/src|]),
            "Gradual Grammar",
            "gradgram",
            "VSCode",
            "myLanguageContributor"
        )
    );
}


