import Foundation

struct AgencyStats: Decodable {
    let activeProperties:   Int
    let pendingProperties:  Int
    let reservedProperties: Int
    let soldProperties:     Int
    let newLeads:           Int
    let pendingLeads:       Int
    let convertedLeads:     Int
    let monthlyViews:       Int
}
