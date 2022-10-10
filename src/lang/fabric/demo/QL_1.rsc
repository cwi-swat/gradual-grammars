module lang::fabric::demo::QL_1

// Level 1

extend lang::std::Layout;

lexical Id = [A-Za-z][A-Za-z0-9_]* !>> [A-Za-z0-9_] \ Reserved; 

lexical String = [\"]![\"]* [\"];

keyword Reserved = ;

syntax Form = form: "form" Id Question*;

syntax Question = question: "ask" String "into" Id ":" Type;

syntax Type = \bool: "boolean";
