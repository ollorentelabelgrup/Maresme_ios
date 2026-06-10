import Foundation

struct AgencyStats: Decodable {
    let activeProperties:  Int
    let pendingProperties: Int
    let newLeads:          Int
    let pendingLeads:      Int
    let monthlyViews:      Int
}
