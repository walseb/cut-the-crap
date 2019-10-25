OPTIMIZATION=-O0
build: 
	cabal new-build all -j --ghc-options $(OPTIMIZATION)

haddock:
	cabal new-haddock all

ghcid: clean
	nix-shell --run "make update-cabal"
	nix-shell --run "ghcid -s \"import Main\" -c \"cabal new-repl\" -T \"main\" test:unit"

update-cabal:
	hpack --force ./
	cabal2nix ./ > default.nix

enter:
	nix-shell --cores 0 -j 8 --pure

RUN=""
run-in-shell:
	nix-shell --cores 0 -j 8 --run "$(RUN)"

clean:
	rm -fR dist dist-*

.PHONY: test

sdist:
	make run-in-shell RUN="cabal sdist"
