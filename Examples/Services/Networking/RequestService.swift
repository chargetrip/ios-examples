//
//  Request.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import Foundation
import Combine

enum NetworkingScheme: String {
    case secure = "https"
    case insecure = "http"
}

enum Host: String {
    case chargetrip = "api.chargetrip.io"
    case mapbox = "api.mapbox.com"
}

enum HttpMethod: Equatable {
    case get
    case put
    case post
    case delete
    case head

    var name: String {
        switch self {
        case .get: return "GET"
        case .put: return "PUT"
        case .post: return "POST"
        case .delete: return "DELETE"
        case .head: return "HEAD"
        }
    }
}

enum NetworkError: Error {
    case url(URLError?)
    case decode(Error)
}

struct Request<Response: Decodable> {
    var scheme: NetworkingScheme = .secure
    var host: Host = .chargetrip
    var path: String = "/"
    var method: HttpMethod = .get
    var headers: [String: String] = [:]
    var queryItems: [URLQueryItem]?
    var body: Encodable?

    func scheme(_ scheme: NetworkingScheme) -> Request<Response> {
        .init(
            scheme: scheme,
            host: self.host,
            path: path,
            method: self.method,
            headers: self.headers,
            queryItems: self.queryItems,
            body: self.body
        )
    }

    func host(_ host: Host) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: host,
            path: self.path,
            method: self.method,
            headers: self.headers,
            queryItems: self.queryItems,
            body: self.body
        )
    }

    func path(_ path: String) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: self.host,
            path: path,
            method: self.method,
            headers: self.headers,
            queryItems: self.queryItems,
            body: self.body
        )
    }

    func method(_ method: HttpMethod) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: self.host,
            path: self.path,
            method: method,
            headers: self.headers,
            queryItems: self.queryItems,
            body: self.body
        )
    }

    func headers(_ headers: [String: String]) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: self.host,
            path: self.path,
            method: self.method,
            headers: headers,
            queryItems: self.queryItems,
            body: self.body
        )
    }

    func queryItems(_ queryItems: [URLQueryItem]) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: self.host,
            path: self.path,
            method: self.method,
            headers: self.headers,
            queryItems: queryItems,
            body: self.body
        )
    }

    func body<T: Encodable>(_ body: T) -> Request<Response> {
        .init(
            scheme: self.scheme,
            host: self.host,
            path: self.path,
            method: self.method,
            headers: self.headers,
            queryItems: self.queryItems,
            body: body
        )
    }

    func constructURL() -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme.rawValue
        urlComponents.host = host.rawValue
        urlComponents.path = path
        urlComponents.queryItems = queryItems

        return urlComponents.url
    }

    func fetch() -> AnyPublisher<Data, Error> {
        guard let url = constructURL() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let urlSession = URLSession.shared
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = method.name

        switch method {
        case .post, .put:
            if let body {
                do {
                    urlRequest.httpBody = try JSONEncoder().encode(body)
                } catch let error {
                    print(error)
                }
            }
        default: break
        }

        if host == .chargetrip {
            urlRequest.addValue("", forHTTPHeaderField: "x-client-id")
            urlRequest.addValue("", forHTTPHeaderField: "x-app-id")
        }

        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }

        return urlSession.dataTaskPublisher(for: urlRequest)
            .map { (data, _) -> Data in
                return data
            }
            .mapError { error -> NetworkError in
                return NetworkError.url(error)
            }
            .retry(1)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchAsModel() -> AnyPublisher<Response, Error> {
        fetch()
            .decode(type: Response.self, decoder: JSONDecoder())
            .mapError { error -> NetworkError in
                return NetworkError.decode(error)
            }
            .eraseToAnyPublisher()
    }
}
