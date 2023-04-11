MAKEDIR:=$(shell pwd)
PATH:=$(shell cygpath "$(MAKEDIR)"):$(shell cygpath "$(PREFIX)")/bin:$(PATH)

all: ocaml findlib num ocamlbuild camlp-streams camlp4 gtk libxml gtksourceview lablgtk z3 csexp dune sexplib0 base res stdio cppo ocplib-endian stdint result capnp capnp-ocaml stdlib-shims ocaml-compiler-libs ppx_derivers ppxlib ppx_parser

clean::
	-rm -Rf $(PREFIX)

# ---- OCaml ----

OCAML_VERSION=4.14.0
OCAML_TGZ=ocaml-$(OCAML_VERSION).tar.gz
OCAML_DIR=ocaml-$(OCAML_VERSION)
FLEXDLL_VERSION=0.42
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
	./configure --prefix=$(PREFIX) --build=x86_64-pc-cygwin --host=x86_64-w64-mingw32 && \
	make && make install

ocaml: $(OCAML_EXE)
.PHONY: ocaml

clean::
	-rm -Rf ocaml-$(OCAML_VERSION)
	-rm -Rf flexdll-$(FLEXDLL_VERSION)

# ---- Findlib ----

FINDLIB_VERSION=1.9.5
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

$(FINDLIB_EXE): | $(FINDLIB_CFG)
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

$(NUM_BINARY): $(FINDLIB_EXE) | $(NUM_SRC)
	cd num-$(NUM_VERSION) && make && make install SO=dll

num: $(NUM_BINARY)
.PHONY: num

clean::
	-rm -Rf num-$(NUM_VERSION)

# ---- ocamlbuild ----

OCAMLBUILD_VERSION=0.14.2
OCAMLBUILD_BINARY=$(PREFIX)/bin/ocamlbuild.exe
OCAMLBUILD_TGZ=ocamlbuild-$(OCAMLBUILD_VERSION).tar.gz
OCAMLBUILD_SRC=ocamlbuild-$(OCAMLBUILD_VERSION)/Makefile

$(OCAMLBUILD_TGZ):
	curl -Lfo $(OCAMLBUILD_TGZ) https://github.com/ocaml/ocamlbuild/archive/$(OCAMLBUILD_VERSION).tar.gz

$(OCAMLBUILD_SRC): $(OCAMLBUILD_TGZ)
	tar xzfm $(OCAMLBUILD_TGZ)

$(OCAMLBUILD_BINARY): $(FINDLIB_EXE) | $(OCAMLBUILD_SRC)
	cd ocamlbuild-$(OCAMLBUILD_VERSION) && \
	make configure && make && make install

ocamlbuild: $(OCAMLBUILD_BINARY)
.PHONY: ocamlbuild

clean::
	-rm -Rf ocamlbuild-$(OCAMLBUILD_VERSION)

# ---- dune ----
DUNE_VERSION=3.7.1
DUNE_BINARY=$(PREFIX)/bin/dune

