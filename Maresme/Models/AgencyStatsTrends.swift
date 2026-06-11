import Foundation

struct TrendPoint: Decodable, Identifiable {
    let date:  String
    let count: Int

    var id: String { date }
}

struct AgencyStatsTrends: Decodable {
    let propertiesCreated: [TrendPoint]
    let leadsCreated:      [TrendPoint]
    let views:             [TrendPoint]
}
