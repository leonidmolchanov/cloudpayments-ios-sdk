//
//  CloudpaymentsRequestType.swift
//  Cloudpayments
//
//  Created by Sergey Iskhakov on 01.07.2021.
//

import Foundation

public protocol CloudpaymentsRequestType {
    associatedtype ResponseType: Codable
    var data: CloudpaymentsRequest { get }
}

public extension CloudpaymentsRequestType {
    
    func execute(dispatcher: CloudpaymentsNetworkDispatcher = CloudpaymentsURLSessionNetworkDispatcher.instance,
                 keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                 onSuccess: @escaping (ResponseType) -> Void,
                 onError: @escaping (Error) -> Void,
                 onRedirect: ((URLRequest) -> Bool)? = nil) {
        dispatcher.dispatch(
            request: self.data,
            onSuccess: { (responseData: Data) in
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
                    let result = try jsonDecoder.decode(ResponseType.self, from: responseData)
                    DispatchQueue.main.async {
                        onSuccess(result)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        if error is DecodingError {
                            onError(CloudpaymentsError.parseError)
                        } else {
                            onError(error)
                        }
                    }
                }
            },
            onError: { (error: Error) in
                DispatchQueue.main.async {
                    onError(error)
                }
            }, onRedirect: onRedirect
        )
    }
    
    func executeWithStatusCode(dispatcher: CloudpaymentsNetworkDispatcher = CloudpaymentsURLSessionNetworkDispatcher.instance,
                               keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                               onSuccess: @escaping (Int, ResponseType) -> Void,
                               onError: @escaping (Int, Error) -> Void,
                               onRedirect: ((URLRequest) -> Bool)? = nil) {
        dispatcher.dispatchWithStatusCode(
            request: self.data,
            onSuccess: { (statusCode: Int, responseData: Data) in
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
                    let result = try jsonDecoder.decode(ResponseType.self, from: responseData)
                    DispatchQueue.main.async {
                        onSuccess(statusCode, result) 
                    }
                } catch let error {
                    let parseError: Error = (error is DecodingError) ? CloudpaymentsError.parseError : error
                    DispatchQueue.main.async {
                        onError(statusCode, parseError)
                    }
                }
            },
            onError: { error, statusCode in
                DispatchQueue.main.async {
                    onError(statusCode, error)
                }
            },
            onRedirect: onRedirect
        )
    }
}

