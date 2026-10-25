import Foundation
import CryptoKit

final class HistoryStore {
    static let shared = HistoryStore()

    private(set) var items: [ClipItem] = []  // newest first
    private let dir: URL
    private let blobs: URL
    private var indexURL: URL { dir.appendingPathComponent("items.json") }

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("Clipboard", isDirectory: true)
        blobs = dir.appendingPathComponent("blobs", isDirectory: true)
        try? FileManager.default.createDirectory(at: blobs, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder.iso.decode([ClipItem].self, from: data) {
            items = decoded
        }
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func blobURL(_ item: ClipItem, ext: String) -> URL {
        blobs.appendingPathComponent("\(item.id.uuidString).\(ext)")
    }

    func imageURL(_ item: ClipItem) -> URL { blobURL(item, ext: "png") }

    func rtf(_ item: ClipItem) -> Data? { item.hasRTF ? try? Data(contentsOf: blobURL(item, ext: "rtf")) : nil }
    func html(_ item: ClipItem) -> Data? { item.hasHTML ? try? Data(contentsOf: blobURL(item, ext: "html")) : nil }

    func addText(_ text: String, rtf: Data?, html: Data?) {
        let hash = Self.sha256(Data(text.utf8))
        if bumpExisting(hash: hash) { return }
        let item = ClipItem(id: UUID(), date: Date(), kind: .text, text: text,
                            hasRTF: rtf != nil, hasHTML: html != nil, hash: hash)
        if let rtf { try? rtf.write(to: blobURL(item, ext: "rtf")) }
        if let html { try? html.write(to: blobURL(item, ext: "html")) }
        insert(item)
    }

    func addImage(png: Data) {
        let hash = Self.sha256(png)
        if bumpExisting(hash: hash) { return }
        let item = ClipItem(id: UUID(), date: Date(), kind: .image, text: nil,
                            hasRTF: false, hasHTML: false, hash: hash)
        try? png.write(to: imageURL(item))
        insert(item)
    }

    func bump(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var item = items.remove(at: i)
        item.date = Date()
        items.insert(item, at: 0)
        save()
    }

    func delete(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        removeBlobs(items.remove(at: i))
        save()
    }

    func clear() {
        items.forEach(removeBlobs)
        items.removeAll()
        save()
    }

    func prune() {
        let s = Settings.shared
        var removed: [ClipItem] = []
        if s.maxAgeDays > 0 {
            let cutoff = Date().addingTimeInterval(-Double(s.maxAgeDays) * 86400)
            removed += items.filter { $0.date < cutoff }
            items.removeAll { $0.date < cutoff }
        }
        if s.maxItems > 0, items.count > s.maxItems {
            removed += items[s.maxItems...]
            items.removeLast(items.count - s.maxItems)
        }
        removed.forEach(removeBlobs)
        if !removed.isEmpty { save() }
    }

    private func bumpExisting(hash: String) -> Bool {
        guard let existing = items.first(where: { $0.hash == hash }) else { return false }
        bump(existing.id)
        return true
    }

    private func insert(_ item: ClipItem) {
        items.insert(item, at: 0)
        prune()
        save()
    }

    private func removeBlobs(_ item: ClipItem) {
        for ext in ["png", "rtf", "html"] {
            try? FileManager.default.removeItem(at: blobURL(item, ext: ext))
        }
    }

    private func save() {
        guard let data = try? JSONEncoder.iso.encode(items) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}

private extension JSONEncoder {
    static var iso: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }
}
private extension JSONDecoder {
    static var iso: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }
}
