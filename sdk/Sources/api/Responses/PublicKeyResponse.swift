//
//  PublicKeyData.swift
//  Cloudpayments
//
//  Created by CloudPayments on 31.05.2023.
//

import Foundation

public struct PublicKeyResponse: Codable {
    let Pem: String?
    let Version: Int?
}
