//
//  BinInfoRequest.swift
//  sdk
//
//  Created by Cloudpayments on 05.02.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class BinInfoRequestWithIntentId: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = BankInfo

    private let intentId: String

    init(intentId: String, queryItems: [String: String?], apiUrl: String) {
        self.intentId = intentId
        super.init(queryItems: queryItems, apiUrl: apiUrl)
    }

    var data: CloudpaymentsRequest {
        let path = "\(apiUrl)api/intent/\(intentId)/bininfo"

        guard var component = URLComponents(string: path) else {
            return CloudpaymentsRequest(path: path, method: .get, headers: headers)
        }

        if !queryItems.isEmpty {
            let items = queryItems.compactMap { URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }

        guard let url = component.url else {
            return CloudpaymentsRequest(path: path, method: .get, headers: headers)
        }

        let fullPath = url.absoluteString

        return CloudpaymentsRequest(path: fullPath, method: .get, headers: headers)
    }
}
