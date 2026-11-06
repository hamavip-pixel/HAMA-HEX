import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct ContentView: View {
    @StateObject private var store = ProjectStore()
    @State private var showingImporter = false
    @State private var showingRename = false
    @State private var renameFrom = ""
    @State private var renameTo = ""
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var replacement = ""
    @State private var notice: String?

    private let red = Color(red: 1.0, green: 0.12, blue: 0.18)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        importButton
                        toolsGrid
                        if let url = store.selectedURL {
                            editorPanel(for: url)
                        } else {
                            emptyPanel
                        }
                        if !store.files.isEmpty { filesPanel }
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [.item],
                          allowsMultipleSelection: true) { result in
                do {
                    let urls = try result.get()
                    for url in urls { try store.importItem(url) }
                    notice = "Import completed"
                } catch {
                    notice = error.localizedDescription
                }
            }
            .alert("HAMA CODEX", isPresented: Binding(
                get: { notice != nil },
                set: { if !$0 { notice = nil } }
            )) {
                Button("OK", role: .cancel) { notice = nil }
            } message: {
                Text(notice ?? "")
            }
            .sheet(isPresented: $showingRename) {
                NavigationStack {
                    Form {
                        Section("Bulk rename") {
                            TextField("Text to find", text: $renameFrom)
                            TextField("Replace with", text: $renameTo)
                        }
                        Text("Renames matching file names in the imported workspace. File contents and images are not changed.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .navigationTitle("Rename files")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingRename = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Apply") {
                                do {
                                    try store.bulkRename(from: renameFrom, to: renameTo)
                                    notice = "Rename completed"
                                } catch { notice = error.localizedDescription }
                                showingRename = false
                            }
                        }
                    }
                    .preferredColorScheme(.dark)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 230)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(red.opacity(0.65), lineWidth: 1))
            Text("HAMA⚡CODEX")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("DYLIB • HEX • CODE • PROJECTS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(red)
        }
    }

    private var importButton: some View {
        Button { showingImporter = true } label: {
            Label("IMPORT FILE / ZIP PROJECT", systemImage: "folder.badge.plus")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var toolsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            toolCard("DYLIB / HEX", detail: "Inspect and edit bytes", icon: "memorychip") {
                if let dylib = store.files.first(where: { $0.pathExtension.lowercased() == "dylib" }) {
                    store.select(dylib)
                } else { showingImporter = true }
            }
            toolCard("CODE STUDIO", detail: "Edit text source files", icon: "chevron.left.forwardslash.chevron.right") {
                if let code = store.files.first(where: { ["swift","m","mm","h","c","cpp","txt"].contains($0.pathExtension.lowercased()) }) {
                    store.select(code)
                } else { showingImporter = true }
            }
            toolCard("BULK RENAME", detail: "Rename project files", icon: "textformat") {
                showingRename = true
            }
            toolCard("STRING REPLACE", detail: "Find and replace text", icon: "arrow.left.arrow.right") {
                if store.selectedURL == nil, let first = store.files.first { store.select(first) }
            }
        }
    }

    private func toolCard(_ title: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundStyle(red)
                Text(title).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text(detail).font(.caption2).foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
            .padding(12)
            .background(Color(white: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(red.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyPanel: some View {
        VStack(spacing: 8) {
            Image(systemName: "shippingbox").font(.largeTitle).foregroundStyle(red)
            Text("Your workspace is empty").font(.headline).foregroundStyle(.white)
            Text("Import a ZIP project, source file, or DYLIB to begin.")
                .font(.caption).foregroundStyle(.gray).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(28)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func editorPanel(for url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(url.lastPathComponent).font(.headline).foregroundStyle(.white)
                    Text(url.pathExtension.uppercased().isEmpty ? "FILE" : url.pathExtension.uppercased())
                        .font(.caption2).foregroundStyle(red)
                }
                Spacer()
                Button("SAVE") {
                    do { try store.saveEditor() ; notice = "Saved successfully" }
                    catch { notice = error.localizedDescription }
                }
                .font(.caption.bold()).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(red).clipShape(Capsule())
            }

            if url.pathExtension.lowercased() == "dylib" || url.pathExtension.lowercased() == "so" {
                Text("HEX VIEW • First 2,048 bytes")
                    .font(.caption.bold()).foregroundStyle(.gray)
                ScrollView(.horizontal) {
                    Text(store.hexText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.4))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("Binary editing is limited to safe file inspection in this starter.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                HStack {
                    TextField("Find", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    TextField("Replace", text: $replacement)
                        .textFieldStyle(.roundedBorder)
                    Button("GO") {
                        store.replaceText(search: searchText, with: replacement)
                    }.foregroundStyle(red).font(.caption.bold())
                }
                TextEditor(text: $store.editorText)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(6)
                    .frame(minHeight: 260)
                    .background(Color(white: 0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color(white: 0.085))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKSPACE FILES (\(store.files.count))")
                .font(.caption.bold()).tracking(1).foregroundStyle(red)
            ForEach(store.files, id: \.path) { file in
                Button { store.select(file) } label: {
                    HStack {
                        Image(systemName: file.pathExtension.lowercased() == "dylib" ? "memorychip" : "doc.text")
                            .foregroundStyle(red)
                        Text(file.lastPathComponent).lineLimit(1).foregroundStyle(.white)
                        Spacer()
                        if store.selectedURL == file { Image(systemName: "checkmark.circle.fill").foregroundStyle(red) }
                    }
                    .font(.caption)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(white: 0.075))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
