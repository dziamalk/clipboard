import Foundation

enum ClipKind: String, Codable {
    case text, image
}

struct ClipItem: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var kind: ClipKind
    var text: String?
    var hasRTF: Bool
    var hasHTML: Bool
    var hash: String

    /// Single-line preview for the list.
    var snippet: String {
        guard let text else { return "" }
        let head = String(text.prefix(300))
        return head.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
