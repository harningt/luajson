#
# Makefile to prepare releases and run tests
#

.PHONY: all clean check dist dist-all dist-bzip2 dist-gzip dist-zip distcheck

DIST_DIR=dist
LUA_BIN=lua


all:
	@echo Building nothing - no binaries

clean:
	@echo Cleaning nothing - no binaries


dist dist-all: distdir dist-bzip2 dist-gzip dist-zip

distdir:
	mkdir -p dist

VERSION=luajson-$(shell git describe --abbrev=4 HEAD 2>/dev/null)
dist-bzip2: distdir
	git archive --format=tar --prefix=$(VERSION)/ HEAD | bzip2 > $(DIST_DIR)/$(VERSION).tar.bz2
dist-gzip: distdir
	git archive --format=tar --prefix=$(VERSION)/ HEAD | gzip > $(DIST_DIR)/$(VERSION).tar.gz
dist-zip: distdir
	git archive --format=zip --prefix=$(VERSION)/ HEAD > $(DIST_DIR)/$(VERSION).zip

# Config to make sure that Lua uses the contained Lua code
LUA_PATH_SETUP=LUA_PATH="?/init.lua;../src/?.lua;../src/?/init.lua;$(LUA_PATH);"
LUA_SETUP=LUA_OLD_INIT="$(LUA_INIT)" LUA_INIT="@hook_require.lua" $(LUA_PATH_SETUP)
check:
	cd tests && $(LUA_SETUP) lua regressionTest.lua
	cd tests && $(LUA_SETUP) lunit lunit-*.lua

distcheck: dist-bzip2
	mkdir -p tmp
	tar -C tmp -xf $(DIST_DIR)/$(VERSION).tar.bz2
	cd tmp/$(VERSION) && make check
	rm -rf tmp
