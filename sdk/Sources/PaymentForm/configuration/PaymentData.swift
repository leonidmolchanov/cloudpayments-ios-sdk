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
    private (set) var splits: [Splits]?
    private (set) var payer: PaymentDataPayer?
    private (set) var amount: String = "0"
    private (set) var currency: String = "RUB"
    private (set) var applePayMerchantId: String? = ""
    private (set) var cardholderName: String?
    private (set) var description: String?
    private (set) var accountId: String?
    private (set) var invoiceId: String?
    private (set) var cultureName: String?
    private (set) var receipt: Receipt?
    private (set) var recurrent: Recurrent?
    private var jsonData: String?
    
    var email: String?
    var terminalUrl: String? = nil
    var saveCard: Bool? = nil
    var cryptogram: String?
    var isCvvRequired: Bool?
    var isAllowedNotSanctionedCards: Bool? = nil
    var isQiwi: Bool? = nil
    var isTest: Bool? = nil
    
    public init() {
    }
    
    public func setAmount(_ amount: String) -> PaymentData {
        self.amount = amount
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
    
    public func getJsonData() -> String? {
        
        var baseData: [String: Any] = [:]
        
        if let existingJsonData = self.jsonData,
           let parsedData = convertStringToDictionary(text: existingJsonData) {
            baseData = parsedData
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        
        var cloudPayments: [String: Any] = baseData["CloudPayments"] as? [String: Any] ?? [:]
        
        if let recurrent = recurrent {
            if let recurrentData = try? encoder.encode(recurrent),
               let recurrentJson = try? JSONSerialization.jsonObject(with: recurrentData, options: []) as? [String: Any] {
                cloudPayments["recurrent"] = recurrentJson
            } else {
                print("Failed to encode or convert Recurrent to JSON")
            }
        }
        
        if let receipt = receipt {
            if let receiptData = try? encoder.encode(receipt),
               let receiptJson = try? JSONSerialization.jsonObject(with: receiptData, options: []) as? [String: Any] {
                cloudPayments["CustomerReceipt"] = receiptJson
            } else {
                print("Failed to encode or convert Receipt to JSON")
            }
        }
        
        if !cloudPayments.isEmpty {
            baseData["CloudPayments"] = cloudPayments
        }
        
        guard JSONSerialization.isValidJSONObject(baseData) else {
            print("Invalid JSON structure: \(baseData)")
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: baseData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            self.jsonData = jsonString // Кэшируем результат
            return jsonString
        } catch {
            print("Failed to serialize JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func setJsonData(_ jsonData: String) -> PaymentData {
        
        let map = convertStringToDictionary(text: jsonData)
        
        if (map == nil) {
            self.jsonData = nil
            return self
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: map as Any, options: .sortedKeys) {
            let jsonString = String(data: data, encoding: .utf8)
            self.jsonData = jsonString
        }
        
        return self
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("JSON data is empty")
            }
        }
        return nil
    }
}
