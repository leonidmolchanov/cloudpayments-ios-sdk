//
//  Scheme.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

enum Scheme: String, Codable {
    case charge = "charge"
    case auth = "auth"
}

enum IntentScheme: String, Codable {
    case single = "single"
    case dual = "dual"
}
