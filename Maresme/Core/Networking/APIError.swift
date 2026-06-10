import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case validation(message: String, errors: [String: [String]])
    case server(statusCode: Int, message: String)
    case network(underlying: Error)
    case decoding(underlying: Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Sesión expirada. Por favor, inicia sesión de nuevo."
        case .forbidden:
            return "No tienes permisos para realizar esta acción."
        case .notFound:
            return "El recurso solicitado no existe."
        case .validation(let message, _):
            return message
        case .server(_, let message):
            return message
        case .network(let error):
            return error.localizedDescription
        case .decoding:
            return "Error procesando la respuesta del servidor."
        case .unknown:
            return "Ha ocurrido un error inesperado."
        }
    }

    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    var validationErrors: [String: [String]] {
        if case .validation(_, let errors) = self { return errors }
        return [:]
    }
}
