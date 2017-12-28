IPKG=package.ipkg
PACKAGE=simple-bmp
EXE=$(PACKAGE)-example
SOURCES=$(shell find src/ -name "*.idr")

all: build/$(EXE)

run: example.bmp
example: example.bmp

install: $(SOURCES)
	idris --install $(IPKG)

example.bmp: build/$(EXE)
	./build/$(EXE) > example.bmp

repl:
	EDITOR=vim idris --repl $(IPKG)

build/$(EXE): $(SOURCES) | build/
	idris --build example.ipkg && mv $(EXE) build/

build/:
	mkdir -p build/

check: $(SOURCES)
	idris --checkpkg $(IPKG)

test: $(SOURCES)
	idris --testpkg $(IPKG)

doc: $(SOURCES)
	idris --mkdoc $(IPKG)

clean:
	idris --clean $(IPKG)
	idris --clean example.ipkg
	rm -rf $(PACKAGE)_doc/
	rm -f `find src/ -name *.ibc`
	rm -f example.bmp

cleanall: clean
	rm -rf build/
