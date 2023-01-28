docsdir = ./docs
macros = $(wildcard macros/*.lua)
modules = $(wildcard modules/*/*.lua)

#:: docs: Generate documentation
$(docsdir): config.ld .ldoc/* $(macros) $(modules) README.md LICENSE
	rm -rf $(docsdir)
	ldoc .

#:: lint: Lint scripts
lint: .luacheckrc $(macros) $(modules)
	luacheck .

.PHONY: lint
