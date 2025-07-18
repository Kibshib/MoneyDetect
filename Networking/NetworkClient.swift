//
//  NetworkClient.swift
//  SHMR Finance Client
//
//  Универсальный сетевой клиент под https://shmr-finance.ru/api/v1
//  - async/await
//  - generic Body: Encodable / Response: Decodable
//  - перегрузка без body для GET
//  - Bearer токен
//  - фоновое encode/decode
//  - обработка HTTP / API message / сериализационных ошибок
//

import Foundation

// MARK: - Ошибки

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case noResponse
    case http(status: Int, data: Data?)
    case apiMessage(String)
    case decoding(Error)
    case encoding(Error)
    case noData
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let s): return "Неверный URL: \(s)"
        case .noResponse: return "Нет ответа от сервера."
        case .http(let status, _): return "HTTP \(status)."
        case .apiMessage(let m): return m
        case .decoding: return "Ошибка декодирования данных."
        case .encoding: return "Ошибка кодирования данных."
        case .noData: return "Пустой ответ сервера."
        case .underlying(let e): return e.localizedDescription
        }
    }
}

// MARK: - HTTP / Endpoint

enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE" }

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var query: [URLQueryItem]
    var headers: [String: String]

    init(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
    }
}

// MARK: - Пустое тело

struct EmptyPayload: Codable { init() {} }

// MARK: - API Error (сервер может вернуть message)

private struct APIErrorResponse: Decodable { let message: String? }

// MARK: - NetworkClient

final class NetworkClient {

    static let shared = NetworkClient(
        baseURL: URL(string: "https://shmr-finance.ru/api/v1")!,
        token: AppSecrets.bearerToken
    )

    private let baseURL: URL
    private let session: URLSession
    private var token: String

    init(baseURL: URL, session: URLSession = .shared, token: String) {
        self.baseURL = baseURL
        self.session = session
        self.token = token
    }

    func updateToken(_ new: String) { token = new }

    // MARK: Convenience GET (без body)
    @discardableResult
    func request<Response: Decodable>(
        _ endpoint: Endpoint,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        let noBody: EmptyPayload? = nil
        return try await request(endpoint, body: noBody, responseType: responseType)
    }

    // MARK: Generic основной
    @discardableResult
    func request<Response: Decodable, Body: Encodable>(
        _ endpoint: Endpoint,
        body: Body? = nil,
        responseType: Response.Type = Response.self
    ) async throws -> Response {

        let request = try await buildURLRequest(from: endpoint, body: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.underlying(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiMsg = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
               let m = apiMsg.message, !m.isEmpty {
                throw NetworkError.apiMessage(m)
            }
            throw NetworkError.http(status: http.statusCode, data: data)
        }

        if data.isEmpty {
            if Response.self == EmptyPayload.self {
                return EmptyPayload() as! Response
            } else {
                throw NetworkError.noData
            }
        }

        return try await decode(Response.self, from: data)
    }

    // MARK: - Helpers

    private func buildURLRequest<Body: Encodable>(
        from endpoint: Endpoint,
        body: Body?
    ) async throws -> URLRequest {
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL(endpoint.path)
        }
        if !endpoint.query.isEmpty { comps.queryItems = endpoint.query }
        guard let url = comps.url else { throw NetworkError.invalidURL(endpoint.path) }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        endpoint.headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        if let body = body, endpoint.method != .get {
            let data = try await encode(body)
            req.httpBody = data
        }
        return req
    }

    private func encode<Body: Encodable>(_ body: Body) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let enc = JSONEncoder()
                    cont.resume(returning: try enc.encode(body))
                } catch {
                    cont.resume(throwing: NetworkError.encoding(error))
                }
            }
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let dec = JSONDecoder()
                    cont.resume(returning: try dec.decode(T.self, from: data))
                } catch {
                    cont.resume(throwing: NetworkError.decoding(error))
                }
            }
        }
    }
}
