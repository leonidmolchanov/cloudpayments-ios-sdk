//
//  BaseRequest.swift
//  Cloudpayments
//
//  Created by Sergey Iskhakov on 01.07.2021.
//

import Foundation

open class BaseRequest {
    var queryItems: [String: String?]
    var params: [String: Any?]
    var headers: [String: String]
    var apiUrl: String
    var body: Data?     

    public init(queryItems: [String: String?] = [:],
                params: [String: Any?] = [:],
                headers: [String: String] = [:],
                apiUrl: String = "",
                body: Data? = nil) {
        self.queryItems = queryItems
        self.params = params
        self.headers = headers
        self.apiUrl = apiUrl
        self.body = body
    }
}
