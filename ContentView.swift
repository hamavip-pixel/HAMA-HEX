import SwiftUI
import UniformTypeIdentifiers

private enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case kurdish = "کوردی"
    var id: String { rawValue }
}

private struct ByteRow: Identifiable {
    let id: Int
    let offset: Int
    let bytes: [UInt8]
}

struct ContentView: View {
    @State private var data = Data()
    @State private var originalName = "No file selected"
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportDocument = HexDocument()
    @State private var language: AppLanguage = .english
    @State private var searchText = ""
    @State private var replacementText = ""
    @State private var status = "Import a file to begin."
    @State private var hexInput = ""
    @State private var selectedOffset = 0

    private let red = Color(red: 1.0, green: 0.16, blue: 0.20)

    private var isKurdish: Bool { language == .kurdish }
    private func tr(_ en: String, _ ku: String) -> String { isKurdish ? ku : en }

    private var rows: [ByteRow] {
        let bytes = Array(data)
        return stride(from: 0, to: bytes.count, by: 16).map { start in
            ByteRow(id: start, offset: start, bytes: Array(bytes[start..<min(start + 16, bytes.count)]))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.045).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        fileCard
                        actionRow
                        editorCard
                        stringTools
                        footerNote
                    }
                    .padding(16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .data,
                defaultFilename: exportName,
                onCompletion: handleExport
            )
        }
        .tint(red)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HAMA")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.65))
                    HStack(spacing: 5) {
                        Text("HAMA")
                        Text("⚡").foregroundStyle(red)
                        Text("HEX")
                    }
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                }
                Spacer()
                Menu {
                    Picker(tr("Language", "زمان"), selection: $language) {
                        ForEach(AppLanguage.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                } label: {
                    Label(language.rawValue, systemImage: "globe")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.07), in: Capsule())
                }
            }
            Text(tr("BINARY FILE WORKSPACE", "شوێنی کاری فایلە باینەرییەکان"))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var fileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(tr("CURRENT FILE", "فایلی ئێستا"), systemImage: "doc.zipper")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Circle().fill(data.isEmpty ? .gray : .green).frame(width: 7, height: 7)
            }
            Text(originalName)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.white)
            HStack(spacing: 16) {
                metric(tr("SIZE", "قەبارە"), ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                metric(tr("BYTES", "بایت"), "\(data.count)")
                metric(tr("TYPE", "جۆر"), originalName.lowercased().hasSuffix(".dylib") ? "DYLIB" : (data.isEmpty ? "—" : "DATA"))
            }
            Text(status)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(16)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(red.opacity(0.35), lineWidth: 1))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
            Text(value).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.white)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { showingImporter = true } label: {
                Label(tr("Open File", "کردنەوەی فایل"), systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryRedButton())
            .accessibilityHint(tr("Choose a file from the Files app", "فایلێک لە ئەپی Files هەڵبژێرە"))

            Button {
                guard !data.isEmpty else { status = tr("Import a file first.", "سەرەتا فایلێک بهێنە."); return }
                exportDocument = HexDocument(data: data)
                showingExporter = true
            } label: {
                Label(tr("Export", "هەناردە"), systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButton())
            .disabled(data.isEmpty)
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("HEX EDITOR", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.black))
                    .tracking(1)
                Spacer()
                Text(tr("16 bytes / row", "١٦ بایت / ڕیز"))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 34))
                        .foregroundStyle(red)
                    Text(tr("No file loaded", "هیچ فایلێک نەکراوەتەوە"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(tr("Tap Open File to inspect binary data.", "بۆ پشکنینی داتای باینەری، Open File بکە."))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("OFFSET").frame(width: 62, alignment: .leading)
                            Text("00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F")
                        }
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(red)
                        ForEach(rows) { row in
                            HStack(spacing: 12) {
                                Text(String(format: "%08X", row.offset))
                                    .frame(width: 62, alignment: .leading)
                                    .foregroundStyle(.white.opacity(0.4))
                                Text(row.bytes.map { String(format: "%02X", $0) }.joined(separator: " "))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 300)
            }
            Divider().overlay(.white.opacity(0.1))
            Text(tr("EDIT BYTE AT OFFSET", "دەستکاری بایت لە ئۆفست"))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
            HStack {
                TextField("Offset (decimal)", value: $selectedOffset, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                TextField("00–FF", text: $hexInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                Button(tr("Apply", "جێبەجێکردن")) { applyByte() }
                    .buttonStyle(PrimaryRedButton())
                    .disabled(data.isEmpty)
            }
            Text(tr("Enter a decimal offset and a two-digit hex byte.", "ئۆفستی ژمارەیی و بایتێکی دوو-هێمایی HEX بنووسە."))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
    }

    private var stringTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(tr("STRING REPLACE", "گۆڕینی دەق"), systemImage: "text.magnifyingglass")
                .font(.caption.weight(.black))
                .tracking(1)
            TextField(tr("Find UTF-8 text", "دەقی گەڕان"), text: $searchText)
                .textFieldStyle(.roundedBorder)
            TextField(tr("Replace with", "بیگۆڕە بە"), text: $replacementText)
                .textFieldStyle(.roundedBorder)
            Button {
                replaceText()
            } label: {
                Label(tr("Find & Replace", "گەڕان و گۆڕین"), systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButton())
            .disabled(data.isEmpty || searchText.isEmpty)
            Text(tr("Text replacement may change file length. Always export to a new copy and test it before use.", "گۆڕینی دەق لەوانەیە درێژی فایل بگۆڕێت. هەمیشە وەک کۆپییەکی نوێ هەناردەی بکە و پێش بەکارهێنان تاقی بکەرەوە."))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
    }

    private var footerNote: some View {
        Text(tr(
            "Local editing only • No jailbreak • No code injection",
            "دەستکاریکردنی ناوخۆیی • بەبێ جەیلبرەیک • بەبێ کۆد ئینجێکشن"
        ))
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.35))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var exportName: String {
        let base = (originalName as NSString).deletingPathExtension
        return (base.isEmpty || base == "No file selected") ? "HAMA_HEX_edited" : base + "_edited"
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            do {
                data = try Data(contentsOf: url)
                originalName = url.lastPathComponent
                status = tr("File loaded. Original remains unchanged until export.", "فایل کراوەتەوە؛ ئەسڵییەکە تا هەناردەکردن ناگۆڕدرێت.")
            } catch {
                status = tr("Could not read file: ", "نەتوانرا فایل بخوێندرێتەوە: ") + error.localizedDescription
            }
        case .failure(let error):
            status = tr("Import failed: ", "هێنانەژوورەوە سەرکەوتوو نەبوو: ") + error.localizedDescription
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            status = tr("Exported: ", "هەناردە کرا: ") + url.lastPathComponent
        case .failure(let error):
            status = tr("Export failed: ", "هەناردە سەرکەوتوو نەبوو: ") + error.localizedDescription
        }
    }

    private func applyByte() {
        guard selectedOffset >= 0, selectedOffset < data.count else {
            status = tr("Offset is outside the file.", "ئۆفست لە دەرەوەی فایلەکەیە.")
            return
        }
        let cleaned = hexInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count == 2, let byte = UInt8(cleaned, radix: 16) else {
            status = tr("Enter exactly two hex digits (00–FF).", "دوو هێمای HEX بنووسە (00–FF).")
            return
        }
        data[selectedOffset] = byte
        status = tr("Byte updated in memory. Export to save a copy.", "بایتەکە لە بیرگەدا نوێکرایەوە؛ بۆ پاشەکەوتکردن هەناردەی بکە.")
    }

    private func replaceText() {
        guard let source = String(data: data, encoding: .utf8) else {
            status = tr("The whole file is not valid UTF-8; use byte editing instead.", "هەموو فایلەکە UTF-8 نییە؛ دەستکاری بایت بەکاربهێنە.")
            return
        }
        guard source.contains(searchText) else {
            status = tr("Text not found.", "دەقەکە نەدۆزرایەوە.")
            return
        }
        let changed = source.replacingOccurrences(of: searchText, with: replacementText)
        data = Data(changed.utf8)
        status = tr("Replacement complete in memory. Export a new copy.", "گۆڕینەکە تەواو بوو؛ کۆپییەکی نوێ هەناردە بکە.")
    }
}

private struct PrimaryRedButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(Color(red: 0.88, green: 0.08, blue: 0.13).opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 13))
    }
}

private struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.08), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}
