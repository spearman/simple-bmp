IPKG=package.ipkg
PACKAGE=simple-bmp
EXE=$(PACKAGE)-example
SOURCES=$(shell find src/ -name "*.idr")

all: build/$(EXE)

run: test.bmp
example: test.bmp

install: $(SOURCES)
	idris --install $(IPKG)

test.bmp: build/$(EXE)
	./build/$(EXE) > test.bmp

repl:
	EDITOR=vim idris --repl $(IPKG)

build/$(EXE): $(SOURCES) | build/
	idris --build $(IPKG) && mv $(EXE) build/

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
	rm -rf $(PACKAGE)_doc/
	rm -f `find src/ -name *.ibc`
	rm -f test.bmp

cleanall: clean
	rm -rf build/
