
module VSCode

import util::LanguageServer;
import ParseTree;
import lang::fabric::GradualGrammar;
import lang::fabric::Compile;
import util::Reflective;

import IO;
import String;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[Module], input, src);
    }),
    outliner(myOutliner),
    lenses(myLenses),
    executor(myCommands)
};

data Command
  = compileGG(start[Module] program);

rel[loc,Command] myLenses(start[Module] input) = {<input@\loc, compileGG(input, title="Compile")>};


void myCommands(compileGG(start[Module] input)) {
    compile(input);
}


list[DocumentSymbol] myOutliner(start[Module] input) {
    Module m = input.top;
    DocumentSymbol d = DocumentSymbol::symbol("<m.name>", DocumentSymbolKind::file(), input.src);
    kids = [];
    for (Level l <- m.levels) {
        DocumentSymbol ld = symbol("level <l.number>", namespace(), l.src);
        lkids = [];
        for (Rule r <- l.rules) {
            DocumentSymbol rd = symbol("<r.nt>", struct(), r.src);

            for (Prod p <- r.prods) {
                rd.children += [symbol("<p.label>", function(), p.src)];
            }

            lkids += [rd];
        }
        ld.children = lkids;
        kids += [ld];
    }
    d.children = kids;
    return [d];
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


