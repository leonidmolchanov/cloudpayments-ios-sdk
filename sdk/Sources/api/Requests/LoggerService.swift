//
//  LoggerService.swift
//  sdk
//
//  Created by Cloudpayments on 05.02.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

final class LoggerService {
    
    static let shared = LoggerService()
    
    private var publicId: String = "Unknown publicId"
    
    private init() { }
    
    private lazy var pathUrl: String = {
        return "https://fm.cloudpayments.ru/monitoring-api/logger"
    }()
    
    private var apiKey: String {
        let selectedKey = "b8cac4dd-b244-46e0-8fdc-930f291e3304"
        debugPrint("[LoggerService] using api key \(selectedKey)")
        return selectedKey
    }
    
    private lazy var device: String = {
        return UIDevice.current.model
    }()
    
    private lazy var version: String = {
        return UIDevice.current.systemVersion
    }()
    
    func startLogging(publicId: String) {
        self.publicId = publicId
        setUncaughtExceptionHandler()
        debugPrint("-------->>>>>>> [LoggerService] started")
    }
    
    private func setUncaughtExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let stackTrace = exception.callStackSymbols.joined(separator: "\n")
            let message = exception.reason ?? "No message provided"
            
            let semaphore = DispatchSemaphore(value: 0)
            LoggerService.shared.logCrash(stackTrace: stackTrace, message: message) {
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 3)
        }
    }
    
    func logCrash(stackTrace: String, message: String, completion: (() -> Void)? = nil) {
        let logData: [String: Any] = [
            "apiKey": apiKey,
            "level": "ERROR",
            "messageTemplate": "Exception on user {publicId} with {stackTrace} with message {exceptionMessage}, on iOS OS version {osVersion}, device model {model}",
            "templateData": [
                publicId,
                stackTrace,
                message,
                version,
                device
            ]
        ]
        
        let jsonString = jsonString(from: logData)
        sendLog(jsonString: jsonString, completion: completion)
    }
    
    func logApiRequest(method: String, url: String, success: Bool) {
        debugPrint("[LoggerService] Logging API request")
        debugPrint("Method: \(method)")
        debugPrint("URL: \(url)")
        debugPrint("Version: \(version)")
        debugPrint("Device: \(device)")
        
        let logData: [String: Any] = [
            "apiKey": apiKey,
            "level": "INFO",
            "messageTemplate": "User {publicId} send a request {method} {url} and received a response with success {success}, on iOS OS version {osVersion}, device model {model}",
            "templateData": [
                self.publicId,
                method,
                url,
                success,
                version,
                device
            ]
        ]
        
        debugPrint("[LoggerService] Json on Logger \(logData)")
        let jsonString = jsonString(from: logData)
        sendLog(jsonString: jsonString)
    }
    
    private func sendLog(jsonString: String, completion: (() -> Void)? = nil) {
        guard let monitoringURL = URL(string: pathUrl) else {
            debugPrint("Ошибка: Некорректный URL мониторинга")
            completion?()
            return
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            debugPrint("Ошибка: Не удалось сериализовать JSON")
            completion?()
            return
        }
        
        debugPrint("[LoggerService] Sending log to server: \(pathUrl)")
        
        var request = URLRequest(url: monitoringURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("[LoggerService] Ошибка отправки лога: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                debugPrint("[LoggerService] Лог отправлен: Status Code: \(httpResponse.statusCode)")
            }
            completion?()
        }
        task.resume()
    }
    
    private func jsonString(from dictionary: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            debugPrint("Ошибка: Не удалось преобразовать в JSON")
            return ""
        }
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
