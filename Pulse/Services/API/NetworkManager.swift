import Foundation

actor NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.unauthorized
            case 403:
                // Forbidden - likely invalid API key or rate limit
                let errorMessage = String(data: data, encoding: .utf8) ?? "Forbidden"
                throw APIError.serverError(statusCode: 403, message: "API key invalid or rate limit exceeded: \(errorMessage)")
            case 404:
                throw APIError.notFound
            case 429:
                throw APIError.rateLimitExceeded
            case 400...499:
                // Try to decode error message, fallback to raw string
                let message: String
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    message = errorResponse.message ?? errorResponse.error ?? "Client error"
                } else {
                    message = String(data: data, encoding: .utf8) ?? "Unknown client error"
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            case 500...599:
                let message: String
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    message = errorResponse.message ?? errorResponse.error ?? "Server error"
                } else {
                    message = String(data: data, encoding: .utf8) ?? "Unknown server error"
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }
            
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                return decodedData
            } catch {
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}

// MARK: - Error Response Model
private struct ErrorResponse: Codable {
    let message: String?
    let error: String?
    let status: String?
}
