//
//  PostThreeDsRequest.swift
//  Cloudpayments
//
//  Created by Sergey Iskhakov on 01.07.2021.
//

import CloudpaymentsNetworking
import Foundation

final class CreateIntentApiPayRequest: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = PaymentIntentResponse
    var data: CloudpaymentsRequest {
        let path = CloudpaymentsHTTPResource.apiIntentPay.asUrl(apiUrl: apiUrl)
       
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
