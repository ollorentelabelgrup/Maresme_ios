import Foundation

struct AgencyTeamMember: Decodable, Identifiable {
    let id:             Int
    let name:           String
    let email:          String
    let role:           String
    let roleLabel:      String
    let isActive:       Bool
    let acceptedAt:     Date?
    let joinedAt:       Date?
    let totalLeads:     Int
    let openLeads:      Int
    let convertedLeads: Int

    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
