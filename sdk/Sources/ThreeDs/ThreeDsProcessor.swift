//
//  ThreeDSDialog.swift
//  sdk
//
//  Created by Sergey Iskhakov on 09.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import WebKit

public protocol ThreeDsDelegate: AnyObject  {
    func willPresentWebView(_ webView: WKWebView)
    func onAuthorizationCompleted(with transactionStatus: Bool?)
    func onAuthorizationFailed(with code: String)
}

public class ThreeDsProcessor: NSObject, WKNavigationDelegate {
    private weak var delegate: ThreeDsDelegate?
    private var intentId: String?
    
    public func make3DSPayment(with data: ThreeDsData, delegate: ThreeDsDelegate, intentId: String?) {
        self.delegate = delegate
        self.intentId = intentId
        
        print(" make3DSPayment STARTED")
        print(" - acsUrl: \(data.acsUrl)")
        print(" - transactionId: \(data.transactionId)")
        print(" - paReq: \(data.paReq)")

        let mdParams: [String: Any] = [
            "TransactionId": data.transactionId,
            "ThreeDsCallbackId": data.threeDSCallbackId,
            "SuccessUrl": "https://cp.ru",
            "FailUrl": "https://cp.ru"
        ]
        
        print("MDParams before encoding: \(mdParams)")

        if let mdParamsData = try? JSONSerialization.data(withJSONObject: mdParams, options: .sortedKeys),
           let mdParamsStr = String(data: mdParamsData, encoding: .utf8) {
            
            let base64MD = RSAUtils.base64Encode(mdParamsStr.data(using: .utf8)!)
            
            print("MDParams JSON: \(mdParamsStr)")
            print("MDParams Base64: \(base64MD)")
            
            if let url = URL(string: data.acsUrl) {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.cachePolicy = .reloadIgnoringCacheData
                
                let requestBody = String(format: "MD=%@&PaReq=%@&TermUrl=%@", base64MD, data.paReq, termUrl()).replacingOccurrences(of: "+", with: "%2B")
                request.httpBody = requestBody.data(using: .utf8)
                
                print("3DS Request URL: \(url)")
                print("Request Body: \(requestBody)")
                
                URLCache.shared.removeCachedResponse(for: request)
                
                URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else {
                        return
                    }
                    
                    if let error = error {
                        print("Request failed with error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.delegate?.onAuthorizationFailed(with: error.localizedDescription)
                        }
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("Response Status Code: \(httpResponse.statusCode)")
                        
                        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201), let data = data {
                            print("3DS Response received, loading into WebView")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else {
                                    return
                                }
                                
                                LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: true)
                                
                                let webView = WKWebView()
                                webView.navigationDelegate = self
                                if let mimeType = httpResponse.mimeType,
                                   let url = httpResponse.url {
                                    
                                    let textEncodingName = httpResponse.textEncodingName ?? ""
                                    webView.load(data, mimeType: mimeType, characterEncodingName: textEncodingName, baseURL: url)
                                }
                                self.delegate?.willPresentWebView(webView)
                            }
                        } else {
                            print("Invalid status code: \(httpResponse.statusCode)")
                            DispatchQueue.main.async {
                                self.delegate?.onAuthorizationFailed(with: "Status code: \(httpResponse.statusCode)")
                                
                                LoggerService.shared.logApiRequest(method: request.httpMethod ?? "", url: url.absoluteString, success: false)
                            }
                        }
                    }
                }.resume()
            } else {
                print("Invalid ACS URL")
                self.delegate?.onAuthorizationFailed(with: "Invalid ACS URL")
            }
            
        }
    }
    
    private func termUrl() -> String {
        guard let intentId = intentId else { return "" }
        return "https://intent-api.cloudpayments.ru/api/intent/\(intentId)/threeDsResult"
    }

    //MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let url = webView.url
        
        if url?.absoluteString.elementsEqual(termUrl()) == true {
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
                var str = result as? String ?? ""
                let method = "POST"

                repeat {
                    guard let startIndex = str.firstIndex(of: "{"),
                          let endIndex = str.lastIndex(of: "}") else {
                        break
                    }
                    
                    str = String(str[startIndex...endIndex])
                    
                    if let data = str.data(using: .utf8) {
                        do {
                            let result = try JSONDecoder().decode(IntentThreeDsResultResponse.self, from: data)
                            if result.data?.success == true {
                                self.delegate?.onAuthorizationCompleted(with: true)
                                
                                LoggerService.shared.logApiRequest(method: method, url: self.termUrl(), success: true)
                                
                            } else {
                                print("Ошибка 3DS, код: \(String(describing: result.data?.code))")
                                self.delegate?.onAuthorizationFailed(with: result.data?.code ?? "Операция не может быть обработана")
                                
                                LoggerService.shared.logApiRequest(method: method, url: self.termUrl(), success: false)
                            }
                        } catch {
                            print("Ошибка при разборе JSON: \(error.localizedDescription)")
                            self.delegate?.onAuthorizationFailed(with: "JSON Parse Error")
                        }
                    }
                } while false
            }
        }
    }
}
