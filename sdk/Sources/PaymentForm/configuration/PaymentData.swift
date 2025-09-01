//
//  PaymentConfiguration.swift
//  sdk
//
//  Created by Sergey Iskhakov on 22.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import Foundation

public struct PaymentDataPayer: Codable {
    let firstName: String
    let lastName: String
    let middleName: String
    let birth: String
    let address: String
    let street: String
    let city: String
    let country: String
    let phone: String
    let postcode: String
    
    public init(firstName: String = "",
                lastName: String = "",
                middleName: String = "",
                birth: String = "",
                address: String = "",
                street: String = "",
                city: String = "",
                country: String = "",
                phone: String = "",
                postcode: String = "") {
        self.firstName = firstName
        self.lastName = lastName
        self.middleName = middleName
        self.birth = birth
        self.address = address
        self.street = street
        self.city = city
        self.country = country
        self.phone = phone
        self.postcode = postcode
    }
    
    var dictionary: [String: String] { return ["FirstName": firstName,
                                               "LastName": lastName,
                                               "MiddleName": middleName,
                                               "Birth": birth,
                                               "Address": address,
                                               "Street": street,
                                               "City": city,
                                               "Country": country,
                                               "Phone": phone,
                                               "Postcode": postcode] }
}

public class PaymentData {
    private(set) var splits: [Splits]?
    private(set) var payer: PaymentDataPayer?
    private(set) var amount: String = "0"
    private(set) var currency: String = "RUB"
    private(set) var applePayMerchantId: String? = ""
    private(set) var cardholderName: String?
    private(set) var description: String?
    private(set) var accountId: String?
    private(set) var invoiceId: String?
    private(set) var cultureName: String?
    private(set) var receipt: Receipt?
    private(set) var recurrent: Recurrent?
    private(set) var jsonData: String?
  
    var email: String?
    var saveCard: Bool? = nil
    var cryptogram: String?
    var isCvvRequired: Bool?
    var isAllowedNotSanctionedCards: Bool? = nil
    var isQiwi: Bool? = nil
    var intentId: String? = nil
    var paymentLinks: [String: String] = [:]
    var sberPayData: String?
    var sbpBanks: [Bank]?
    var intentSaveCardState: IntentSaveCardState?
    var savedTokenize: Bool? = nil
    var pem: String?
    var version: Int?
    var secret: String?
    var terminalFullUrl: String? = nil
    var isTest: Bool? = nil
    
    var sdkConfiguration: SDKConfiguration?
    
    public init() {
    }
    
    public func setAmount(_ amount: String) -> PaymentData {
        if let decimal = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) {
            var rounded = Decimal()
            var src = decimal
            NSDecimalRound(&rounded, &src, 2, .plain)
            self.amount = NSDecimalNumber(decimal: rounded).stringValue
        } else {
            self.amount = amount
        }
        return self
    }

    internal func setAmount(decimal: Decimal) -> PaymentData {
        var rounded = Decimal()
        var src = decimal
        NSDecimalRound(&rounded, &src, 2, .plain)
        self.amount = NSDecimalNumber(decimal: rounded).stringValue
        return self
    }
    
    public func setCurrency(_ currency: String) -> PaymentData {
        if (currency.isEmpty) {
            self.currency = "RUB"
        } else {
            self.currency = currency
        }
        return self
    }
    
    public func setApplePayMerchantId(_ applePayMerchantId: String) -> PaymentData {
        self.applePayMerchantId = applePayMerchantId
        return self
    }
    
    public func setCardholderName(_ cardholderName: String?) -> PaymentData {
        self.cardholderName = cardholderName
        return self
    }
    
    public func setDescription(_ description: String?) -> PaymentData {
        self.description = description
        return self
    }
    
    public func setAccountId(_ accountId: String?) -> PaymentData {
        self.accountId = accountId
        return self
    }
    
    public func setInvoiceId(_ invoiceId: String?) -> PaymentData {
        self.invoiceId = invoiceId
        return self
    }
    
    public func setCultureName(_ cultureName: String?) -> PaymentData {
        self.cultureName = cultureName
        return self
    }
    
    public func setPayer(_ payer: PaymentDataPayer?) -> PaymentData {
        self.payer = payer
        return self
    }
    
    public func setEmail(_ email: String?) -> PaymentData {
        self.email = email
        return self
    }
    
    public func setSplits(_ splits: [Splits]) -> PaymentData {
        self.splits = splits
        return self
    }
    
    public func setRecurrent(_ recurrent: Recurrent?) -> PaymentData {
        self.recurrent = recurrent
        return self
    }
    
    public func setReceipt(_ receipt: Receipt?) -> PaymentData {
        self.receipt = receipt
        return self
    }
    
    public func setJsonData(_ jsonData: String) -> PaymentData {
        self.jsonData = jsonData
        return self
    }
}
