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

#include "Tun2Socks.h"
#include <sys/socket.h>
#include <sys/types.h>
#include "libtun2socks.h"

static const int kTunMtu = 1500;
NSString *const kLocalHostIp = @"127.0.0.1";

@interface Tun2Socks ()
@property(nonatomic) NEPacketTunnelFlow *tunnelPacketFlow;
@property(nonatomic) uint16_t socksServerPort;
@property(nonatomic) uint32_t parentFd;
@property(nonatomic) uint32_t childFd;
@property BOOL shouldProcessPackets;
@end

@implementation Tun2Socks

+ (Tun2Socks *)shared {
  static dispatch_once_t onceToken;
  static Tun2Socks *tun2socks;
  dispatch_once(&onceToken, ^{
    tun2socks = [Tun2Socks new];
  });
  return tun2socks;
}

+ (NSError *)start:(int)socksServerPort packetFlow:(NEPacketTunnelFlow *)packetFlow {
  if (packetFlow == nil) {
    return [Tun2Socks getErrorWithMessage:@"packetFlow cannot be nil"];
  }
  int fds[2];
  if (socketpair(AF_UNIX, SOCK_DGRAM, 0, fds) == -1) {
    return [Tun2Socks
        getErrorWithMessage:[NSString stringWithFormat:@"Failed to create tun2socks socket: %s",
                                                       strerror(errno)]];
  }
  __weak Tun2Socks *tun2socks = [Tun2Socks shared];
  tun2socks.parentFd = fds[0];
  tun2socks.childFd = fds[1];
  tun2socks.tunnelPacketFlow = packetFlow;
  [NSThread detachNewThreadSelector:@selector(startTun2Socks:)
                           toTarget:tun2socks
                         withObject:@(socksServerPort)];
  [Tun2Socks processPackets];
  return nil;
}

- (void)startTun2Socks:(NSNumber *)socksServerPort {
  self.socksServerPort = [socksServerPort intValue];
  NSString *socksServerAddress =
      [NSString stringWithFormat:@"%@:%d", kLocalHostIp, self.socksServerPort];
  char *socks_server = (char *)[socksServerAddress cStringUsingEncoding:kCFStringEncodingUTF8];
  char *argv[] = {"tun2socks",
                  "--netif-ipaddr",
                  "192.0.2.4",
                  "--netif-netmask",
                  "255.255.255.0",
                  "--loglevel",
                  "debug",  // TODO(alalama): warning
                  "--socks-server-addr",
                  socks_server,
                  "--socks5-udp",
                  "--transparent-dns"};
  NSLog(@"Starting tun2socks...");
  int ret = start_tun2socks(sizeof(argv) / sizeof(argv[0]), argv, self.childFd, kTunMtu);
  NSLog(@"tun2socks exited with code %d", ret);
}

// Starts two threads to handle communication between the VPN and tun2socks. The first thread
// writes packets originating from the VPN to the TUN file descriptor; the second reads packets
// originating from tun2socks and writes them back to the VPN.
+ (void)processPackets {
  __weak Tun2Socks *tun2socks = [Tun2Socks shared];
  [Tun2Socks dispatchBlock:^{
    [NSThread detachNewThreadSelector:@selector(processOutboundPackets)
                             toTarget:tun2socks
                           withObject:nil];
  }
                 withDelay:0.5];
  [Tun2Socks dispatchBlock:^{
    [NSThread detachNewThreadSelector:@selector(processInboundPackets)
                             toTarget:tun2socks
                           withObject:nil];
  }
                 withDelay:0.5];
}

- (void)processInboundPackets {
  NSLog(@"PROCESS INBOUND TRAFFIC");
  __weak typeof(self) weakSelf = self;
  [weakSelf.tunnelPacketFlow
      readPacketsWithCompletionHandler:^(NSArray<NSData *> *_Nonnull packets,
                                         NSArray<NSNumber *> *_Nonnull protocols) {
        for (NSData *packet in packets) {
          uint8_t *data = (uint8_t *)packet.bytes;
          NSLog(@"TUN2SOCKS WRITE %lu", (unsigned long)packet.length);
          if (write(weakSelf.parentFd, data, packet.length) == -1) {
            NSLog(@"Failed to write data to tun2socks: %s", strerror(errno));
          };
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf processInboundPackets];
        });

      }];
}

// Reads packets originating from tun2socks and writes them to the packet flow (i.e. TUN device).
- (void)processOutboundPackets {
  __weak typeof(self) weakSelf = self;
  uint8_t buffer[kTunMtu];
  ssize_t bytesRead;
  while ((bytesRead = read(weakSelf.parentFd, buffer, kTunMtu)) != -1) {
    NSLog(@"TUN2SOCKS READ %zd", bytesRead);
    NSData *data = [[NSData alloc] initWithBytes:buffer length:bytesRead];
    [weakSelf.tunnelPacketFlow writePackets:@[ data ] withProtocols:@[ @(AF_INET) ]];
  }
}

+ (void)dispatchBlock:(void (^)(void))block withDelay:(double)secs {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secs * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), block);
}

+ (void)stop {
  __weak Tun2Socks *tun2socks = [Tun2Socks shared];
  close(tun2socks.parentFd);
  close(tun2socks.childFd);
  stop_tun2socks();
}

+ (NSError *)getErrorWithMessage:(NSString *)msg {
  return [NSError errorWithDomain:[NSString stringWithFormat:@"%@.Tun2Socks", [[NSBundle mainBundle]
                                                                                  bundleIdentifier]]
                             code:1
                         userInfo:@{NSLocalizedDescriptionKey : msg}];
}

@end
