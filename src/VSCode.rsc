
module VSCode

import util::LanguageServer;
import ParseTree;
import GradualGrammar;
import Compile;
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



/*
data DocumentSymbol
    = symbol(
        str name,
        DocumentSymbolKind kind,
        loc range,
        loc selection=range,
        str detail="",
        list[DocumentSymbol] children=[]
    );

data DocumentSymbolKind
	= \file()
	| \module()
	| \namespace()
	| \package()
	| \class()
	| \method()
	| \property()
	| \field()
	| \constructor()
	| \enum()
	| \interface()
	| \function()
	| \variable()
	| \constant()
	| \string()
	| \number()
	| \boolean()
	| \array()
	| \object()
	| \key()
	| \null()
	| \enumMember()
	| \struct()
	| \event()
	| \operator()
	| \typeParameter()
    ;
    */

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


