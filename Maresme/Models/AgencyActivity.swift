import Foundation

struct AgencyActivity: Decodable, Identifiable {
    let id:        Int
    let type:      String
    let icon:      String
    let color:     String
    let message:   String
    let createdAt: Date?
    let user:      ActivityUser?
    let property:  ActivityProperty?
    let lead:      ActivityLead?

    struct ActivityUser: Decodable {
        let id:   Int
        let name: String
    }

    struct ActivityProperty: Decodable {
        let id:    Int
        let title: String
        let slug:  String
    }

    struct ActivityLead: Decodable {
        let id:    Int
        let name:  String
        let email: String
    }
}
