module IDE

import util::IDE;
import ParseTree;
import GradualGrammar;
import Message;
import Compile;

void setupIDE() {
  registerLanguage("Gradual Grammar", "gradgram", start[Module](str src, loc org) {
    return parse(#start[Module], src, org);
  });
  
  registerContributions("Gradual Grammar", {
    builder(set[Message](Tree pt) {
      if (start[Module] m := pt) {
        compile(m);
        return {};
      }
      return {error("not a gradual grammar", pt@\loc)};
    })});
}