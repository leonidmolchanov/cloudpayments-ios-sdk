
import CloudpaymentsNetworking
import Foundation
import UIKit

public struct ButtonConfiguration {
    public let isOnTPayButton: Bool
    public let isOnSbpButton: Bool
    public let isOnSberPayButton: Bool
    public let successRedirectUrl: String?
    public let failRedirectUrl: String?
    let isTest: Bool?
    
    init(isOnTPayButton: Bool, isOnSbpButton: Bool, isOnSberPayButton: Bool, successRedirectUrl: String? = nil, failRedirectUrl: String? = nil, isTest: Bool? = nil) {
        self.isOnTPayButton = isOnTPayButton
        self.isOnSbpButton = isOnSbpButton
        self.isOnSberPayButton = isOnSberPayButton
        self.successRedirectUrl = successRedirectUrl
        self.failRedirectUrl = failRedirectUrl
        self.isTest = isTest
    }
}


public class CloudpaymentsApi {
    enum Source: String {
        case cpForm = "Cloudpayments SDK iOS (Default form)"
        case ownForm = "Cloudpayments SDK iOS (Custom form)"
    }
    
    public static let baseURLString = "https://api.cloudpayments.ru/"
    public static let baseIntentURLString = "https://intent-api.cloudpayments.ru/"
    
    private let defaultCardHolderName = "Cloudpayments SDK"
    
    private let threeDsSuccessURL = "https://cloudpayments.ru/success"
    private let threeDsFailURL = "https://cloudpayments.ru/fail"
    
    private let publicId: String
    private let apiUrl: String
    private let source: Source
    
    public required convenience init(publicId: String, apiUrl: String = baseURLString) {
        self.init(publicId: publicId, apiUrl: apiUrl, source: .ownForm)
    }
    
    init(publicId: String, apiUrl: String = baseURLString, source: Source) {
        self.publicId = publicId
        
        if (apiUrl.isEmpty) {
            self.apiUrl = CloudpaymentsApi.baseURLString
        } else {
            self.apiUrl = apiUrl
        }
        
        self.source = source
    }
    
