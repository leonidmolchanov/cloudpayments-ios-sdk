//
//  CloudpaymentsURLSessionNetworkDispatcher.swift
//  Cloudpayments
//
//  Created by Sergey Iskhakov on 01.07.2021.
//

import Foundation

public protocol CloudpaymentsNetworkDispatcher {
    func dispatch(request: CloudpaymentsRequest,
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void,
                  onRedirect: ((URLRequest) -> Bool)?)
    
    func dispatchWithStatusCode(request: CloudpaymentsRequest,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)?)
}

public class CloudpaymentsURLSessionNetworkDispatcher: NSObject, CloudpaymentsNetworkDispatcher {
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    
    public static let instance = CloudpaymentsURLSessionNetworkDispatcher()
    
    private var onRedirect: ((URLRequest) -> Bool)?
    
    public func dispatch(request: CloudpaymentsRequest,
                         onSuccess: @escaping (Data) -> Void,
                         onError: @escaping (Error) -> Void,
                         onRedirect: ((URLRequest) -> Bool)? = nil) {
        self.onRedirect = onRedirect
        
        guard let url = URL(string: request.path) else {
            onError(CloudpaymentsConnectionError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        if let body = request.body {
            urlRequest.httpBody = body
            print("[dispatch] Используется кастомный body (Data), длина: \(body.count) байт")
        } else if request.method != .get && !request.params.isEmpty {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.params, options: [])
                print("[dispatch] Сериализованное тело из params: \(request.params)")
            } catch let error {
                print("[dispatch] Ошибка сериализации параметров: \(error.localizedDescription)")
                onError(error)
                return
            }
        } else {
            print("[dispatch] Метод \(request.method.rawValue) — тело запроса не добавляется.")
        }
        
        var headers = request.headers
        if headers["User-Agent"] == nil {
            headers["User-Agent"] = "Mobile_SDK_iOS"
        }
        headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
        urlRequest.allHTTPHeaderFields = headers
        
        print("[dispatch] Заголовки запроса: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("[dispatch] URL: \(urlRequest.url?.absoluteString ?? "nil")")
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("[dispatch] Ошибка: \(error.localizedDescription)")
                onError(error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[dispatch] HTTP Status Code: \(httpResponse.statusCode)")
                print("[dispatch] HTTP Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("[dispatch] Нет данных в ответе")
                onError(CloudpaymentsConnectionError.noData)
                return
            }
            
            onSuccess(data)
        }.resume()
    }
    
    public func dispatchWithStatusCode(request: CloudpaymentsRequest,
                                       onSuccess: @escaping (Int, Data) -> Void,
                                       onError: @escaping (Error, Int) -> Void,
                                       onRedirect: ((URLRequest) -> Bool)? = nil) {
        performRequest(request: request, returnStatusCode: true, onSuccess: onSuccess, onError: onError, onRedirect: onRedirect)
    }
    
    private func performRequest(request: CloudpaymentsRequest,
                                returnStatusCode: Bool,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)? = nil) {
        guard let url = URL(string: request.path) else {
            onError(CloudpaymentsConnectionError.invalidURL, 0)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        if !request.params.isEmpty {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: request.params, options: [])
        }
        
        var headers = request.headers
        headers["Content-Type"] = "application/json"
        headers["User-Agent"] = "Mobile_SDK_iOS"
        urlRequest.allHTTPHeaderFields = headers
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                onError(error, 0)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                onError(CloudpaymentsConnectionError.noData, 0)
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard let data = data else {
                onError(CloudpaymentsConnectionError.noData, statusCode)
                return
            }
            
            if returnStatusCode {
                onSuccess(statusCode, data)
            } else {
                onSuccess(0, data)
            }
        }.resume()
    }
    
    
}

extension CloudpaymentsURLSessionNetworkDispatcher: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let _ = onRedirect?(request) {
            completionHandler(request)
        } else {
            completionHandler(nil)
        }
    }
}
