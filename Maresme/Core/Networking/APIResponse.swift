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
    let path:       String
    let perPage:    Int       // JSON: "per_page" → convertFromSnakeCase → perPage ✓
    let nextCursor: String?   // JSON: "next_cursor" → nextCursor ✓
    let prevCursor: String?   // JSON: "prev_cursor" → prevCursor ✓
}

// Cursor pagination — Laravel cursorPaginate() returns a flat structure (no links/meta wrapper).
// JSON: { "data":[...], "next_cursor":"...", "prev_cursor":null, "next_page_url":"...", ... }
struct CursorPage<T: Decodable>: Decodable {
    let data:        [T]
    let nextCursor:  String?   // next_cursor → nextCursor (convertFromSnakeCase)
    let prevCursor:  String?
}

// GET /api/v1/properties — respuesta dual: cursor (featured/newest) u offset (price_asc/price_desc).
// Los campos de meta son mutuamente excluyentes: next_cursor solo aparece en cursor pagination,
// current_page/last_page solo en offset pagination. Todos opcionales → ambos casos decodifican bien.
struct PropertyListResponse: Decodable {
    let data: [PropertyCard]
    let meta: Meta

    struct Meta: Decodable {
        let perPage:     Int
        let nextCursor:  String?   // cursor pagination: "next_cursor"
        let prevCursor:  String?
        let currentPage: Int?      // offset pagination: "current_page"
        let lastPage:    Int?      // offset pagination: "last_page"
    }

    var hasMore: Bool {
        if let cursor = meta.nextCursor, !cursor.isEmpty { return true }
        if let cur = meta.currentPage, let last = meta.lastPage { return cur < last }
        return false
    }

    var nextCursor: String? { meta.nextCursor }

    var nextPage: Int? {
        guard let cur = meta.currentPage, let last = meta.lastPage, cur < last else { return nil }
        return cur + 1
    }
}

// Toggle / store / destroy favorite responses:
// POST /favorites/{slug}/toggle   → { "favorited": bool, "count": N }
// POST /favorites/{slug}          → { "favorited": true, "count": N }  (201)
// DELETE /favorites/{slug}        → { "favorited": false, "count": N }
struct FavoriteActionResponse: Decodable {
    let favorited: Bool
    let count:     Int
}

// GET /favorites/count → { "count": N }
struct FavoriteCountResponse: Decodable {
    let count: Int
}

// Explicit nonisolated init(from:) is required because SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
// would otherwise synthesize a @MainActor Decodable conformance, preventing decoding from
// within actor APIClient (which is not @MainActor).

// GET /notifications/count → { "total": N, "unread": N }
struct NotificationCountResponse: Decodable {
    let total:  Int
    let unread: Int
}

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
