//
//  MerchantConfigurationRequest.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 16.06.2023.
//

import CloudpaymentsNetworking
import Foundation

struct PayButtonStatus {
    var isOnSbp: Bool
    var isOnTPay: Bool
    var isOnSberPay: Bool
    var isSaveCard: Int?
    var failRedirectUrl: String?
    var successRedirectUrl: String?
    var isCvvRequired: Bool?
    var isAllowedNotSanctionedCards: Bool?
    var isQiwi: Bool?
    var isTest: Bool?
    
    init(isOnSbp: Bool = false,
         isOnTPay: Bool = false,
         isOnSberPay: Bool = false,
         isSaveCard: Int? = nil,
         terminalUrl: String? = nil,
         isCvvRequired: Bool? = nil,
         isAllowedNotSanctionedCards: Bool? = nil,
         isQiwi: Bool? = nil,
         isTest: Bool? = nil) {
        
        self.isOnSbp = isOnSbp
        self.isOnTPay = isOnTPay
        self.isOnSberPay = isOnSberPay
        self.isSaveCard = isSaveCard
        self.isCvvRequired = isCvvRequired
        self.isAllowedNotSanctionedCards = isAllowedNotSanctionedCards
        self.isQiwi = isQiwi
        self.isTest = isTest
    }
}

final class MerchantConfigurationRequest {
    
    static var payButtonStatus: PayButtonStatus?
    
    private class MerchantConfigurationRequestData<Model: Codable>: BaseRequest, CloudpaymentsRequestType {
        
        var data: CloudpaymentsNetworking.CloudpaymentsRequest
        typealias ResponseType = Model
        
        fileprivate init(baseURL: String, terminalPublicId: String?) {
            let baseURL = baseURL + "merchant/configuration/"
            guard var path = URLComponents(string: baseURL) else {
                data = .init(path: "")
                return
            }
            
            let queryItems: [URLQueryItem] = [
                .init(name: "terminalPublicId", value: terminalPublicId),
            ]
            path.queryItems = queryItems
            
            let fullUrl = path.url?.absoluteString ?? ""
            data = .init(path: fullUrl)
        }
    }
}

extension MerchantConfigurationRequest {
    
    public static func getMerchantConfiguration(baseURL: String, terminalPublicId: String?, completion: @escaping (PayButtonStatus?) -> Void) {
        var result = PayButtonStatus()
        
        MerchantConfigurationRequestData<MerchantConfigurationResponse>(baseURL: baseURL, terminalPublicId: terminalPublicId).execute { value in
            result.isSaveCard = value.model.features?.isSaveCard
            result.successRedirectUrl = value.model.terminalFullUrl
            result.failRedirectUrl = value.model.terminalFullUrl
            result.isCvvRequired = value.model.isCvvRequired
            result.isAllowedNotSanctionedCards = value.model.features?.isAllowedNotSanctionedCards
            result.isQiwi = value.model.features?.isQiwi
            result.isTest = value.model.isTest
            
            for element in value.model.externalPaymentMethods {
                guard let rawValue = element.type, let value = CaseOfBank(rawValue: rawValue) else { continue }
                
                switch value {
                case .tPay: result.isOnTPay = element.enabled
                case .sbp: result.isOnSbp = element.enabled
                case .sberPay: result.isOnSberPay = element.enabled
                }
            }
            
            self.payButtonStatus = result
            
            LoggerService.shared.logApiRequest(method: "GET", url: baseURL + "merchant/configuration", success: true)
            
            return completion(result)
            
        } onError: { error in
            print(error.localizedDescription)
            
            LoggerService.shared.logApiRequest(method: "GET", url: baseURL + "merchant/configuration", success: false)
            
            let code = error._code < 0 ? -error._code : error._code
            self.payButtonStatus = code == 1009 ? nil : result
            if code == 1009 {
                return completion(nil)
            }
            
            return completion(result)
        }
    }
}
