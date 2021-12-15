MAKEDIR:=$(shell pwd)
PATH:=$(shell cygpath "$(MAKEDIR)"):$(shell cygpath "$(PREFIX)")/bin:$(PATH)
CXX_BUILD_TYPE?=Release
SET_MSV_ENV:=vcvarsall.bat x86
COMMON_CXX_PROPS=-p:Configuration=$(CXX_BUILD_TYPE) -p:Platform=Win32 -m

all: ocaml findlib num ocamlbuild camlp4 gtk lablgtk z3 csexp dune sexplib0 base res stdio cppo ocplib-endian stdint result capnp capnp-ocaml

clean::
	-rm -Rf $(PREFIX)

# ---- OCaml ----

OCAML_VERSION=4.13.0
OCAML_TGZ=ocaml-$(OCAML_VERSION).tar.gz
OCAML_DIR=ocaml-$(OCAML_VERSION)
FLEXDLL_VERSION=0.39
FLEXDLL_TGZ=flexdll-$(FLEXDLL_VERSION).tar.gz
FLEXDLL_DIR=flexdll-$(FLEXDLL_VERSION)
OCAML_EXE=$(PREFIX)/bin/ocamlopt.opt.exe

$(OCAML_TGZ):
	curl -Lfo ocaml-$(OCAML_VERSION).tar.gz https://github.com/ocaml/ocaml/archive/$(OCAML_VERSION).tar.gz

$(OCAML_DIR): $(OCAML_TGZ)
	tar xzfm $(OCAML_TGZ)

$(FLEXDLL_TGZ):
	curl -Lfo $(FLEXDLL_TGZ) https://github.com/alainfrisch/flexdll/archive/$(FLEXDLL_VERSION).tar.gz

$(FLEXDLL_DIR): $(FLEXDLL_TGZ)
	tar xzfm $(FLEXDLL_TGZ)

