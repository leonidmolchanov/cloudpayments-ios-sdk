//
//  WaitStatusRequest.swift
//  sdk
//
//  Created by Cloudpayments on 15.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class IntentStatusWait: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = PaymentTransactionStatusModel
    
    private let intentId: String

    init(intentId: String, apiUrl: String) {
        self.intentId = intentId
        super.init(apiUrl: apiUrl)
    }

    var data: CloudpaymentsRequest {
        let path = "\(apiUrl)api/intent/\(intentId)/status"

        guard var component = URLComponents(string: path) else {
            return CloudpaymentsRequest(path: path, method: .get, params: params, headers: headers)
        }

        if !queryItems.isEmpty {
            let items = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
            component.queryItems = items
        }

        guard let url = component.url else {
            return CloudpaymentsRequest(path: path, method: .get, params: params, headers: headers)
        }

        return CloudpaymentsRequest(path: url.absoluteString, method: .get, params: params, headers: headers)
    }
}

