TYPST ?= typst
BUILD := build
SOURCES := $(wildcard templates/*.typ) $(wildcard examples/*.typ)
PDFS := $(patsubst %.typ,$(BUILD)/%.pdf,$(SOURCES))

.PHONY: all clean list

all: $(PDFS)

$(BUILD)/%.pdf: %.typ project-kit.typ
	@mkdir -p "$(dir $@)"
	$(TYPST) compile --root . "$<" "$@"

list:
	@printf '%s\n' $(SOURCES)

clean:
	rm -rf $(BUILD)
