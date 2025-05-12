//
//  CloudpaymentsError.swift
//  sdk
//
//  Created by Sergey Iskhakov on 25.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import Foundation

public class CloudpaymentsError: Error {
    static let defaultCardError = CloudpaymentsError(message: "Unable to determine bank")
    static let networkError = CloudpaymentsError(message: "Ошибка запроса")
    static let incorrectResponseJson = CloudpaymentsError(message: "Некорректный ответ JSON")
    
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
