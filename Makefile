#
# Makefile to prepare releases and run tests
#

DISTOPS= dist distclean dist-all dist-bzip2 dist-gzip dist-tar dist-zip
.PHONY: all clean check $(DISTOPS) distcheck install test-env test-matrix

LUA_BIN=lua
LUNIT_BIN=lunit
VERSION=luajson-$(shell git describe --abbrev=4 HEAD 2>/dev/null)

MKDIR=mkdir -p
PREFIX ?= /usr/local
INSTALL_TOP= $(PREFIX)

INSTALL_LMOD= $(INSTALL_TOP)/share/lua/5.1
INSTALL_CMOD= $(INSTALL_TOP)/lib/lua/5.1

all:
	@echo Building nothing - no binaries

clean:
	@echo Cleaning nothing - no binaries

$(DISTOPS):
	$(MAKE) $(MFLAGS) -C dist $@

# Config to make sure that Lua uses the contained Lua code
LUA_PATH_SETUP=LUA_PATH="?/init.lua;../lua/?.lua;../lua/?/init.lua;$(LUA_PATH);"
LUA_SETUP=LUA_OLD_INIT="$(LUA_INIT)" LUA_INIT="@hook_require.lua" $(LUA_PATH_SETUP)

check-regression:
	cd tests && $(LUA_SETUP) $(LUA_BIN) regressionTest.lua
check-unit:
	cd tests && $(LUA_SETUP) $(LUNIT_BIN) --interpreter $(LUA_BIN) lunit-*.lua

check: check-regression check-unit

LUA ?= lua 5.3
LPEG ?= 1.0.1-1

test-env:
	./run_tests.sh "$(LUA)" "$(LPEG)"

test-matrix:
	./run_tests.sh "lua 5.1" "1.0.1-1"
	./run_tests.sh "lua 5.2" "1.0.1-1"
	./run_tests.sh "lua 5.3" "1.0.1-1"
	./run_tests.sh "lua 5.4" "1.1.0-1"
	./run_tests.sh "lua 5.5" "1.1.0-1"
	./run_tests.sh "luajit 2.0" "1.0.1-1"
	./run_tests.sh "luajit 2.1" "1.1.0-1"
	./run_tests.sh "moonjit 2.2.0" "1.1.0-1"

distcheck-tar: dist-tar
	$(MKDIR) tmp
	tar -C tmp -xf dist/$(VERSION).tar
	cd tmp/$(VERSION) && make check
	rm -rf tmp

distcheck-zip: dist-zip
	$(MKDIR) tmp
	unzip -q -d tmp dist/$(VERSION).zip
	cd tmp/$(VERSION) && make check
	rm -rf tmp

distcheck: distcheck-zip distcheck-tar


install:
	$(MKDIR) $(DESTDIR)$(INSTALL_LMOD)
	cp -p -r lua/* $(DESTDIR)$(INSTALL_LMOD)
