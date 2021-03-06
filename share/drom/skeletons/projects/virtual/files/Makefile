# Generated by "drom project"
.PHONY: all build build-depsfmt fmt-check install dev-deps test
.PHONY: clean distclean

DEV_DEPS := merlin ocamlformat odoc![if:gen:test] ppx_expect ppx_inline_test![fi]

all: build

build:
	opam exec -- dune build @install!{make-copy-programs}

build-deps:
	if ! [ -e _opam ]; then \
	   opam switch create . !{edition} ; \
	fi
	opam install ./*.opam --deps-only

![if:gen:docs]
.PHONY: doc-common odoc view![if:gen:sphinx] sphinx![fi]
doc-common:
	opam exec -- dune build @doc
	mkdir -p _drom/docs
	rsync -auv docs/. _drom/docs/.
![if:gen:sphinx]
sphinx: doc-common 
	if [ -e ./scripts/before-sphinx.sh ]; then \
		./scripts/before-sphinx.sh _drom/docs/!{sphinx-target}; \
	else \
		echo No file ./scripts/before-sphinx.sh; \
	fi
	sphinx-build sphinx _drom/docs/!{sphinx-target}
![fi]
odoc: doc-common 
	mkdir -p _drom/docs/!{odoc-target}/.
	rsync -auv --delete _build/default/_doc/_html/. _drom/docs/!{odoc-target}

doc: doc-common odoc![if:gen:sphinx] sphinx![fi]

view:
	xdg-open file://$$(pwd)/_drom/docs/index.html
![fi]
fmt:
	opam exec -- dune build @fmt --auto-promote

fmt-check:
	opam exec -- dune build @fmt

install:
	opam exec -- dune install

opam:
	opam pin -k path .

uninstall:
	opam exec -- dune uninstall

dev-deps:
	opam install ./*.opam --deps-only --with-doc --with-test

test:
	opam exec -- dune build @runtest

clean:
	rm -rf _build

distclean: clean
	rm -rf _opam _drom

!(makefile-trailer)
