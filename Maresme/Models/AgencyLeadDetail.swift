import Foundation

struct AgencyLeadDetail: Decodable, Identifiable {
    let id:               Int
    let name:             String
    let email:            String
    let phone:            String?
    let message:          String?
    let requestType:      String?
    let requestTypeLabel: String?
    let status:           String
    let statusLabel:      String
    let statusColor:      String
    let leadScore:        Int?
    let leadQuality:      String?
    let leadQualityLabel: String?
    let buyerStage:       String?
    let buyerStageLabel:  String?
    let source:           String?
    let matchingScore:    Int?
    let property:         PropertyRef?
    let notes:            [AgencyLeadNote]
    let assignedTo:       AssignedUser?
    let assignedAt:       Date?
    let createdAt:        Date?
    let updatedAt:        Date?

    struct PropertyRef: Decodable {
        let id:           String
        let slug:         String
        let title:        String
        let price:        Int?
        let image:        String?
        let municipality: String?
    }

    struct AssignedUser: Decodable {
        let id:   Int
        let name: String
        let role: String?
    }
}
