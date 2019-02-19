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

package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"time"

	"github.com/eycorsican/go-tun2socks/core"
	"github.com/eycorsican/go-tun2socks/proxy"

	"github.com/eycorsican/go-tun2socks/proxy/socks"
)

const (
	mtu        = 1500
	bufferSize = 512 * 1024
)

// -proxyHost 127.0.0.1 -proxyPort 9999 -inboundSocketPath "/Users/alalama/Library/Containers/org.outline.macos.client.VpnExtension/Data/out_socket" -outboundSocketPath "/Users/alalama/Library/Containers/org.outline.macos.client.VpnExtension/Data/in_socket"
// codesign -f --prefix org.outline.  --entitlements helloworld.entitlements -s "Mac Developer: Alberto Lalama (6U3H9CUW4N)" helloworld
// codesign -vv -d --entitlements - helloworld
func main() {
	proxyHost := flag.String("proxyHost", "", "proxy host")
	proxyPort := flag.Int("proxyPort", -1, "proxy port")
	inboundSocketPath := flag.String("inboundSocketPath", "", "inbound Unix socket path")
	outboundSocketPath := flag.String("outboundSocketPath", "", "outbound Unix socket path")
	flag.Parse()

	if *inboundSocketPath == "" || *outboundSocketPath == "" {
		fmt.Println("Must provide in/out Unix socket paths")
		os.Exit(1)
	}
	if *proxyHost == "" || *proxyPort == -1 {
		fmt.Println("Must provide a proxy host and port")
		os.Exit(1)
	}
	const connType = "unixgram"
	inAddr := net.UnixAddr{Name: *inboundSocketPath, Net: connType}
	outAddr := net.UnixAddr{Name: *outboundSocketPath, Net: connType}
	conn, err := net.DialUnix(connType, &inAddr, &outAddr)
	if err != nil {
		fmt.Printf("Failed to connect to socket: %v", err)
		os.Exit(1)
	}
	defer conn.Close()

	var lwipStack = core.NewLWIPStack()
	core.RegisterTCPConnectionHandler(socks.NewTCPHandler(*proxyHost, uint16(*proxyPort)))
	core.RegisterUDPConnectionHandler(socks.NewUDPHandler(*proxyHost, uint16(*proxyPort), 30*time.Second, proxy.NewDNSCache()))
	core.RegisterOutputFn(func(data []byte) (int, error) {
		// return conn.Write(data)
		len, err := conn.Write(data)
		if err != nil {
			// TODO: recover?
			fmt.Printf("Failed to write packet %v\n", err.Error())
		}
		return len, err
	})
	conn.SetReadBuffer(bufferSize)
	conn.SetReadBuffer(bufferSize)
	var buf = make([]byte, mtu)
	for {
		_, err := conn.Read(buf)
		if err != nil {
			// TODO: can we recover?
			fmt.Printf("Failed to read packet %v\n", err.Error())
			continue
		}
		lwipStack.Write(buf)
	}
}
