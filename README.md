# Metrik SDK **Alpha**

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/metrik-tech/sdk?label=latest%20release)](https://github.com/metrik-tech/sdk/releases/latest) [![GitHub issues](https://img.shields.io/github/issues/metrik-tech/sdk)](https://github.com/metrik-tech/sdk/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc) [![GitHub pull requests](https://img.shields.io/github/issues-pr/metrik-tech/sdk)](https://github.com/metrik-tech/sdk/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc) [![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/metrik-tech/sdk/ci.yml)](https://github.com/metrik-tech/sdk/actions/workflows/ci.yml)

> **Warning**
> The Metrik API is NOT currently online. Metrik and the SDK will not work at the moment. Additionally, some parts of the codebase will just straight up not work.

This is the Roblox SDK for Metrik, the automated LiveOps toolkit for Roblox. This module is still in heavy development, is not feature complete, subject to breaking changes, and is not recommended for production use.

Install options include:
- Plugin (coming soon)
- Wally
- `.rbxm`/`.rbxmx`
- `roblox-ts`

# Installation

## via Wally

You must have wally installed. Learn more about Wally by Uplift Games [here](
    https://github.com/UpliftGames/wally
).

```bash
wally install metrik-tech/metrik
```

## via `.rbxm`/`.rbxmx`

Download from GitHub releases and insert into Studio or Rojo. Releases can be found [here](
    https://github.com/metrik-tech/sdk/releases/latest
).

## via `roblox-ts`

> **Note**
> This is \*NOT\* to be used with regular Luau. This is only for use with `roblox-ts`, a TypeScript-to-Luau compiler. Learn more about `roblox-ts` and whether or not it's the right fit for your project [here](https://roblox-ts.com/).

```bash
# npm
npm install @rbxts/metrik

# yarn
yarn add @rbxts/metrik

# pnpm
pnpm add @rbxts/metrik
```

# Usage

You need to initalize Metrik on **both** the client and the server. However, config options only need to be passed on the server (This is subject to change).
## Server

### TypeScript

```ts
// any server script (file.server.ts)
import Metrik from "@rbxts/metrik";

const metrik = new Metrik({
    token: "your-token-here",
    options: {
        debug: true
    }
})
```

### Lua

```lua
-- any server script (file.server.lua)
-- or a script in ServerScriptService
local Metrik = require(path.to.Metrik)

local metrik = Metrik.new({
    token = "your-token-here",
    options = {
        debug = true
    }
})

```

## Client

### TypeScript

```ts
// any client script (file.client.ts)
import Metrik from "@rbxts/metrik";

new Metrik();
```

### Lua

```lua
-- any client script (file.client.lua)
-- or a LocalScript (preferably in StarterPlayerScripts)

local Metrik = require(path.to.Metrik)

Metrik.new()
```

## Options

```ts
interface IOptions {
    debug?: boolean; // defaults to false. logs internal events and errors to output if true
    logMetrikMessages?: boolean; // defaults to false. logs messages outputted by the SDK to the dashboard if true 
    apiBase?: string; // defaults to https://api.metrik.app. in most cases, you shouldn't need to change this
}
```

## API

### `metrik.log(message: string, data: unknown): Promise<void>` SERVER ONLY

Logs a message to the Metrik dashboard with extra details.  Internally throws a `print`.

### `metrik.error(message: string, data: unknown): Promise<void>` SERVER ONLY

Logs an error to the Metrik dashboard with extra details. Internally throws a `warn`.

### `metrik.crash(message: string, data: unknown): Promise<void>` SERVER ONLY

Logs a crash to the Metrik dashboard with extra details. Internally throws an `error`, which stops the thread where it was called AFTER the crash is logged.

### `metrik.warn(message: string, data: unknown): Promise<void>` SERVER ONLY

Logs a warning to the Metrik dashboard with extra details. Internally throws a `warn`.


