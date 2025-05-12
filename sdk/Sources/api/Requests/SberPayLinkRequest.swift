//
//  SberPayLinkRequest.swift
//  sdk
//
//  Created by Cloudpayments on 21.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class SberPayLinkRequestIntent: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = SberPayResponse
    
    var data: CloudpaymentsRequest {
        guard var component = URLComponents(string: apiUrl) else {
            print("Некорректный URL")
            return CloudpaymentsRequest(path: apiUrl, method: .get, params: params, headers: headers)
        }
        
        if !queryItems.isEmpty {
            let items = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
            component.queryItems = items
        }
        
        guard let url = component.url else {
            print("Не удалось создать URL с query параметрами")
            return CloudpaymentsRequest(path: apiUrl, method: .get, params: params, headers: headers)
        }
        
        print(url.absoluteString)

        return CloudpaymentsRequest(path: url.absoluteString, method: .get, params: [:], headers: headers)
        
    }
}
