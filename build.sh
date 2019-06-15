#!/bin/bash

set -xe

# 
# 1. Compile cross toolcahin
#    a. compile llvm, clang
#    b. compile binutils
#    c. compile cross tool libc, libcxx
#
# 2. Compile flutter engine
# 3. Compile flutter embedder for raspi
#

# IMPORTANT :  SETUP
# 1. Script is not writter for retriggering, do so manually / by commenting build steps
# 2. all install will be done at /sdk/toolchain (assumes this dir to be present with writer permissions)
#       > sudo mkdir -p /sdk/toolchain
#       > suod chmod -R a+wx /sdk
# 2. Modify to point to right directory after cloning, TODO make it build arg
BUILD_DIR=/home/shrkamat/hackathon-2019/build

# 1.a
mkdir -p $BUILD_DIR/llvm
cmake -B $BUILD_DIR/llvm llvm-project/llvm            \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_INSTALL_PREFIX=/sdk/toolchain             \
    -DLLVM_DEFAULT_TARGET_TRIPLE=arm-linux-gnueabihf  \
    -DLLVM_TARGETS_TO_BUILD=ARM                       \
    -DLLVM_ENABLE_PROJECTS="clang;libunwind;lldb;compiler-rt;lld;polly"
make -C $BUILD_DIR/llvm -j4
make -C $BUILD_DIR/llvm install

# 1.b
mkdir -p $BUILD_DIR/binutils
cd $BUILD_DIR/binutils
../../binutils/configure --prefix="/sdk/toolchain"    \
    --enable-gold                                     \
    --enable-ld                                       \
    --target=arm-linux-gnueabihf
make
make install
cd -

# 1.c
mkdir -p $BUILD_DIR/libcxxabi
cmake -B $BUILD_DIR/libcxxabi llvm-project/libcxxabi  \
    -DCMAKE_CROSSCOMPILING=True                       \
    -DCMAKE_SYSROOT=/sdk/sysroot                      \
    -DLIBCXX_ENABLE_SHARED=False                      \
    -DCMAKE_INSTALL_PREFIX=/sdk/toolchain             \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_SYSTEM_NAME=Linux                         \
    -DCMAKE_SYSTEM_PROCESSOR=ARM                      \
    -DCMAKE_C_COMPILER=/sdk/toolchain/bin/clang       \
    -DCMAKE_CXX_COMPILER=/sdk/toolchain/bin/clang++   \
    -DLLVM_TARGETS_TO_BUILD=ARM                       \
    -DLIBCXXABI_ENABLE_EXCEPTIONS=False
make -C $BUILD_DIR/libcxxabi -j4
make -C $BUILD_DIR/libcxxabi install

mkdir -p $BUILD_DIR/libcxx
cmake -B $BUILD_DIR/libcxx llvm-project/libcxx                   \
    -DCMAKE_CROSSCOMPILING=True                                  \
    -DCMAKE_SYSROOT=/sdk/sysroot                                 \
    -DLIBCXX_ENABLE_SHARED=False                                 \
    -DCMAKE_INSTALL_PREFIX=/sdk/toolchain                        \
    -DCMAKE_BUILD_TYPE=Release                                   \
    -DCMAKE_SYSTEM_NAME=Linux                                    \
    -DCMAKE_SYSTEM_PROCESSOR=ARM                                 \
    -DCMAKE_C_COMPILER=/sdk/toolchain/bin/clang                  \
    -DCMAKE_CXX_COMPILER=/sdk/toolchain/bin/clang++              \
    -DLLVM_TARGETS_TO_BUILD=ARM                                  \
    -DLIBCXX_ENABLE_EXCEPTIONS=False                             \
    -DLIBCXX_ENABLE_RTTI=False                                   \
    -DLIBCXX_CXX_ABI=libcxxabi                                   \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/sdk/toolchain/include/c++/v1 \
    -DLIBCXX_CXX_ABI_LIBRARY_PATH=/sdk/toolchain/lib             \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=True

make -C $BUILD_DIR/libcxx -j4
make -C $BUILD_DIR/libcxx install