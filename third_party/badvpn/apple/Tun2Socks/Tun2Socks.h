// Copyright 2019 The Outline Authors
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

#ifndef Tun2Socks_h
#define Tun2Socks_h

@import Foundation;
@import NetworkExtension;

@interface Tun2Socks : NSObject
+ (NSError *)start:(int)socksServerPort packetFlow:(NEPacketTunnelFlow *)packetFlow;
+ (void)stop;
@end

#endif /* Tun2Socks_h */
