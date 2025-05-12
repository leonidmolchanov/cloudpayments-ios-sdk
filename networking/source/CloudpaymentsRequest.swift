//
//  CloudpaymentsRequest.swift
//
//  Created by Sergey Iskhakov on 02.06.2021.
//

import Foundation

public struct CloudpaymentsRequest {
    public let path: String
    public let method: HTTPMethod
    public let params: [String: Any?]
    public let headers: [String: String]
    public let body: Data? 

    public init(path: String,
                method: HTTPMethod = .get,
                params: [String: Any?] = [:],
                headers: [String: String] = [:],
                body: Data? = nil) {
        self.path = path
        self.method = method
        self.params = params
        self.headers = headers
        self.body = body
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public enum CloudpaymentsConnectionError: Swift.Error {
    case invalidURL
    case noData
}
