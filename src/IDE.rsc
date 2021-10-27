module IDE

import util::IDE;
import ParseTree;
import GradualGrammar;

void main() {
  registerLanguage("Gradual Grammar", "gradgram", start[Module](str src, loc org) {
    return parse(#start[Module], src, org);
  });
}