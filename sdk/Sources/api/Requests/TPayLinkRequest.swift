//
//  TPayLinkRequest.swift
//  sdk
//
//  Created by Cloudpayments on 15.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class TPayLinkRequestIntent: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = String
    
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

final class CreateIntentRequest: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = PaymentIntentResponse
    var data: CloudpaymentsRequest {
        let path = CloudpaymentsHTTPResource.apiIntent.asUrl(apiUrl: apiUrl)
       
        guard var component = URLComponents(string: path) else { return CloudpaymentsRequest(path: path, method: .post, params: params, headers: headers) }
       
        if !queryItems.isEmpty {
            let items = queryItems.compactMap { return URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }
        
        guard let url = component.url else { return CloudpaymentsRequest(path: path, method: .post, params: params, headers: headers) }
        let fullPath = url.absoluteString
        print(fullPath)
        
        return CloudpaymentsRequest(path: fullPath, method: .post, params: params, headers: headers)
    }
}
