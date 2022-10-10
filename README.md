# Artifact accompanying "Gradual Grammars: Syntax In Levels and Locales"

## Setting up the artifact

- Install [VS Code](https://code.visualstudio.com/)

- From the extensions pane, install [Rascal](https://marketplace.visualstudio.com/items?itemName=UseTheSource.rascalmpl). Note, you don't need the link, just search for "Rascal" in the market place from within VS Code.

- Clone the `gradual-grammars` Github repository [https://github.com/cwi-swat/gradual-grammars/tree/artifact-sle-2022](https://github.com/cwi-swat/gradual-grammars/tree/artifact-sle-2022) (Note the branch!).

- From the File menu in VS Code, select "Add folder to workspace", and select the folder where you've cloned the Github repo.

- Go to the the file `src/ArtifactSLE22.rsc` and open it. If all is well, a link should occur above the first line of the module, "Import in new Rascal terminal". Click the link.

- In the just started terminal (bottom of the screen), enter the following snippet of code `setup()` (with enter). You should now be good to go to evaluate the artifact.

## Fabric

The working of Fabric can be explored by opening the files with the extension "gradgram". The link at the top of a file allows you to compile to LARK grammars, which will appear next to the grammar file itself.

- `src/lang/fabric/demo/{QL,QL-NL}.gradgram`: toy gradual grammar for the QL DSL and its translation to Dutch.

- `hedy/*.gradgram`: the Hedy' gradual grammar and translation to Dutch.


## Fabric embedded in Rascal

### Example DSL: QL

- `src/lang/fabric/demo/QL_[1-5].rsc`: leveled grammar of the QL DSL.

- `src/lang/fabric/demo/QL_NL_fabric.rsc`: Dutch Fabric grammar of QL.

- `src/lang/fabric/demo/QL_NL.rsc`: Dutch QL grammar generated from stitching.

- `src/lang/fabric/demo/Main.rsc`: run the `main()` function to see how a Dutch QL program is unraveled to its base syntax, and to an AST using `implode` (see `src/util/Implode.rsc` for the implementation of `implode`).

### Rebel2: a DSL for state-based modeling

- `src/lang/rebel2/`: the base grammar of the Rebel2 DSL.

- `src/lang/rebel2/dutch`: the Dutch translation of the Rebel2 DSL.

- `src/lang/rebel2/dutch/Main.rsc`: run the `main()` to see how Dutch Rebel2 files (in subfolder `demo`) are unraveld to their base syntax.

## Overhead of unravel 

Import `/src/lang/fabric/demo/Main` in the terminal by issuing `import lang::fabric::demo::Main;`. 
Then execute `randomizedTests(n=100, depth=10);`, where you can vary the values for `n` (= number of trials), and `depth` (maximum sentence depth).
The results will be written to `unravel.csv` file in the root folder of the project.

If you have [gnuplot](http://www.gnuplot.info/) available, you may plot the result by executing `gnuplot -p unravel.gnuplot` (in the project folder), and inspect the resulting `unravel.pdf`.

*NB*: this benchmark is based on randomized sentence generation, so the results will never be exactly the same as in the paper. However, the point is to confirm linear time in the size of the input, and relative overhead of `unravel` w.r.t. to `implode`.


## Contact

[Felienne Hermans](mailto:f.f.j.hermans@vu.nl)



