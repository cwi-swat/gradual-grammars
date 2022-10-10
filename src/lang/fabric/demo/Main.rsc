module lang::fabric::demo::Main

import lang::fabric::demo::QL;
import lang::fabric::demo::ImplodeQL;
import lang::fabric::demo::QL_NL_fabric;
import lang::fabric::demo::ParseQL_NL;

import lang::fabric::Stitch;

import util::Benchmark;
import util::GenSen;
import lang::csv::IO;
import ParseTree;

import String;
import IO;


void main() {
  type[start[Form]] base = lang::fabric::demo::QL::reflect();
  type[start[Form_NL]] fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  
  dutchQL = |project://gradual-grammars/src/lang/fabric/demo/taxform.qlnl|;
  
  pt = parseQL_NL(dutchQL);
  
  println("#### Dutch syntax");
  println(pt);
  
  ptBase = unravel(base, fabric, pt, "NL");
  
  println("\n#### Unraveled (base-)syntax");
  println(ptBase);
  
  println("\n#### Implode from Dutch");
  
  ast = implodeQL_NL(pt);
  
  iprintln(ast);
  
   
}

void stitchDutchQL() {
  base = lang::fabric::demo::QL::reflect();
  fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  path = |project://gradual-grammars/src/lang/fabric/demo|;
  writeStitchedGrammar(base, fabric, "NL", path, "lang::fabric::demo::QL_NL");
}

tuple[start[Form], int] unravelWithTime(start[Form] f) {
  type[start[Form]] base = lang::fabric::demo::QL::reflect();
  type[start[Form_NL]] fabric = lang::fabric::demo::QL_NL_fabric::reflect();
  int t0 = getMilliTime();
  start[Form] f2 = unravel(base, fabric, f, "NL");
  int t1 = getMilliTime();
  return <f2, t1 - t0>;
}


alias Bench = rel[int size, int parse, int unravel, int implode];


void randomizedTests(int n=100, int depth=10) {
  nl = lang::fabric::demo::ParseQL_NL::reflect();

  Bench bench = {};

  int nActual = 0;

  for (int i <- [0..n]) {
        println("# ITERATION: <i>");

        start[Form] pt = genSenTop(nl, depth=depth);
        
        str src = "<pt>";

        //println(src);
        int t0 = getMilliTime();
        try {
          parseQL_NL(src);
        }
        catch e:ParseError(loc l): {
            println("parse error: <e>");
            println(src);
            println("#####");
            println(src[l.offset..]);
            continue;
            return;
            
        }
        catch e:Ambiguity(_, _, _): {
            println("Ambiguity: <e>");
            continue;
        }
        int t1 = getMilliTime();
        nActual += 1;
        <ref, n> = unravelWithTime(pt);
        
        int t2 = getMilliTime();
        z = implodeQL_NL(pt);
        int tImplode = getMilliTime();
        
        bench += {<size(src), t1 - t0, n, tImplode - t2>};

        println("size = <size(src)>, parse = <t1 - t0>, unravel = <n>, implode <tImplode - t2>");

  }

  str csv = "size,parse,unravel,implode\n";
  for (<a, b, c, d> <- bench) {
    csv += "<a>,<b>,<c>,<d>\n";
  }


  str sActual = "<nActual>";
  str sDepth = "<depth>";
  writeFile(|project://gradual-grammars/unravel.csv|, csv);
}