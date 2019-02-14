#!/bin/bash -eu
#
# Copyright 2018 The Outline Authors
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

yarn do src/electron/package_common

# desktopName is required for setAsDefaultProtocolClient to succeed. It must match the name of the
# .desktop file added when the user chooses to "integrate" the AppImage with their system (typically
# it's placed in ~/.local/share/applications).
#
# Set this - very lightly documented - option here rather than in package.json because it is so
# Linux-specific (it unfortunately *cannot* be set in electron-builder.json).

electron-builder \
  --linux \
  --publish never \
  --config src/electron/electron-builder.json \
  --config.extraMetadata.version=$(scripts/semantic_version.sh -p dev) \
  --config.extraMetadata.desktopName=appimagekit-outline-client.desktop
