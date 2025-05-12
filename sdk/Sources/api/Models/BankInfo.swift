//
//  BankInfo.swift
//  sdk
//
//  Created by Sergey Iskhakov on 09.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

public struct BankInfo: Codable {
    let logoURL: String?
    let convertedAmount: String?
    let currency: String?
    let hideCvvInput: Bool?
    let isCardAllowed: Bool?
    let cardType: NameCardType.RawValue?
    let bankName: String?
    let countryCode: Int?
}
