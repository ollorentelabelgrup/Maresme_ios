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

    // Roles del backend: "user", "professional", "admin", "super_admin"
    var isProfessional: Bool { role == "professional" }
    var isAdmin: Bool { role == "admin" || role == "super_admin" }

    // No CodingKeys needed: keyDecodingStrategy = .convertFromSnakeCase in APIClient
    // automatically converts "email_verified" → emailVerified, "created_at" → createdAt, etc.
    // Adding explicit CodingKeys with snake_case raw values breaks the lookup because the
    // decoder converts JSON keys FIRST and then matches against CodingKey raw values.
}
