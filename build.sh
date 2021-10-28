#!/bin/bash

set -e # Stop as soon as a command fails.
set -x # Print what is being executed.

pwd
VFDEPS_VERSION=`git describe --always`
VFDEPS_DIRNAME=vfdeps

BUILD_DIR=`pwd`
mkdir upload
UPLOAD_DIR=$BUILD_DIR/upload

VFDEPS_PARENT_DIR=C:/
VFDEPS_PLATFORM=win

VFDEPS_DIR=$VFDEPS_PARENT_DIR/$VFDEPS_DIRNAME
mkdir $VFDEPS_DIR

/c/cygwin/bin/bash -lc "cd /cygdrive/$BUILD_DIR && make PREFIX=$VFDEPS_DIR"

VFDEPS_FILENAME=$VFDEPS_DIRNAME-$VFDEPS_VERSION-$VFDEPS_PLATFORM.txz
VFDEPS_FILEPATH=$UPLOAD_DIR/$VFDEPS_FILENAME
cd $VFDEPS_PARENT_DIR
tar cjf $VFDEPS_FILEPATH $VFDEPS_DIRNAME
cd $BUILD_DIR

ls -l $VFDEPS_FILEPATH
/c/cygwin/bin/bash -lc "sha224sum /cygdrive$VFDEPS_FILEPATH"