ocaml-$(OCAML_VERSION)/flexdll/flexdll.c: | $(OCAML_DIR) $(FLEXDLL_DIR)
	cd ocaml-$(OCAML_VERSION)/flexdll && cp -R ../../flexdll-$(FLEXDLL_VERSION)/* .

$(OCAML_EXE): ocaml-$(OCAML_VERSION)/flexdll/flexdll.c | $(OCAML_DIR) $(FLEXDLL_DIR)
	cd ocaml-$(OCAML_VERSION) && \
	./configure --prefix=$(PREFIX) --build=i686-pc-cygwin --host=i686-w64-mingw32 && \
	make flexdll world opt opt.opt flexlink.opt install

ocaml: $(OCAML_EXE)
.PHONY: ocaml

clean::
	-rm -Rf ocaml-$(OCAML_VERSION)
	-rm -Rf flexdll-$(FLEXDLL_VERSION)

# ---- Findlib ----

FINDLIB_VERSION=1.9.1
FINDLIB_EXE=$(PREFIX)/bin/ocamlfind.exe
FINDLIB_TGZ=findlib-$(FINDLIB_VERSION).tar.gz
FINDLIB_SRC=findlib-$(FINDLIB_VERSION)/configure
FINDLIB_CFG=findlib-$(FINDLIB_VERSION)/Makefile.config

$(FINDLIB_TGZ):
	curl -Lfo $(FINDLIB_TGZ) http://download.camlcity.org/download/findlib-$(FINDLIB_VERSION).tar.gz

$(FINDLIB_SRC): $(FINDLIB_TGZ)
	tar xzfm $(FINDLIB_TGZ)

$(FINDLIB_CFG): $(OCAML_EXE) $(FINDLIB_SRC)
	cd findlib-$(FINDLIB_VERSION) && \
	./configure \
	  -bindir $(PREFIX)/bin \
	  -mandir $(PREFIX)/man \
	  -sitelib $(PREFIX)/lib/ocaml \
	  -config $(PREFIX)/etc/findlib.conf

$(FINDLIB_EXE): $(FINDLIB_CFG)
	cd findlib-$(FINDLIB_VERSION) && \
	make all && \
	make opt && \
	make install

findlib: $(FINDLIB_EXE)
.PHONY: findlib

clean::
	-rm -Rf findlib-$(FINDLIB_VERSION)

# ---- Num ----

NUM_VERSION=1.4
NUM_BINARY=$(PREFIX)/lib/ocaml/nums.cmxa
NUM_TGZ=num-$(NUM_VERSION).tar.gz
NUM_SRC=num-$(NUM_VERSION)/Makefile

$(NUM_TGZ):
	curl -Lfo $(NUM_TGZ) https://github.com/ocaml/num/archive/v$(NUM_VERSION).tar.gz

$(NUM_SRC): $(NUM_TGZ)
	tar xzfm $(NUM_TGZ)

$(NUM_BINARY): $(NUM_SRC) $(FINDLIB_EXE)
	cd num-$(NUM_VERSION) && make && make install SO=dll

num: $(NUM_BINARY)
.PHONY: num

clean::
	-rm -Rf num-$(NUM_VERSION)

# ---- ocamlbuild ----

OCAMLBUILD_VERSION=0.14.0
OCAMLBUILD_BINARY=$(PREFIX)/bin/ocamlbuild.exe
OCAMLBUILD_TGZ=ocamlbuild-$(OCAMLBUILD_VERSION).tar.gz
OCAMLBUILD_SRC=ocamlbuild-$(OCAMLBUILD_VERSION)/Makefile

$(OCAMLBUILD_TGZ):
	curl -Lfo $(OCAMLBUILD_TGZ) https://github.com/ocaml/ocamlbuild/archive/$(OCAMLBUILD_VERSION).tar.gz

$(OCAMLBUILD_SRC): $(OCAMLBUILD_TGZ)
	tar xzfm $(OCAMLBUILD_TGZ)

$(OCAMLBUILD_BINARY): $(FINDLIB_BINARY) $(OCAMLBUILD_SRC)
	cd ocamlbuild-$(OCAMLBUILD_VERSION) && \
	make configure && make && make install

ocamlbuild: $(OCAMLBUILD_BINARY)
.PHONY: ocamlbuild

clean::
	-rm -Rf ocamlbuild-$(OCAMLBUILD_VERSION)

# ---- camlp4 ----

CAMLP4_VERSION=4.13+1
CAMLP4_DIR=camlp4-$(subst +,-,$(CAMLP4_VERSION))
CAMLP4_BINARY=$(PREFIX)/bin/camlp4o.exe
CAMLP4_TGZ=camlp4-$(CAMLP4_VERSION).tar.gz
CAMLP4_SRC=$(CAMLP4_DIR)/configure

$(CAMLP4_TGZ):
	curl -Lfo $(CAMLP4_TGZ) https://github.com/ocaml/camlp4/archive/$(CAMLP4_VERSION).tar.gz

$(CAMLP4_SRC): $(CAMLP4_TGZ)
	tar xzfm $(CAMLP4_TGZ)

$(CAMLP4_BINARY): $(OCAMLBUILD_BINARY) $(CAMLP4_SRC)
	cd $(CAMLP4_DIR) && \
	./configure && make all && make install

camlp4: $(CAMLP4_BINARY)
.PHONY: camlp4

clean::
	-rm -Rf $(CAMLP4_DIR)

# ---- GTK ----

GTK_BINARY=$(PREFIX)/bin/gtk-demo.exe

$(GTK_BINARY):
	cd $(PREFIX) && \
	  for url in \
	    https://people.cs.kuleuven.be/~bart.jacobs/verifast/gtk2-win32-binaries/gtk+-bundle_2.24.10-20120208_win32.zip \
	    https://people.cs.kuleuven.be/~bart.jacobs/verifast/gtk2-win32-binaries/gtksourceview-2.10.0.zip \
	    https://people.cs.kuleuven.be/~bart.jacobs/verifast/gtk2-win32-binaries/gtksourceview-dev-2.10.0.zip \
	    https://people.cs.kuleuven.be/~bart.jacobs/verifast/gtk2-win32-binaries/libxml2_2.9.0-1_win32.zip \
	    https://people.cs.kuleuven.be/~bart.jacobs/verifast/gtk2-win32-binaries/libxml2-dev_2.9.0-1_win32.zip \
	  ; do \
	    download_and_unzip --dlcache "$(MAKEDIR)" "$$url" \
	  ; done && \
	  mv bin/pkg-config.exe bin/pkg-config.exe_ && \
	  cp "$(MAKEDIR)/pkg-config_" bin/pkg-config && \
	  mv bin/pkg-config.exe_ bin/pkg-config.exe

gtk: $(GTK_BINARY)
.PHONY: gtk

# ---- lablgtk ----

LABLGTK_VERSION=2.18.11-btj1
LABLGTK_SRC=lablgtk-$(LABLGTK_VERSION)/configure
LABLGTK_CFG=lablgtk-$(LABLGTK_VERSION)/config.make
LABLGTK_BUILD=lablgtk-$(LABLGTK_VERSION)/src/lablgtk.cmxa
LABLGTK_BINARY=$(PREFIX)/lib/ocaml/lablgtk2/lablgtk.cmxa

$(LABLGTK_SRC):
	download_and_untar https://github.com/btj/lablgtk/archive/refs/tags/$(LABLGTK_VERSION).tar.gz

$(LABLGTK_CFG): $(LABLGTK_SRC) $(CAMLP4_BINARY) $(GTK_BINARY)
	cd lablgtk-$(LABLGTK_VERSION) && \
	  (./configure "CC=i686-w64-mingw32-gcc" "USE_CC=1" || bash -vx ./configure "CC=i686-w64-mingw32-gcc" "USE_CC=1")

$(LABLGTK_BUILD): $(LABLGTK_CFG)
	cd lablgtk-$(LABLGTK_VERSION) && \
	  make && make opt

$(LABLGTK_BINARY): $(LABLGTK_BUILD)
	cd lablgtk-$(LABLGTK_VERSION) && make old-install

lablgtk: $(LABLGTK_BINARY)
.PHONY: lablgtk

clean::
	-rm -Rf lablgtk-$(LABLGTK_VERSION)

# ---- Z3 ----

Z3_VERSION=4.8.5
Z3_BINARY=$(PREFIX)/lib/libz3.dll
Z3_DIR=z3-Z3-$(Z3_VERSION)
Z3_SRC=$(Z3_DIR)/scripts/mk_make.py
Z3_CFG=$(Z3_DIR)/build/Makefile
Z3_BUILD=$(Z3_DIR)/build/libz3.dll

$(Z3_SRC):
	download_and_untar https://github.com/Z3Prover/z3/archive/Z3-$(Z3_VERSION).tar.gz
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

# ---- dune ----
DUNE_VERSION=2.9.1
DUNE_BINARY=$(PREFIX)/bin/dune.exe
DUNE_CONF_BINARY=$(PREFIX)/lib/ocaml/dune-configurator/configurator.cmxa

dune-$(DUNE_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml/dune/archive/refs/tags/$(DUNE_VERSION).tar.gz

dune-$(DUNE_VERSION): dune-$(DUNE_VERSION).tar.gz
	tar xzf $<

$(DUNE_BINARY): | dune-$(DUNE_VERSION)
	cd $| && ./configure --libdir=$(PREFIX)/lib/ocaml && make release && make install

$(DUNE_CONF_BINARY): $(DUNE_BINARY) $(CSEXP_BINARY) | dune-$(DUNE_VERSION)
	cd $| && ./dune.exe build @install && ./dune.exe install

dune: $(DUNE_BINARY)
.PHONY: dune

clean::
	-rm -Rf dune-$(DUNE_VERSION)

# ---- csexp ----
CSEXP_VERSION=1.5.1
CSEXP_BINARY=$(PREFIX)/lib/ocaml/csexp/csexp.cmxa

csexp-$(CSEXP_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-dune/csexp/archive/refs/tags/$(CSEXP_VERSION).tar.gz

csexp-$(CSEXP_VERSION): csexp-$(CSEXP_VERSION).tar.gz
	tar xzf $<

$(CSEXP_BINARY): $(DUNE_BINARY) | csexp-$(CSEXP_VERSION)
	cd $| && dune build && dune install

csexp: $(CSEXP_BINARY)
.PHONY: csexp

# ---- sexplib0 ----
SEXPLIB0_VERSION=0.14.0
SEXPLIB0_BINARY=$(PREFIX)/lib/ocaml/sexplib0/sexplib0.cmxa

sexplib0-$(SEXPLIB0_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/sexplib0/archive/refs/tags/v$(SEXPLIB0_VERSION).tar.gz

sexplib0-$(SEXPLIB0_VERSION): sexplib0-$(SEXPLIB0_VERSION).tar.gz
	tar xzf $<

$(SEXPLIB0_BINARY): $(DUNE_BINARY) $(DUNE_CONF_BINARY) | sexplib0-$(SEXPLIB0_VERSION)
	cd $| && dune build && dune install

sexplib0: $(SEXPLIB0_BINARY)
.PHONY: sexplib0

clean::
	-rm -Rf sexplib0-$(SEXPLIB0_VERSION)

# ---- base ----
BASE_VERSION=0.14.1
BASE_BINARY=$(PREFIX)/lib/ocaml/base/base.cmxa

base-$(BASE_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/base/archive/refs/tags/v$(BASE_VERSION).tar.gz

base-$(BASE_VERSION): base-$(BASE_VERSION).tar.gz
	tar xzf $<

$(BASE_BINARY): $(DUNE_BINARY) $(SEXPLIB0_BINARY) | base-$(BASE_VERSION)
	cd $| && dune build && dune install

base: $(SEXPLIB0_BINARY) $(BASE_BINARY)
.PHONY: base

clean::
	-rm -Rf base-$(BASE_VERSION)

# ---- res ----
RES_VERSION=5.0.1
RES_BINARY=$(PREFIX)/lib/ocaml/res/res.cmxa

res-$(RES_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/mmottl/res/archive/refs/tags/$(RES_VERSION).tar.gz

res-$(RES_VERSION): res-$(RES_VERSION).tar.gz
	tar xzf $<

$(RES_BINARY): $(DUNE_BINARY) | res-$(RES_VERSION)
	cd $| && dune build && dune install

res: $(RES_BINARY)
.PHONY: res

clean::
	-rm -Rf res-$(RES_VERSION)

# ---- stdio ----
STDIO_VERSION=0.14.0
STDIO_BINARY=$(PREFIX)/lib/ocaml/stdio/stdio.cmxa

stdio-$(STDIO_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/stdio/archive/refs/tags/v$(STDIO_VERSION).tar.gz

stdio-$(STDIO_VERSION): stdio-$(STDIO_VERSION).tar.gz
	tar xzf $<

$(STDIO_BINARY): $(DUNE_BINARY) $(BASE_BINARY) | stdio-$(STDIO_VERSION)
	cd $| && dune build && dune install

stdio: $(STDIO_BINARY)
.PHONY: stdio

clean::
	-rm -Rf stdio-$(STDIO_VERSION)

# ---- cppo ----
CPPO_VERSION=1.6.8
CPPO_BINARY=$(PREFIX)/bin/cppo.exe

cppo-$(CPPO_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-community/cppo/archive/refs/tags/v$(CPPO_VERSION).tar.gz

cppo-$(CPPO_VERSION): cppo-$(CPPO_VERSION).tar.gz
	tar xzf $<

$(CPPO_BINARY): $(DUNE_BINARY) | cppo-$(CPPO_VERSION)
	cd $| && dune build && dune install

cppo: $(CPPO_BINARY)
.PHONY: cppo

clean::
	-rm -Rf cppo-$(CPPO_VERSION)

# ---- ocplib-endian ----
OCPLIB-ENDIAN_VERSION=1.1
OCPLIB-ENDIAN_BINARY=$(PREFIX)/lib/ocaml/ocplib-endian/ocplib_endian.cmxa

ocplib-endian-$(OCPLIB-ENDIAN_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/OCamlPro/ocplib-endian/archive/$(OCPLIB-ENDIAN_VERSION).tar.gz

ocplib-endian-$(OCPLIB-ENDIAN_VERSION): ocplib-endian-$(OCPLIB-ENDIAN_VERSION).tar.gz
	tar xzf $<

$(OCPLIB-ENDIAN_BINARY): $(DUNE_BINARY) $(CPPO_BINARY) | ocplib-endian-$(OCPLIB-ENDIAN_VERSION)
	cd $| && dune build && dune install

ocplib-endian: $(OCPLIB-ENDIAN_BINARY)
.PHONY: ocplib-endian

clean::
	-rm -Rf ocplib-endian-$(OCPLIB-ENDIAN_VERSION)

# ---- stdint ----
STDINT_VERSION=0.7.0
STDINT_DIR=ocaml-stdint-$(STDINT_VERSION)
STDINT_BINARY=$(PREFIX)/lib/ocaml/stdint/stdint.cmxa

stdint-$(STDINT_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/andrenth/ocaml-stdint/archive/refs/tags/$(STDINT_VERSION).tar.gz

$(STDINT_DIR): stdint-$(STDINT_VERSION).tar.gz
	tar xzf $<

$(STDINT_BINARY): $(DUNE_BINARY) | $(STDINT_DIR)
	cd $| && dune build && dune install

stdint: $(STDINT_BINARY)
.PHONY: stdint

clean::
	-rm -Rf stdint-$(STDINT_VERSION)

# ---- result ----
RESULT_VERSION=1.5
RESULT_BINARY=$(PREFIX)/lib/ocaml/result/result.cmxa

result-$(RESULT_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/result/archive/refs/tags/$(RESULT_VERSION).tar.gz

result-$(RESULT_VERSION): result-$(RESULT_VERSION).tar.gz
	tar xzf $<

$(RESULT_BINARY): $(DUNE_BINARY) | result-$(RESULT_VERSION)
	cd $| && dune build && dune install

result: $(RESULT_BINARY)
.PHONY: result

clean::
	-rm -Rf result-$(RESULT_VERSION)

## capnp plugin for ocaml, which allows to create stubs code with the capnp tool
CAPNP_OCAML_VERSION=3.4.0
CAPNP_OCAML_DIR=capnp-ocaml-$(CAPNP_OCAML_VERSION)
CAPNP_OCAML_BINARY=$(PREFIX)/lib/ocaml/capnp/capnp.cmxa

capnp-$(CAPNP_OCAML_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/capnproto/capnp-ocaml/archive/refs/tags/v$(CAPNP_OCAML_VERSION).tar.gz

$(CAPNP_OCAML_DIR): capnp-$(CAPNP_OCAML_VERSION).tar.gz
	tar xzf $<

$(CAPNP_OCAML_BINARY): $(DUNE_BINARY) $(BASE_BINARY) $(STDIO_BINARY) $(RES_BINARY) $(OCPLIB-ENDIAN_BINARY) $(RESULT_BINARY) $(STDINT_BINARY) | $(CAPNP_OCAML_DIR)
	cd $| && dune build && dune install

capnp-ocaml: $(CAPNP_OCAML_BINARY)
.PHONY: capnp-ocaml

clean::
	-rm -Rf $(CAPNP_OCAML_DIR)

# ---- cap'n proto ----
CAPNP_VERSION=0.9.1
CAPNP_DIR=capnproto
CAPNP_BUILD_DIR=capnproto/c++/build
CAPNP_BINARY=$(PREFIX)/bin/capnp.exe
CAPNP_PROJ_FILENAME=ALL_BUILD.vcxproj
CAPNP_PROJ_FILEPATH=$(CAPNP_BUILD_DIR)/$(CAPNP_PROJ_FILENAME)

$(CAPNP_DIR):
	git clone --depth 1 --branch v$(CAPNP_VERSION) https://github.com/capnproto/capnproto
	patch -u $(CAPNP_DIR)/c++/CMakeLists.txt -i capnpCMakeLists.patch
	patch -u $(CAPNP_DIR)/c++/src/kj/CMakeLists.txt -i kjCMakeLists.patch

$(CAPNP_BUILD_DIR): | $(CAPNP_DIR)
	mkdir $@

$(CAPNP_PROJ_FILEPATH): | $(CAPNP_BUILD_DIR)
	cd $| && \
	cmd /C "$(SET_MSV_ENV) && \
	cmake -DCMAKE_INSTALL_PREFIX=$(PREFIX) -DWITH_OPENSSL=OFF -DWITH_ZLIB=OFF -G "Visual Studio 16 2019" -A Win32 -Thost=x64 .."

$(CAPNP_BINARY): $(CAPNP_PROJ_FILEPATH)
	cd $(CAPNP_BUILD_DIR) && \
	cmd /C "$(SET_MSV_ENV) && \
	msbuild $(CAPNP_PROJ_FILENAME) $(COMMON_CXX_PROPS) && \
	msbuild INSTALL.vcxproj $(COMMON_CXX_PROPS)"
	
capnp: $(CAPNP_BINARY)
.PHONY: capnp

clean::
	-rm -Rf $(CAPNP_DIR)
