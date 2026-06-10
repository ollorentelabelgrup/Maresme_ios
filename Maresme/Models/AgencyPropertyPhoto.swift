import Foundation

struct AgencyPropertyPhoto: Decodable, Identifiable {
    let id:        Int
    let url:       String
    let sortOrder: Int
    let isPrimary: Bool
    let createdAt: Date?
}
