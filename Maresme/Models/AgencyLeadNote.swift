import Foundation

struct AgencyLeadNote: Decodable, Identifiable {
    let id:        Int
    let note:      String
    let user:      NoteUser?
    let createdAt: Date?

    struct NoteUser: Decodable {
        let id:   Int
        let name: String
    }
}
