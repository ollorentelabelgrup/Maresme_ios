import UIKit

struct LoginRequest: Encodable {
    let email:      String
    let password:   String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case email, password
        case deviceName = "device_name"
    }
}

struct RegisterRequest: Encodable {
    let name:                 String
    let email:                String
    let password:             String
    let passwordConfirmation: String
    let deviceName:           String

    enum CodingKeys: String, CodingKey {
        case name, email, password
        case passwordConfirmation = "password_confirmation"
        case deviceName           = "device_name"
    }
}

// POST /auth/login and /auth/register both return:
// { "data": { "access_token": "...", "token_type": "Bearer", "user": UserResource } }
struct AuthResponse: Decodable {
    let accessToken: String   // snake_case decoder: access_token → accessToken
    let user:        UserModel
}

// GET /me returns:
// { "data": { "user": UserResource, "agency": AgencyResource|null,
//             "unread_notifications_count": N, "active_sessions_count": N } }
struct MeResponse: Decodable {
    let user:                      UserModel
    let agency:                    AgencyModel?
    let unreadNotificationsCount:  Int
    let activeSessionsCount:       Int
}

struct AuthService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(
            email:      email,
            password:   password,
            deviceName: UIDevice.current.name
        )
        let wrapped: WrappedResponse<AuthResponse> = try await client.request(
            Endpoint(.post, "/auth/login", body: body)
        )
        return wrapped.data
    }

    func register(name: String, email: String, password: String, confirmation: String) async throws -> AuthResponse {
        let body = RegisterRequest(
            name:                 name,
            email:                email,
            password:             password,
            passwordConfirmation: confirmation,
            deviceName:           UIDevice.current.name
        )
        let wrapped: WrappedResponse<AuthResponse> = try await client.request(
            Endpoint(.post, "/auth/register", body: body)
        )
        return wrapped.data
    }

    func logout() async throws {
        try await client.requestVoid(Endpoint(.post, "/auth/logout"))
    }

    func me() async throws -> MeResponse {
        let wrapped: WrappedResponse<MeResponse> = try await client.request(
            Endpoint(.get, "/me")
        )
        return wrapped.data
    }
}
