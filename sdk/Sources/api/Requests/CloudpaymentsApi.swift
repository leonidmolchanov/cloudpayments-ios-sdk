
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
    
    public class func getBinInfo(cleanCardNumber: String, 
                                 with configuration: PaymentConfiguration,
                                 completion: @escaping (BankInfo?, Bool?) -> Void) {
      
        var sevenNumberHash: String? = nil
        var eightNumberHash: String? = nil
        var firstSixDigits: String? = nil
        
        if cleanCardNumber.count >= 6 {
            let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
            firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        }
        
        if cleanCardNumber.count >= 7 {
            let firstSevenIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 7)
            let firstSevenDigits = String(cleanCardNumber[..<firstSevenIndex])
            
            sevenNumberHash = RSAUtils.sha512HashString(input: firstSevenDigits)
        }
        
        if cleanCardNumber.count >= 8 {
            let firstEightIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 8)
            let firstEightDigits = String(cleanCardNumber[..<firstEightIndex])
            
            eightNumberHash = RSAUtils.sha512HashString(input: firstEightDigits)
        }
    
        var queryItems = [
            "Bin": firstSixDigits,
            "Currency": configuration.paymentData.currency,
            "Amount": configuration.paymentData.amount,
        ] as [String: String?]
        
        if let isQiwi = configuration.paymentData.isQiwi {
            queryItems["isQiwi"] = String(isQiwi)
        }
        
        if let isAllowedNotSanctionedCards = configuration.paymentData.isAllowedNotSanctionedCards {
            queryItems["isAllowedNotSanctionedCards"] = String(isAllowedNotSanctionedCards)
        }

        if let sevenNumberHash = sevenNumberHash {
            queryItems["SevenNumberHash"] = sevenNumberHash
        }
        
        if let eightNumberHash = eightNumberHash {
            queryItems["EightNumberHash"] = eightNumberHash
        }
        
        let request = BinInfoRequest(queryItems: queryItems, apiUrl: configuration.apiUrl)

        request.execute { result in
            completion(result.model, result.success)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            print(error)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            completion(nil, false)
        }
    }
    
    public func charge(cardCryptogramPacket: String,
                       email: String?,
                       paymentData: PaymentData,
                       completion: @escaping CloudpaymentsRequestCompletion<TransactionResponse>) {
        let parameters = generateParams(cardCryptogramPacket: cardCryptogramPacket,
                                        email: email,
                                        paymentData: paymentData)
        ChargeRequest(params: patch(params: parameters), headers: getDefaultHeaders(), apiUrl: apiUrl).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: { response in
            completion(response, nil)
            
            LoggerService.shared.logApiRequest(method: "POST", url: "https://api.cloudpayments.ru/payments/cards/charge", success: true)
            
            
        }, onError: { error in
            
            LoggerService.shared.logApiRequest(method: "POST", url: "https://api.cloudpayments.ru/payments/cards/charge", success: false)
            
            completion(nil, error)
        })
    }
    
    public func auth(cardCryptogramPacket: String,
                     email: String?,
                     paymentData: PaymentData,
                     completion: @escaping CloudpaymentsRequestCompletion<TransactionResponse>) {
        let parameters = generateParams(cardCryptogramPacket: cardCryptogramPacket,
                                        email: email,
                                        paymentData: paymentData)
        AuthRequest(params: patch(params: parameters), headers: getDefaultHeaders(), apiUrl: apiUrl).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: {
            response in
            completion(response, nil) 
            
            LoggerService.shared.logApiRequest(method: "POST", url: "https://api.cloudpayments.ru/payments/cards/auth", success: true)
            
        }, onError: { error in
            
            LoggerService.shared.logApiRequest(method: "POST", url: "https://api.cloudpayments.ru/payments/cards/auth", success: false)
            
            completion(nil, error)
        })
    }
    
    fileprivate static func determineSaveCardMode(_ configuration: PaymentConfiguration) -> Bool? {
        if let saveCardMode = configuration.saveCardSinglePaymentMode {
            return saveCardMode
        } else {
            return configuration.paymentData.saveCard
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
    
    public class func getSbpLink(with configuration: PaymentConfiguration, 
                                 completion handler: @escaping (AltPayTransactionResponse?) -> Void) {
        
        let publicId = configuration.publicId
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let invoiceId = configuration.paymentData.invoiceId
        let description = configuration.paymentData.description
        let currency = configuration.paymentData.currency
        let email = configuration.paymentData.email
        let jsonData = configuration.paymentData.getJsonData()
        let successRedirectUrl = configuration.successRedirectUrl
        let apiUrl = configuration.apiUrl
        
        var params = [
            "PublicId": publicId,
            "Amount" :  amount,
            "InvoiceId": invoiceId,
            "Currency" : currency,
            "AccountId": accountId,
            "Device" : "MobileApp",
            "Description" : description,
            "Email" : email,
            "TtlMinutes" : 30,
            "Scenario": "7",
            "JsonData": jsonData,
        ] as [String : Any?]
    
        if let saveCard = determineSaveCardMode(configuration) {
            params["SaveCard"] = saveCard
        }
        
        if let successRedirectUrl = successRedirectUrl {
            params["SuccessRedirectUrl"] = successRedirectUrl
        }
        
        let request = SbpLinkRequest(params: params,
                                     apiUrl: apiUrl)
        
        request.execute { result in
            handler(result.model)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            print(error.localizedDescription)
            handler(nil)
        }
    }
    
    public class func getTPayLink(with configuration: PaymentConfiguration,
                                        completion handler: @escaping (AltPayTransactionResponse?) -> Void) {
                
        let publicId = configuration.publicId
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let invoiceId = configuration.paymentData.invoiceId
        let description = configuration.paymentData.description
        let currency = configuration.paymentData.currency
        let email = configuration.paymentData.email
        let sсheme: Scheme = configuration.useDualMessagePayment ? .auth : .charge
        let jsonData = configuration.paymentData.getJsonData()
        let successRedirectUrl = configuration.successRedirectUrl
        let failRedirectUrl = configuration.failRedirectUrl
        let apiUrl = configuration.apiUrl
        
        var params = [
            "PublicId": publicId,
            "Amount" : amount,
            "AccountId": accountId,
            "InvoiceId": invoiceId,
            "Browser" : nil,
            "Currency" : currency,
            "Device" : "MobileApp",
            "Description" : description,
            "Email" : email,
            "Os" : "iOS",
            "Scheme" : sсheme.rawValue,
            "TtlMinutes" : 30,
            "SuccessRedirectUrl" : successRedirectUrl,
            "FailRedirectUrl" : failRedirectUrl,
            "Webview" : true,
            "Scenario": "7",
            "JsonData": jsonData,
        ] as [String : Any?]
        
        if let saveCard = determineSaveCardMode(configuration) {
            params["SaveCard"] = saveCard
        }
        
        let request = TPayLinkRequest(params: params,
                                      apiUrl: apiUrl)
        
        request.execute { result in
            handler(result.model)
                    
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            print(error.localizedDescription)
            handler(nil)
        }
    }
    
    public class func getSberPayLink(with configuration: PaymentConfiguration,
                                     completion handler: @escaping (AltPayTransactionResponse?) -> Void) {
                
        let publicId = configuration.publicId
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let invoiceId = configuration.paymentData.invoiceId
        let description = configuration.paymentData.description
        let currency = configuration.paymentData.currency
        let email = configuration.paymentData.email
        let sсheme: Scheme = configuration.useDualMessagePayment ? .auth : .charge
        let jsonData = configuration.paymentData.getJsonData()
        let successRedirectUrl = configuration.successRedirectUrl
        let failRedirectUrl = configuration.failRedirectUrl
        let apiUrl = configuration.apiUrl
        
        var params = [
            "PublicId": publicId,
            "Amount" : amount,
            "AccountId": accountId,
            "InvoiceId": invoiceId,
            "Browser" : nil,
            "Currency" : currency,
            "Device" : "MobileApp",
            "Description" : description,
            "Email" : email,
            "Os" : "iOS",
            "Scheme" : sсheme.rawValue,
            "TtlMinutes" : 30,
            "SuccessRedirectUrl" : successRedirectUrl,
            "FailRedirectUrl" : failRedirectUrl,
            "Webview" : true,
            "Scenario": "7",
            "JsonData": jsonData,
        ] as [String : Any?]
        
        if let saveCard = determineSaveCardMode(configuration) {
            params["SaveCard"] = saveCard
        }
     
        let request = SberPayLinkRequest(params: params,
                                         apiUrl: apiUrl)
        
        request.execute { result in
            handler(result.model)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            print(error.localizedDescription)
            handler(nil)
        }
    }
    
    public class func getWaitStatus(_ configuration: PaymentConfiguration,
                                    _ transactionId: Int64,
                                    _ publicId: String) {
        
        let apiUrl = configuration.apiUrl
        
        let params = [
            "TransactionId": transactionId,
            "PublicId": publicId,
        ] as [String : Any?]
        
        let request = WaitStatusRequest(params: params,
                                        apiUrl: apiUrl)
        
        request.execute { value in
            NotificationCenter.default.post(name: ObserverKeys.generalObserver.key,
                                            object: value)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            print(error.localizedDescription)
            NotificationCenter.default.post(name: ObserverKeys.generalObserver.key,
                                            object: error)
            return
        }
    }
    
    public func post3ds(transactionId: String, 
                        threeDsCallbackId: String,
                        paRes: String, completion: @escaping (_ result: ThreeDsResponse) -> ()) {
        
        let mdParams = ["TransactionId": transactionId,
                        "ThreeDsCallbackId": threeDsCallbackId,
                        "SuccessUrl": self.threeDsSuccessURL,
                        "FailUrl": self.threeDsFailURL]
        if let mdParamsData = try? JSONSerialization.data(withJSONObject: mdParams, options: .sortedKeys), let mdParamsStr = String.init(data: mdParamsData, encoding: .utf8) {
            let parameters: [String: Any] = [
                "MD" : mdParamsStr,
                "PaRes" : paRes
            ]

            PostThreeDsRequest(params: parameters, headers: getDefaultHeaders(), apiUrl: apiUrl).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: { r in
            }, onError: { error in
            }, onRedirect: { [weak self] request in
                guard let self = self else {
                    return true
                }
                
                if let url = request.url {
                    let items = url.absoluteString.split(separator: "&").filter { $0.contains("ReasonCode")}
                    var reasonCode: String? = nil
                    if !items.isEmpty, let params = items.first?.split(separator: "="), params.count == 2 {
                        reasonCode = String(params[1]).removingPercentEncoding
                    }
                    
                    LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: true)

                    if url.absoluteString.starts(with: self.threeDsSuccessURL) {
                        DispatchQueue.main.async {
                            let r = ThreeDsResponse.init(success: true, reasonCode: reasonCode)
                            completion(r)
                        }
                        
                        return false
                    } else if url.absoluteString.starts(with: self.threeDsFailURL) {
                        DispatchQueue.main.async {
                            let r = ThreeDsResponse.init(success: false, reasonCode: reasonCode)
                            completion(r)
                        }
                        
                        LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: false)
                        
                        return false
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            })
        } else {
            completion(ThreeDsResponse.init(success: false, reasonCode: ""))
        }
    }
    
    private func generateParams(cardCryptogramPacket: String,
                                email: String?,
                                paymentData: PaymentData) -> [String: Any] {
        
        var parameters: [String: Any] = [
            "Amount" : paymentData.amount, // Сумма платежа (Обязательный)
            "Currency" : paymentData.currency, // Валюта (Обязательный)
            "Name" : paymentData.cardholderName ?? defaultCardHolderName, // Имя держателя карты в латинице (Обязательный для всех платежей кроме Apple Pay и Google Pay)
            "CardCryptogramPacket" : cardCryptogramPacket, // Криптограмма платежных данных (Обязательный)
            "Email" : email ?? "", // E-mail, на который будет отправлена квитанция об оплате
            "InvoiceId" : paymentData.invoiceId ?? "", // Номер счета или заказа в вашей системе (Необязательный)
            "Description" : paymentData.description ?? "", // Описание оплаты в свободной форме (Необязательный)
            "AccountId" : paymentData.accountId ?? "", // Идентификатор пользователя в вашей системе (Необязательный)
            "Payer" : paymentData.payer?.dictionary as Any, // Доп. поле, куда передается информация о плательщике. (Необязательный)
            "scenario" : 7
        ]
        
        if let jsonData = paymentData.getJsonData() {
            parameters["JsonData"] = jsonData // Любые другие данные, которые будут связаны с транзакцией, в том числе инструкции для создания подписки или формирования онлайн-чека (Необязательный)
        }
        
        if let saveCard = paymentData.saveCard {
            parameters["SaveCard"] = saveCard
        }
        
        if let splitsDataArray = paymentData.splits {
            let splitsDictArray = splitsDataArray.flatMap { $0.splits.map { $0.dictionary } }
            parameters["Splits"] = splitsDictArray
        }
        
        return parameters
    }

    private func patch(params: [String: Any]) -> [String: Any] {
        var parameters = params
        parameters["PublicId"] = self.publicId
        return parameters
    }
    
    private func getDefaultHeaders() -> [String: String] {
        var headers = [String: String]()
        headers["MobileSDKSource"] = self.source.rawValue
        return headers
    }
    
    class func loadImage(url string: String, completion: @escaping (UIImage?) -> Void) {
        
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
