import Foundation

struct WrappedResponse<T: Decodable>: Decodable {
    let data: T
}

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let links: PaginationLinks
    let meta: PaginationMeta
}

struct PaginationLinks: Decodable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}

struct PaginationMeta: Decodable {
    let path: String
    let perPage: Int
    let nextCursor: String?
    let prevCursor: String?

    enum CodingKeys: String, CodingKey {
        case path
        case perPage    = "per_page"
        case nextCursor = "next_cursor"
        case prevCursor = "prev_cursor"
    }
}

// Explicit nonisolated init(from:) is required because SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
// would otherwise synthesize a @MainActor Decodable conformance, preventing decoding from
// within actor APIClient (which is not @MainActor).

struct MessageResponse {
    let message: String
}

extension MessageResponse: Decodable {
    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message = try c.decode(String.self, forKey: .message)
    }
    private enum CodingKeys: String, CodingKey { case message }
}

struct ValidationErrorResponse {
    let message: String
    let errors:  [String: [String]]?
}

extension ValidationErrorResponse: Decodable {
    nonisolated init(from decoder: any Decoder) throws {
        let c   = try decoder.container(keyedBy: CodingKeys.self)
        message = try  c.decode(String.self, forKey: .message)
        errors  = try? c.decode([String: [String]].self, forKey: .errors)
    }
    private enum CodingKeys: String, CodingKey { case message, errors }
}
