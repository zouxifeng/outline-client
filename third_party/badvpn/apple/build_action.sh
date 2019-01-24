#!/bin/bash -eu
#
# Copyright 2019 The Outline Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "Building Tun2Socks frameworks..."

TUN2SOCKS_DIR=$ROOT_DIR/third_party/badvpn/apple
BUILD_DIR=$TUN2SOCKS_DIR/build

function build_libtun2socks() {
  local OS=$1
  local CMAKE_FLAGS=$2
  case "$OS" in
    "ios") CMAKE_OS="OS" ;;
    "macos") CMAKE_OS="MACOS" ;;
    *) echo "Cannot build tun2socks for $OS"; return 1 ;;
  esac
  echo "Building libtun2socks for $OS..."

  pushd $BUILD_DIR > /dev/null

  cmake ../.. -DCMAKE_TOOLCHAIN_FILE=../apple_toolchain.cmake -DIOS_PLATFORM=$CMAKE_OS -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DCMAKE_BUILD_TYPE=Release $CMAKE_FLAGS
  make
  cp tun2socks/libtun2socks.dylib $TUN2SOCKS_DIR/Tun2Socks/libtun2socks/lib/$OS/

  popd > /dev/null
  rm -rf $BUILD_DIR
}

mkdir -p $BUILD_DIR
build_libtun2socks "macos" ""
# Disable bitcode in iOS, otherwise the dynamic library will fail to link at runtime.
build_libtun2socks "ios" "-DENABLE_BITCODE=0"

# TODO(alalama): build Tun2Socks_[iOS|macOS] frameworks with xcodebuild

