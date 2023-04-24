![build workflow](https://github.com/verifast/vfdeps-win/actions/workflows/build.yml/badge.svg)
# vfdeps-win
OCaml and OCaml-based VeriFast dependencies on Windows

This repository contains the build script for building OCaml and the OCaml-based packages needed to build [VeriFast](https://github.com/verifast/verifast) for Windows.

The binary produced by this repository contains all dependencies.

## Supply chain security

This repository's GitHub Actions workflow signs the output artifact using [sigstore](https://www.sigstore.dev)'s [cosign](https://docs.sigstore.dev/cosign/overview/) tool, so that anyone can check that the artifact was indeed generated by GitHub Actions from a particular commit of this repository. To do so, in a Bash shell, in the artifact's directory, create a SHASUMS file with the artifact's SHA-256 sum and then compute the SHASUMS file's SHA-256 sum:
```
cd path/to/artifact_directory && sha256sum artifact_name > SHASUMS && sha256sum SHASUMS
```
Note that on Windows, the SHASUMS file will look like `...<SHA256>... *artifact_name`, i.e. there will be an asterisk before the artifact name.
Then look up this hash in [Rekor](https://search.sigstore.dev/), and check that it maps to this repository. If the hash is not in Rekor or does not map to this repository, do not trust the artifact.
