# HAMA⚡CODEX

A SwiftUI iOS starter for local project and binary-file workflows.

## Build from iPad using GitHub Actions
1. Upload the contents of this folder to a GitHub repository (keep `.github/workflows/ios.yml`).
2. Open **Actions** and run **HAMA CODEX iOS Build**.
3. Download the artifact named `HAMA-CODEX-unsigned-app-build`.

The artifact is an **unsigned** iOS app build. It is not directly installable until signed with an appropriate Apple provisioning profile/certificate.

## Included
- Local Files picker
- ZIP extraction into an app-owned workspace (ZIPFoundation)
- File list and text-file editor
- Text find/replace
- Bulk file-name rename
- Basic DYLIB/SO byte inspection (first 2 KB)

## Important iOS limitations
- The app edits only files the user explicitly imports into its own sandbox.
- This starter does not inject libraries into other apps, bypass iOS security, or execute arbitrary native code.
- The DYLIB panel is a read-only hex inspector in this starter; it does not patch binary bytes.
- The code editor is a text editor, not a full VS Code environment or native compiler.
- Cloud compilation and signing require a suitable remote macOS build environment and signing credentials.
