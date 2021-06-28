// Copyright 2020 The Outline Authors
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

// Represents a Shadowsocks proxy server configuration.
export interface ShadowsocksConfig {
  host?: string;
  port?: number;
  password?: string;
  method?: string;
  name?: string;
}

// SIP008 online config
type Sip008Json = Readonly < {
  version: number,
  servers: ReadonlyArray < Readonly < {
    readonly id: string;
    readonly remarks: string;
    readonly server: string;
    readonly server_port: number;
    readonly password: string;
    readonly method: string;
    readonly plugin: string;
    readonly plugin_opts: string;
  }>>,
}>;

// Parses a SIP008 JSON server configuration into a list of ShadowsocksConfig.
// See https://github.com/shadowsocks/shadowsocks-org/wiki/SIP008-Online-Configuration-Delivery
export function sip008JsonToShadowsocksConfig(sip008Json: {}): ShadowsocksConfig[] {
  const config = sip008Json as Sip008Json;
  if (config?.version !== 1) {
    console.warn(`unsupported SIP008 version: ${config.version}`);
  }
  const ssConfigs: ShadowsocksConfig[] = [];
  if (!config?.servers) {
    return ssConfigs;
  }
  for (const serverConfig of config.servers) {
    try {
      const ssConfig = {
        host: serverConfig.server,
        port: serverConfig.server_port,
        password: serverConfig.password,
        method: serverConfig.method,
        name: serverConfig.remarks,
      };
      if (!ssConfig.host || !ssConfig.port || !ssConfig.password || !ssConfig.method) {
        continue;
      }
      if (typeof ssConfig.host !== 'string' || typeof ssConfig.port !== 'number' ||
          typeof ssConfig.password !== 'string' || typeof ssConfig.method !== 'string') {
        continue;
      }
      ssConfigs.push(ssConfig);
    } catch (e) {
      console.warn(`invalid server configuration: ${e}`);
      continue;
    }
  }
  return ssConfigs;
}
