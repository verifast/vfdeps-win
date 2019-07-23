MAKEDIR:=$(shell pwd)
PATH:=$(shell cygpath "$(MAKEDIR)"):$(shell cygpath "$(PREFIX)")/bin:$(PATH)

all: z3

clean::
	-rm -Rf $(PREFIX)

# ---- Z3 ----

Z3_VERSION=4.8.5
Z3_BINARY=$(PREFIX)/lib/libz3.dll
Z3_DIR=z3-Z3-$(Z3_VERSION)
Z3_SRC=$(Z3_DIR)/scripts/mk_make.py
Z3_CFG=$(Z3_DIR)/build/Makefile
Z3_BUILD=$(Z3_DIR)/build/libz3.dll

$(Z3_SRC):
	download_and_untar https://github.com/Z3Prover/z3/archive/master.tar.gz
	cd $(Z3_DIR)/scripts && patch mk_util.py ../../mk_util.py.patch

$(Z3_CFG): $(FINDLIB_EXE) $(Z3_SRC)
	cd $(Z3_DIR) && CXX=i686-w64-mingw32-g++ CC=i686-w64-mingw32-gcc AR=i686-w64-mingw32-ar python scripts/mk_make.py --ml --prefix=$(PREFIX)

$(Z3_BUILD): $(Z3_CFG)
	cd $(Z3_DIR)/build && make

$(Z3_BINARY): $(Z3_BUILD)
	cd $(Z3_DIR)/build && make install && cp libz3.dll.a $(PREFIX)/lib

z3: $(Z3_BINARY)
.PHONY: z3

clean::
	-rm -Rf $(Z3_DIR)
