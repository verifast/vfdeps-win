#!/bin/bash

set -e # Stop as soon as a command fails.
set -x # Print what is being executed.

pwd
VFDEPS_VERSION=`git describe --always`
VFDEPS_DIRNAME=vfdeps-$VFDEPS_VERSION

BUILD_DIR=`pwd`
mkdir upload
UPLOAD_DIR=$BUILD_DIR/upload

VFDEPS_PARENT_DIR=C:/
VFDEPS_PLATFORM=win

VFDEPS_DIR=$VFDEPS_PARENT_DIR/$VFDEPS_DIRNAME

/c/cygwin/bin/bash -lc "cd /cygdrive/$BUILD_DIR && make PREFIX=$VFDEPS_DIR"

VFDEPS_FILENAME=$VFDEPS_DIRNAME-$VFDEPS_PLATFORM.txz
VFDEPS_FILEPATH=$UPLOAD_DIR/$VFDEPS_FILENAME
cd $VFDEPS_PARENT_DIR
tar cjf $VFDEPS_FILEPATH $VFDEPS_DIRNAME
cd $BUILD_DIR

echo '{' > bintray.json
echo '    "package": {' >> bintray.json
echo '        "name": "vfdeps",' >> bintray.json
echo '        "repo": "verifast",' >> bintray.json
echo '        "subject": "verifast",' >> bintray.json
echo '        "vcs_url": "https://github.com/verifast/vfdeps",' >> bintray.json
echo '        "licenses": ["MIT"]' >> bintray.json
echo '    },' >> bintray.json
echo '    "version": {' >> bintray.json
echo '        "name": "'$VFDEPS_VERSION'"' >> bintray.json
echo '    },' >> bintray.json
echo '    "files": [{"includePattern": "upload/(.*)", "uploadPattern": "$1"}],' >> bintray.json
echo '    "publish": true' >> bintray.json
echo '}' >> bintray.json

cat bintray.json
