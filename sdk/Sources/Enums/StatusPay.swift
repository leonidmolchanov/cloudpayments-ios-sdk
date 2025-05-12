//
//  StatusPay.swift
//  sdk
//
//  Created by Cloudpayments on 12.09.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation

enum StatusPay: String {
    case created = "Created"
    case pending = "Pending"
    case authorized = "Authorized"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case declined = "Declined"
    
    init?(rawValue: Int) {
        switch StatusPayCode(rawValue: rawValue) {
        case .created: self = .created
        case .declined: self = .declined
        case .completed: self = .completed
        default: self = .declined
        }
    }
}

enum StatusPayCode: Int {
    case created = 0
    case declined = 5
    case completed = 3
}

enum IntentTransactionStatus: String {
    case authorized = "Authorized"
    case completed = "Completed"
    case declined = "Declined"
    case cancelled = "Cancelled"
}

enum IntentWaitStatus: String {
    case requiresPaymentMethod = "RequiresPaymentMethod"
    case succeeded = "Succeeded"
}
