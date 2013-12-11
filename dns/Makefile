configure:
	opam install oasis-mirage dns --yes
	oasis setup && ocaml setup.ml -configure

build:
	mir-crunch -name fs lib_test > datax.ml
	ocaml setup.ml -build -j 8
	ocamlbuild main.native

clean: configure
	ocaml setup.ml -clean
	$(RM) dns/datax.ml dns/setup.data
