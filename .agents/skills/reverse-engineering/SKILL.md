---
name: reverse-engineering
description: Guide and instructions for reverse engineering apps using REA (Reverse Engineer Anything)
---

# Reverse Engineering with REA

This workspace is integrated with [REA (Reverse Engineer Anything)](https://github.com/morluto/rea).

## CLI Usage
The `rea` CLI is installed globally at `/Users/mac/.nvm/versions/node/v24.14.0/bin/rea`.

### Common Commands:
- `rea analyze <path-to-target>`: High-level overview of an app bundle, binary, or package.
- `rea analyze-javascript-application <path>`: Deconstruct Electron or JS apps, ASAR archives, or web app bundles.
- `rea decompile <target>`: Decompile code from supported applications.
- `rea search <term>`: Search through strings, symbols, and procedure names.
- `rea decode-android-resources <apk>`: Decode Android manifest, resources, and metadata.
- `rea identify-flutter-build <apk>`: Identify Flutter Dart snapshot hashes and engine characteristics.
- `rea project-apple-application-graph <ipa/app>`: Graph macOS / iOS app structures and Mach-O load paths.

## MCP Server Integration
Configured via `mcp_config.json`:
- Command: `rea --mcp`
