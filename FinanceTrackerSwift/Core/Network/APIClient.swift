import Foundation

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case noData
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(_, let msg): return msg
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .noData: return "No data received"
        case .unauthorized: return "Unauthorized — please log in again"
        }
    }
}

// MARK: - App Config
enum AppConfig {
    static var baseURL: String {
        ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:5237"
    }
}

// MARK: - Empty Response helper
struct EmptyResponse: Codable {}

// MARK: - API Client
actor APIClient {
    static let shared = APIClient()
    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: Generic request
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        params: [String: String]? = nil
    ) async throws -> T {
        var urlString = "\(AppConfig.baseURL)\(path)"
        if let params = params, !params.isEmpty {
            var comps = URLComponents(string: urlString) ?? URLComponents()
            comps.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = comps.url?.absoluteString ?? urlString
        }

        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.read(key: "finance_tracker_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }

        if http.statusCode == 401 { throw APIError.unauthorized }

        guard (200..<300).contains(http.statusCode) else {
            let message = extractErrorMessage(from: data, status: http.statusCode)
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }

        if http.statusCode == 204 {
            if let empty = EmptyResponse() as? T { return empty }
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: Void request
    func requestVoid(path: String, method: String = "DELETE", body: (any Encodable)? = nil) async throws {
        guard let url = URL(string: "\(AppConfig.baseURL)\(path)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.shared.read(key: "finance_tracker_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body { request.httpBody = try JSONEncoder().encode(body) }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode, message: "Request failed with status \(http.statusCode)")
        }
    }

    // MARK: Convenience
    func get<T: Decodable>(_ path: String, params: [String: String]? = nil) async throws -> T {
        try await request(path: path, method: "GET", params: params)
    }
    func post<T: Decodable>(_ path: String, body: (any Encodable)? = nil, params: [String: String]? = nil) async throws -> T {
        try await request(path: path, method: "POST", body: body, params: params)
    }
    func put<T: Decodable>(_ path: String, body: (any Encodable)? = nil, params: [String: String]? = nil) async throws -> T {
        try await request(path: path, method: "PUT", body: body, params: params)
    }
    func delete(_ path: String) async throws {
        try await requestVoid(path: path, method: "DELETE")
    }

    // MARK: Error parsing
    private func extractErrorMessage(from data: Data, status: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let detail = json["detail"] as? String { return detail }
            if let message = json["message"] as? String { return message }
            if let title = json["title"] as? String { return title }
            if let errors = json["errors"] as? [String: Any] {
                let messages = errors.values.compactMap { val -> String? in
                    if let arr = val as? [String] { return arr.joined(separator: ", ") }
                    return val as? String
                }
                if !messages.isEmpty { return messages.joined(separator: ". ") }
            }
        }
        return "Request failed with status \(status)"
    }
}
