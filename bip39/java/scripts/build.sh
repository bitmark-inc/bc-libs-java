#!/bin/bash

set -e

source scripts/helper.sh

echo "${JAVA_HOME:?}"
echo "${CC:?}"

echo 'Cleanup...'
./scripts/cleanup.sh

PARENT_ROOT_DIR=$(
  cd ../..
  pwd
)
LIB_NAME="libbc-bip39-jni.dylib"
OUT_DIR=src/main/libs
JNI_MD_DIR="darwin"
if ! is_osx; then
  LIB_NAME="libbc-bip39-jni.so"
  JNI_MD_DIR="linux"
fi

# Install bc-crypto-base
pushd "$PARENT_ROOT_DIR/deps/bc-crypto-base"
./configure
make clean
make CFLAGS=-fPIC check
make CFLAGS=-fPIC install
popd

# Install bc-bip39
pushd "$PARENT_ROOT_DIR/deps/bc-bip39"
./configure
make clean
make CFLAGS=-fPIC check
popd

# Install jni lib
echo "Building $LIB_NAME..."
mkdir -p $OUT_DIR
$CC -I"$JAVA_HOME/include" \
  -I"$JAVA_HOME/include/$JNI_MD_DIR" \
  -I"$PARENT_ROOT_DIR/base-jni" \
  -I"$PARENT_ROOT_DIR/deps/bc-bip39/src" \
  -fexceptions -frtti -shared -fPIC \
  src/main/jniLibs/*.c \
  "$PARENT_ROOT_DIR"/base-jni/*.c \
  "$PARENT_ROOT_DIR"/deps/bc-bip39/src/libbc-bip39.a \
  "$PARENT_ROOT_DIR"/deps/bc-crypto-base/src/libbc-crypto-base.a \
  -o \
  $OUT_DIR/$LIB_NAME
echo "Done. Checkout the release file at $OUT_DIR/$LIB_NAME"
