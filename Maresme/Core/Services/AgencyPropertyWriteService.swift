import Foundation
import UIKit

// MARK: - Payload

struct UpdatePropertyPayload: Encodable {
    let title:           String?
    let description:     String?
    let type:            String?
    let zoneId:          Int?
    let address:         String?
    let lat:             Double?
    let lng:             Double?
    let priceSale:       Int?
    let priceRent:       Int?
    let rooms:           Int?
    let bathrooms:       Int?
    let surfaceM2:       Int?
    let usefulSurfaceM2: Int?
    let floorNumber:     Int?
    let hasElevator:     Bool?
    let hasTerrace:      Bool?
    let hasParking:      Bool?
    let hasPool:         Bool?
    let hasStorageRoom:  Bool?
    let hasGarden:       Bool?
    let hasSeaView:      Bool?
    let isNewBuild:      Bool?
    let isExclusive:     Bool?
    let isFeatured:      Bool?

    enum CodingKeys: String, CodingKey {
        case title, description, type, address, lat, lng, rooms, bathrooms
        case zoneId          = "zone_id"
        case priceSale       = "price_sale"
        case priceRent       = "price_rent"
        case surfaceM2       = "surface_m2"
        case usefulSurfaceM2 = "useful_surface_m2"
        case floorNumber     = "floor_number"
        case hasElevator     = "has_elevator"
        case hasTerrace      = "has_terrace"
        case hasParking      = "has_parking"
        case hasPool         = "has_pool"
        case hasStorageRoom  = "has_storage_room"
        case hasGarden       = "has_garden"
        case hasSeaView      = "has_sea_view"
        case isNewBuild      = "is_new_build"
        case isExclusive     = "is_exclusive"
        case isFeatured      = "is_featured"
    }
}

// MARK: - Service

struct AgencyPropertyWriteService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // POST /api/v1/agency/properties
    func create(payload: UpdatePropertyPayload) async throws -> AgencyPropertyDetail {
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.post, "/agency/properties", body: payload)
        )
        return wrapped.data
    }

    // PATCH /api/v1/agency/properties/{slug}
    func update(slug: String, payload: UpdatePropertyPayload) async throws -> AgencyPropertyDetail {
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.patch, "/agency/properties/\(slug)", body: payload)
        )
        return wrapped.data
    }

    // POST /api/v1/agency/properties/{slug}/publish
    func publish(slug: String) async throws -> AgencyPropertyDetail {
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.post, "/agency/properties/\(slug)/publish")
        )
        return wrapped.data
    }

    // POST /api/v1/agency/properties/{slug}/unpublish
    func unpublish(slug: String) async throws -> AgencyPropertyDetail {
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.post, "/agency/properties/\(slug)/unpublish")
        )
        return wrapped.data
    }

    // PATCH /api/v1/agency/properties/{slug}/status
    // status: "reserved" | "sold" | "active"
    func changeStatus(slug: String, to status: String) async throws -> AgencyPropertyDetail {
        struct Payload: Encodable { let status: String }
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.patch, "/agency/properties/\(slug)/status", body: Payload(status: status))
        )
        return wrapped.data
    }

    // POST /api/v1/agency/properties/{slug}/photos (multipart)
    func uploadPhotos(slug: String, images: [UIImage]) async throws -> [AgencyPropertyPhoto] {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = buildMultipartBody(images: images, boundary: boundary)
        let wrapped: WrappedResponse<[AgencyPropertyPhoto]> = try await client.uploadMultipart(
            "/agency/properties/\(slug)/photos",
            boundary: boundary,
            body: body
        )
        return wrapped.data
    }

    // DELETE /api/v1/agency/properties/{slug}/photos/{photoId}
    func deletePhoto(propertySlug: String, photoId: Int) async throws {
        try await client.requestVoid(
            Endpoint(.delete, "/agency/properties/\(propertySlug)/photos/\(photoId)")
        )
    }

    // PATCH /api/v1/agency/properties/{slug}/photos/reorder
    func reorderPhotos(propertySlug: String, order: [Int]) async throws -> [AgencyPropertyPhoto] {
        struct Payload: Encodable { let order: [Int] }
        let wrapped: WrappedResponse<[AgencyPropertyPhoto]> = try await client.request(
            Endpoint(.patch, "/agency/properties/\(propertySlug)/photos/reorder", body: Payload(order: order))
        )
        return wrapped.data
    }

    // PATCH /api/v1/agency/properties/{slug}/photos/{photoId}/set-primary
    func setPrimaryPhoto(propertySlug: String, photoId: Int) async throws -> [AgencyPropertyPhoto] {
        let wrapped: WrappedResponse<[AgencyPropertyPhoto]> = try await client.request(
            Endpoint(.patch, "/agency/properties/\(propertySlug)/photos/\(photoId)/set-primary")
        )
        return wrapped.data
    }

    // MARK: - Multipart builder

    private func buildMultipartBody(images: [UIImage], boundary: String) -> Data {
        var data = Data()
        let crlf = "\r\n"
        for image in images {
            let imageData = image.jpegData(compressionQuality: 0.85) ?? Data()
            data.append("--\(boundary)\(crlf)".utf8Data)
            data.append("Content-Disposition: form-data; name=\"photos[]\"; filename=\"photo.jpg\"\(crlf)".utf8Data)
            data.append("Content-Type: image/jpeg\(crlf)\(crlf)".utf8Data)
            data.append(imageData)
            data.append(crlf.utf8Data)
        }
        data.append("--\(boundary)--\(crlf)".utf8Data)
        return data
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
