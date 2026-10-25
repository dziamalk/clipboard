import SwiftUI
import ImageIO

final class PopupViewModel: ObservableObject {
    @Published var query = "" { didSet { refilter() } }
    @Published private(set) var filtered: [ClipItem] = []
    @Published var selected = 0

    init() { refilter() }

    func refilter() {
        let all = HistoryStore.shared.items
        let words = query.lowercased().split(separator: " ")
        if words.isEmpty {
            filtered = all
        } else {
            filtered = all.filter { item in
                guard let text = item.text?.lowercased() else { return false }
                return words.allSatisfy { text.contains($0) }
            }
        }
        selected = 0
    }

    func move(_ delta: Int) {
        guard !filtered.isEmpty else { return }
        selected = min(max(selected + delta, 0), filtered.count - 1)
    }

    var current: ClipItem? { filtered.indices.contains(selected) ? filtered[selected] : nil }

    func deleteCurrent() {
        guard let item = current else { return }
        let keep = selected
        HistoryStore.shared.delete(item.id)
        refilter()
        selected = min(keep, max(filtered.count - 1, 0))
    }
}

struct PopupView: View {
    @ObservedObject var model: PopupViewModel
    var onPick: (ClipItem, Bool) -> Void
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clipboard history", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(12)
                .focused($searchFocused)
            Divider()
            if model.filtered.isEmpty {
                Text(model.query.isEmpty ? "Clipboard history is empty" : "No matches")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(model.filtered.enumerated()), id: \.element.id) { index, item in
                                RowView(item: item, selected: index == model.selected)
                                    .id(item.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onPick(item, false) }
                            }
                        }
                    }
                    .onChange(of: model.selected) { _, new in
                        if model.filtered.indices.contains(new) {
                            proxy.scrollTo(model.filtered[new].id)
                        }
                    }
                }
            }
            Divider()
            Text("↩ paste   ⇧↩ plain text   ⌘⌫ delete   esc close")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.vertical, 5)
        }
        .frame(width: 440, height: 380)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.15)))
        .onAppear { searchFocused = true }
    }
}

private struct RowView: View {
    let item: ClipItem
    let selected: Bool

    var body: some View {
        HStack {
            switch item.kind {
            case .text:
                Text(item.snippet)
                    .lineLimit(2)
                    .font(.system(size: 13))
            case .image:
                if let thumb = Thumbnails.image(for: item) {
                    Image(nsImage: thumb).resizable().scaledToFit().frame(maxHeight: 56)
                } else {
                    Text("Image").foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color.accentColor.opacity(0.35) : Color.clear)
    }
}

enum Thumbnails {
    private static let cache = NSCache<NSUUID, NSImage>()

    static func image(for item: ClipItem) -> NSImage? {
        let key = item.id as NSUUID
        if let hit = cache.object(forKey: key) { return hit }
        let url = HistoryStore.shared.imageURL(item) as CFURL
        guard let src = CGImageSourceCreateWithURL(url, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 240,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: cg.width / 2, height: cg.height / 2))
        cache.setObject(img, forKey: key)
        return img
    }
}
