[![Build Status](https://travis-ci.org/verifast/vfdeps-win.svg?branch=master)](https://travis-ci.org/verifast/vfdeps-win)
# vfdeps-win
OCaml and OCaml-based VeriFast dependencies on Windows

This repository contains the build script for building OCaml and the OCaml-based packages needed to build [VeriFast](https://github.com/verifast/verifast) for Windows.

The Travis CI script deploys the binary to [Bintray](https://dl.bintray.com/verifast/verifast).

To avoid running into the Travis CI build time limit, this build has been split into two phases: all dependencies except for Z3 are built by [vfdeps-win-noz3](https://github.com/verifast/vfdeps-win-noz3); the present repository downloads the binary produced by `vfdeps-win-noz3` and builds Z3 on top of it. See [setup-build.sh](https://github.com/verifast/vfdeps-win/blob/master/setup-build.sh) to tell which version of `vfdeps-win-noz3` is being used.

The binary produced by this repository contains all dependencies.
