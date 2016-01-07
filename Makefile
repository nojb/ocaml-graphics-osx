test.byte: graphics_server
	ocamlbuild -use-ocamlfind -classic-display -package unix $@

graphics_server: graphics_server.m
	clang -o $@ -framework cocoa -fmodules -fobjc-arc $<

clean:
	rm -f graphics_server
	ocamlbuild -clean

.PHONY: clean test.byte
