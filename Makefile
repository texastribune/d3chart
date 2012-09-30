EXAMPLES = $(wildcard ./docs-src/*.js)
HEADER = ./docs-src/header.html
FOOTER = ./docs-src/footer.html

#
# BUILD DOCS AND EXAMPLES
#

build:
	@docco src/*
	@rm docs/examples/*.html
	@$(foreach example, $(EXAMPLES),\
	  echo building example: $(notdir $(example)) && \
	  cat $(HEADER) $(example) $(FOOTER) >> \
	  docs/examples/$(notdir $(basename $(example))).html;)

gist:
	@$(foreach example, $(EXAMPLES),\
	  cat $(HEADER2) $(example) $(FOOTER) | ./gist.sh $(example);)