dune-$(DUNE_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml/dune/archive/refs/tags/$(DUNE_VERSION).tar.gz

dune-$(DUNE_VERSION): dune-$(DUNE_VERSION).tar.gz
	tar xzf $<

$(DUNE_BINARY): | dune-$(DUNE_VERSION)
	cd $| && ./configure --libdir=$(PREFIX)/lib/ocaml && make release && make install

dune: $(DUNE_BINARY)
.PHONY: dune

clean::
	-rm -Rf dune-$(DUNE_VERSION)

DUNE_INSTALL=dune build @install --profile release && dune install --profile release --prefix=$(PREFIX) --libdir=$(PREFIX)/lib/ocaml

# ---- camlp-streams ----
CAMLP_STREAMS_VERSION=5.0.1
CAMLP_STREAMS_BINARY=$(PREFIX)/lib/ocaml/camlp-stream/camlp-streams.cmxa

camlp-streams-$(CAMLP_STREAMS_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml/camlp-streams/archive/refs/tags/v$(CAMLP_STREAMS_VERSION).tar.gz

camlp-streams-$(CAMLP_STREAMS_VERSION): camlp-streams-$(CAMLP_STREAMS_VERSION).tar.gz
	tar xzf $<

$(CAMLP_STREAMS_BINARY): $(DUNE_BINARY) | camlp-streams-$(CAMLP_STREAMS_VERSION)
	cd $| && $(DUNE_INSTALL)

camlp-streams: $(CAMLP_STREAMS_BINARY)
.PHONY: camlp-streams

clean::
	-rm -Rf camlp-streams-$(CAMLP_STREAMS_VERSION)

# ---- camlp4 ----

CAMLP4_VERSION=4.14+1
CAMLP4_DIR=camlp4-$(subst +,-,$(CAMLP4_VERSION))
CAMLP4_BINARY=$(PREFIX)/bin/camlp4o.exe
CAMLP4_TGZ=camlp4-$(CAMLP4_VERSION).tar.gz
CAMLP4_SRC=$(CAMLP4_DIR)/configure

$(CAMLP4_TGZ):
	curl -Lfo $(CAMLP4_TGZ) https://github.com/ocaml/camlp4/archive/$(CAMLP4_VERSION).tar.gz

$(CAMLP4_SRC): $(CAMLP4_TGZ)
	tar xzfm $(CAMLP4_TGZ)

$(CAMLP4_BINARY): $(OCAMLBUILD_BINARY) $(CAMLP_STREAMS_BINARY) | $(CAMLP4_SRC)
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
	download_and_unzip --dlcache "$(MAKEDIR)" "https://download.gnome.org/binaries/win64/gtk+/2.22/gtk%2B-bundle_2.22.1-20101229_win64.zip" && \
	mv bin/pkg-config.exe bin/pkg-config.exe_ && \
	cp "$(MAKEDIR)/pkg-config_" bin/pkg-config && \
	mv bin/pkg-config.exe_ bin/pkg-config.exe

gtk: $(GTK_BINARY)
.PHONY: gtk

# ---- libxml2 ----
LIBXML_VERSION=v2.10.2
LIBXML_DLL=$(PREFIX)/bin/libxml2-2.dll

libxml2-$(LIBXML_VERSION).tar.gz:
	curl -Lfo $@ https://gitlab.gnome.org/GNOME/libxml2/-/archive/$(LIBXML_VERSION)/libxml2-$(LIBXML_VERSION).tar.gz

libxml2-$(LIBXML_VERSION): libxml2-$(LIBXML_VERSION).tar.gz
	tar xzf $<

$(LIBXML_DLL): | libxml2-$(LIBXML_VERSION)
	cd $| && \
	./autogen.sh --build=x86_64-pc-cygwin --host=x86_64-w64-mingw32 \
		--prefix=$(PREFIX) --disable-static --without-zlib \
		--without-iconv --without-lzma --without-python \
	&& make && make install

libxml: $(LIBXML_DLL)
.PHONY: libxml

clean::
	-rm -Rf libxml2-$(LIBXML_VERSION)

# ---- gtksourceview2 ----
GTK_SOURCEVIEW_VERSION=2.10.5
GTK_SOURCEVIEW_DLL=$(PREFIX)/bin/libgtksourceview-2.0-0.dll

gtksourceview-$(GTK_SOURCEVIEW_VERSION).tar.gz:
	curl -Lfo $@ https://download.gnome.org/sources/gtksourceview/2.10/gtksourceview-$(GTK_SOURCEVIEW_VERSION).tar.gz

gtksourceview-$(GTK_SOURCEVIEW_VERSION): gtksourceview-$(GTK_SOURCEVIEW_VERSION).tar.gz
	tar xzf $<

$(GTK_SOURCEVIEW_DLL): $(LIBXML_DLL) $(GTK_BINARY) | gtksourceview-$(GTK_SOURCEVIEW_VERSION)
	cd $| && \
	./configure PKG_CONFIG=$(PREFIX)/bin/pkg-config --build=x86_64-pc-cygwin --host=x86_64-w64-mingw32 --prefix=$(PREFIX) && \
	make && make install

gtksourceview: $(GTK_SOURCEVIEW_DLL)
.PHONY: gtksourceview

clean::
	-rm -Rf gtksourceview-$(GTK_SOURCEVIEW_VERSION)

# ---- lablgtk ----

LABLGTK_VERSION=2.18.13
LABLGTK_SRC=lablgtk-$(LABLGTK_VERSION)/configure
LABLGTK_CFG=lablgtk-$(LABLGTK_VERSION)/config.make
LABLGTK_BUILD=lablgtk-$(LABLGTK_VERSION)/src/lablgtk.cmxa
LABLGTK_BINARY=$(PREFIX)/lib/ocaml/lablgtk2/lablgtk.cmxa

$(LABLGTK_SRC):
	download_and_untar https://github.com/garrigue/lablgtk/archive/refs/tags/$(LABLGTK_VERSION).tar.gz
$(LABLGTK_CFG): $(CAMLP4_BINARY) $(GTK_BINARY) $(GTK_SOURCEVIEW_DLL) | $(LABLGTK_SRC)
	cd lablgtk-$(LABLGTK_VERSION) && \
	  (./configure "CC=CC=x86_64-w64-mingw32-gcc" "USE_CC=1" || bash -vx ./configure "CC=x86_64-w64-mingw32-gcc" "USE_CC=1") && \
	  cd src && sed -i '1s/^/.SECONDARY:\n /' Makefile
# .SECONDARY: stops make from deleting temporary files, which are required for installation

$(LABLGTK_BUILD): $(LABLGTK_CFG)
	cd lablgtk-$(LABLGTK_VERSION) && \
	  make && make opt

$(LABLGTK_BINARY): | $(LABLGTK_BUILD)
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

$(Z3_CFG): $(FINDLIB_EXE) $(NUM_BINARY) | $(Z3_SRC)
	cd $(Z3_DIR) && CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc AR=x86_64-w64-mingw32-ar python scripts/mk_make.py --ml --prefix=$(PREFIX)

$(Z3_BUILD): $(Z3_CFG)
	cd $(Z3_DIR)/build && make

$(Z3_BINARY): $(Z3_BUILD)
	cd $(Z3_DIR)/build && make install && cp libz3.dll.a $(PREFIX)/lib

z3: $(Z3_BINARY)
.PHONY: z3

clean::
	-rm -Rf $(Z3_DIR)

# ---- csexp ----
CSEXP_VERSION=1.5.1
CSEXP_BINARY=$(PREFIX)/lib/ocaml/csexp/csexp.cmxa

csexp-$(CSEXP_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-dune/csexp/archive/refs/tags/$(CSEXP_VERSION).tar.gz

csexp-$(CSEXP_VERSION): csexp-$(CSEXP_VERSION).tar.gz
	tar xzf $<

$(CSEXP_BINARY): $(DUNE_BINARY) | csexp-$(CSEXP_VERSION)
	cd $| && $(DUNE_INSTALL)

csexp: $(CSEXP_BINARY)
.PHONY: csexp

# ---- dune other libraries ----
STDUNE_BINARY=$(PREFIX)/lib/ocaml/stdune/stdune.cmxa
$(STDUNE_BINARY): $(DUNE_BINARY) $(CSEXP_BINARY) | dune-$(DUNE_VERSION)
	cd $| && ./dune.exe build stdune.install && dune install stdune --prefix=$(PREFIX) --libdir=$(PREFIX)/lib/ocaml

DUNE_CONF_BINARY=$(PREFIX)/lib/ocaml/dune-configurator/configurator.cmxa
$(DUNE_CONF_BINARY): $(DUNE_BINARY) $(STDUNE_BINARY) | dune-$(DUNE_VERSION)
	cd $| && ./dune.exe build dune-configurator.install && ./dune.exe install dune-configurator --prefix=$(PREFIX) --libdir=$(PREFIX)/lib/ocaml

# ---- sexplib0 ----
SEXPLIB0_VERSION=0.15.1
SEXPLIB0_BINARY=$(PREFIX)/lib/ocaml/sexplib0/sexplib0.cmxa

sexplib0-$(SEXPLIB0_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/sexplib0/archive/refs/tags/v$(SEXPLIB0_VERSION).tar.gz

sexplib0-$(SEXPLIB0_VERSION): sexplib0-$(SEXPLIB0_VERSION).tar.gz
	tar xzf $<

$(SEXPLIB0_BINARY): $(DUNE_BINARY) | sexplib0-$(SEXPLIB0_VERSION)
	cd $| && $(DUNE_INSTALL)

sexplib0: $(SEXPLIB0_BINARY)
.PHONY: sexplib0

clean::
	-rm -Rf sexplib0-$(SEXPLIB0_VERSION)

# ---- base ----
BASE_VERSION=0.15.1
BASE_BINARY=$(PREFIX)/lib/ocaml/base/base.cmxa

base-$(BASE_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/base/archive/refs/tags/v$(BASE_VERSION).tar.gz

base-$(BASE_VERSION): base-$(BASE_VERSION).tar.gz
	tar xzf $<

$(BASE_BINARY): $(DUNE_BINARY) $(DUNE_CONF_BINARY) $(SEXPLIB0_BINARY) | base-$(BASE_VERSION)
	cd $| && $(DUNE_INSTALL)

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
	cd $| && $(DUNE_INSTALL)

res: $(RES_BINARY)
.PHONY: res

clean::
	-rm -Rf res-$(RES_VERSION)

# ---- stdio ----
STDIO_VERSION=0.15.0
STDIO_BINARY=$(PREFIX)/lib/ocaml/stdio/stdio.cmxa

stdio-$(STDIO_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/stdio/archive/refs/tags/v$(STDIO_VERSION).tar.gz

stdio-$(STDIO_VERSION): stdio-$(STDIO_VERSION).tar.gz
	tar xzf $<

$(STDIO_BINARY): $(DUNE_BINARY) $(BASE_BINARY) | stdio-$(STDIO_VERSION)
	cd $| && $(DUNE_INSTALL)

stdio: $(STDIO_BINARY)
.PHONY: stdio

clean::
	-rm -Rf stdio-$(STDIO_VERSION)

# ---- cppo ----
CPPO_VERSION=1.6.9
CPPO_BINARY=$(PREFIX)/bin/cppo

cppo-$(CPPO_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-community/cppo/archive/refs/tags/v$(CPPO_VERSION).tar.gz

cppo-$(CPPO_VERSION): cppo-$(CPPO_VERSION).tar.gz
	tar xzf $<

$(CPPO_BINARY): $(DUNE_BINARY) | cppo-$(CPPO_VERSION)
	cd $| && $(DUNE_INSTALL)

cppo: $(CPPO_BINARY)
.PHONY: cppo

clean::
	-rm -Rf cppo-$(CPPO_VERSION)

# ---- ocplib-endian ----
OCPLIB-ENDIAN_VERSION=1.2
OCPLIB-ENDIAN_BINARY=$(PREFIX)/lib/ocaml/ocplib-endian/ocplib_endian.cmxa

ocplib-endian-$(OCPLIB-ENDIAN_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/OCamlPro/ocplib-endian/archive/$(OCPLIB-ENDIAN_VERSION).tar.gz

ocplib-endian-$(OCPLIB-ENDIAN_VERSION): ocplib-endian-$(OCPLIB-ENDIAN_VERSION).tar.gz
	tar xzf $<

$(OCPLIB-ENDIAN_BINARY): $(DUNE_BINARY) $(CPPO_BINARY) | ocplib-endian-$(OCPLIB-ENDIAN_VERSION)
	cd $| && $(DUNE_INSTALL)

ocplib-endian: $(OCPLIB-ENDIAN_BINARY)
.PHONY: ocplib-endian

clean::
	-rm -Rf ocplib-endian-$(OCPLIB-ENDIAN_VERSION)

# ---- stdint ----
STDINT_VERSION=0.7.2
STDINT_DIR=ocaml-stdint-$(STDINT_VERSION)
STDINT_BINARY=$(PREFIX)/lib/ocaml/stdint/stdint.cmxa

stdint-$(STDINT_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/andrenth/ocaml-stdint/archive/refs/tags/$(STDINT_VERSION).tar.gz

$(STDINT_DIR): stdint-$(STDINT_VERSION).tar.gz
	tar xzf $<

$(STDINT_BINARY): $(DUNE_BINARY) | $(STDINT_DIR)
	cd $| && $(DUNE_INSTALL)

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
	cd $| && $(DUNE_INSTALL)

result: $(RESULT_BINARY)
.PHONY: result

clean::
	-rm -Rf result-$(RESULT_VERSION)

# ---- cap'n proto ----
## capnp tool to produce stubs code based on .capnp schema files, also installs the C++ plugin to create C++ stubs
CAPNP_VERSION=0.10.3
CAPNP_DIR=capnproto-$(CAPNP_VERSION)
CAPNP_BINARY=$(PREFIX)/bin/capnp.exe

capnp-c++-$(CAPNP_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/capnproto/capnproto/archive/refs/tags/v$(CAPNP_VERSION).tar.gz

$(CAPNP_DIR): capnp-c++-$(CAPNP_VERSION).tar.gz
	tar xzf $<

$(CAPNP_BINARY): | $(CAPNP_DIR)
	cd $| && cmake -G Ninja -S . -B build -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DWITH_OPENSSL=OFF -DCMAKE_INSTALL_PREFIX=$(shell cygpath $(PREFIX)) -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -static" -DBUILD_TESTING=OFF && cmake --build build --target install

capnp: $(CAPNP_BINARY)
.PHONY: capnp

clean::
	-rm -Rf $(CAPNP_DIR)

## capnp plugin for ocaml, which allows to create stubs code with the capnp tool
CAPNP_OCAML_VERSION=3.5.0
CAPNP_OCAML_DIR=capnp-ocaml-$(CAPNP_OCAML_VERSION)
CAPNP_OCAML_BINARY=$(PREFIX)/lib/ocaml/capnp/capnp.cmxa

capnp-ocaml-$(CAPNP_OCAML_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/capnproto/capnp-ocaml/archive/refs/tags/v$(CAPNP_OCAML_VERSION).tar.gz

$(CAPNP_OCAML_DIR): capnp-ocaml-$(CAPNP_OCAML_VERSION).tar.gz
	tar xzf $<

$(CAPNP_OCAML_BINARY): $(DUNE_BINARY) $(BASE_BINARY) $(STDIO_BINARY) $(RES_BINARY) $(OCPLIB-ENDIAN_BINARY) $(RESULT_BINARY) $(STDINT_BINARY) | $(CAPNP_OCAML_DIR)
	cd $| && $(DUNE_INSTALL)

capnp-ocaml: $(CAPNP_OCAML_BINARY)
.PHONY: capnp-ocaml

clean::
	-rm -Rf $(CAPNP_OCAML_DIR)

# ---- ocaml compiler libs ----
OCAML_COMPILER_LIBS_VERSION=0.12.4
OCAML_COMPILER_LIBS_BINARY=$(PREFIX)/lib/ocaml/ocaml-compiler-libs/toplevel/ocaml_toplevel.cmxa

ocaml-compiler-libs-$(OCAML_COMPILER_LIBS_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/janestreet/ocaml-compiler-libs/archive/refs/tags/v$(OCAML_COMPILER_LIBS_VERSION).tar.gz

ocaml-compiler-libs-$(OCAML_COMPILER_LIBS_VERSION): ocaml-compiler-libs-$(OCAML_COMPILER_LIBS_VERSION).tar.gz
	tar xzf $<

$(OCAML_COMPILER_LIBS_BINARY): $(DUNE_BINARY) | ocaml-compiler-libs-$(OCAML_COMPILER_LIBS_VERSION)
	cd $| && $(DUNE_INSTALL)

ocaml-compiler-libs: $(OCAML_COMPILER_LIBS_BINARY)
.PHONY: ocaml-compiler-libs

clean::
	-rm -Rd ocaml-compiler-libs-$(OCAML_COMPILER_LIBS_VERSION)

# ---- stdlib-shims ----
STDLIB-SHIMS_VERSION=0.3.0
STDLIB-SHIMS_BINARY=$(PREFIX)/lib/ocaml/stdlib-shims/stdlib_shims.cmxa

stdlib-shims-$(STDLIB-SHIMS_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml/stdlib-shims/archive/refs/tags/$(STDLIB-SHIMS_VERSION).tar.gz

stdlib-shims-$(STDLIB-SHIMS_VERSION): stdlib-shims-$(STDLIB-SHIMS_VERSION).tar.gz
	tar xzf $<

$(STDLIB-SHIMS_BINARY): $(DUNE_BINARY) | stdlib-shims-$(STDLIB-SHIMS_VERSION)
	cd $| && $(DUNE_INSTALL)

stdlib-shims: $(STDLIB-SHIMS_BINARY)
.PHONY: stdlib-shims

clean::
	-rm -Rf stdlib-shims-$(STDLIB-SHIMS_VERSION)

# ---- ppx derivers ----
PPX_DERIVERS_VERSION=1.2.1
PPX_DERIVERS_BINARY=$(PREFIX)/lib/ocaml/ppx_derivers/ppx_derivers.cmxa

ppx_derivers-$(PPX_DERIVERS_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-ppx/ppx_derivers/archive/refs/tags/$(PPX_DERIVERS_VERSION).tar.gz

ppx_derivers-$(PPX_DERIVERS_VERSION): ppx_derivers-$(PPX_DERIVERS_VERSION).tar.gz
	tar xzf $<

$(PPX_DERIVERS_BINARY): $(DUNE_BINARY) | ppx_derivers-$(PPX_DERIVERS_VERSION)
	cd $| && $(DUNE_INSTALL)

ppx_derivers: $(PPX_DERIVERS_BINARY)
.PHONY: ppx_derivers

clean::
	-rm -Rf ppx_derivers-$(PPX_DERIVERS_VERSION)

# ---- ppxlib ----
PPXLIB_VERSION=0.28.0
PPXLIB_BINARY=$(PREFIX)/lib/ocaml/ppxlib/ppxlib.cmxa

ppxlib-$(PPXLIB_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/ocaml-ppx/ppxlib/archive/refs/tags/$(PPXLIB_VERSION).tar.gz

ppxlib-$(PPXLIB_VERSION): ppxlib-$(PPXLIB_VERSION).tar.gz
	tar xzf $<

$(PPXLIB_BINARY): $(DUNE_BINARY) $(STDLIB-SHIMS_BINARY) $(OCAML_COMPILER_LIBS_BINARY) $(PPX_DERIVERS_BINARY) $(SEXPLIB0_BINARY) | ppxlib-$(PPXLIB_VERSION)
	cd $| && $(DUNE_INSTALL)

ppxlib: $(PPXLIB_BINARY)
.PHONY: ppxlib

clean::
	-rm -Rf ppxlib-$(PPXLIB_VERSION)

# ---- ppx parser ----
PPX_PARSER_VERSION=0.1.0
PPX_PARSER_BINARY=$(PREFIX)/lib/ocaml/ppx_parser/ppx_parser.cmxa

ppx_parser-$(PPX_PARSER_VERSION).tar.gz:
	curl -Lfo $@ https://github.com/NielsMommen/ppx_parser/archive/refs/tags/$(PPX_PARSER_VERSION).tar.gz

ppx_parser-$(PPX_PARSER_VERSION): ppx_parser-$(PPX_PARSER_VERSION).tar.gz
	tar xzf $<

$(PPX_PARSER_BINARY): $(DUNE_BINARY) $(PPXLIB_BINARY) | ppx_parser-$(PPX_PARSER_VERSION)
	cd $| && $(DUNE_INSTALL)

ppx_parser: $(PPX_PARSER_BINARY)
.PHONY: ppx_parser

clean::
	-rm -Rf ppx_parser-$(PPX_PARSER_VERSION)
