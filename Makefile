STDLIB=`ocamlfind printconf stdlib`

all: test

test: client.o test.o graphics_server.o
	clang -framework cocoa -L$(STDLIB) -lasmrun $^ -o $@

test.o: test.ml
	ocamlopt -output-obj $^ -o $@

client.o: client.m
	clang -fmodules -fobjc-arc -I$(STDLIB) -c $< -o $@

graphics_server.o: graphics_server.m
	clang -fmodules -fobjc-arc -c $^ -o $@

clean:
	rm -f graphics_server client.o test.cm* test.o

.PHONY: clean all
