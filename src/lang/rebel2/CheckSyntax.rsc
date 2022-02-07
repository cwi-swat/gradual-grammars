module lang::rebel2::CheckSyntax

import lang::rebel2::CommonSyntax;
import lang::rebel2::SpecSyntax;

syntax Part
  = Config cfg
  | Assert asrt
  | Check chk
  ;
  
syntax Config = "config" Id name "=" {InstanceSetup ","}+ instances ";";

syntax InstanceSetup 
  = {Id ","}+ labels ":" Type spec Mocks? mocks Forget? forget InState? inState WithAssignments? assignments
  | Id label WithAssignments assignments
  ;

syntax Mocks = "mocks" Type concrete;

syntax Forget = forget: "forget" {Id ","}+ fields;

syntax InState = "is" State state;

syntax WithAssignments = with: "with" {Assignment ","}+ assignments;

syntax Assignment
  = Id fieldName "=" Expr val
  ;
  
syntax Assert = \assert: "assert" Id name "=" Formula form ";";

syntax Formula 
  = non-assoc ifThenElse: "if" Formula cond "then" Formula then "else" Formula else
  > on: TransEvent event "on" Expr var WithAssignments? with
  > next: "next" Formula form
  | first: "first" Formula form
  | last: "last" Formula form
  > eventually: "eventually" Formula form
  | always: "always" Formula form
  | alwaysLast: "always-last" Formula form
  | right until: Formula first "until" Formula second
  | right release: Formula first "release" Formula second
  ;

syntax TransEvent 
  = wildcard: "*"
  ;

syntax Check 
  = fromIn: Command cmd Id name "from" Id config "in" SearchDepth depth Objectives? objs Expect? expect";"
  ;

syntax Command
  = check: "check"
  | run: "run"
  ;
  
syntax SearchDepth
  = max: "max" Int steps "steps"
  | exact: "exact" Int steps "steps"
  ;  

syntax Objectives
  = with: "with" {Objective ","}+ objs
  ;
  
syntax Objective
  = minimal: "minimal" Expr expr
  | maximal: "maximal" Expr expr
  | infinite: "infinite" "trace"
  | finite: "finite" "trace"
  ;

syntax Expect
  = expect: "expect" ExpectResult
  ;
  
syntax ExpectResult
  = trace: "trace"
  | noTrace: "no" "trace"
  ;  
  
keyword Keywords 
  = "config"
  | "with"
  | "assert"
  | "fact"
  | "until"
  | "release"
  | "eventually"
  | "always"
  | "always-last"
  | "next"
  | "minimal"
  | "maximal"
  | "exact"
  | "on"
  | "first"
  | "last"
  | "inifinite"
  | "finite"
  | "trace"
  | "check"
  | "run"
  | "mocks"
  ;
