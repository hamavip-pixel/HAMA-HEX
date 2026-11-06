import Foundation
import ZIPFoundation
import Combine

@MainActor
final class ProjectStore: ObservableObject {
    @Published var files: [URL] = []
    @Published var selectedURL: URL?
    @Published var editorText = ""
    @Published var hexText = ""

    private let fm = FileManager.default
    private var workspace: URL {
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("HamaCodexWorkspace", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func importItem(_ source: URL) throws {
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }

        if source.pathExtension.lowercased() == "zip" {
            let archive = try Archive(url: source, accessMode: .read)
            for entry in archive {
                let destination = workspace.appendingPathComponent(entry.path)
                let rootPath = workspace.standardizedFileURL.path + "/"
                let targetPath = destination.standardizedFileURL.path
                guard targetPath.hasPrefix(rootPath) else { continue }
                if entry.type == .directory {
                    try fm.createDirectory(at: destination, withIntermediateDirectories: true)
                } else {
                    try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                    _ = try archive.extract(entry, to: destination)
                }
            }
        } else {
            let destination = workspace.appendingPathComponent(source.lastPathComponent)
            if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
            try fm.copyItem(at: source, to: destination)
        }
        refreshFiles()
        if let first = files.first { select(first) }
    }

    func refreshFiles() {
        let enumerator = fm.enumerator(at: workspace, includingPropertiesForKeys: [.isRegularFileKey])
        var found: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            if (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                found.append(url)
            }
        }
        files = found.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }

    func select(_ url: URL) {
        selectedURL = url
        if ["dylib", "so"].contains(url.pathExtension.lowercased()) {
            let data = (try? Data(contentsOf: url)) ?? Data()
            hexText = data.prefix(2048).enumerated().map { index, byte in
                String(format: "%08X  %02X", index, byte)
            }.joined(separator: "\n")
            editorText = ""
        } else {
            editorText = (try? String(contentsOf: url, encoding: .utf8)) ?? "This file is not UTF-8 text. It can be selected and preserved, but not shown in the text editor."
            hexText = ""
        }
    }

    func saveEditor() throws {
        guard let url = selectedURL, !["dylib", "so"].contains(url.pathExtension.lowercased()) else {
            throw NSError(domain: "HamaCodex", code: 1, userInfo: [NSLocalizedDescriptionKey: "Text save is available for text files only."])
        }
        try editorText.write(to: url, atomically: true, encoding: .utf8)
        refreshFiles()
    }

    func replaceText(search: String, with replacement: String) {
        guard !search.isEmpty else { return }
        editorText = editorText.replacingOccurrences(of: search, with: replacement)
    }

    func bulkRename(from search: String, to replacement: String) throws {
        guard !search.isEmpty else { return }
        let candidates = files.sorted { $0.pathComponents.count > $1.pathComponents.count }
        for file in candidates where file.lastPathComponent.contains(search) {
            let newName = file.lastPathComponent.replacingOccurrences(of: search, with: replacement)
            let destination = file.deletingLastPathComponent().appendingPathComponent(newName)
            if !fm.fileExists(atPath: destination.path) {
                try fm.moveItem(at: file, to: destination)
            }
        }
        refreshFiles()
        if let selectedURL, !fm.fileExists(atPath: selectedURL.path) { self.selectedURL = nil }
    }
}
