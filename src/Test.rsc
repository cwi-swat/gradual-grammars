module Test

import QL_NL;
import Type;
import ParseTree;
import String;

import Stitch;
import GenSen;
import IO;
import util::Benchmark;
import lang::csv::IO;

alias Bench = rel[int size, int parse, int unravel];


void randomizedTests(int n=100, int depth=10) {
  type[start[Form]] nl = #start[Form];

  Bench bench = {};

  for (int i <- [0..n]) {
        println("# ITERATION: <i>");

        start[Form] pt = genSenTop(nl, depth=depth);
        
        str src = "<pt>";
        //println(src);
        int t0 = getMilliTime();
        try {
          parse(#start[Form], src);
        }
        catch e:ParseError(loc l): {
            println("parse error: <e>");
            continue;
            println(src);
            println("#####");
            println(src[l.offset..]);
            return;
            
        }
        catch e:Ambiguity(_, _, _): {
            println("Ambiguity: <e>");
            continue;
        }
        int t1 = getMilliTime();

        <ref, n> = testItWithTime(pt);
        // println("##########");
        // println(ref);
        bench += {<size(src), t1 - t0, n>};
        println("size = <size(src)>, parse = <t1 - t0>, unravel = <n>");

  }

  str csv = "size,parse,unravel\n";
  for (<a, b, c> <- bench) {
    csv += "<a>,<b>,<c>\n";
  }


  writeFile(|project://gradual-grammars/src/unravel.csv|, csv);
}