import Foundation

struct AgencyLead: Decodable, Identifiable {
    let id:          Int
    let name:        String
    let email:       String
    let phone:       String?
    let status:      String
    let statusLabel: String
    let statusColor: String
    let requestType: String?
    let leadQuality: String?
    let leadScore:   Int?
    let property:    PropertyRef?
    let createdAt:   Date?

    struct PropertyRef: Decodable {
        let id:    String
        let slug:  String
        let title: String
        let image: String?
    }
}
