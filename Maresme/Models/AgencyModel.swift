import Foundation

struct AgencyModel: Decodable, Identifiable {
    let id:      Int
    let slug:    String
    let name:    String
    let logoUrl: String?
    let phone:   String?
    let email:   String?
    let website: String?
    let address: String?
    let myRole:  String?   // role of the current user in this agency (from MeController)
}
