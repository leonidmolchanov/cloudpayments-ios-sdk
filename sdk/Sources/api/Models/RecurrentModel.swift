//
//  RecurrentModel.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 10.07.2023.
//

import Foundation

struct CloudPaymentsModel: Codable {
    let cloudPayments: CloudPayments?
}

struct CloudPayments: Codable {
    let recurrent: Recurrent?
}

public struct Receipt: Codable {
    public struct Item: Codable {
        public let label: String
        public let price: Double
        public let quantity: Double
        public let amount: Double
        public let vat: Int?
        public let method: Int
        public let object: Int
        
        public init(label: String, price: Double, quantity: Double, amount: Double, vat: Int? = nil, method: Int, object: Int) {
            self.label = label
            self.price = price
            self.quantity = quantity
            self.amount = amount
            self.vat = vat
            self.method = method
            self.object = object
        }
    }
    
    public let items: [Item]
    public let taxationSystem: Int
    public let email: String
    public let phone: String
    public let isBso: Bool
    public let amounts: Amounts?
    
    public struct Amounts: Codable {
        public let electronic: Double
        public let advancePayment: Double
        public let credit: Double
        public let provision: Double
        
        public init(electronic: Double, advancePayment: Double, credit: Double, provision: Double) {
            self.electronic = electronic
            self.advancePayment = advancePayment
            self.credit = credit
            self.provision = provision
        }
    }
    
    public init(items: [Item], taxationSystem: Int, email: String = "", phone: String = "", isBso: Bool = false, amounts: Amounts? = nil) {
        self.items = items
        self.taxationSystem = taxationSystem
        self.email = email
        self.phone = phone
        self.isBso = isBso
        self.amounts = amounts
    }
}

public struct Recurrent: Codable {
    public let amount: Int?
    public let interval: String
    public let period: Int
    public let startDate: String?
    public let maxPeriods: Int?
    public let customerReceipt: Receipt?
    
    public init(interval: String, period: Int, customerReceipt: Receipt? = nil, amount: Int? = nil, startDate: String? = nil, maxPeriods: Int? = nil) {
        self.interval = interval
        self.period = period
        self.customerReceipt = customerReceipt
        self.amount = amount
        self.startDate = startDate
        self.maxPeriods = maxPeriods
    }
}

extension Receipt {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "items": items.map { $0.toDictionary() },
            "taxationSystem": taxationSystem,
            "email": email,
            "phone": phone,
            "isBso": isBso
        ]
        
        if let amounts = amounts {
            dict["amounts"] = amounts.toDictionary()
        }
        
        return dict
    }
}

extension Receipt.Item {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "label": label,
            "price": price,
            "quantity": quantity,
            "amount": amount,
            "method": method,
            "object": object
        ]
        
        if let vat = vat {
            dict["vat"] = vat
        }
        
        return dict
    }
}

extension Receipt.Amounts {
    func toDictionary() -> [String: Any] {
        return [
            "electronic": electronic,
            "advancePayment": advancePayment,
            "credit": credit,
            "provision": provision
        ]
    }
}

extension Recurrent {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "interval": interval,
            "period": period
        ]
        
        if let customerReceipt = customerReceipt {
            dict["customerReceipt"] = customerReceipt.toDictionary()
        }
        if let amount = amount {
            dict["amount"] = amount
        }
        if let startDate = startDate {
            dict["startDate"] = startDate
        }
        if let maxPeriods = maxPeriods {
            dict["maxPeriods"] = maxPeriods
        }
        
        return dict
    }
}
