//
//  AltPayDataResponse.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 02.07.2024.
//

import Foundation

struct AltPayDataResponse: Codable {
    let model: AltPayTransactionResponse?
    let success: Bool
    let message: String?

    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case success = "Success"
        case message = "Message"
    }
}

public struct AltPayTransactionResponse: Codable {
    let qrURL: String?
    let transactionId: Int64?
    let providerQrId: String?
    let amount: Int?
    let message: String?
    let isTest: Bool?
    var banks: SbpBanksList?

    enum CodingKeys: String, CodingKey {
        case qrURL = "QrUrl"
        case transactionId = "TransactionId"
        case providerQrId = "ProviderQrId"
        case amount = "Amount"
        case message = "Message"
        case isTest = "IsTest"
        case banks = "Banks"
    }
    
    init(qrURL: String?, transactionId: Int64?, amount: Int?, message: String?, isTest: Bool?, banks: SbpBanksList? = nil, providerQrId: String? = nil) {
        self.qrURL = qrURL
        self.transactionId = transactionId
        self.amount = amount
        self.message = message
        self.isTest = isTest
        self.banks = banks
        self.providerQrId = providerQrId
    }
}

public struct PaymentIntentResponse: Codable {
    let id: String?
    let transactions: [PaymentTransactionResponse]?
    let transaction: PaymentTransactionResponse?
    let paymentSchema: String?
    let secret: String?
    let status: String?
    let threeDsCallbackId: String?
    let acsUrl: String?
    let paReq: String?
    let amount: Double?
    let currency: String?
    let culture: String?
    let createdDate: String?
    let updatedDate: String?
    let description: String?
    let tokenize: Bool?
    let externalId: String?
    let paymentUrl: String?
    let receiptEmail: String?
    let payerServiceFee: String?
    let offerLink: String?
    let successRedirectUrl: String?
    let failRedirectUrl: String?
    let paymentMethods: [PaymentMethod]?
    let restrictedPaymentMethods: [String]?
    let paymentMethodSequence: [String]?
    let items: [Item]?
    let terminalInfo: TerminalInfo?
    let userInfo: UserInfo?
    let tag: String?
    let requireEmail: Bool?
    let publicTerminalId: String?
    let authCode: String?
    let authDate: String?
    let reference: String?
    let affiliationId: String?
    let lastFour: String?
    let isCard: Bool?
    let installmentData: InstallmentData?
    let escrow: String?
    let retryPayment: Bool?
    let autoClose: Bool?
    let cryptogramMode: Bool?
}

public struct SberPayResponse: Codable {
    let qrURL: String?
    let transactionId: Int?
    let amount: Int?
    let currency: String?
    let message: String?
    let isTest: Bool?
    let status: String?
    let redirectUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case qrURL = "qrUrl"
        case transactionId = "transactionId"
        case amount, currency, message, isTest
        case status, redirectUrls
    }
}

public struct PaymentTransactionResponse: Codable {
    let transactionId: Int64?
    let paymentMethod: String?
    let puid: String?
    let status: String?
    let code: String?
}

public struct PaymentTransactionStatusModel: Codable {
    let status: String?
    let transactions: [PaymentTransactionResponse]?
}

struct PaymentMethod: Codable {
    let type: String?
    let networks: [String]?
    let link: String?
    let image: String?
    let minSum: Double?
    let maxSum: Double?
    let data: String?
    let appleMerchantId: String?
    let merchantCapabilities: [String]?
    let supportedNetworks: [String]?
    let startSessionUrl: String?
    let countryCode: String?
    let merchantId: String?
    let gateway: String?
    let merchantName: String?
    let env: String?
    let deepLink: String?
    let banks: [Bank]?
}

public enum PaymentMethodType: String {
    case tpay = "TinkoffPay"
    case sberPay = "SberPay"
    case sbp = "Sbp"
}

struct Bank: Codable {
    let bankName: String?
    let logoUrl: String?
    let schema: String?
    let webClientUrl: String?
    let isWebClientActive: String?
}

struct TerminalInfo: Codable {
    let widgetUrl: String?
    let logoUrl: String?
    let terminalUrl: String?
    let terminalFullUrl: String?
    let isCharity: Bool?
    let isTest: Bool?
    let terminalName: String?
    let skipExpiryValidation: Bool?
    let agreementPath: String?
    let isCvvRequired: Bool?
    let features: PaymentFeatures?
    let bannerAdvertiseUrl: String?
    let displayAdvertiseBannerOnWidget: Bool?
}

struct PaymentFeatures: Codable {
    let isAllowedNotSanctionedCards: Bool?
    let isQiwi: Bool?
    let isSaveCard: String?
    let isPayOrderingEnabled: Bool?
    let isThreeCardInput: Bool?
}

public struct UserInfo: Codable {
    let email: String?
}

struct InstallmentData: Codable {
}

struct Item: Codable {
}

enum IntentSaveCardState: String {
    case optional = "Optional"
    case force = "Force"
    case classic = "Classic"
    case new = "New"
}

class SDKConfiguration {
    var email: String?
    var terminalUrl: String? = nil
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
}