    public class func getBankInfo(cardNumber: String,
                                  completion: ((_ bankInfo: BankInfo?, _ error: CloudpaymentsError?) -> ())?) {
        let cleanCardNumber = Card.cleanCreditCardNo(cardNumber)
        guard cleanCardNumber.count >= 6 else {
            completion?(nil, CloudpaymentsError.init(message: "You must specify at least the first 6 digits of the card number"))
            return
        }
        
        let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
        let firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        
        BankInfoRequest(firstSix: firstSixDigits).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: { response in
            completion?(response.model, nil)
        }, onError: { error in
            if !error.localizedDescription.isEmpty  {
                completion?(nil, CloudpaymentsError.init(message: error.localizedDescription))
            } else {
                completion?(nil, CloudpaymentsError.defaultCardError)
            }
        })
    }
    
   public class func getBinInfoWithIntentId(cleanCardNumber: String,
                                             with configuration: PaymentConfiguration,
                                             completion: @escaping (BankInfo?, Bool?) -> Void) {
        
        guard let intentId = configuration.paymentData.intentId else {
            completion(nil, false)
            return
        }
        
        var firstSixDigits: String? = nil
        
        if cleanCardNumber.count >= 6 {
            let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
            firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        }
        
        let queryItems = [
            "PaymentMethod": "Card",
            "Bin": firstSixDigits,
        ] as [String: String?]
        
        let request = BinInfoRequestWithIntentId(intentId: intentId, queryItems: queryItems, apiUrl: baseIntentURLString)
        
        request.execute { result in
            completion(result, true)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            print(error)
            completion(nil, false)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getMerchantConfiguration(configuration: PaymentConfiguration,
                                               completion: @escaping (ButtonConfiguration?) -> Void) {
        let request = ConfigurationRequest(queryItems: ["terminalPublicId" : configuration.publicId],
                                           apiUrl: configuration.apiUrl)
        
        request.execute { result in
            var isOnTPay = false
            var isOnSbp = false
            var isOnSberPay = false
            
            for element in result.model.externalPaymentMethods {
                guard let rawValue = element.type, let value = CaseOfBank(rawValue: rawValue) else { continue }
                
                switch value {
                case .tPay: isOnTPay = element.enabled
                case .sbp: isOnSbp = element.enabled
                case .sberPay: isOnSberPay = element.enabled
                }
            }
            
            let value = ButtonConfiguration(isOnTPayButton: isOnTPay,
                                            isOnSbpButton: isOnSbp,
                                            isOnSberPayButton: isOnSberPay,
                                            successRedirectUrl: result.model.terminalFullUrl,
                                            failRedirectUrl: result.model.terminalFullUrl,
                                            isTest: result.model.isTest)
            
            completion(value)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            print(error.localizedDescription)
            return completion(.init(isOnTPayButton: false, isOnSbpButton: false, isOnSberPayButton: false, isTest: false))
        }
    }
    
    
    public class func getSbpLinkIntentApi(puid: String,
                                          schema: String,
                                          configuration: PaymentConfiguration,
                                          completion handler: @escaping (Int?, String?) -> Void) {
        var queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        if !schema.isEmpty {
            queryItems["schema"] = schema
        }
        
        guard let sbpLink = configuration.paymentData.paymentLinks["Sbp"] else {
            print("[getSbpLinkIntentApi] Ссылка Sbp отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getSbpLinkIntentApi] Ссылка Sbp: \(sbpLink)")
        
        let request = SbpLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: sbpLink)
        
        print("[getSbpLinkIntentApi] Формируем запрос с URL: \(sbpLink)")
        print("[getSbpLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getSbpLinkIntentApi] Получена ссылка: \(resultLink)")
            
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func intentPatchById(configuration: PaymentConfiguration,
                                      patches: [[String: Any]],
                                      completion: @escaping (PaymentIntentResponse?) -> Void) {
        guard let intentId = configuration.paymentData.intentId else {
            print("PATCH: intentId отсутствует")
            completion(nil)
            return
        }
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: patches, options: []) else {
            print("PATCH: не удалось сериализовать JSON")
            completion(nil)
            return
        }
        
        var headers: [String: String] = [
            "Content-Type": "application/json-patch+json"
        ]
        
        if let secret = configuration.paymentData.secret {
            headers["Secret"] = secret
        }
        
        let request = IntentPatchById(
            patchBody: bodyData,
            intentId: intentId,
            apiUrl: baseIntentURLString,
            headers: headers
        )
        
        print("PATCH: отправка запроса")
        print("PATCH: \(patches)")
        
        request.execute { result in
            
            print("PATCH: ответ получен")
            
            completion(result)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            print("PATCH: ошибка: \(error.localizedDescription)")
            completion(nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func createIntent(with configuration: PaymentConfiguration,
                                   completion handler: @escaping (PaymentIntentResponse?) -> Void) {
        
        let publicId = configuration.publicId
        let currency = configuration.paymentData.currency
        let sсheme: IntentScheme = configuration.useDualMessagePayment ? .dual : .single
        let type = "Default"
        let scenario = "7"
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let email = configuration.paymentData.email
        let paymentUrl = "cloudpayments://sdk.cp.ru"
        let culture = configuration.paymentData.cultureName
        let payer = configuration.paymentData.payer
        let recurrent = configuration.paymentData.recurrent?.toDictionary()
        let receipt = configuration.paymentData.receipt?.toDictionary()
        let successRedirectUrl = configuration.successRedirectUrl
        let failRedirectUrl = configuration.failRedirectUrl
        
        let metadata: [String: Any]? = {
            if let jsonString = configuration.paymentData.jsonData,
               let data = jsonString.data(using: .utf8) {
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            }
            return nil
        }()
        
        let params: [String: Any?] = [
            "publicTerminalId": publicId,
            "currency": currency,
            "paymentSchema": sсheme.rawValue,
            "culture": culture,
            "type": type,
            "scenario": scenario,
            "amount": amount,
            "paymentUrl": paymentUrl,
            "receiptEmail": email,
            "userInfo": [
                "accountId": accountId,
                "firstName": payer?.firstName,
                "lastName": payer?.lastName,
                "middleName": payer?.middleName,
                "address": payer?.address,
                "street": payer?.street,
                "city": payer?.city,
                "country": payer?.country,
                "phone": payer?.phone,
                "postcode": payer?.postcode
            ],
            "recurrent": recurrent,
            "receipt": receipt,
            "metadata": metadata,
            "successRedirectUrl": successRedirectUrl,
            "failRedirectUrl":  failRedirectUrl
            
        ] as [String : Any?]
        
        let request = CreateIntentRequest(params: params,
                                          apiUrl: baseIntentURLString)
        request.execute { result in
            handler(result)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            print(error.localizedDescription)
            handler(nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getTPayLinkIntentApi(puid: String,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let tpayLink = configuration.paymentData.paymentLinks["TinkoffPay"] else {
            print("[getTPayLinkIntentApi] Ссылка TinkoffPay отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getTPayLinkIntentApi] Ссылка TinkoffPay: \(tpayLink)")
        
        let request = TPayLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: tpayLink)
        
        print("[getTPayLinkIntentApi] Формируем запрос с URL: \(tpayLink)")
        print("[getTPayLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getTPayLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getSberPayLinkIntentApi(puid: String,
                                              configuration: PaymentConfiguration,
                                              completion handler: @escaping (Int?, SberPayResponse?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let sberPayLink = configuration.paymentData.sberPayData else {
            print("[getSberPayLinkIntentApi] Ссылка SberPay отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getSberPayLinkIntentApi] Ссылка SberPay: \(sberPayLink)")
        
        let request = SberPayLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: sberPayLink)
        
        print("[getSberPayLinkIntentApi] Формируем запрос с URL: \(sberPayLink)")
        print("[getSberPayLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getSberPayLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            print("[getSberPayLinkIntentApi] Ошибка выполнения запроса SberPayLinkRequestIntent: \(error.localizedDescription)")
            handler(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getIntentWaitStatus(_ configuration: PaymentConfiguration,
                                          type: PaymentMethodType,
                                          completion: @escaping (Int?) -> Void) {
        guard let intentId = configuration.paymentData.intentId else { return }
        
        let request = IntentStatusWait(intentId: intentId, apiUrl: baseIntentURLString)
        
        let observerName: Notification.Name
        switch type {
        case .tpay:
            observerName = ObserverKeys.intentTpayObserver.key
        case .sberPay:
            observerName = ObserverKeys.intentSberPayObserver.key
        case .sbp:
            observerName = ObserverKeys.intentSbpObserver.key
        }
        
        request.executeWithStatusCode { statusCode, value in
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
            completion(statusCode)
            
            NotificationCenter.default.post(name: observerName, object: value)
        } onError: { statusCode, error in
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            completion(statusCode)
            
            NotificationCenter.default.post(name: observerName, object: error)
        }
    }
    
    public func createIntentApiPay(cardCryptogram: String,
                                   with configuration: PaymentConfiguration,
                                   completion: @escaping (Int?, PaymentIntentResponse?) -> Void) {
        
        let params = ["Id": configuration.paymentData.intentId,
                      "PaymentMethod": "Card",
                      "Cryptogram": cardCryptogram]
        
        print(cardCryptogram)
        print(params)
        
        let request = CreateIntentApiPayRequest(params: params,
                                                apiUrl: CloudpaymentsApi.baseIntentURLString)
        
        request.executeWithStatusCode { statusCode, result in
            print("Status Code: \(statusCode), Result: \(String(describing: result))")
            completion(statusCode, result)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            completion(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    class func loadImage(url string: String,
                         completion: @escaping (UIImage?) -> Void) {
        
        guard let url = URL(string: string) else { return completion(nil) }
        
        let task = URLSession.shared.dataTask(with: .init(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return completion(nil) }
            completion(image)
        }
        
        task.resume()
    }
}

public typealias CloudpaymentsRequestCompletion<T> = (_ response: T?, _ error: Error?) -> Void

private struct CloudpaymentsCodingKey: CodingKey {
    var stringValue: String
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    init?(intValue: Int) {
        return nil
    }
}

extension JSONDecoder.KeyDecodingStrategy {
    static var convertToUpperCamelCase: JSONDecoder.KeyDecodingStrategy {
        return .custom({ keys -> CodingKey in
            let lastKey = keys.last!
            if lastKey.intValue != nil {
                return lastKey
            }
            
            let firstLetter = lastKey.stringValue.prefix(1).lowercased()
            let modifiedKey = firstLetter + lastKey.stringValue.dropFirst()
            return CloudpaymentsCodingKey(stringValue: modifiedKey)
        })
    }
}

extension CloudpaymentsApi {
    public class func getPublicKey(completion: @escaping (PublicKeyResponse?, Error?) -> Void) {
        let publicKeyUrl = baseURLString + "payments/publickey"
        guard let url = URL(string: publicKeyUrl) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            guard let method = request.httpMethod else {
                return
            }
            guard let path = request.url?.absoluteString else {
                return
            }
            
            guard let data = data else {
                completion(nil, CloudpaymentsError.networkError)
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PublicKeyResponse.self, from: data)
                completion(response, nil)
                LoggerService.shared.logApiRequest(method: method, url: path, success: true)
            } catch {
                LoggerService.shared.logApiRequest(method: method, url: path, success: false)
                completion(nil, error)
            }
        }.resume()
    }
}

