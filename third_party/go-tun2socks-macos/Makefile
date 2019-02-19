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

GOCMD=go
GOBUILD=$(GOCMD) build
BUILDDIR=$(shell pwd)/build
BINARY_NAME=go-tun2socks-macos
ARTIFACT=$(BUILDDIR)/$(BINARY_NAME)
LDFLAGS='-s -w'
TUN2SOCKS_PATH=$(GOPATH)/src/github.com/eycorsican/go-tun2socks

BUILD_CMD="cd $(BUILDDIR) && $(GOBUILD) -ldflags $(LDFLAGS) -o $(ARTIFACT) $(BINARY_NAME)"

all: $(ARTIFACT)

$(ARTIFACT):
	mkdir -p $(BUILDDIR)
	cd $(TUN2SOCKS_PATH) && make copy
	eval $(BUILD_CMD)
	cd $(TUN2SOCKS_PATH) && make clean

clean:
	rm -rf $(BUILDDIR)
	cd $(TUN2SOCKS_PATH) && make clean
