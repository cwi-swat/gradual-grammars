
module VSCode

import util::LanguageServer;
import ParseTree;
import GradualGrammar;
import util::Reflective;

import IO;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[Module], input, src);
    })
};


void main() {
    registerLanguage(
        language(
            pathConfig(),
            "Gradual Grammar",
            "gradgram",
            "VSCode",
            "myLanguageContributor"
        )
    );
}


