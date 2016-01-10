STDLIB=`ocamlfind printconf stdlib`

all: test graphics_server

test: client.o test.o
	clang -framework cocoa -L$(STDLIB) -lasmrun $^ -o $@

test.o: test.ml
	ocamlopt -output-obj $^ -o $@

client.o: client.m
	clang -fmodules -fobjc-arc -I$(STDLIB) -c $< -o $@

graphics_server: graphics_server.m
	clang -framework cocoa -fmodules -fobjc-arc $^ -o $@

clean:
	rm -f graphics_server client.o test.cm* test.o

.PHONY: clean all
