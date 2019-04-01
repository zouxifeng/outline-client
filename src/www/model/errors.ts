// Copyright 2018 The Outline Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import {Server} from './server';

export class OutlineError extends Error {
  constructor(message?: string) {
    super(message);  // 'Error' breaks prototype chain here
    // https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-2.html#support-for-newtarget
    Object.setPrototypeOf(this, new.target.prototype);
    this.name = new.target.name;
  }
}

export class ServerAlreadyAdded extends OutlineError {
  constructor(public readonly server: Server) {
    super();
  }
}

export class ServerIncompatible extends OutlineError {
  constructor(message: string) {
    super(message);
  }
}

export class ServerUrlInvalid extends OutlineError {
  constructor(message: string) {
    super(message);
  }
}

export class OperationTimedOut extends OutlineError {
  constructor(public readonly timeoutMs: number, public readonly operationName: string) {
    super();
  }
}

export class FeedbackSubmissionError extends OutlineError {
  constructor() {
    super();
  }
}

// Error thrown by "native" code.
//
// Must be kept in sync with its Cordova doppelganger:
//   cordova-plugin-outline/outlinePlugin.js
//
// TODO: Rename this class, "plugin" is a poor name since the Electron apps do not have plugins.
export class OutlinePluginError extends OutlineError {
  constructor(message: string, public readonly errorCode: ErrorCode) {
    super(message);
  }
}

// Must be kept in sync with:
//  - cordova-plugin-outline/apple/src/OutlineVpn.swift#ErrorCode
//  - cordova-plugin-outline/apple/vpn/PacketTunnelProvider.h#NS_ENUM
//  - cordova-plugin-outline/outlinePlugin.js#ERROR_CODE
//  - cordova-plugin-outline/android/java/org/outline/OutlinePlugin.java#ErrorCode
export const enum ErrorCode {
  // TODO: NO_ERROR is weird. Only used internally by the Android plugin?
  NO_ERROR = 0,
  // TODO: Rename to something more specific, or remove - only used by Android?
  UNEXPECTED = 1,
  VPN_PERMISSION_NOT_GRANTED = 2,
  INVALID_SERVER_CREDENTIALS = 3,
  UDP_RELAY_NOT_ENABLED = 4,
  SERVER_UNREACHABLE = 5,
  VPN_START_FAILURE = 6,
  ILLEGAL_SERVER_CONFIGURATION = 7,
  SHADOWSOCKS_START_FAILURE = 8,
  CONFIGURE_SYSTEM_PROXY_FAILURE = 9,
  NO_ADMIN_PERMISSIONS = 10,
  UNSUPPORTED_ROUTING_TABLE = 11,
  SYSTEM_MISCONFIGURED = 12
}
