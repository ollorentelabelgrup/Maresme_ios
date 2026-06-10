import Foundation

struct UserModel: Decodable, Identifiable {
    let id:            Int
    let ulid:          String?
    let name:          String
    let email:         String
    let phone:         String?
    let avatar:        String?
    let bio:           String?
    let role:          String
    let emailVerified: Bool
    let createdAt:     Date?

    var isProfessional: Bool { role == "professional" || role == "agency" }

    // keyDecodingStrategy = .convertFromSnakeCase handles snake_case automatically.
    // Custom CodingKeys only needed for fields that don't follow the pattern.
    enum CodingKeys: String, CodingKey {
        case id, ulid, name, email, phone, avatar, bio, role
        case emailVerified = "email_verified"
        case createdAt     = "created_at"
    }
}
