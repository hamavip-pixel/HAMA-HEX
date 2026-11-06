# HAMA⚡HEX — SwiftUI starter

A native iOS starter for browsing and editing files you explicitly import through the iOS Files picker.

## Included
- Red/black bilingual (English + Kurdish Sorani) interface
- Import files using `fileImporter`
- Hex view with editable byte values
- Search and replace UTF-8 text
- Export edited data using `fileExporter`
- Original imported bytes remain separate until you export

## Important iOS limitation
On a non-jailbroken iPhone, this app can edit a `.dylib` file that the user selects and has permission to access. It cannot inject the library into another app, bypass iOS sandboxing, or load/execute arbitrary third-party code.

## Add to Xcode
1. In Xcode, create a new **iOS App** project named `HAMAHex`.
2. Choose **SwiftUI** and **Swift**.
3. Set the deployment target to iOS 16 or later.
4. Replace the generated app file and ContentView with the matching files here, and add `HexDocument.swift`.
5. Build and run on your iPhone.

The starter uses SwiftUI's document picker/exporter. It does not require jailbreak or private APIs.
