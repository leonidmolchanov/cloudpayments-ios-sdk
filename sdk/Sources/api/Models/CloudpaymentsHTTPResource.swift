//
//  CloudpaymentsHTTPResource.swift
//  sdk
//
//  Created by Sergey Iskhakov on 02.07.2021.
//  Copyright © 2021 Cloudpayments. All rights reserved.
//

import Foundation

enum CloudpaymentsHTTPResource: String {
    case charge = "payments/cards/charge"
    case auth = "payments/cards/auth"
    case post3ds = "payments/ThreeDSCallback"
    case configuration = "merchant/configuration"
    case tpay = "payments/qr/tinkoffpay/link"
    case sberPay = "payments/qr/sberpay/link"
    case sbp = "payments/qr/sbp/link"
    case waitStatus = "payments/qr/status/wait"
    case binInfo = "bins/info"
    case apiIntent = "api/intent"
    case apiIntentPay = "api/intent/pay"
    
    func asUrl(apiUrl: String) -> String {
        return apiUrl.appending(self.rawValue)
    }
}
