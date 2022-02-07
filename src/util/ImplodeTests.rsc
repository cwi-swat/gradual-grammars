module util::ImplodeTests

import util::Implode;
import Node;

layout Space = [\ \n]* !>> [\ \n];
 
start syntax Prog
 = prog: Stat*;
 
syntax Stat
  = assign: Id ":=" Expr
  | ngissa: Expr "=:" Id
  | group: "{" Stat* "}"
  | parallel: "{|" Stat* "|}"
  ;

syntax Expr
  = boolean: Bool
  | integer: Int
  | var: Id
  | ref: "#" Ref
  | withSrc: "$$"
  | pair: "(" Expr "," Expr ")"
  | record: "{" {IdExpr ","}* "}"
  | bracket "(" Expr ")"
  | left add: Expr "+" Expr
  > quote: "quote" Expr
  ;
  
syntax IdExpr = Id ":" Expr; // NB: no prod label

syntax Ref = Ref2;

syntax Ref2 = Int;

lexical Id = [a-z]+ !>> [a-z] \ Reserved;

keyword Reserved = "true" | "false";

lexical Int = [0-9]+ !>> [0-9];

syntax Bool = "true" | "false";

data AProg = prog(list[AStat] stats);

data AStat
  = assign(str var, AExpr expr)
  | ngissa(str var, AExpr expr) 
  | group(list[AStat] stats)
  | parallel(set[AStat] sstats)
  ;

data AExpr
  = boolean(bool b)
  | integer(int n)
  | var(str s)
  | ref(int n)
  | withSrc(loc src=|dummy:///|)
  | quote(node t)
  | add(AExpr lhs, AExpr rhs)
  ;


AExpr myImplode(Expr e) = implode(#AExpr, e, adtPrefix="A");

AStat myImplode(Stat s) = implode(#AStat, s, adtPrefix="A", reorder={<"Stat", "ngissa", (1: 0, 0: 1)>});

AProg myImplode(Prog p) = implode(#AProg, p, adtPrefix="A", reorder={<"Stat", "ngissa", (1: 0, 0: 1)>});


test bool testLexicalBool() = myImplode((Expr)`true`)  == boolean(true);

test bool testLexicalInt() = myImplode((Expr)`42`) == integer(42);

test bool testLexicalStr() = myImplode((Expr)`x`) == var("x");

test bool testSrcParamIfDeclared() = myImplode((Expr)`$$`).src != |dummy:///|;

test bool testInjectionSkipping() = myImplode((Expr)`#42`) == ref(42); 

test bool testInjectionSkippingUntyped() =   
  quote("ref"("42")) := myImplode((Expr)`quote #42`);
  
test bool testUntypedNode() =  
  quote("add"("integer"("42"), "integer"("42"))) := myImplode((Expr)`quote 42 + 42`); 

test bool testUntypedNodesGetSrcParam() =
  "src" in getKeywordParameters(myImplode((Expr)`quote 42 + 42`).t);
  
test bool testTypedNode() = myImplode((Expr)`1 + 2`) == add(integer(1), integer(2));

test bool testBracketIsSkipped() = myImplode((Expr)`(1 + 2)`) == add(integer(1), integer(2));

test bool testBracketIsSkippedUntyped() =  
  quote("add"("integer"("1"), "integer"("2"))) := myImplode((Expr)`quote (1 + 2)`); 

test bool testMultiType() = myImplode((Stat)`x := 1 + 2`)
  == assign("x", add(integer(1), integer(2)));
  
test bool testList() = myImplode((Stat)`{x := 1 x := 2 x := 3}`)
  == group([assign("x", integer(1)), assign("x", integer(2)), assign("x", integer(3))]);
  
test bool testSet() = myImplode((Stat)`{|x := 1 x := 2 x := 3|}`)
  == parallel({assign("x", integer(1)), assign("x", integer(2)), assign("x", integer(3))});
  
test bool testReorder() = myImplode((Stat)`1 =: x`)
  == ngissa("x", integer(1));
  
test bool testAllTogether() = 
  prog([
    parallel({
        assign(
          "x",
          add(
            add(
              integer(1),
              integer(2)),
            var("x"))),
        group([
            assign(
              "y",
              quote("add"(
                  "add"(
                    "integer"("1"),
                    "integer"("2")),
                  "boolean"("true")))),
            ngissa(
              "y",
              add(
                var("x"),
                integer(1)))
          ])
      }),
    assign(
      "z",
      add(
        var("z"),
        var("z")))
  ]) := myImplode((Prog)`{|x := 1 + 2 + x
					    '{y := quote (1 + 2) + true
					    'x + 1 =: y}|}
					    'z := z + z`);


  

  
